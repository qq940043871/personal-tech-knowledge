# Spring Cache抽象

> 模块：Java框架全景图 / 07-缓存框架
> 更新时间：2026-06-20

---

## 一、概述

Spring Cache是Spring提供的缓存抽象层，通过注解方式简化缓存操作，支持多种缓存实现（Redis、Ehcache、Caffeine等）。

### 核心特性
- **注解驱动** — `@Cacheable`、`@CachePut`、`@CacheEvict`
- **透明切换** — 切换缓存实现无需修改业务代码
- **条件缓存** — 支持SpEL表达式条件判断
- **自定义Key** — 灵活的Key生成策略

---

## 二、核心注解

### 2.1 @Cacheable

```java
@Cacheable(value = "users", key = "#id")
public User getUserById(Long id) {
    return userRepository.findById(id).orElse(null);
}

// 条件缓存
@Cacheable(value = "users", key = "#id", condition = "#id > 0", unless = "#result == null")
public User getUserById(Long id) {
    return userRepository.findById(id).orElse(null);
}
```

### 2.2 @CachePut

```java
@CachePut(value = "users", key = "#user.id")
public User updateUser(User user) {
    return userRepository.save(user);
}
```

### 2.3 @CacheEvict

```java
// 删除单个缓存
@CacheEvict(value = "users", key = "#id")
public void deleteUser(Long id) {
    userRepository.deleteById(id);
}

// 清除所有缓存
@CacheEvict(value = "users", allEntries = true)
public void clearCache() {
    // 清除所有users缓存
}
```

### 2.4 @Caching

```java
@Caching(
    put = { @CachePut(value = "users", key = "#user.id") },
    evict = { @CacheEvict(value = "userList", allEntries = true) }
)
public User saveUser(User user) {
    return userRepository.save(user);
}
```

---

## 三、Key生成策略

### 3.1 默认策略

```java
// 使用方法参数作为Key
@Cacheable(value = "users", key = "#id")
public User getUserById(Long id) { ... }

// 使用多个参数
@Cacheable(value = "users", key = "#username + ':' + #email")
public User getUser(String username, String email) { ... }
```

### 3.2 自定义KeyGenerator

```java
@Bean
public KeyGenerator keyGenerator() {
    return (target, method, params) -> {
        StringBuilder sb = new StringBuilder();
        sb.append(target.getClass().getSimpleName());
        sb.append(":");
        sb.append(method.getName());
        for (Object param : params) {
            sb.append(":").append(param);
        }
        return sb.toString();
    };
}

@Cacheable(value = "users", keyGenerator = "keyGenerator")
public User getUser(Long id) { ... }
```

---

## 四、配置示例

### 4.1 Caffeine配置

```java
@Configuration
@EnableCaching
public class CaffeineCacheConfig {
    
    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager manager = new CaffeineCacheManager();
        manager.setCaffeine(Caffeine.newBuilder()
            .maximumSize(10_000)
            .expireAfterWrite(Duration.ofMinutes(5)));
        return manager;
    }
}
```

### 4.2 Redis配置

```java
@Configuration
@EnableCaching
public class RedisCacheConfig {
    
    @Bean
    public CacheManager cacheManager(RedisConnectionFactory factory) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(30))
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));
        
        return RedisCacheManager.builder(factory)
            .cacheDefaults(config)
            .build();
    }
}
```

---

## 五、多级缓存

```java
@Configuration
@EnableCaching
public class MultiLevelCacheConfig {
    
    @Bean
    public CacheManager cacheManager(RedisConnectionFactory factory) {
        // L1: Caffeine本地缓存
        CaffeineCacheManager l1Manager = new CaffeineCacheManager();
        l1Manager.setCaffeine(Caffeine.newBuilder()
            .maximumSize(1000)
            .expireAfterWrite(Duration.ofMinutes(1)));
        
        // L2: Redis分布式缓存
        RedisCacheManager l2Manager = RedisCacheManager.builder(factory)
            .cacheDefaults(RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofMinutes(30)))
            .build();
        
        // 组合缓存管理器
        CompositeCacheManager manager = new CompositeCacheManager();
        manager.setCacheManagers(Arrays.asList(l1Manager, l2Manager));
        return manager;
    }
}
```

---

## 六、最佳实践

1. **统一缓存命名** — 使用有意义的缓存名称
2. **合理设置过期时间** — 根据数据更新频率设置
3. **避免缓存大对象** — 缓存ID而非完整对象
4. **处理缓存穿透** — 使用条件缓存或空值缓存
5. **监控缓存命中率** — 定期检查缓存效果

---

*Spring Cache是缓存抽象层，建议配合Caffeine或Redis使用。*
