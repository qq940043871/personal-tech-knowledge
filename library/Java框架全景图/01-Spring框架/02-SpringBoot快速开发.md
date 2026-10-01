# Spring Boot

> 模块：基础核心框架
> 更新时间：2026-03-29

---

## 一、框架介绍

Spring Boot是Spring Framework的子项目，旨在简化Spring应用的创建和部署过程。它通过"约定大于配置"的理念，让开发者能够快速搭建生产级别的Spring应用。

**官网**：[https://spring.io/projects/spring-boot](https://spring.io/projects/spring-boot)

**核心目标**：
- 开箱即用：自动配置
- 嵌入式服务器：无需部署WAR文件
- 生产就绪：监控、健康检查
- 零配置：减少XML配置

---

## 二、核心特性

### 1. 自动配置（Auto Configuration）

Spring Boot根据添加的JAR依赖自动配置Spring应用：

```java
// 当classpath下有Spring-webmvc时，自动配置DispatcherServlet
// 当有spring-boot-starter-data-redis时，自动配置RedisTemplate
// 开发者只需要添加依赖，配置自动完成
```

### 2. 快速启动示例

**Maven依赖**：
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.0</version>
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

**主程序**：
```java
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### 3. application.yml配置

```yaml
# application.yml
server:
  port: 8080
  servlet:
    context-path: /api

spring:
  application:
    name: myapp
  datasource:
    url: jdbc:mysql://localhost:3306/test
    username: root
    password: 123456
    driver-class-name: com.mysql.cj.jdbc.Driver

# 自定义配置
app:
  version: 1.0.0
  cache:
    enabled: true
```

---

## 三、实际业务应用场景

### 场景1：RESTful API开发

```java
@RestController
@RequestMapping("/users")
public class UserController {
    
    @Autowired
    private UserService userService;
    
    @GetMapping("/{id}")
    public Result<User> getUser(@PathVariable Long id) {
        return Result.success(userService.getById(id));
    }
    
    @PostMapping
    public Result<Long> createUser(@RequestBody @Valid User user) {
        return Result.success(userService.save(user));
    }
    
    @PutMapping("/{id}")
    public Result<Void> updateUser(@PathVariable Long id, 
                                   @RequestBody User user) {
        user.setId(id);
        userService.updateById(user);
        return Result.success();
    }
    
    @DeleteMapping("/{id}")
    public Result<Void> deleteUser(@PathVariable Long id) {
        userService.removeById(id);
        return Result.success();
    }
    
    @GetMapping("/page")
    public Result<Page<User>> getUserPage(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size,
            @RequestParam(required = false) String name) {
        return Result.success(userService.getPage(page, size, name));
    }
}
```

### 场景2：统一异常处理

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(BizException.class)
    public Result<Void> handleBizException(BizException e) {
        return Result.error(e.getCode(), e.getMessage());
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<Void> handleValidException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldError().getDefaultMessage();
        return Result.error(400, message);
    }
    
    @ExceptionHandler(Exception.class)
    public Result<Void> handleException(Exception e) {
        log.error("系统异常", e);
        return Result.error(500, "系统异常");
    }
}
```

### 场景3：多环境配置

```yaml
# application-dev.yml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/test_dev

# application-prod.yml
spring:
  datasource:
    url: jdbc:mysql://prod-db:3306/test_prod

# application.yml - 激活环境
spring:
  profiles:
    active: dev
```

---

## 四、常用Starter

| Starter | 用途 |
|---------|------|
| spring-boot-starter-web | Web开发 |
| spring-boot-starter-data-jpa | JPA数据访问 |
| spring-boot-starter-data-redis | Redis缓存 |
| spring-boot-starter-security | 安全认证 |
| spring-boot-starter-validation | 参数校验 |
| spring-boot-starter-actuator | 应用监控 |

---

## 五、Spring Boot 3.x新特性

```java
// 1. 构造函数注入（推荐）
@Service
public class UserServiceImpl implements UserService {
    private final UserDao userDao;
    
    public UserServiceImpl(UserDao userDao) {
        this.userDao = userDao;
    }
}

// 2. 记录启动日志
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(Application.class);
        app.setBannerMode(Banner.Mode.CONSOLE);
        app.run(args);
    }
}

// 3. Native Image支持（GraalVM）
```

---

## 六、总结

Spring Boot极大简化了Spring开发，是现代Java开发的标准起点。

**学习要点**：
1. 理解自动配置原理
2. 掌握配置文件的优先级和外部化配置
3. 熟练使用@SpringBootApplication组合注解
4. 了解Spring Boot DevTools热部署

---

*下一步：Spring Cloud微服务*
