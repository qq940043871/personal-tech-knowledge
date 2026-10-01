# HTTP缓存机制

> 模块：网络层
> 更新时间：2026-03-29

---

## 一、缓存策略

```
HTTP缓存类型：
  1. 强缓存
     - Cache-Control / Expires
     - 不发送请求，直接使用缓存
     - 优先级：Cache-Control > Expires
  
  2. 协商缓存
     - Last-Modified / ETag
     - 发送请求，服务器判断是否使用缓存
     - 优先级：ETag > Last-Modified
```

---

## 二、缓存头

```
Cache-Control：
  max-age=3600         缓存有效期（秒）
  no-cache             强制协商缓存
  no-store             禁止缓存
  private              仅客户端缓存
  public               可被CDN等中间节点缓存
  must-revalidate       过期后必须验证

Expires：
  Expires: Wed, 21 Oct 2026 07:28:00 GMT

Last-Modified / If-Modified-Since：
  Last-Modified: Wed, 21 Oct 2026 07:28:00 GMT
  If-Modified-Since: Wed, 21 Oct 2026 07:28:00 GMT

ETag / If-None-Match：
  ETag: "33a64df551425fcc55e4d42a148795d9"
  If-None-Match: "33a64df551425fcc55e4d42a148795d9"
```

---

## 三、缓存决策流程

```
┌──────────────────────────────────────────────────────────┐
│                     请求资源                               │
└─────────────────────────┬────────────────────────────────┘
                          │
                          ▼
               ┌────────────────────────┐
               │  查找缓存？             │
               └───────────┬────────────┘
                    │是    │否
                    ▼       ▼
         ┌──────────────┐  ┌──────────────┐
         │  强缓存有效？ │  │  发起请求    │
         └──────┬───────┘  └──────┬───────┘
              │是   │否          │
              ▼     ▼            ▼
    直接返回    ▼       ┌──────────────┐
    缓存响应    │       │ 发送请求     │
              ▼       │ + 条件头     │
        ┌────────────┐│ └──────┬───────┘
        │  304 Not   ││        │
        │  Modified  ││        ▼
        └──────┬─────┘│  ┌─────────────┐
               │      │  │  200 OK     │
               ▼      │  │  (新内容)   │
        返回缓存响应   │  └──────┬──────┘
                       │        │
                       │        ▼
                       │  更新缓存
                       └────────┘
```

---

## 四、C++实现

```cpp
class HttpCache {
private:
    std::map<std::string, CacheEntry> cache;
    std::mutex mutex;
    size_t maxCacheSize;
    
public:
    CacheResult get(const std::string& url) {
        std::lock_guard<std::mutex> lock(mutex);
        
        auto it = cache.find(url);
        if (it == cache.end()) {
            return CacheResult::NOT_FOUND;
        }
        
        CacheEntry& entry = it->second;
        
        // 检查过期
        if (entry.isExpired()) {
            cache.erase(it);
            return CacheResult::EXPIRED;
        }
        
        return CacheResult::HIT;
    }
    
    void put(const std::string& url, const HttpResponse& response) {
        std::lock_guard<std::mutex> lock(mutex);
        
        // 检查缓存大小
        if (cache.size() >= maxCacheSize) {
            evictOldest();
        }
        
        CacheEntry entry;
        entry.response = response;
        entry.cachedTime = time(nullptr);
        
        // 解析Cache-Control
        if (auto maxAge = response.getHeader("max-age")) {
            entry.expiresTime = entry.cachedTime + std::stoi(maxAge);
        }
        
        cache[url] = entry;
    }
    
    std::optional<HttpResponse> getCached(const std::string& url) {
        if (get(url) == CacheResult::HIT) {
            return cache[url].response;
        }
        return std::nullopt;
    }
};
```

---

*下一步：URL解析与规范*
