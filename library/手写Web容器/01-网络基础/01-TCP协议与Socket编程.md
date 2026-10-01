# TCP协议与Socket编程

> 模块：网络基础
> 更新时间：2026-03-29

---

## 一、理论基础

### 1. TCP三次握手

```
客户端                    服务端
   │                        │
   │ ──── SYN ────────────► │  第一次握手：客户端发起连接
   │      seq=x             │
   │                        │
   │ ◄─── SYN+ACK ─────────│  第二次握手：服务端确认+发起
   │      seq=y, ack=x+1    │
   │                        │
   │ ──── ACK ────────────► │  第三次握手：客户端确认
   │      seq=x+1, ack=y+1  │
   │                        │
```

### 2. TCP四次挥手

```
客户端                    服务端
   │                        │
   │ ──── FIN ────────────► │  第一次：客户端请求关闭
   │                        │
   │ ◄─── ACK ─────────────│  第二次：服务端确认
   │                        │
   │ ◄─── FIN ─────────────│  第三次：服务端请求关闭
   │                        │
   │ ──── ACK ────────────► │  第四次：客户端确认
   │                        │
   │   TIME_WAIT 2MSL       │
```

---

## 二、Java Socket编程

### 1. BIO服务端

```java
public class BioServer {
    public static void main(String[] args) throws IOException {
        ServerSocket serverSocket = new ServerSocket(8080);
        System.out.println("服务器启动，端口8080");
        
        while (true) {
            Socket socket = serverSocket.accept();  // 阻塞等待
            new Thread(() -> handle(socket)).start();  // 每连接一线程
        }
    }
    
    static void handle(Socket socket) {
        try (BufferedReader in = new BufferedReader(
                new InputStreamReader(socket.getInputStream()));
             PrintWriter out = new PrintWriter(socket.getOutputStream())) {
            
            String line;
            while ((line = in.readLine()) != null) {
                System.out.println("收到: " + line);
                out.println("Echo: " + line);
                out.flush();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

### 2. NIO服务端

```java
public class NioServer {
    public static void main(String[] args) throws IOException {
        Selector selector = Selector.open();
        ServerSocketChannel serverChannel = ServerSocketChannel.open();
        serverChannel.bind(new InetSocketAddress(8080));
        serverChannel.configureBlocking(false);
        serverChannel.register(selector, SelectionKey.OP_ACCEPT);
        
        while (true) {
            selector.select();  // 阻塞等待事件
            Iterator<SelectionKey> keys = selector.selectedKeys().iterator();
            
            while (keys.hasNext()) {
                SelectionKey key = keys.next();
                keys.remove();
                
                if (key.isAcceptable()) {
                    accept(key);
                } else if (key.isReadable()) {
                    read(key);
                }
            }
        }
    }
    
    static void accept(SelectionKey key) throws IOException {
        ServerSocketChannel server = (ServerSocketChannel) key.channel();
        SocketChannel client = server.accept();
        client.configureBlocking(false);
        client.register(key.selector(), SelectionKey.OP_READ);
    }
    
    static void read(SelectionKey key) throws IOException {
        SocketChannel client = (SocketChannel) key.channel();
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        int len = client.read(buffer);
        if (len > 0) {
            buffer.flip();
            byte[] data = new byte[buffer.remaining()];
            buffer.get(data);
            System.out.println("收到: " + new String(data));
        }
    }
}
```

---

## 三、Web容器中的连接

```java
public class Connector {
    private int port = 8080;
    private ServerSocket serverSocket;
    private ExecutorService threadPool;
    
    public void start() {
        threadPool = Executors.newFixedThreadPool(200);
        try {
            serverSocket = new ServerSocket(port);
            while (running) {
                Socket socket = serverSocket.accept();
                threadPool.execute(new RequestProcessor(socket));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

---

*下一步：HTTP协议详解*
