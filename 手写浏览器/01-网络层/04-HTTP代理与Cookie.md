# HTTP代理与Cookie

> 模块：网络层
> 更新时间：2026-03-29

---

## 一、代理机制

```
HTTP代理类型：
  1. 正向代理
     - 客户端使用
     - 隐藏客户端身份
     - 突破访问限制
  
  2. 反向代理
     - 服务端使用
     - 负载均衡
     - 隐藏服务端架构
  
  3.透明代理
     - 不修改请求/响应
     - 用于网络监控
```

---

## 二、代理请求

```
普通HTTP请求：
  GET http://example.com/index.html HTTP/1.1

代理请求：
  GET /index.html HTTP/1.1
  Host: example.com

CONNECT请求（HTTPS代理）：
  CONNECT example.com:443 HTTP/1.1
```

---

## 三、Cookie机制

```
Cookie属性：
  name=value        Cookie数据
  Path=/           生效路径
  Domain=.example.com  生效域名
  Expires=...      过期时间
  Max-Age=3600     有效期（秒）
  HttpOnly         JS不可访问
  Secure           仅HTTPS传输
  SameSite=Strict   CSRF防护
```

---

## 四、C++实现

```cpp
class CookieManager {
private:
    std::map<std::string, std::vector<Cookie>> cookies;
    std::mutex mutex;
    
public:
    void parseSetCookie(const std::string& domain, 
                        const std::string& setCookie) {
        Cookie cookie = parseCookie(setCookie);
        
        std::lock_guard<std::mutex> lock(mutex);
        cookies[domain].push_back(cookie);
    }
    
    std::string getCookieHeader(const std::string& url) {
        std::ostringstream oss;
        URL parsed(url);
        std::string domain = parsed.host;
        
        std::lock_guard<std::mutex> lock(mutex);
        
        bool first = true;
        for (auto& cookie : cookies[domain]) {
            if (cookie.isExpired()) continue;
            if (!cookie.matchesPath(parsed.path)) continue;
            
            if (!first) oss << "; ";
            oss << cookie.name() << "=" << cookie.value();
            first = false;
        }
        
        return oss.str();
    }
};

class ProxyHandler {
public:
    HttpRequest handleRequest(const HttpRequest& request, 
                             const ProxyConfig& config) {
        HttpRequest proxied = request;
        
        // 添加代理头
        proxied.setHeader("X-Forwarded-For", config.clientIP);
        proxied.setHeader("Via", "MyBrowser/1.0");
        
        // 处理认证
        if (!config.username.empty()) {
            std::string auth = base64Encode(
                config.username + ":" + config.password);
            proxied.setHeader("Proxy-Authorization", 
                "Basic " + auth);
        }
        
        return proxied;
    }
};
```

---

*下一步：URL解析与规范*
