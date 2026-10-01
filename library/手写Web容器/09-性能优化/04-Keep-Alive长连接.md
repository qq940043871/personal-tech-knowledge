# Keep-Alive长连接

> 模块：性能优化
> 更新时间：2026-03-29

---

## 一、Keep-Alive原理

```
HTTP/1.0：
  - 每个请求建立新连接
  - 连接开销大

HTTP/1.1：
  - 默认启用Keep-Alive
  - 复用TCP连接
  - 减少连接建立时间

参数：
  - timeout: 连接超时时间
  - max: 最大请求数
```

---

## 二、实现代码

```java
public class KeepAliveManager {
    private int timeout = 60000;      // 60秒
    private int maxRequests = 100;    // 最多100个请求
    
    public void handleConnection(Socket socket) throws IOException {
        int requestCount = 0;
        
        while (requestCount < maxRequests) {
            socket.setSoTimeout(timeout);
            
            try {
                // 读取请求
                HttpRequest request = parseRequest(socket.getInputStream());
                
                // 处理请求
                HttpResponse response = processRequest(request);
                
                // 检查Connection头
                String connection = request.getHeader("Connection");
                boolean keepAlive = "keep-alive".equalsIgnoreCase(connection) ||
                                   "HTTP/1.1".equals(request.getProtocol());
                
                if (!keepAlive) {
                    response.setHeader("Connection", "close");
                    response.send();
                    break;
                }
                
                response.setHeader("Connection", "keep-alive");
                response.setHeader("Keep-Alive", "timeout=" + (timeout/1000) + 
                                                 ", max=" + (maxRequests - requestCount - 1));
                response.send();
                
                requestCount++;
                
            } catch (SocketTimeoutException e) {
                // 连接超时，关闭
                break;
            }
        }
        
        socket.close();
    }
}
```

---

## 三、性能对比

```
无Keep-Alive：
  - 10个请求 = 10次连接建立 + 10次连接关闭
  - 总时间 ≈ 10 * (连接建立时间 + 请求处理时间 + 连接关闭时间)

有Keep-Alive：
  - 10个请求 = 1次连接建立 + 10次请求处理 + 1次连接关闭
  - 总时间 ≈ 连接建立时间 + 10 * 请求处理时间 + 连接关闭时间
  - 性能提升：50-80%
```

---

*下一步：HTTPS支持*
