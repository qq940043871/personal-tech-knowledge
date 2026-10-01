# HTTP协议详解

> 模块：网络基础
> 更新时间：2026-03-29

---

## 一、HTTP请求报文

```
GET /index.html HTTP/1.1
Host: localhost:8080
User-Agent: Mozilla/5.0
Accept: text/html
Connection: keep-alive

请求体（POST请求才有）
```

### 结构解析

```
请求行：
  方法：GET/POST/PUT/DELETE/HEAD/OPTIONS
  URL：请求路径
  协议版本：HTTP/1.1

请求头：
  Host: 目标主机
  User-Agent: 客户端信息
  Content-Type: 请求体类型
  Content-Length: 请求体长度
  Connection: 连接方式
  Cookie: 会话信息

请求体：
  POST/PUT请求携带的数据
```

---

## 二、HTTP响应报文

```
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: 1234
Date: Sun, 29 Mar 2026 03:28:00 GMT
Server: MyTomcat/1.0

响应体内容
```

### 状态码

```
1xx: 信息响应
2xx: 成功
  200 OK
  201 Created
  204 No Content

3xx: 重定向
  301 Moved Permanently
  302 Found
  304 Not Modified

4xx: 客户端错误
  400 Bad Request
  401 Unauthorized
  403 Forbidden
  404 Not Found

5xx: 服务端错误
  500 Internal Server Error
  502 Bad Gateway
  503 Service Unavailable
```

---

## 三、Java解析实现

```java
public class HttpRequest {
    private String method;
    private String uri;
    private String protocol;
    private Map<String, String> headers;
    private byte[] body;
    
    public static HttpRequest parse(InputStream input) throws IOException {
        HttpRequest request = new HttpRequest();
        BufferedReader reader = new BufferedReader(new InputStreamReader(input));
        
        // 解析请求行
        String requestLine = reader.readLine();
        String[] parts = requestLine.split(" ");
        request.method = parts[0];
        request.uri = parts[1];
        request.protocol = parts[2];
        
        // 解析请求头
        request.headers = new HashMap<>();
        String line;
        while ((line = reader.readLine()) != null && !line.isEmpty()) {
            int colon = line.indexOf(':');
            String name = line.substring(0, colon).trim();
            String value = line.substring(colon + 1).trim();
            request.headers.put(name, value);
        }
        
        return request;
    }
}
```

---

*下一步：NIO与多路复用*
