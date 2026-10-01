# TCP连接管理

> 模块：网络层
> 更新时间：2026-03-29

---

## 一、连接池原理

```
浏览器连接池：
  - 复用TCP连接
  - 减少握手延迟
  - 控制并发连接数

Chrome连接限制：
  每个域名：6个并发连接
  总连接数：无限制
  连接超时：通常60-120秒
```

---

## 二、连接状态机

```
CLOSED → SYN_SENT → ESTABLISHED → CLOSE_WAIT → LAST_ACK → CLOSED
         ↓
      SYN_RECV（同时打开）
```

---

## 三、C++实现

```cpp
class ConnectionPool {
private:
    std::map<std::string, std::vector<Connection*>> pool;
    std::mutex mutex;
    size_t maxConnectionsPerHost;
    
public:
    Connection* getConnection(const std::string& host, int port) {
        std::lock_guard<std::mutex> lock(mutex);
        
        std::string key = host + ":" + std::to_string(port);
        auto it = pool.find(key);
        
        if (it != pool.end() && !it->second.empty()) {
            Connection* conn = it->second.back();
            it->second.pop_back();
            
            if (conn->isAlive()) {
                return conn;
            }
            delete conn;
        }
        
        return createConnection(host, port);
    }
    
    void releaseConnection(Connection* conn) {
        if (!conn || !conn->isAlive()) {
            delete conn;
            return;
        }
        
        std::lock_guard<std::mutex> lock(mutex);
        std::string key = conn->getHost() + ":" + std::to_string(conn->getPort());
        
        if (pool[key].size() < maxConnectionsPerHost) {
            conn->reset();
            pool[key].push_back(conn);
        } else {
            delete conn;
        }
    }
};
```

---

## 四、DNS解析

```cpp
class DnsResolver {
private:
    std::map<std::string, DnsResult> cache;
    std::mutex cacheMutex;
    time_t cacheTTL = 300; // 5分钟
    
public:
    std::vector<IPAddress> resolve(const std::string& hostname) {
        // 检查缓存
        {
            std::lock_guard<std::mutex> lock(cacheMutex);
            auto it = cache.find(hostname);
            if (it != cache.end() && !isExpired(it->second)) {
                return it->second.addresses;
            }
        }
        
        // 发起DNS查询
        std::vector<IPAddress> result = doDnsQuery(hostname);
        
        // 缓存结果
        {
            std::lock_guard<std::mutex> lock(cacheMutex);
            cache[hostname] = {result, time(nullptr)};
        }
        
        return result;
    }
};
```

---

*下一步：HTTP缓存机制*
