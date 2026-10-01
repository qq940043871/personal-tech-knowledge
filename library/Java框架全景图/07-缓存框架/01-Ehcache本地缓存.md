# Ehcache本地缓存

> 模块：Java框架全景图 / 07-缓存框架
> 更新时间：2026-06-20

---

## 一、概述

Ehcache是Java领域最成熟的本地缓存框架，支持内存和磁盘存储，广泛用于Hibernate二级缓存、Spring Cache等场景。

### 核心特性
- **快速** — 纯内存操作，微秒级响应
- **轻量** — 无外部依赖
- **灵活** — 支持内存、磁盘、堆外存储
- **分布式** — Ehcache 3支持Terracotta分布式缓存

---

## 二、Ehcache 3使用

### 2.1 Maven依赖

```xml
<dependency>
    <groupId>org.ehcache</groupId>
    <artifactId>ehcache</artifactId>
    <version>3.10.8</version>
</dependency>
```

### 2.2 基本使用

```java
CacheManager cacheManager = CacheManagerBuilder.newCacheManagerBuilder()
    .withCache("users",
        CacheConfigurationBuilder.newCacheConfigurationBuilder(
            Long.class, User.class,
            ResourcePoolsBuilder.heap(100))  // 堆内100个元素
        .withExpiry(ExpiryPolicyBuilder.timeToLiveExpiration(
            Duration.ofMinutes(5))))         // 5分钟过期
    .build(true);

Cache<Long, User> usersCache = cacheManager.getCache("users", Long.class, User.class);

// 放入缓存
usersCache.put(1L, new User("Alice", 25));

// 获取缓存
User user = usersCache.get(1L);

// 删除缓存
usersCache.remove(1L);
```

### 2.3 多级缓存

```java
CacheConfigurationBuilder.newCacheConfigurationBuilder(
    Long.class, User.class,
    ResourcePoolsBuilder.newResourcePoolsBuilder()
        .heap(100)                          // 堆内100个元素
        .offheap(10, MemoryUnit.MB)         // 堆外10MB
        .disk(100, MemoryUnit.MB, true))    // 磁盘100MB
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
        EhcacheCachingProvider provider = (EhcacheCachingProvider) 
            Caching.getCachingProvider("org.ehcache.jsr107.EhcacheCachingProvider");
        
        Configuration config = new DefaultConfiguration(
            provider.getDefaultClassLoader(),
            Collections.singletonMap("users", 
                new MutableConfiguration<>(Long.class, User.class)
                    .setExpiryPolicyFactory(CreatedExpiryPolicy.factoryOf(
                        Duration.ofMinutes(5)))
                    .setStoreByValue(false)));
        
        return new JCacheCacheManager(provider.getCacheManager(
            provider.getDefaultURI(), config));
    }
}
```

### 3.2 使用注解

```java
@Service
public class UserService {
    
    @Cacheable(value = "users", key = "#id")
    public User getUserById(Long id) {
        // 查询数据库
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
    
    @CacheEvict(value = "users", allEntries = true)
    public void clearCache() {
        // 清除所有缓存
    }
}
```

---

## 四、缓存策略

### 4.1 过期策略

```java
// TTL: 写入后过期
ExpiryPolicyBuilder.timeToLiveExpiration(Duration.ofMinutes(30));

// TTI: 访问后过期
ExpiryPolicyBuilder.timeToIdleExpiration(Duration.ofMinutes(10));
```

### 4.2 淘汰策略

- **LRU** — 最近最少使用（默认）
- **LFU** — 最不经常使用
- **FIFO** — 先进先出

---

## 五、监控与统计

```java
// 获取缓存统计
CacheStatistics stats = cacheManager.getStatistics();

long hitCount = stats.getCacheHits();
long missCount = stats.getCacheMisses();
double hitRate = stats.getCacheHitPercentage();
```

---

## 六、最佳实践

1. **合理设置容量** — 根据内存和访问模式设置
2. **设置过期时间** — 避免缓存数据过期
3. **缓存穿透防护** — 使用空值缓存或布隆过滤器
4. **监控缓存命中率** — 低命中率需要调整策略
5. **分布式场景** — 考虑使用Redis替代本地缓存

---

## 七、与其他缓存框架对比

| 特性 | Ehcache | Caffeine | Guava Cache |
|------|---------|----------|-------------|
| 性能 | 高 | 更高 | 高 |
| 功能 | 丰富 | 精简 | 丰富 |
| 磁盘存储 | 支持 | 不支持 | 不支持 |
| 分布式 | 支持 | 不支持 | 不支持 |
| 维护状态 | 活跃 | 活跃 | 维护模式 |

---

*Caffeine性能更优，新项目推荐使用Caffeine。*
