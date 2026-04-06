# Spring开发避坑指南

> 模块：Spring开发篇
> 更新时间：2026-03-29

---

## 一、@Autowired与构造函数注入

### ❌ 错误示例
```java
@Controller
public class UserController {
    @Autowired
    private UserService userService;  // Field注入，不推荐
}
```

### ✅ 正确做法
```java
// 方法1：构造器注入（推荐）
@Controller
public class UserController {
    private final UserService userService;
    
    @Autowired
    public UserController(UserService userService) {
        this.userService = userService;
    }
}

// 方法2：Lombok（更简洁）
@Controller
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;
}

// 方法3：Setter注入（可选注入时使用）
@Controller
public class UserController {
    private UserService userService;
    
    @Autowired
    public void setUserService(UserService userService) {
        this.userService = userService;
    }
}
```

---

## 二、@Transactional失效

### ❌ 错误示例
```java
@Service
public class UserService {
    
    @Transactional
    public void transfer(String from, String to, BigDecimal amount) {
        // 在同一个类中调用另一个@Transactional方法
        deduct(from, amount);      // 不会开启新事务！
        add(to, amount);         // 也不会开启新事务！
    }
    
    @Transactional
    public void deduct(String account, BigDecimal amount) {
        // 扣款逻辑
    }
}
```

### ✅ 正确做法
```java
// 方法1：注入自己
@Service
public class UserService {
    
    @Autowired
    private UserService self;
    
    public void transfer(String from, String to, BigDecimal amount) {
        self.deduct(from, amount);
        self.add(to, amount);
    }
    
    @Transactional
    public void deduct(String account, BigDecimal amount) {
        // 扣款逻辑
    }
}

// 方法2：拆分到另一个Service
// 方法3：使用编程式事务
```

---

## 三、@Transactional在private方法上

### ❌ 错误示例
```java
@Service
public class UserService {
    
    @Transactional
    private void doSomething() {  // private方法，事务不生效
        // 事务不会生效，因为private方法不能被代理
    }
}
```

### ✅ 正确做法
```java
@Service
public class UserService {
    
    @Transactional
    public void publicMethod() {  // 必须是public
        // 业务逻辑
    }
    
    private void doSomething() {
        // 内部逻辑
    }
}
```

---

## 四、Spring事务与锁的顺序

### ❌ 错误示例
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

### ✅ 正确做法
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

## 五、循环依赖

### ❌ 错误示例
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

### ✅ 正确做法
```java
// 方法1：使用@Lazy延迟注入
@Service
public class AService {
    private BService bService;
    
    public AService(@Lazy BService bService) {
        this.bService = bService;
    }
}

// 方法2：使用Setter注入（setter注入可以解决循环依赖）
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

## 六、@Configuration的代理模式

### ❌ 错误示例
```java
@Configuration
public class MyConfig {
    
    @Bean
    public UserService userService() {
        return new UserService();  // 每次都返回新实例？
    }
}
```

### ✅ 正确做法
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

## 七、配置类扫描不到

### ❌ 错误示例
```java
@Configuration
public class MyConfig {  // 这个配置类可能扫描不到
    @Bean
    public MyService myService() {
        return new MyService();
    }
}
```

### ✅ 正确做法
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

## 八、@Async注解失效

### ❌ 错误示例
```java
@Service
public class UserService {
    
    @Async
    public void sendEmail() {  // 在同一个类中调用，@Async失效！
        // 因为是this.sendEmail()，不走代理
    }
    
    public void doSomething() {
        sendEmail();  // 不会异步执行！
    }
}
```

### ✅ 正确做法
```java
@Service
public class UserService {
    
    @Autowired
    private UserService self;  // 注入自己
    
    public void doSomething() {
        self.sendEmail();  // 走代理，异步生效
    }
    
    @Async
    public void sendEmail() {
        // 异步发送邮件
    }
}

// 或者确保@Async配置正确
@Configuration
@EnableAsync
public class AsyncConfig {
    // 配置线程池
}
```

---

## 九、@Value注入Map/List

### ❌ 错误示例
```yaml
# application.yml
myapp:
  users:
    - id: 1
      name: 张三
    - id: 2
      name: 李四
```

```java
// 错误的注入方式
@Value("${myapp.users}")
private List<User> users;  // 无法直接注入复杂类型
```

### ✅ 正确做法
```java
// 方法1：使用@ConfigurationProperties
@Component
@ConfigurationProperties(prefix = "myapp")
public class MyAppProperties {
    private List<User> users = new ArrayList<>();
    
    public List<User> getUsers() {
        return users;
    }
    
    public void setUsers(List<User> users) {
        this.users = users;
    }
    
    public static class User {
        private int id;
        private String name;
        // getters and setters
    }
}

// 方法2：使用@ImportResource + 自定义Bean
@Configuration
@PropertySource("classpath:application.yml")
public class YamlConfig {
    @Bean
    public Yaml yaml() {
        return new Yaml();
    }
}
```

---

*下一步：数据库开发篇*
