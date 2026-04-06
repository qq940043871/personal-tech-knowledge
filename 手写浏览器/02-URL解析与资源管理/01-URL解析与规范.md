# URL解析与规范

> 模块：URL解析与资源管理
> 更新时间：2026-03-29

---

## 一、URL结构

```
URL完整格式：
  scheme://username:password@host:port/path?query#fragment

示例：
  https://john:pass@example.com:8080/news/list?page=1#top

分解：
  scheme:    https
  username:  john
  password:  pass
  host:      example.com
  port:      8080
  path:      /news/list
  query:     page=1
  fragment:  top
```

---

## 二、URL编码

```
需要编码的字符：
  - 非ASCII字符 → UTF-8 → %XX
  - 特殊字符 → %XX
    空格 → %20
    # → %23
    ? → %3F
    & → %26
    = → %3D
    / → %2F
    : → %3A
```

---

## 三、C++实现

```cpp
class URL {
private:
    std::string scheme;
    std::string username;
    std::string password;
    std::string host;
    int port;
    std::string path;
    std::string query;
    std::string fragment;
    
public:
    static URL parse(const std::string& urlString) {
        URL url;
        
        // 解析scheme
        size_t pos = urlString.find("://");
        if (pos != std::string::npos) {
            url.scheme = urlString.substr(0, pos);
            pos += 3;
        } else {
            pos = 0;
        }
        
        // 解析认证信息
        size_t atPos = urlString.find('@', pos);
        size_t slashPos = urlString.find('/', pos);
        
        if (atPos != std::string::npos && 
            (slashPos == std::string::npos || atPos < slashPos)) {
            std::string auth = urlString.substr(pos, atPos - pos);
            size_t colonPos = auth.find(':');
            url.username = auth.substr(0, colonPos);
            url.password = auth.substr(colonPos + 1);
            pos = atPos + 1;
        }
        
        // 解析host:port
        size_t hostEnd = slashPos;
        if (hostEnd == std::string::npos) {
            hostEnd = urlString.find('?', pos);
        }
        if (hostEnd == std::string::npos) {
            hostEnd = urlString.find('#', pos);
        }
        if (hostEnd == std::string::npos) {
            hostEnd = urlString.length();
        }
        
        std::string hostPart = urlString.substr(pos, hostEnd - pos);
        size_t colonPos = hostPart.find(':');
        if (colonPos != std::string::npos) {
            url.host = hostPart.substr(0, colonPos);
            url.port = std::stoi(hostPart.substr(colonPos + 1));
        } else {
            url.host = hostPart;
            url.port = url.defaultPort();
        }
        
        return url;
    }
    
    std::string toString() const {
        std::ostringstream oss;
        oss << scheme << "://";
        if (!username.empty()) {
            oss << username << ":" << password << "@";
        }
        oss << host;
        if (port != defaultPort()) {
            oss << ":" << port;
        }
        oss << path;
        if (!query.empty()) {
            oss << "?" << query;
        }
        if (!fragment.empty()) {
            oss << "#" << fragment;
        }
        return oss.str();
    }
    
    std::string resolve(const std::string& relative) const {
        if (relative.find("://") != std::string::npos) {
            return relative;
        }
        
        URL base = *this;
        if (relative.empty()) {
            return base.toString();
        }
        
        if (relative[0] == '/') {
            base.path = relative;
            return base.toString();
        }
        
        size_t lastSlash = base.path.rfind('/');
        if (lastSlash != std::string::npos) {
            base.path = base.path.substr(0, lastSlash + 1) + relative;
        } else {
            base.path = "/" + relative;
        }
        
        return base.toString();
    }
};
```

---

## 四、URL规范（rfc3986）

```
有效URL字符：
  ALPHA / DIGIT / - / . / _ / ~
  
编码规则：
  保留字符：: / ? # [ ] @ ! $ & ' ( ) * + , ; =
  未保留字符：字母 数字 - . _ ~
```

---

*下一步：资源类型识别*
