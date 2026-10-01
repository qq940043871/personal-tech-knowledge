# Caffeine高性能缓存

> 模块：Java框架全景图 / 07-缓存框架
> 更新时间：2026-06-20

---

## 一、概述

Caffeine是Java 8+的高性能本地缓存库，由Google Guava Cache的作者开发，性能比Guava Cache提升显著。

### 核心特性
- **高性能** — Window-TinyLFU淘汰算法，接近最优命中率
- **自动加载** — 支持异步刷新和自动加载
- **统计** — 内置缓存命中率统计
- **轻量** — 无外部依赖

---

## 二、基本使用

### 2.1 Maven依赖

```xml
<dependency>
    <groupId>com.github.ben-manes.caffeine</groupId>
    <artifactId>caffeine</artifactId>
    <version>3.1.8</version>
</dependency>
```

### 2.2 同步缓存

```java
Cache<String, User> cache = Caffeine.newBuilder()
    .maximumSize(10_000)                    // 最大10000条
    .expireAfterWrite(Duration.ofMinutes(5)) // 写入后5分钟过期
    .expireAfterAccess(Duration.ofMinutes(10)) // 访问后10分钟过期
    .recordStats()                          // 开启统计
    .build();

// 放入缓存
cache.put("user:1", new User("Alice", 25));

// 获取缓存，不存在时返回null
User user = cache.getIfPresent("user:1");

// 获取缓存，不存在时加载
User user = cache.get("user:1", key -> loadUserFromDB(key));

// 删除缓存
cache.invalidate("user:1");
```

### 2.3 异步缓存

```java
AsyncCache<String, User> asyncCache = Caffeine.newBuilder()
    .maximumSize(10_000)
    .expireAfterWrite(Duration.ofMinutes(5))
    .buildAsync();

// 异步获取
CompletableFuture<User> future = asyncCache.get("user:1", key -> loadUserFromDB(key));
```

---

## 三、Spring Cache集成

### 3.1 配置

```java
@Configuration
@EnableCaching
public class CacheConfig {
    
    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();
        cacheManager.setCaffeine(Caffeine.newBuilder()
            .maximumSize(10_000)
            .expireAfterWrite(Duration.ofMinutes(5))
            .recordStats());
        return cacheManager;
    }
}
```

### 3.2 使用注解

```java
@Service
public class UserService {
    
    @Cacheable(value = "users", key = "#id")
    public User getUserById(Long id) {
        return userRepository.findById(id).orElse(null);
    }
    
    @CachePut(value = "users", key = "#user.id")
    public User updateUser(User user) {
        return userRepository.save(user);
    }
    
    @CacheEvict(value = "users", key = "#id")
    public void deleteUser(Long id) {
        userRepository.deleteById(id);
    }
}
```

---

## 四、高级特性

### 4.1 刷新策略

```java
Cache<String, User> cache = Caffeine.newBuilder()
    .maximumSize(10_000)
    .refreshAfterWrite(Duration.ofMinutes(1)) // 写入后1分钟刷新
    .build(key -> loadUserFromDB(key));        // 刷新时的加载器
```

### 4.2 引用类型

```java
// 软引用 - 内存不足时回收
Caffeine.newBuilder()
    .softValues()
    .build();

// 弱引用 - GC时回收
Caffeine.newBuilder()
    .weakValues()
    .build();
```

### 4.3 监听器

```java
Cache<String, User> cache = Caffeine.newBuilder()
    .maximumSize(10_000)
    .removalListener((key, value, cause) -> {
        log.info("Cache entry removed: key={}, cause={}", key, cause);
    })
    .build();
```

---

## 五、性能对比

| 操作 | Caffeine | Guava Cache | ConcurrentHashMap |
|------|----------|-------------|-------------------|
| 读 | 60ns | 100ns | 50ns |
| 写 | 80ns | 150ns | 60ns |
| 命中率 | 99% | 95% | N/A |

---

## 六、最佳实践

1. **设置合理的maximumSize** — 根据内存和访问模式设置
2. **使用refreshAfterWrite** — 避免缓存失效时的延迟
3. **开启recordStats** — 监控缓存命中率
4. **避免缓存大对象** — 考虑使用软引用或分布式缓存

---

## 七、与Ehcache对比

| 特性 | Caffeine | Ehcache |
|------|----------|---------|
| 性能 | 更高 | 高 |
| 内存占用 | 更低 | 较高 |
| 磁盘存储 | 不支持 | 支持 |
| 分布式 | 不支持 | 支持 |
| 使用场景 | 纯内存缓存 | 多级缓存 |

---

*纯内存缓存场景推荐Caffeine，需要磁盘或分布式缓存选Ehcache。*
