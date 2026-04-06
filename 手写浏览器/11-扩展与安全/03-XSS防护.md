# XSS防护

> 模块：扩展与安全
> 更新时间：2026-03-29

---

## 一、XSS类型

```
反射型XSS：
  - 用户输入立即返回
  - 如：URL参数直接显示
  
存储型XSS：
  - 输入被存储在服务器
  - 所有访问者都受影响
  
DOM型XSS：
  - 纯客户端处理
  - 不涉及服务端
```

---

## 二、防护措施

```cpp
class XSSProtector {
public:
    std::string sanitizeHTML(const std::string& input) {
        std::string output = input;
        
        // 替换危险字符
        replaceAll(output, "&", "&amp;");
        replaceAll(output, "<", "&lt;");
        replaceAll(output, ">", "&gt;");
        replaceAll(output, "\"", "&quot;");
        replaceAll(output, "'", "&#x27;");
        
        return output;
    }
    
    std::string sanitizeURL(const std::string& url) {
        URL parsed(url);
        
        // 仅允许安全协议
        if (parsed.scheme() != "http" && 
            parsed.scheme() != "https" &&
            parsed.scheme() != "mailto") {
            return "about:blank";
        }
        
        return url;
    }
    
    void enableCSP(const std::string& policy) {
        cspPolicy = policy;
    }
    
    bool checkCSPViolation(const HTTPResponse& response,
                          const std::string& resource) {
        // 检查CSP策略
        // ...
    }
};

// CSP头示例
// Content-Security-Policy: default-src 'self'; 
//                          script-src 'self' 'unsafe-inline'; 
//                          style-src 'self' 'unsafe-inline';
```

---

## 三、安全头部

```cpp
class SecurityHeaders {
public:
    void setSecurityHeaders(HTTPResponse& response) {
        // 防止XSS
        response.setHeader("X-XSS-Protection", "1; mode=block");
        
        // 防止点击劫持
        response.setHeader("X-Frame-Options", "DENY");
        
        // 内容类型 sniffing
        response.setHeader("X-Content-Type-Options", "nosniff");
        
        // HSTS（HTTPS严格传输安全）
        response.setHeader("Strict-Transport-Security", 
            "max-age=31536000; includeSubDomains");
        
        // CSP
        // response.setHeader("Content-Security-Policy", csp);
    }
};
```

---

*文档生成完成！*
