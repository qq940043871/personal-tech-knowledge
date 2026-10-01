# HTTP协议与HTTPS

> 模块：网络层
> 更新时间：2026-03-29

---

## 一、HTTP协议基础

```
HTTP（HyperText Transfer Protocol）：
  - 无状态请求/响应协议
  - 基于TCP/IP
  - 默认端口80（HTTP）/443（HTTPS）

版本演进：
  HTTP/0.9：1991年，仅GET，HTML格式
  HTTP/1.0：1996年，引入请求头、状态码
  HTTP/1.1：1999年，持久连接、虚拟主机
  HTTP/2：2015年，多路复用、头部压缩
  HTTP/3：2022年，QUIC协议
```

---

## 二、HTTP请求

```
HTTP请求格式：
  请求行：GET /index.html HTTP/1.1
  请求头：
    Host: www.example.com
    User-Agent: Mozilla/5.0
    Accept: text/html
    Connection: keep-alive
  空行
  请求体（POST/PUT）

请求方法：
  GET：获取资源
  POST：提交数据
  PUT：上传资源
  DELETE：删除资源
  HEAD：获取头部
  OPTIONS：跨域预检
  PATCH：部分更新
```

---

## 三、HTTP响应

```
HTTP响应格式：
  状态行：HTTP/1.1 200 OK
  响应头：
    Content-Type: text/html
    Content-Length: 1234
    Cache-Control: max-age=3600
    Set-Cookie: session=abc123
  空行
  响应体：<html>...</html>

状态码分类：
  1xx：信息性
  2xx：成功（200 OK, 201 Created）
  3xx：重定向（301, 302, 304）
  4xx：客户端错误（400, 401, 403, 404）
  5xx：服务端错误（500, 502, 503）
```

---

## 四、HTTPS原理

```
HTTPS = HTTP + TLS/SSL

TLS握手过程：
  1. 客户端Hello
     - 客户端支持的TLS版本
     - 加密套件列表
     - 随机数A
  
  2. 服务端Hello
     - 选定TLS版本和加密套件
     - 证书（公钥）
     - 随机数B
  
  3. 密钥交换
     - 客户端生成预主密钥
     - 用服务端公钥加密后发送
  
  4. 完成握手
     - 双方用预主密钥+随机数生成会话密钥
     - 后续通信使用对称加密
```

---

## 五、C++实现

```cpp
class HttpRequest {
public:
    std::string method;
    std::string path;
    std::string version;
    std::map<std::string, std::string> headers;
    std::string body;
    
    std::string serialize() {
        std::ostringstream oss;
        oss << method << " " << path << " " << version << "\r\n";
        
        for (auto& h : headers) {
            oss << h.first << ": " << h.second << "\r\n";
        }
        
        oss << "\r\n";
        oss << body;
        
        return oss.str();
    }
};

class HttpResponse {
public:
    int status_code;
    std::string status_message;
    std::map<std::string, std::string> headers;
    std::string body;
    
    bool parse(const std::string& raw) {
        // 解析状态行
        // 解析响应头
        // 解析响应体
    }
};
```

---

*下一步：TCP连接管理*
