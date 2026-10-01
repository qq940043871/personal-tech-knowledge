# Spring WebFlux响应式编程

> 模块：Java框架全景图 / 02-Web开发
> 更新时间：2026-06-20

---

## 一、概述

Spring WebFlux是Spring 5引入的响应式Web框架，基于Reactor库实现非阻塞IO，适合高并发、低延迟的场景。

### 核心特性
- **非阻塞IO** — 基于Netty，少量线程处理大量并发连接
- **响应式流** — 支持背压（Backpressure）机制
- **函数式端点** — RouterFunction定义路由
- **SSE支持** — 服务器推送事件

---

## 二、核心概念

### 2.1 Mono与Flux

```java
// Mono: 0或1个元素
Mono<String> mono = Mono.just("Hello");

// Flux: 0到N个元素
Flux<Integer> flux = Flux.just(1, 2, 3, 4, 5);

// 异步创建
Mono<String> asyncMono = Mono.fromCallable(() -> {
    // 耗时操作
    return "result";
});
```

### 2.2 操作符

```java
Flux.just(1, 2, 3, 4, 5)
    .filter(i -> i > 2)           // 过滤
    .map(i -> i * 10)             // 映射
    .flatMap(i -> Mono.just(i))   // 扁平化
    .collectList()                // 收集为List
    .subscribe();                 // 订阅
```

---

## 三、注解方式

```java
@RestController
@RequestMapping("/api/users")
public class UserWebFluxController {
    
    @Autowired
    private ReactiveUserRepository userRepository;
    
    @GetMapping("/{id}")
    public Mono<User> getUser(@PathVariable Long id) {
        return userRepository.findById(id);
    }
    
    @GetMapping
    public Flux<User> listUsers() {
        return userRepository.findAll();
    }
    
    @PostMapping
    public Mono<User> createUser(@RequestBody User user) {
        return userRepository.save(user);
    }
    
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<UserEvent> streamUsers() {
        return userRepository.findAll()
                .map(user -> new UserEvent(user))
                .delayElements(Duration.ofSeconds(1));
    }
}
```

---

## 四、函数式端点

```java
@Configuration
public class RouterConfig {
    
    @Bean
    public RouterFunction<ServerResponse> routes(UserHandler handler) {
        return RouterFunctions.route()
                .GET("/api/users", handler::listUsers)
                .GET("/api/users/{id}", handler::getUser)
                .POST("/api/users", handler::createUser)
                .build();
    }
}

@Component
public class UserHandler {
    
    public Mono<ServerResponse> listUsers(ServerRequest request) {
        Flux<User> users = userRepository.findAll();
        return ServerResponse.ok().body(users, User.class);
    }
    
    public Mono<ServerResponse> getUser(ServerRequest request) {
        Long id = Long.valueOf(request.pathVariable("id"));
        Mono<User> user = userRepository.findById(id);
        return ServerResponse.ok().body(user, User.class);
    }
}
```

---

## 五、WebClient

```java
@Service
public class ExternalApiService {
    
    private final WebClient webClient = WebClient.builder()
            .baseUrl("https://api.example.com")
            .build();
    
    public Mono<User> getUser(Long id) {
        return webClient.get()
                .uri("/users/{id}", id)
                .retrieve()
                .bodyToMono(User.class);
    }
    
    public Flux<User> listUsers() {
        return webClient.get()
                .uri("/users")
                .retrieve()
                .bodyToFlux(User.class);
    }
}
```

---

## 六、适用场景

| 场景 | 是否适合WebFlux |
|------|----------------|
| 高并发API服务 | ✅ 适合 |
| 实时数据推送（SSE） | ✅ 适合 |
| 微服务网关 | ✅ 适合 |
| 传统CRUD应用 | ❌ 不适合 |
| 阻塞IO操作多 | ❌ 不适合 |

---

## 七、与Spring MVC对比

| 特性 | Spring MVC | Spring WebFlux |
|------|-----------|----------------|
| 线程模型 | 每请求一线程 | 少量线程+事件循环 |
| IO模型 | 阻塞IO | 非阻塞IO |
| 并发能力 | 受线程数限制 | 可处理大量并发 |
| 学习曲线 | 低 | 高 |
| 生态支持 | 成熟 | 逐渐完善 |

---

*WebFlux适合高并发场景，传统应用建议使用Spring MVC。*
