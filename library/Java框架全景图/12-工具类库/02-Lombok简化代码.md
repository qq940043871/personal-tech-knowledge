# Lombok

> 模块：工具类库
> 更新时间：2026-03-29

---

## 一、框架介绍

Lombok是一个Java库，通过注解自动生成样板代码（getter、setter、构造函数等），显著减少代码冗余。

**官网**：[https://projectlombok.org](https://projectlombok.org)

**核心注解**：
- @Getter/@Setter - 生成getter/setter
- @ToString - 生成toString
- @EqualsAndHashCode - 生成equals和hashCode
- @Data - 组合注解
- @NoArgsConstructor/@AllArgsConstructor - 构造函数
- @Builder - 建造者模式
- @Slf4j - 日志对象

---

## 二、常用注解

```java
// 1. @Data - 最常用
@Data
@Entity
@TableName("t_user")
public class User {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, length = 50)
    private String name;
    
    private Integer age;
    
    private String email;
    
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;
    
    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;
}

// 2. @Builder - 建造者模式
@Data
@Builder
public class CreateOrderRequest {
    private Long userId;
    private Long productId;
    private Integer quantity;
}

// 使用
CreateOrderRequest request = CreateOrderRequest.builder()
    .userId(1L)
    .productId(100L)
    .quantity(2)
    .build();

// 3. @Slf4j - 日志
@Slf4j
@Service
public class UserServiceImpl implements UserService {
    
    public void createUser(User user) {
        log.info("创建用户: {}", user.getName());
        // 业务逻辑
    }
}

// 4. @RequiredArgsConstructor - 构造器注入
@Service
@RequiredArgsConstructor
public class OrderService {
    
    private final UserService userService;
    private final ProductService productService;
    private final OrderMapper orderMapper;
    
    // 自动生成包含final字段的构造器
}

// 5. @NonNull - 空指针检查
@Data
public class User {
    @NonNull
    private String name;
    
    private String email;
}
```

---

## 三、IDE支持

需要在IDE中安装Lombok插件：
- IntelliJ IDEA：Marketplace搜索Lombok
- Eclipse：下载lombok.jar运行安装

---

## 四、总结

Lombok是提高开发效率的必备工具，让代码更简洁。

**使用注意**：
1. IDE需要安装对应插件
2. 避免与手写方法冲突
3. @Data用于DTO/Entity，@Value用于不可变对象

---

*下一步：MySQL数据库*
