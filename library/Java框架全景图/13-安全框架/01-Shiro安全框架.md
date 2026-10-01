# Shiro安全框架

> 模块：Java框架全景图 / 13-安全框架
> 更新时间：2026-06-20

---

## 一、概述

Apache Shiro是Java领域轻量级安全框架，提供认证、授权、加密、会话管理等功能，比Spring Security更简单易用。

### 核心特性
- **轻量** — 体积小，依赖少
- **简单** — API简洁易懂
- **灵活** — 可独立使用，也可集成Spring
- **全面** — 认证、授权、会话、加密

---

## 二、核心概念

### 2.1 三大核心组件

```
Subject（主体）
    ↓
SecurityManager（安全管理器）
    ↓
Realm（领域）
```

- **Subject** — 当前用户，所有安全操作的入口
- **SecurityManager** — 安全管理器，协调所有安全组件
- **Realm** — 数据源，获取用户信息和权限

---

## 三、Spring Boot集成

### 3.1 Maven依赖

```xml
<dependency>
    <groupId>org.apache.shiro</groupId>
    <artifactId>shiro-spring-boot-web-starter</artifactId>
    <version>1.13.0</version>
</dependency>
```

### 3.2 配置类

```java
@Configuration
public class ShiroConfig {
    
    @Bean
    public ShiroFilterFactoryDefinition shiroFilterFactoryDefinition() {
        return new ShiroFilterFactoryDefinition();
    }
    
    @Bean
    public SecurityManager securityManager(Realm realm) {
        DefaultWebSecurityManager manager = new DefaultWebSecurityManager();
        manager.setRealm(realm);
        return manager;
    }
    
    @Bean
    public Realm realm() {
        return new CustomRealm();
    }
}
```

### 3.3 自定义Realm

```java
public class CustomRealm extends AuthorizingRealm {
    
    @Autowired
    private UserService userService;
    
    @Override
    protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principals) {
        String username = (String) principals.getPrimaryPrincipal();
        
        // 查询用户权限
        Set<String> permissions = userService.getPermissions(username);
        Set<String> roles = userService.getRoles(username);
        
        SimpleAuthorizationInfo info = new SimpleAuthorizationInfo();
        info.setStringPermissions(permissions);
        info.setRoles(roles);
        return info;
    }
    
    @Override
    protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken token) 
            throws AuthenticationException {
        String username = (String) token.getPrincipal();
        
        // 查询用户
        User user = userService.getByUsername(username);
        if (user == null) {
            throw new UnknownAccountException("用户不存在");
        }
        
        return new SimpleAuthenticationInfo(
            user.getUsername(), 
            user.getPassword(), 
            getName()
        );
    }
}
```

---

## 四、认证

```java
@Controller
public class AuthController {
    
    @PostMapping("/login")
    public String login(String username, String password, Model model) {
        Subject subject = SecurityUtils.getSubject();
        UsernamePasswordToken token = new UsernamePasswordToken(username, password);
        
        try {
            subject.login(token);
            return "redirect:/index";
        } catch (AuthenticationException e) {
            model.addAttribute("error", "登录失败: " + e.getMessage());
            return "login";
        }
    }
    
    @GetMapping("/logout")
    public String logout() {
        SecurityUtils.getSubject().logout();
        return "redirect:/login";
    }
}
```

---

## 五、授权

### 5.1 注解方式

```java
@RequiresPermissions("user:view")
@GetMapping("/users")
public String listUsers() {
    return "user/list";
}

@RequiresPermissions("user:edit")
@GetMapping("/users/{id}/edit")
public String editUser(@PathVariable Long id) {
    return "user/edit";
}

@RequiresRoles("admin")
@GetMapping("/admin")
public String admin() {
    return "admin/index";
}
```

### 5.2 编程方式

```java
Subject subject = SecurityUtils.getSubject();

// 检查权限
if (subject.isPermitted("user:view")) {
    // 有权限
}

// 检查角色
if (subject.hasRole("admin")) {
    // 是管理员
}
```

---

## 六、会话管理

```java
Subject subject = SecurityUtils.getSubject();

// 获取会话
Session session = subject.getSession();

// 设置属性
session.setAttribute("key", "value");

// 获取属性
Object value = session.getAttribute("key");

// 获取会话ID
String sessionId = session.getId();
```

---

## 七、加密

```java
// MD5加密
String hashed = new Md5Hash(password, salt, 1024).toHex();

// SHA加密
String hashed = new Sha256Hash(password, salt, 1024).toHex();

// 自定义加密
ByteSource credentialsSalt = ByteSource.Util.bytes(salt);
SimpleAuthenticationInfo info = new SimpleAuthenticationInfo(
    username, hashed, credentialsSalt, realmName
);
```

---

## 八、与Spring Security对比

| 特性 | Shiro | Spring Security |
|------|-------|-----------------|
| 复杂度 | 简单 | 复杂 |
| 学习曲线 | 低 | 高 |
| Spring集成 | 需配置 | 原生支持 |
| 功能丰富度 | 够用 | 更丰富 |
| 适用场景 | 中小项目 | 企业级项目 |

---

## 九、最佳实践

1. **密码加密** — 使用SHA-256 + 盐值
2. **权限缓存** — 使用Redis缓存权限数据
3. **会话管理** — 配置会话超时和并发控制
4. **异常处理** — 统一处理认证和授权异常

---

*Shiro适合中小项目，企业级项目建议使用Spring Security。*
