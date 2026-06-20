# Spring MVC详解

> 模块：Java框架全景图 / 02-Web开发
> 更新时间：2026-06-20

---

## 一、概述

Spring MVC是基于Servlet API构建的Web框架，采用MVC（Model-View-Controller）设计模式，是Spring Framework的核心模块之一。

### 核心特性
- **注解驱动** — `@Controller`、`@RequestMapping`等注解简化配置
- **数据绑定** — 自动将请求参数绑定到Java对象
- **视图解析** — 支持JSP、Thymeleaf、FreeMarker等多种视图技术
- **RESTful支持** — `@RestController`、`@RequestBody`、`@ResponseBody`
- **拦截器** — HandlerInterceptor实现请求预处理和后处理

---

## 二、核心组件

### 2.1 DispatcherServlet

前端控制器，所有请求的入口：

```java
@Configuration
@EnableWebMvc
public class WebConfig implements WebMvcConfigurer {
    
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LogInterceptor())
                .addPathPatterns("/**")
                .excludePathPatterns("/static/**");
    }
}
```

### 2.2 Controller

请求处理器：

```java
@RestController
@RequestMapping("/api/users")
public class UserController {
    
    @Autowired
    private UserService userService;
    
    @GetMapping("/{id}")
    public User getUser(@PathVariable Long id) {
        return userService.getById(id);
    }
    
    @PostMapping
    public User createUser(@Valid @RequestBody UserDTO dto) {
        return userService.create(dto);
    }
}
```

### 2.3 数据绑定与验证

```java
@Data
public class UserDTO {
    
    @NotBlank(message = "用户名不能为空")
    @Size(min = 2, max = 20, message = "用户名长度2-20")
    private String username;
    
    @Email(message = "邮箱格式不正确")
    private String email;
    
    @NotNull(message = "年龄不能为空")
    @Min(value = 0, message = "年龄不能小于0")
    private Integer age;
}
```

---

## 三、请求处理流程

```
客户端请求
    ↓
DispatcherServlet
    ↓
HandlerMapping（找到Handler）
    ↓
HandlerAdapter（执行Handler）
    ↓
Controller方法执行
    ↓
ViewResolver（解析视图）
    ↓
View渲染
    ↓
响应客户端
```

---

## 四、RESTful API设计

```java
@RestController
@RequestMapping("/api/v1/articles")
public class ArticleController {
    
    @GetMapping                    // GET /api/v1/articles
    public Page<Article> list(Pageable pageable) { ... }
    
    @GetMapping("/{id}")           // GET /api/v1/articles/1
    public Article get(@PathVariable Long id) { ... }
    
    @PostMapping                   // POST /api/v1/articles
    public Article create(@RequestBody ArticleDTO dto) { ... }
    
    @PutMapping("/{id}")           // PUT /api/v1/articles/1
    public Article update(@PathVariable Long id, @RequestBody ArticleDTO dto) { ... }
    
    @DeleteMapping("/{id}")        // DELETE /api/v1/articles/1
    public void delete(@PathVariable Long id) { ... }
}
```

---

## 五、异常处理

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    @ExceptionHandler(BusinessException.class)
    public Result<?> handleBusiness(BusinessException e) {
        return Result.error(e.getCode(), e.getMessage());
    }
    
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<?> handleValidation(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining(", "));
        return Result.error(400, message);
    }
}
```

---

## 六、最佳实践

1. **统一响应格式** — 使用统一的Result封装返回值
2. **参数校验** — 使用`@Valid`注解进行参数验证
3. **异常处理** — 全局异常处理器统一处理异常
4. **API版本控制** — URL路径或请求头版本化
5. **接口文档** — 集成Swagger/SpringDoc生成API文档

---

## 七、与Spring WebFlux对比

| 特性 | Spring MVC | Spring WebFlux |
|------|-----------|----------------|
| 编程模型 | 同步阻塞 | 异步非阻塞 |
| Servlet API | 支持 | 不支持 |
| 适用场景 | 传统Web应用 | 高并发、响应式应用 |
| 学习曲线 | 较低 | 较高 |

---

*Spring MVC是Java Web开发的基础，建议先掌握MVC再学习WebFlux。*
