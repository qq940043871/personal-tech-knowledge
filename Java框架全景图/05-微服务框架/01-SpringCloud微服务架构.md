# Spring Cloud

> 模块：微服务框架
> 更新时间：2026-03-29

---

## 一、框架介绍

Spring Cloud是Spring官方提供的微服务架构解决方案，它提供了一整套微服务开发所需的组件和工具，包括服务注册与发现、配置中心、负载均衡、熔断器、网关等。

**官网**：[https://spring.io/projects/spring-cloud](https://spring.io/projects/spring-cloud)

**核心组件**：
- **Nacos/Eureka**：服务注册与发现
- **Gateway**：API网关
- **Ribbon/OpenFeign**：负载均衡与服务调用
- **Sentinel/Hystrix**：熔断器
- **Config/Nacos**：配置中心
- **Sleuth/Zipkin**：链路追踪

---

## 二、核心组件详解

### 1. Nacos - 服务注册与配置中心

**服务注册**：
```yaml
# provider服务的application.yml
spring:
  application:
    name: user-service
  cloud:
    nacos:
      discovery:
        server-addr: nacos-server:8848
        namespace: dev
        group: DEFAULT_GROUP
```

```java
@SpringBootApplication
@EnableDiscoveryClient
public class UserServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(UserServiceApplication.class, args);
    }
}
```

**配置中心**：
```yaml
# 共享配置 - shared-configs
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/test
    username: root
    password: ${DB_PASSWORD:123456}

# bootstrap.yml - 拉取远程配置
spring:
  cloud:
    nacos:
      config:
        server-addr: nacos-server:8848
        file-extension: yaml
        shared-configs:
          - data-id: shared-config.yaml
            group: SHARED_GROUP
            refresh: true
```

### 2. Gateway - API网关

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: user-service
          uri: lb://user-service
          predicates:
            - Path=/api/user/**
          filters:
            - StripPrefix=1
            - RequestRateLimiter=10,20
```

```java
@Configuration
public class GatewayConfig {
    
    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
            .route("user_route", r -> r
                .path("/api/user/**")
                .filters(f -> f.stripPrefix(1))
                .uri("lb://user-service"))
            .build();
    }
}
```

### 3. OpenFeign - 声明式HTTP客户端

```java
// 1. 启用Feign客户端
@SpringBootApplication
@EnableFeignClients
public class OrderServiceApplication {
}

// 2. 定义Feign接口
@FeignClient(name = "user-service", path = "/users")
public interface UserFeignClient {
    
    @GetMapping("/{id}")
    User getUser(@PathVariable("id") Long id);
    
    @GetMapping("/info")
    UserInfo getUserInfo(@RequestParam("userId") Long userId);
}

// 3. 使用Feign客户端
@Service
public class OrderServiceImpl implements OrderService {
    
    @Autowired
    private UserFeignClient userFeignClient;
    
    public Order createOrder(Long userId, BigDecimal amount) {
        // 调用用户服务获取用户信息
        User user = userFeignClient.getUser(userId);
        
        // 创建订单
        Order order = new Order();
        order.setUserId(userId);
        order.setUserName(user.getName());
        order.setAmount(amount);
        
        return orderDao.insert(order);
    }
}
```

### 4. Sentinel - 熔断器与流量控制

```java
// 1. 定义资源
@RestController
public class UserController {
    
    @GetMapping("/user/{id}")
    @SentinelResource(value = "getUser", 
                     blockHandler = "getUserBlockHandler",
                     fallback = "getUserFallback")
    public User getUser(@PathVariable Long id) {
        return userService.getById(id);
    }
    
    // 限流处理
    public User getUserBlockHandler(Long id, BlockException e) {
        return User.builder().name("系统繁忙").build();
    }
    
    // 降级处理
    public User getUserFallback(Long id, Throwable e) {
        return User.builder().name("服务降级").build();
    }
}

// 2. 配置流控规则
@Configuration
public class SentinelConfig {
    
    @PostConstruct
    public void initRules() {
        List<FlowRule> rules = new ArrayList<>();
        FlowRule rule = new FlowRule();
        rule.setResource("getUser");
        rule.setGrade(RuleConstant.FLOW_GRADE_QPS);
        rule.setCount(100);
        rules.add(rule);
        FlowRuleManager.loadRules(rules);
    }
}
```

---

## 三、实际业务应用场景

### 场景1：微服务间调用

```
用户下单流程：

1. 网关/客户端 → /api/order/createOrder
2. OrderService → UserService（Feign）获取用户信息
3. OrderService → ProductService（Feign）获取商品信息
4. OrderService → 调用库存服务扣减库存
5. OrderService → 保存订单
6. OrderService → 发送消息（RabbitMQ）通知库存服务
```

```java
// OrderController
@RestController
@RequestMapping("/orders")
public class OrderController {
    
    @Autowired
    private OrderService orderService;
    
    @PostMapping("/create")
    public Result<Order> createOrder(@RequestBody CreateOrderRequest request) {
        return Result.success(orderService.createOrder(request));
    }
}

// OrderServiceImpl
@Service
public class OrderServiceImpl implements OrderService {
    
    @Autowired
    private UserFeignClient userFeignClient;
    
    @Autowired
    private ProductFeignClient productFeignClient;
    
    @Autowired
    private OrderDao orderDao;
    
    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        // 1. 获取用户信息
        User user = userFeignClient.getUser(request.getUserId());
        if (user == null) {
            throw new BizException("用户不存在");
        }
        
        // 2. 获取商品信息
        Product product = productFeignClient.getProduct(request.getProductId());
        if (product.getStock() < request.getQuantity()) {
            throw new BizException("库存不足");
        }
        
        // 3. 创建订单
        Order order = new Order();
        order.setUserId(user.getId());
        order.setUserName(user.getName());
        order.setProductName(product.getName());
        order.setQuantity(request.getQuantity());
        order.setTotalAmount(product.getPrice().multiply(
            new BigDecimal(request.getQuantity())));
        
        return orderDao.insert(order);
    }
}
```

### 场景2：统一配置管理

```yaml
# Nacos中创建配置：application-dev.yaml
spring:
  redis:
    host: redis-dev-server
    port: 6379
  datasource:
    url: jdbc:mysql://mysql-dev:3306/app

app:
  upload:
    path: /data/uploads
    max-size: 10485760
  sms:
    enabled: true
```

### 场景3：灰度发布

```yaml
spring:
  cloud:
    gateway:
      routes:
        # 灰度版本（10%流量）
        - id: user-service-gray
          uri: http://user-service-gray:8081
          predicates:
            - Weight=user-service,10
        
        # 正式版本（90%流量）
        - id: user-service
          uri: lb://user-service
          predicates:
            - Weight=user-service,90
```

---

## 四、Spring Cloud Alibaba

国内使用最广泛的微服务解决方案：

| 组件 | 替代方案 | 说明 |
|------|---------|------|
| Nacos | Eureka/Consul | 注册中心+配置中心 |
| Sentinel | Hystrix | 熔断器+流量控制 |
| Seata | - | 分布式事务 |
| Dubbo | OpenFeign | RPC通信 |

---

## 五、总结

Spring Cloud是微服务架构的标准解决方案，Spring Cloud Alibaba在国内企业中使用最广泛。

**学习要点**：
1. 理解微服务架构的核心概念
2. 掌握Nacos、Eureka等服务注册发现
3. 熟练使用OpenFeign进行服务调用
4. 理解Sentinel的限流和熔断机制
5. 了解分布式事务解决方案（Seata）

---

*下一步：MyBatis数据访问*
