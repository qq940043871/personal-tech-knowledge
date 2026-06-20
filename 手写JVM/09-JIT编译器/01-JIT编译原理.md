# JIT编译原理

> 模块：手写JVM / 09-JIT编译器
> 更新时间：2026-06-20

---

## 一、JIT概述

JIT（Just-In-Time）编译器将热点字节码编译为本地机器码，提升执行效率。

### 1.1 执行模式

```
字节码 → 解释执行 → 热点检测 → JIT编译 → 机器码执行
```

### 1.2 热点检测

```cpp
// 方法调用计数器
class Method {
    int invocation_count;
    int back_edge_count;
    
    bool is_hot() {
        return invocation_count > threshold ||
               back_edge_count > back_edge_threshold;
    }
};
```

---

## 二、编译器类型

### 2.1 C1编译器（Client Compiler）

- 编译速度快
- 优化程度低
- 适合客户端应用

### 2.2 C2编译器（Server Compiler）

- 编译速度慢
- 优化程度高
- 适合服务器应用

### 2.3 分层编译

```
Level 0: 解释执行
Level 1: C1编译，无性能监控
Level 2: C1编译，有限性能监控
Level 3: C1编译，完整性能监控
Level 4: C2编译
```

---

## 三、编译优化

### 3.1 方法内联

```java
// 优化前
public int add(int a, int b) {
    return a + b;
}
public int calculate() {
    return add(1, 2);
}

// 优化后
public int calculate() {
    return 1 + 2; // 内联
}
```

### 3.2 逃逸分析

```java
// 对象不逃逸方法，可栈上分配
public void method() {
    Point p = new Point(1, 2); // 不逃逸
    System.out.println(p.x + p.y);
}

// 优化为
public void method() {
    int x = 1, y = 2; // 标量替换
    System.out.println(x + y);
}
```

### 3.3 循环优化

```java
// 循环展开
for (int i = 0; i < 100; i++) {
    sum += i;
}

// 优化为
for (int i = 0; i < 100; i += 4) {
    sum += i;
    sum += i + 1;
    sum += i + 2;
    sum += i + 3;
}
```

### 3.4 死代码消除

```java
// 优化前
int x = 10;
int y = 20;
int z = x + y; // z未使用

// 优化后
// z被消除
```

---

## 四、编译触发条件

### 4.1 方法调用计数

```cpp
// Client模式
int threshold = 1500;

// Server模式
int threshold = 10000;
```

### 4.2 回边计数

```cpp
// 循环回边次数
int back_edge_threshold = 10700;
```

### 4.3 配置参数

```bash
# 设置编译阈值
-XX:CompileThreshold=10000

# 设置回边阈值
-XX:OnStackReplacePercentage=140

# 设置编译线程数
-XX:CICompilerCount=4
```

---

## 五、逆优化

### 5.1 逆优化场景

- 类型假设失败
- 去优化（Deoptimization）
- 重编译

### 5.2 逆优化过程

```cpp
void deoptimize(Method* method) {
    // 1. 恢复解释执行状态
    method->set_not_compiled();
    
    // 2. 重建栈帧
    rebuild_stack_frame();
    
    // 3. 继续解释执行
    interpret(method);
}
```

---

## 六、编译日志

### 6.1 开启编译日志

```bash
-XX:+PrintCompilation
-XX:+UnlockDiagnosticVMOptions
-XX:+PrintInlining
```

### 6.2 日志解读

```
  78   1       3       java.lang.String::hashCode (55 bytes)
  78   2       4       java.lang.String::hashCode (55 bytes)
```

- `78` — 时间戳
- `1` — 编译ID
- `3` — 编译层级
- `java.lang.String::hashCode` — 编译的方法
- `(55 bytes)` — 字节码大小

---

## 七、最佳实践

1. **合理设置编译阈值** — 根据应用特点设置
2. **开启编译日志** — 监控编译情况
3. **避免频繁逆优化** — 保持类型稳定
4. **使用分层编译** — 平衡启动速度和峰值性能
5. **监控编译线程** — 避免编译线程不足

---

## 八、与AOT对比

| 特性 | JIT | AOT |
|------|-----|-----|
| 编译时机 | 运行时 | 编译时 |
| 启动速度 | 慢 | 快 |
| 峰值性能 | 高 | 中 |
| 优化能力 | 强 | 弱 |
| 适用场景 | 长期运行 | 启动敏感 |

---

*JIT编译是JVM性能优化的核心技术。*
