# Socket服务端

> 模块：网络层
> 更新时间：2026-03-29

---

## 一、服务端架构

```
服务端组件：
  ServerSocket: 监听端口
  ConnectionAcceptor: 接收连接
  QueryExecutor: 执行查询
  ResultWriter: 返回结果
```

---

## 二、NIO服务端实现

```java
public class DatabaseServer {
    private int port = 3306;
    private ServerSocketChannel serverChannel;
    private Selector selector;
    private ExecutorService threadPool;
    private volatile boolean running = false;
    
    public void start() throws IOException {
        serverChannel = ServerSocketChannel.open();
        serverChannel.bind(new InetSocketAddress(port));
        serverChannel.configureBlocking(false);
        serverChannel.socket().setReuseAddress(true);
        
        selector = Selector.open();
        serverChannel.register(selector, SelectionKey.OP_ACCEPT);
        
        threadPool = Executors.newFixedThreadPool(
            Runtime.getRuntime().availableProcessors() * 2
        );
        
        running = true;
        System.out.println("Database server started on port " + port);
        
        while (running) {
            selector.select(1000);
            Set<SelectionKey> keys = selector.selectedKeys();
            
            for (SelectionKey key : keys) {
                try {
                    if (key.isAcceptable()) {
                        accept(key);
                    } else if (key.isReadable()) {
                        threadPool.execute(() -> handle(key));
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            keys.clear();
        }
    }
    
    private void accept(SelectionKey key) throws IOException {
        ServerSocketChannel server = (ServerSocketChannel) key.channel();
        SocketChannel client = server.accept();
        client.configureBlocking(false);
        client.register(selector, SelectionKey.OP_READ);
    }
    
    private void handle(SelectionKey key) {
        try {
            SocketChannel channel = (SocketChannel) key.channel();
            
            // 读取请求
            ByteBuffer buffer = ByteBuffer.allocate(8192);
            int len = channel.read(buffer);
            
            if (len > 0) {
                buffer.flip();
                byte[] data = new byte[buffer.remaining()];
                buffer.get(data);
                
                // 处理SQL
                byte[] result = processQuery(data);
                
                // 发送响应
                sendResponse(channel, result);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    private byte[] processQuery(byte[] data) {
        // 解析SQL并执行
        return new byte[0];
    }
}
```

---

## 三、连接管理

```java
public class ConnectionManager {
    private Map<Long, Connection> connections = new ConcurrentHashMap<>();
    private AtomicLong connectionId = new AtomicLong(0);
    
    public Connection createConnection(SocketChannel channel) {
        long id = connectionId.incrementAndGet();
        Connection conn = new Connection(id, channel);
        connections.put(id, conn);
        return conn;
    }
    
    public Connection getConnection(long id) {
        return connections.get(id);
    }
    
    public void closeConnection(long id) {
        Connection conn = connections.remove(id);
        if (conn != null) {
            conn.close();
        }
    }
}
```

---

*下一步：协议报文解析*
