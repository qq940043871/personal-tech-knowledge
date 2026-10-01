# WebSocket支持

> 模块：扩展功能
> 更新时间：2026-03-29

---

## 一、WebSocket原理

```
HTTP升级到WebSocket：

1. 客户端发送升级请求
   GET /chat HTTP/1.1
   Upgrade: websocket
   Connection: Upgrade
   Sec-WebSocket-Key: ...

2. 服务端返回101响应
   HTTP/1.1 101 Switching Protocols
   Upgrade: websocket
   Connection: Upgrade
   Sec-WebSocket-Accept: ...

3. 建立双向通信
```

---

## 二、WebSocket处理

```java
public class WebSocketUpgradeHandler {
    
    public boolean isUpgradeRequest(HttpRequest request) {
        String upgrade = request.getHeader("Upgrade");
        String connection = request.getHeader("Connection");
        
        return "websocket".equalsIgnoreCase(upgrade) && 
               connection != null && connection.contains("Upgrade");
    }
    
    public void handleUpgrade(HttpRequest request, HttpResponse response, 
                             Socket socket) throws IOException {
        // 验证请求
        if (!isValidUpgradeRequest(request)) {
            response.sendError(400, "Invalid WebSocket upgrade request");
            return;
        }
        
        // 计算Sec-WebSocket-Accept
        String key = request.getHeader("Sec-WebSocket-Key");
        String accept = calculateAccept(key);
        
        // 返回101响应
        response.setStatus(101);
        response.setHeader("Upgrade", "websocket");
        response.setHeader("Connection", "Upgrade");
        response.setHeader("Sec-WebSocket-Accept", accept);
        response.send();
        
        // 处理WebSocket通信
        handleWebSocketCommunication(socket);
    }
    
    private String calculateAccept(String key) throws IOException {
        String magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
        String input = key + magic;
        
        MessageDigest md = MessageDigest.getInstance("SHA-1");
        byte[] hash = md.digest(input.getBytes());
        
        return Base64.getEncoder().encodeToString(hash);
    }
    
    private void handleWebSocketCommunication(Socket socket) throws IOException {
        InputStream input = socket.getInputStream();
        OutputStream output = socket.getOutputStream();
        
        while (true) {
            // 读取WebSocket帧
            WebSocketFrame frame = readFrame(input);
            
            if (frame.isCloseFrame()) {
                break;
            }
            
            // 处理消息
            String message = frame.getPayload();
            System.out.println("WebSocket message: " + message);
            
            // 返回响应
            WebSocketFrame response = new WebSocketFrame(message);
            writeFrame(output, response);
        }
    }
}
```

---

*下一步：虚拟主机配置*
