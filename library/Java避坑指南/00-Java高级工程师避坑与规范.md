# Java高级工程师开发指南

> 作者：AI助手
> 更新日期：2026-03-29
> 版本：v1.0
> 适用：Java 8/11/17+

---

## 📋 目录

- [第一部分：开发避坑指南](#第一部分开发避坑指南)
  - [一、Java基础坑](#一java基础坑)
  - [二、集合框架坑](#二集合框架坑)
  - [三、多线程并发坑](#三多线程并发坑)
  - [四、IO流坑](#四io流坑)
  - [五、异常处理坑](#五异常处理坑)
  - [六、泛型坑](#六泛型坑)
- [第二部分：Spring开发坑](#第二部分spring开发坑)
  - [一、Spring核心坑](#一spring核心坑)
  - [二、Spring Boot坑](#二spring-boot坑)
  - [三、Spring事务坑](#三spring事务坑)
  - [四、Spring循环依赖](#四spring循环依赖)
- [第三部分：数据库开发坑](#第三部分数据库开发坑)
  - [一、SQL编写坑](#一sql编写坑)
  - [二、索引坑](#二索引坑)
  - [三、事务坑](#三事务坑)
  - [四、连接池坑](#四连接池坑)
- [第四部分：微服务开发坑](#第四部分微服务开发坑)
  - [一、服务间调用坑](#一服务间调用坑)
  - [二、分布式事务坑](#二分布式事务坑)
  - [三、幂等性坑](#三幂等性坑)
- [第五部分：开发规范](#第五部分开发规范)
  - [一、命名规范](#一命名规范)
  - [二、代码风格规范](#二代码风格规范)
  - [三、注释规范](#三注释规范)
  - [四、方法规范](#四方法规范)
  - [五、类设计规范](#五类设计规范)
  - [六、异常处理规范](#六异常处理规范)
  - [七、日志规范](#七日志规范)
  - [八、接口规范](#八接口规范)
  - [九、数据库规范](#九数据库规范)
  - [十、配置规范](#十配置规范)
  - [十一、安全规范](#十一安全规范)
  - [十二、Git提交规范](#十二git提交规范)

---

# 第一部分：开发避坑指南

## 一、Java基础坑

### 坑1：String的"+"拼接与StringBuilder

**❌ 错误示例**
```java
// 在循环中拼接字符串
String result = "";
for (int i = 0; i < 1000; i++) {
    result += "item" + i;  // 每次都创建新对象！
}
```

**✅ 正确做法**
```java
// 使用StringBuilder
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 1000; i++) {
    sb.append("item").append(i);
}
String result = sb.toString();

// 或者在明确场景下直接用 +
String a = "hello" + "world";  // 编译期优化，无问题
```

**原理说明**：String是不可变对象，`+=` 每次都会创建新String对象，在循环中会导致频繁GC。

---

### 坑2：BigDecimal的比较

**❌ 错误示例**
```java
BigDecimal a = new BigDecimal("0.1");
BigDecimal b = new BigDecimal("0.10");
System.out.println(a.equals(b));  // false！精度不同
System.out.println(a == b);        // false！
```

**✅ 正确做法**
```java
BigDecimal a = new BigDecimal("0.1");
BigDecimal b = new BigDecimal("0.10");

// 方法1：使用compareTo
System.out.println(a.compareTo(b) == 0);  // true

// 方法2：使用stripTrailingZeros
System.out.println(a.stripTrailingZeros()
    .equals(b.stripTrailingZeros()));  // true

// 最佳实践：使用String构造器，避免double
BigDecimal c = new BigDecimal("0.1");  // 精确
BigDecimal d = BigDecimal.valueOf(0.1);  // 推荐
```

---

### 坑3：包装类型与基本类型混合运算

**❌ 错误示例**
```java
Integer a = null;
int b = a + 1;  // NullPointerException！
```

**✅ 正确做法**
```java
Integer a = null;
if (a != null) {
    int b = a + 1;
}

// 或者使用Optional
Optional<Integer> optA = Optional.ofNullable(a);
int b = optA.orElse(0) + 1;
```

---

### 坑4：循环中创建对象

**❌ 错误示例**
```java
List<User> users = new ArrayList<>();
for (int i = 0; i < 10000; i++) {
    users.add(new User());  // 每次都new对象
}
```

**✅ 正确做法**
```java
// 预估容量，避免扩容
List<User> users = new ArrayList<>(10000);
for (int i = 0; i < 10000; i++) {
    users.add(new User());
}
```

---

### 坑5：Date与LocalDateTime混用

**❌ 错误示例**
```java
Date date = new Date();
LocalDateTime ldt = date.toInstant()  // 错误的转换
    .atZone(ZoneId.systemDefault())
    .toLocalDateTime();
```

**✅ 正确做法**
```java
// Java 8+ 使用 LocalDateTime
LocalDateTime ldt = LocalDateTime.now();

// Date 转 LocalDateTime
Date date = new Date();
LocalDateTime ldt = date.toInstant()
    .atZone(ZoneId.systemDefault())
    .toLocalDateTime();

// LocalDateTime 转 Date
LocalDateTime ldt2 = LocalDateTime.now();
Date date2 = Date.from(ldt2.atZone(ZoneId.systemDefault()).toInstant());

// 时间格式化
DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
String str = ldt.format(formatter);
LocalDateTime parsed = LocalDateTime.parse(str, formatter);
```

---

## 二、集合框架坑

### 坑6：Arrays.asList的坑

**❌ 错误示例**
```java
int[] arr = {1, 2, 3};
List<int[]> list = Arrays.asList(arr);  // 得到List<int[]>，不是List<Integer>！

list.add(4);  // UnsupportedOperationException！
```

**✅ 正确做法**
```java
// 基本类型数组要手动转换
int[] arr = {1, 2, 3};
List<Integer> list = Arrays.stream(arr)
    .boxed()
    .collect(Collectors.toList());

// 如果需要可变List
List<Integer> mutableList = new ArrayList<>(Arrays.asList(1, 2, 3));
mutableList.add(4);

// 或者使用List.of (Java 9+)
List<Integer> immutableList = List.of(1, 2, 3);
```

---

### 坑7：HashMap的并发问题

**❌ 错误示例**
```java
Map<String, Integer> map = new HashMap<>();
for (int i = 0; i < 1000; i++) {
    new Thread(() -> map.put("key", i)).start();  // 并发不安全！
}
```

**✅ 正确做法**
```java
// 方法1：使用ConcurrentHashMap
Map<String, AtomicInteger> map = new ConcurrentHashMap<>();
for (int i = 0; i < 1000; i++) {
    new Thread(() -> 
        map.computeIfAbsent("key", k -> new AtomicInteger())
           .incrementAndGet()
    ).start();
}

// 方法2：Collections.synchronizedMap（性能较差）
Map<String, Integer> syncMap = Collections.synchronizedMap(new HashMap<>());

// 方法3：Guava的ConcurrentHashMultimap
```

---

### 坑8：ConcurrentHashMap的误用

**❌ 错误示例**
```java
ConcurrentHashMap<String, List<Order>> map = new ConcurrentHashMap<>();

// 错误的复合操作
List<Order> orders = map.get(userId);
if (orders == null) {
    orders = new ArrayList<>();  // A线程
    map.put(userId, orders);       // B线程可能也put了
}
orders.add(order);  // 数据可能丢失！
```

**✅ 正确做法**
```java
// 使用computeIfAbsent原子操作
map.computeIfAbsent(userId, k -> new ArrayList<>()).add(order);

// 或者使用putIfAbsent + 循环重试
List<Order> orders;
do {
    orders = map.get(userId);
    if (orders == null) {
        orders = new ArrayList<>();
    }
} while (!map.replace(userId, expected, newOrders));
```

---

### 坑9：List删除元素的坑

**❌ 错误示例**
```java
List<String> list = new ArrayList<>(Arrays.asList("a", "b", "c"));
for (String item : list) {
    if ("b".equals(item)) {
        list.remove(item);  // ConcurrentModificationException！
    }
}
```

**✅ 正确做法**
```java
List<String> list = new ArrayList<>(Arrays.asList("a", "b", "c"));

// 方法1：Iterator
Iterator<String> iterator = list.iterator();
while (iterator.hasNext()) {
    if ("b".equals(iterator.next())) {
        iterator.remove();
    }
}

// 方法2：removeIf (Java 8+)
list.removeIf("b"::equals);

// 方法3：倒序遍历
for (int i = list.size() - 1; i >= 0; i--) {
    if ("b".equals(list.get(i))) {
        list.remove(i);
    }
}
```

---

## 三、多线程并发坑

### 坑10：synchronized的误区

**❌ 错误示例**
```java
public class Counter {
    private int count = 0;
    
    // 锁的是this，不是count！
    public synchronized void increment() {
        count++;
    }
    
    // 另一个方法没有加锁
    public void reset() {
        count = 0;  // 不安全！
    }
}
```

**✅ 正确做法**
```java
public class Counter {
    private int count = 0;
    private final Object lock = new Object();
    
    public void increment() {
        synchronized (lock) {  // 使用专门的锁对象
            count++;
        }
    }
    
    public void reset() {
        synchronized (lock) {
            count = 0;
        }
    }
}

// 或者使用AtomicInteger
private AtomicInteger count = new AtomicInteger();

public void increment() {
    count.incrementAndGet();
}

public void reset() {
    count.set(0);
}
```

---

### 坑11：ThreadLocal的内存泄漏

**❌ 错误示例**
```java
public class UserContext {
    private static final ThreadLocal<User> userThreadLocal = new ThreadLocal<>();
    
    public static void set(User user) {
        userThreadLocal.set(user);  // 用完忘记remove！
    }
}

// 在线程池中使用，容易泄漏
ExecutorService executor = Executors.newFixedThreadPool(10);
executor.execute(() -> {
    UserContext.set(currentUser);
    // 业务逻辑
    // 忘记调用 UserContext.remove();
});
```

**✅ 正确做法**
```java
public class UserContext {
    private static final ThreadLocal<User> userThreadLocal = new ThreadLocal<>();
    
    public static void set(User user) {
        userThreadLocal.set(user);
    }
    
    public static User get() {
        return userThreadLocal.get();
    }
    
    // 务必在使用完毕后清理
    public static void remove() {
        userThreadLocal.remove();
    }
}

// 使用try-finally确保清理
try {
    UserContext.set(currentUser);
    // 业务逻辑
} finally {
    UserContext.remove();  // 一定要清理！
}

// 或者使用InheritableThreadLocal（慎用）
// 父线程的ThreadLocal会传递给子线程
```

---

### 坑12：volatile的误用

**❌ 错误示例**
```java
public class Counter {
    private volatile int count = 0;
    
    // volatile只能保证可见性，不能保证原子性！
    public void increment() {
        count++;  // 不是原子操作！count++实际上是3步：读、改、写
    }
}
```

**✅ 正确做法**
```java
public class Counter {
    private final AtomicInteger count = new AtomicInteger(0);
    
    public void increment() {
        count.incrementAndGet();  // 原子操作
    }
    
    public int get() {
        return count.get();
    }
}
```

---

### 坑13：Executors创建线程池

**❌ 错误示例**
```java
// 阿里规范禁止使用Executors创建线程池
ExecutorService executor = Executors.newFixedThreadPool(100);
// 风险：队列无限大，可能导致OOM

ExecutorService executor = Executors.newCachedThreadPool();
// 风险：最大线程数无限，可能创建过多线程
```

**✅ 正确做法**
```java
// 推荐：手动创建线程池
ExecutorService executor = new ThreadPoolExecutor(
    10,                    // corePoolSize
    50,                    // maximumPoolSize
    60L,                   // keepAliveTime
    TimeUnit.SECONDS,       // unit
    new LinkedBlockingQueue<>(1000),  // 队列大小，防止OOM
    new ThreadFactory() {
        private final AtomicInteger i = new AtomicInteger(1);
        @Override
        public Thread newThread(Runnable r) {
            return new Thread(r, "my-pool-" + i.getAndIncrement());
        }
    },
    new ThreadPoolExecutor.AbortPolicy()  // 拒绝策略
);

// 常见拒绝策略
// AbortPolicy: 抛出RejectedExecutionException
// CallerRunsPolicy: 由调用线程执行
// DiscardPolicy: 丢弃任务
// DiscardOldestPolicy: 丢弃队列最旧的任务
```

---

## 四、IO流坑

### 坑14：流未关闭

**❌ 错误示例**
```java
public String readFile(String path) {
    FileReader reader = new FileReader(path);
    char[] buffer = new char[1024];
    reader.read(buffer);  // 如果抛异常，流不会关闭！
    return new String(buffer);
}
```

**✅ 正确做法**
```java
// 方法1：try-with-resources（推荐）
public String readFile(String path) {
    try (FileReader reader = new FileReader(path)) {
        char[] buffer = new char[1024];
        reader.read(buffer);
        return new String(buffer);
    } catch (IOException e) {
        throw new RuntimeException(e);
    }
}

// 方法2：try-finally（不推荐）
public String readFile(String path) {
    FileReader reader = null;
    try {
        reader = new FileReader(path);
        char[] buffer = new char[1024];
        reader.read(buffer);
        return new String(buffer);
    } catch (IOException e) {
        throw new RuntimeException(e);
    } finally {
        if (reader != null) {
            try {
                reader.close();
            } catch (IOException e) {
                // 忽略
            }
        }
    }
}
```

---

### 坑15：资源泄漏

**❌ 错误示例**
```java
// 使用完InputStream忘记关闭
public byte[] readImage(String path) throws IOException {
    InputStream is = new FileInputStream(path);
    return is.readAllBytes();  // 可能抛异常，流未关闭
}
```

**✅ 正确做法**
```java
public byte[] readImage(String path) throws IOException {
    try (InputStream is = new FileInputStream(path)) {
        return is.readAllBytes();
    }
}

// 多个资源都要关闭
public void copyFile(String src, String dest) throws IOException {
    try (InputStream is = new FileInputStream(src);
         OutputStream os = new FileOutputStream(dest)) {
        is.transferTo(os);
    }
}
```

---

## 五、异常处理坑

### 坑16：捕获并吞掉异常

**❌ 错误示例**
```java
try {
    doSomething();
} catch (Exception e) {
    // 什么都不做！异常被吞掉了
}
```

**✅ 正确做法**
```java
try {
    doSomething();
} catch (SpecificException e) {
    // 记录日志
    log.error("执行失败", e);
    // 决定是继续抛出还是返回默认值
    throw new BusinessException("操作失败", e);
    // 或者返回空值
    return null;
}
```

---

### 坑17：异常丢失

**❌ 错误示例**
```java
try {
    doSomething();
} catch (IOException e) {
    throw new RuntimeException(e);  // 原始异常作为cause传入
} catch (Exception e) {
    throw new RuntimeException("未知错误");  // 原始异常丢失了！
}
```

**✅ 正确做法**
```java
try {
    doSomething();
} catch (IOException e) {
    throw new BusinessException("IO操作失败", e);
} catch (Exception e) {
    throw new BusinessException("未知错误", e);  // 保留原始异常
}
```

---

### 坑18：finally中抛异常

**❌ 错误示例**
```java
try {
    return doSomething();
} finally {
    doCleanup();  // 如果这里抛异常，会覆盖原始异常！
}

String doCleanup() {
    throw new RuntimeException("cleanup failed");
}
```

**✅ 正确做法**
```java
String result = null;
RuntimeException originalException = null;

try {
    result = doSomething();
} catch (RuntimeException e) {
    originalException = e;
    throw e;
} finally {
    try {
        doCleanup();
    } catch (Exception cleanupException) {
        if (originalException != null) {
            originalException.addSuppressed(cleanupException);
        } else {
            throw new RuntimeException(cleanupException);
        }
    }
}
```

---

## 六、泛型坑

### 坑19：泛型类型擦除

**❌ 错误示例**
```java
public class GenericClass<T> {
    public T getValue() {
        // 编译后变成 Object
        return new Object();  // ClassCastException！
    }
}
```

**✅ 正确做法**
```java
public class GenericClass<T> {
    public T getValue() {
        return null;  // 返回null是安全的
    }
}

// 如果需要创建泛型实例，使用反射
public T createInstance() {
    try {
        return (T) type.getDeclaredConstructor().newInstance();
    } catch (Exception e) {
        throw new RuntimeException(e);
    }
}
```

---

### 坑20：泛型数组

**❌ 错误示例**
```java
List<String>[] array = new List<String>[10];  // 编译错误！
```

**✅ 正确做法**
```java
// 使用通配符
List<?>[] array = new List<?>[10];
array[0] = new ArrayList<String>();
array[1] = new ArrayList<Integer>();

// 或者使用包装类
List<List<String>> list = new ArrayList<>();
```

---

# 第二部分：Spring开发坑

## 一、Spring核心坑

### 坑21：@Autowired与构造函数注入

**❌ 错误示例**
```java
@Controller
public class UserController {
    @Autowired
    private UserService userService;  // Field注入，不推荐
}
```

**✅ 正确做法**
```java
@Controller
public class UserController {
    private final UserService userService;
    
    // 构造器注入（推荐）
    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }
}

// 或者Lombok（更简洁）
@Controller
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;
}
```

---

### 坑22：@Transactional失效

**❌ 错误示例**
```java
@Service
public class UserService {
    
    @Transactional
    public void transfer(String from, String to, BigDecimal amount) {
        // 在同一个类中调用另一个@Transactional方法
        deduct(from, amount);      // 不会开启新事务！
        add(to, amount);           // 也不会开启新事务！
    }
    
    @Transactional
    public void deduct(String account, BigDecimal amount) {
        // 扣款逻辑
    }
}
```

**✅ 正确做法**
```java
@Service
public class UserService {
    
    // 同一类中调用走的是this，不是代理对象
    // 所以事务不生效
    
    // 方法1：注入自己
    @Autowired
    private UserService self;
    
    public void transfer(String from, String to, BigDecimal amount) {
        self.deduct(from, amount);
        self.add(to, amount);
    }
    
    // 方法2：拆分到另一个Service
    // 方法3：使用编程式事务
}
```

---

### 坑23：@Transactional在private方法上

**❌ 错误示例**
```java
@Service
public class UserService {
    
    @Transactional
    private void doSomething() {  // private方法，事务不生效
        // 事务不会生效，因为private方法不能被代理
    }
}
```

**✅ 正确做法**
```java
@Service
public class UserService {
    
    @Transactional
    public void publicMethod() {  // 必须是public
        // 业务逻辑
    }
}
```

---

## 二、Spring Boot坑

### 坑24：配置类扫描不到

**❌ 错误示例**
```java
@Configuration
public class MyConfig {  // 这个配置类可能扫描不到
    @Bean
    public MyService myService() {
        return new MyService();
    }
}
```

**✅ 正确做法**
```java
// 确保配置类能被扫描到
@Configuration
@ComponentScan(basePackages = {"com.example.config"})
public class MyConfig {

// 或者使用@Import显式导入
@SpringBootApplication
@Import(MyConfig.class)
public class Application {

// Spring Boot主类所在的包及其子包会被自动扫描
```

---

### 坑25：@Configuration的代理模式

**❌ 错误示例**
```java
@Configuration
public class MyConfig {
    
    @Bean
    public UserService userService() {
        return new UserService();  // 每次都返回新实例！
    }
}
```

**✅ 正确做法**
```java
@Configuration
public class MyConfig {
    
    @Bean
    public UserService userService() {
        return new UserService();  // 默认是单例，只调用一次
    }
    
    // 如果需要每次创建新实例
    @Bean
    @Scope("prototype")
    public UserService userServicePrototype() {
        return new UserService();
    }
}
```

---

## 三、Spring事务坑

### 坑26：事务与锁的顺序

**❌ 错误示例**
```java
@Transactional
public void transfer(String from, String to, BigDecimal amount) {
    // 先查余额
    Account fromAccount = accountMapper.findById(from);
    
    // 如果在查询后、更新前有其他事务读取，可能读到脏数据
    // 而且缺少行锁保护
    
    fromAccount.setBalance(fromAccount.getBalance().subtract(amount));
    accountMapper.update(fromAccount);
}
```

**✅ 正确做法**
```java
@Transactional
public void transfer(String from, String to, BigDecimal amount) {
    // 使用SELECT FOR UPDATE加行锁
    Account fromAccount = accountMapper.findByIdForUpdate(from);
    Account toAccount = accountMapper.findByIdForUpdate(to);
    
    // 检查余额
    if (fromAccount.getBalance().compareTo(amount) < 0) {
        throw new BizException("余额不足");
    }
    
    // 更新
    fromAccount.setBalance(fromAccount.getBalance().subtract(amount));
    toAccount.setBalance(toAccount.getBalance().add(amount));
    
    accountMapper.update(fromAccount);
    accountMapper.update(toAccount);
}
```

---

## 四、Spring循环依赖

### 坑27：构造器循环依赖

**❌ 错误示例**
```java
@Service
public class AService {
    private final BService bService;
    
    public AService(BService bService) {  // 构造器注入B
        this.bService = bService;
    }
}

@Service
public class BService {
    private final AService aService;
    
    public BService(AService aService) {  // 构造器注入A，循环依赖！
        this.aService = aService;
    }
}
```

**✅ 正确做法**
```java
// 方法1：使用@Lazy延迟注入
@Service
public class AService {
    private BService bService;
    
    public AService(@Lazy BService bService) {
        this.bService = bService;
    }
}

// 方法2：使用Setter注入
@Service
public class AService {
    private BService bService;
    
    @Autowired
    public void setBService(BService bService) {
        this.bService = bService;
    }
}

// 方法3：重新设计（最佳方案）
// 避免循环依赖是最好的设计
```

---

# 第三部分：数据库开发坑

## 一、SQL编写坑

### 坑28：SQL注入

**❌ 错误示例**
```java
// 危险！SQL注入漏洞
String sql = "SELECT * FROM user WHERE name = '" + name + "'";
statement.executeQuery(sql);

// 如果name = "' OR '1'='1"，会查出所有用户！
```

**✅ 正确做法**
```java
// 使用PreparedStatement
String sql = "SELECT * FROM user WHERE name = ?";
PreparedStatement ps = connection.prepareStatement(sql);
ps.setString(1, name);
ResultSet rs = ps.executeQuery();

// MyBatis使用#{}
<select id="findByName" resultType="User">
    SELECT * FROM user WHERE name = #{name}
</select>

// 避免使用${}，除非确定参数安全
```

---

### 坑29：SELECT * 的滥用

**❌ 错误示例**
```java
// 查询所有字段
List<User> users = userMapper.selectAll();

// 只需要id和name，但查了所有字段，增加网络开销
```

**✅ 正确做法**
```java
// 只查询需要的字段
@Select("SELECT id, name FROM user WHERE status = 1")
List<User> selectActiveUsers();

// MyBatis
<select id="selectActiveUsers" resultType="User">
    SELECT id, name, age FROM user WHERE status = 1
</select>
```

---

## 二、索引坑

### 坑30：索引失效

**❌ 错误示例**
```sql
-- 在索引列上使用函数
SELECT * FROM user WHERE YEAR(birthday) = 1990;

-- 类型转换导致索引失效
SELECT * FROM user WHERE phone = 13800138000;  -- phone是varchar
SELECT * FROM user WHERE phone = '13800138000';  -- 正确

-- 使用LIKE前通配符
SELECT * FROM user WHERE name LIKE '%三';  -- 索引失效

-- OR条件导致索引失效
SELECT * FROM user WHERE name = '张三' OR age = 20;
-- name有索引，但age没有，OR会导致全表扫描
```

**✅ 正确做法**
```sql
-- 避免在索引列上使用函数
SELECT * FROM user WHERE birthday >= '1990-01-01' AND birthday < '1991-01-01';

-- 类型匹配
SELECT * FROM user WHERE phone = '13800138000';

-- 使用后通配符
SELECT * FROM user WHERE name LIKE '张%';  -- 索引生效

-- 使用UNION代替OR
SELECT * FROM user WHERE name = '张三'
UNION
SELECT * FROM user WHERE age = 20;
```

---

## 三、事务坑

### 坑31：长事务

**❌ 错误示例**
```java
@Transactional
public void importUsers(List<User> users) {
    for (User user : users) {
        // 10万条数据在一个事务中
        userMapper.insert(user);
    }
    // 事务时间过长，锁表时间长
}
```

**✅ 正确做法**
```java
// 批量处理，减少事务范围
@Transactional
public void importUsers(List<User> users) {
    // 分批处理
    int batchSize = 1000;
    for (int i = 0; i < users.size(); i += batchSize) {
        List<User> batch = users.subList(i, Math.min(i + batchSize, users.size()));
        batchInsert(batch);
    }
}

// 或者不使用事务，每批独立事务
public void importUsers(List<User> users) {
    int batchSize = 1000;
    for (int i = 0; i < users.size(); i += batchSize) {
        List<User> batch = users.subList(i, Math.min(i + batchSize, users.size()));
        batchInsertWithTransaction(batch);  // 每批独立事务
    }
}
```

---

## 四、连接池坑

### 坑32：Druid连接泄漏

**❌ 错误示例**
```java
public User findById(Long id) {
    Connection conn = null;
    try {
        conn = dataSource.getConnection();
        // 如果抛异常，连接不会被关闭！
        return query(conn, id);
    } finally {
        // 如果上面抛异常，这里不会执行
        conn.close();
    }
}
```

**✅ 正确做法**
```java
// 使用try-with-resources
public User findById(Long id) {
    try (Connection conn = dataSource.getConnection()) {
        return query(conn, id);
    }
}

// 或者使用JdbcTemplate（推荐）
@Service
public class UserService {
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    public User findById(Long id) {
        String sql = "SELECT * FROM user WHERE id = ?";
        return jdbcTemplate.queryForObject(sql, new Object[]{id}, userRowMapper);
    }
}
```

---

# 第四部分：微服务开发坑

## 一、服务间调用坑

### 坑33：Feign超时配置

**❌ 错误示例**
```yaml
feign:
  client:
    config:
      default:
        connect-timeout: 5000
        read-timeout: 5000  # 默认5秒，可能不够
```

**✅ 正确做法**
```yaml
feign:
  client:
    config:
      default:
        connect-timeout: 3000      # 连接超时
        read-timeout: 10000        # 读超时（根据业务调整）
        logger-level: basic        # 开启日志
  circuitbreaker:
    enabled: true                  # 开启熔断器

# 或者针对特定服务配置
feign:
  client:
    config:
      user-service:               # 指定服务名
        connect-timeout: 3000
        read-timeout: 30000
```

---

## 二、分布式事务坑

### 坑34：TCC空回滚

**❌ 错误示例**
```java
@LocalTCC
public class OrderService {
    
    @Override
    public boolean tryDecreaseStock(Long productId, Integer count) {
        // Try阶段：尝试扣减库存
        return stockService.tryDecrease(productId, count);
    }
    
    @Override
    public void confirmDecreaseStock(Long productId, Integer count) {
        // Confirm阶段：确认扣减
        // 如果Try未执行直接调用Confirm，会出现空回滚
        stockService.confirmDecrease(productId, count);
    }
    
    @Override
    public void cancelDecreaseStock(Long productId, Integer count) {
        // Cancel阶段：回滚
        stockService.cancelDecrease(productId, count);
    }
}
```

**✅ 正确做法**
```java
@LocalTCC
public class OrderService {
    
    @Override
    public boolean tryDecreaseStock(Long productId, Integer count) {
        // Try阶段必须检测是否已经扣减过
        Stock stock = stockMapper.selectByProductId(productId);
        if (stock.getLockedCount() >= count) {
            // 已经锁定过，不能重复锁定
            return false;
        }
        stockService.lockStock(productId, count);
        return true;
    }
    
    @Override
    public void confirmDecreaseStock(Long productId, Integer count) {
        // Confirm：直接扣减实际库存
        stockService.confirmDecrease(productId, count);
    }
    
    @Override
    public void cancelDecreaseStock(Long productId, Integer count) {
        // Cancel：释放锁定的库存
        stockService.unlockStock(productId, count);
    }
}
```

---

## 三、幂等性坑

### 坑35：接口幂等性

**❌ 错误示例**
```java
// POST请求扣款，没有幂等性保护
@PostMapping("/deduct")
public Result<Void> deduct(@RequestParam Long accountId, 
                           @RequestParam BigDecimal amount) {
    // 重复请求会导致多次扣款！
    accountService.deduct(accountId, amount);
    return Result.success();
}
```

**✅ 正确做法**
```java
// 方法1：使用Token
@PostMapping("/deduct")
public Result<Void> deduct(@RequestParam Long accountId,
                         @RequestParam BigDecimal amount,
                         @RequestHeader("Idempotent-Token") String token) {
    // 检查Token是否已使用
    if (!idempotentService.tryLock(token)) {
        return Result.error("请求已处理，请勿重复提交");
    }
    try {
        accountService.deduct(accountId, amount);
        return Result.success();
    } finally {
        idempotentService.unlock(token);
    }
}

// 方法2：使用数据库唯一索引
@PostMapping("/create")
public Result<Long> createOrder(@RequestBody CreateOrderRequest request) {
    // 幂等ID作为唯一键
    Order order = new Order();
    order.setIdempotentId(request.getIdempotentId());  // 唯一索引
    try {
        orderService.insert(order);
        return Result.success(order.getId());
    } catch (DuplicateKeyException e) {
        // 重复提交，返回原订单
        return Result.success(orderService.findByIdempotentId(request.getIdempotentId()).getId());
    }
}

// 方法3：使用分布式锁
@PostMapping("/deduct")
public Result<Void> deduct(@RequestParam Long accountId,
                         @RequestParam String idempotentId,
                         @RequestParam BigDecimal amount) {
    String lockKey = "deduct:" + accountId + ":" + idempotentId;
    return redisLock.execute(lockKey, () -> {
        accountService.deduct(accountId, amount);
        return Result.success();
    });
}
```

---

# 第五部分：开发规范

## 一、命名规范

### 1. 包命名

```
com.公司名.业务模块.子模块

示例：
com.alibaba.user.service
com.alibaba.order.controller
com.alibaba.product.dao
```

### 2. 类命名

| 类型 | 规范 | 示例 |
|------|------|------|
| 普通类 | UpperCamelCase | UserService, OrderController |
| 工具类 | UpperCamelCase + Util/Helper | StringUtil, DateHelper |
| 异常类 | UpperCamelCase + Exception | BusinessException |
| 枚举类 | UpperCamelCase | OrderStatus |
| 实体类 | UpperCamelCase | User, Order |
| VO/DTO | UpperCamelCase + VO/DTO | UserVO, OrderDTO |
| DAO接口 | I开头 + UpperCamelCase | IUserDao |
| Service接口 | I开头 + UpperCamelCase | IUserService |
| Service实现 | 普通类名 + Impl | UserServiceImpl |

### 3. 方法命名

| 操作 | 规范 | 示例 |
|------|------|------|
| 查询 | find/select/get + 条件 | findById, selectByName |
| 新增 | save/insert/add + 名词 | saveUser, addOrder |
| 修改 | update/modify + 名词 | updateUser, modifyOrder |
| 删除 | delete/remove + 名词 | deleteById, removeUser |
| 统计 | count + 名词 | countAll, countByStatus |
| 校验 | check/validate + 名词 | checkUserExist, validateToken |

### 4. 变量命名

```
【推荐】
private UserService userService;
private int pageSize;
private List<User> userList;
private Map<String, User> userMap;
private Set<String> userIdSet;
private boolean isActive;
private String[] userNames;

/【不推荐】
private UserService u;
private List<User> list;
private Map<String, User> map;
```

### 5. 常量命名

```java
// 全大写+下划线
public static final int MAX_RETRY_COUNT = 3;
public static final String ORDER_STATUS_PAID = "PAID";

// 枚举值
public enum OrderStatus {
    PENDING("待支付"),
    PAID("已支付"),
    COMPLETED("已完成");
    
    private final String desc;
    OrderStatus(String desc) {
        this.desc = desc;
    }
}
```

---

## 二、代码风格规范

### 1. 大括号

```java
// 【推荐】左大括号不换行
public void method() {
    if (condition) {
        doSomething();
