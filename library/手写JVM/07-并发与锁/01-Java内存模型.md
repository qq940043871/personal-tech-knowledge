# Java内存模型

> 模块：手写JVM / 07-并发与锁
> 更新时间：2026-06-20

---

## 一、JMM概述

Java内存模型（JMM）定义了多线程程序中变量的访问规则，保证内存可见性和有序性。

### 1.1 主内存与工作内存

```
主内存（Main Memory）
├── 变量A
├── 变量B
└── 变量C

工作内存1（线程1）    工作内存2（线程2）
├── 变量A副本          ├── 变量A副本
└── 变量B副本          └── 变量C副本
```

### 1.2 内存交互操作

| 操作 | 说明 |
|------|------|
| lock | 主内存变量加锁 |
| unlock | 主内存变量解锁 |
| read | 主内存读取变量 |
| load | 将read的变量加载到工作内存 |
| use | 将变量传递给执行引擎 |
| assign | 将执行结果赋值给变量 |
| store | 将工作内存变量传送到主内存 |
| write | 将store的变量写入主内存 |

---

## 二、volatile关键字

### 2.1 可见性

```java
// volatile保证可见性
volatile boolean running = true;

// 线程1
while (running) {
    // 执行任务
}

// 线程2
running = false; // 立即可见
```

### 2.2 有序性

```java
// 禁止指令重排序
volatile int a = 1;
int b = 2;

// 保证a=1在b=2之前执行
```

### 2.3 实现原理

```cpp
// 内存屏障
class VolatileVariable {
    int value;
    
    void store(int new_value) {
        value = new_value;
        // 写屏障：保证之前的写操作对其他线程可见
        store_barrier();
    }
    
    int load() {
        // 读屏障：保证读到最新值
        load_barrier();
        return value;
    }
};
```

---

## 三、happens-before规则

### 3.1 规则列表

| 规则 | 说明 |
|------|------|
| 程序顺序规则 | 同一线程内，前面的操作happens-before后面的操作 |
| 监视器锁规则 | unlock操作happens-before后续的lock操作 |
| volatile变量规则 | volatile写happens-before后续的volatile读 |
| 线程启动规则 | Thread.start()happens-before线程内所有操作 |
| 线程终止规则 | 线程内所有操作happens-before Thread.join() |
| 传递性 | A happens-before B，B happens-before C，则A happens-before C |

---

## 四、synchronized关键字

### 4.1 使用方式

```java
// 对象锁
synchronized (this) {
    // 临界区
}

// 方法锁
public synchronized void method() {
    // 临界区
}

// 类锁
public static synchronized void staticMethod() {
    // 临界区
}
```

### 4.2 实现原理

```cpp
// Monitor对象
class Monitor {
    Object* owner;          // 持有者
    WaitSet* wait_set;      // 等待集合
    EntryList* entry_list;  // 入口列表
    
    void enter(Thread* thread) {
        if (owner == nullptr) {
            owner = thread;
        } else {
            entry_list->add(thread);
            thread->block();
        }
    }
    
    void exit(Thread* thread) {
        owner = nullptr;
        if (!entry_list->empty()) {
            Thread* next = entry_list->remove_first();
            owner = next;
            next->unblock();
        }
    }
};
```

---

## 五、final关键字

### 5.1 语义保证

```java
// final字段初始化安全
final class Config {
    final int port;
    final String host;
    
    Config(int port, String host) {
        this.port = port;
        this.host = host;
    }
}

// 构造函数结束后，final字段对其他线程可见
```

### 5.2 内存屏障

```cpp
// final字段写入后插入写屏障
void constructor_end() {
    // 保证final字段在构造函数结束前初始化完成
    store_barrier();
}
```

---

## 六、原子操作

### 6.1 CAS操作

```java
// Compare And Swap
AtomicInteger counter = new AtomicInteger(0);

// 原子递增
counter.incrementAndGet();

// 原子比较并交换
counter.compareAndSet(0, 1);
```

### 6.2 实现原理

```cpp
// CPU原子指令
bool cas(int* addr, int expected, int new_value) {
    return __sync_bool_compare_and_swap(addr, expected, new_value);
}
```

---

## 七、线程安全

### 7.1 不可变对象

```java
// 不可变对象天然线程安全
final class User {
    private final String name;
    private final int age;
    
    User(String name, int age) {
        this.name = name;
        this.age = age;
    }
}
```

### 7.2 线程安全类

```java
// 线程安全集合
ConcurrentHashMap<String, String> map = new ConcurrentHashMap<>();
CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();
```

---

## 八、最佳实践

1. **优先使用不可变对象** — 天然线程安全
2. **合理使用volatile** — 适用于一写多读场景
3. **避免过度同步** — 减少锁竞争
4. **使用并发工具类** — ConcurrentHashMap、AtomicInteger等
5. **理解happens-before** — 保证内存可见性

---

*理解JMM是编写正确并发程序的基础。*
