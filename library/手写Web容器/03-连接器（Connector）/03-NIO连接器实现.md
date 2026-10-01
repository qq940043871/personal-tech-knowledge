# NIO连接器实现

> 模块：连接器（Connector）
> 更新时间：2026-03-29

---

## 一、NIO模型

```
特点：
  - 非阻塞IO
  - Selector多路复用
  - 单线程处理多连接
  - 适合高并发场景

优势：
  - 线程数 << 连接数
  - 减少线程切换开销
  - 扩展性好
```

---

## 二、Poller模式

```java
public class NioEndpoint {
    private ServerSocketChannel serverChannel;
    private Selector selector;
    private Poller[] pollers;
    private int pollerCount = 2;
    private volatile boolean running = false;
    
    public void start() throws IOException {
        // 初始化ServerSocketChannel
        serverChannel = ServerSocketChannel.open();
        serverChannel.bind(new InetSocketAddress(8080));
        serverChannel.configureBlocking(false);
        
        // 初始化Poller
        pollers = new Poller[pollerCount];
        for (int i = 0; i < pollerCount; i++) {
            pollers[i] = new Poller();
            new Thread(pollers[i], "Poller-" + i).start();
        }
        
        running = true;
        System.out.println("NIO Endpoint started on port 8080");
        
        // 主线程接收连接
        while (running) {
            SocketChannel client = serverChannel.accept();
            if (client != null) {
                client.configureBlocking(false);
                // 轮询分配给Poller
                pollers[Math.abs(client.hashCode()) % pollerCount].register(client);
            }
        }
    }
    
    private class Poller implements Runnable {
        private Selector selector;
        private ConcurrentLinkedQueue<SocketChannel> queue = new ConcurrentLinkedQueue<>();
        
        public Poller() throws IOException {
            this.selector = Selector.open();
        }
        
        public void register(SocketChannel channel) {
            queue.offer(channel);
            selector.wakeup();
        }
        
        @Override
        public void run() {
            while (running) {
                try {
                    // 处理新连接
                    SocketChannel channel;
                    while ((channel = queue.poll()) != null) {
                        channel.register(selector, SelectionKey.OP_READ, new NioSocketWrapper(channel));
                    }
                    
                    // 等待事件
                    selector.select(1000);
                    
                    // 处理就绪事件
                    Iterator<SelectionKey> iterator = selector.selectedKeys().iterator();
                    while (iterator.hasNext()) {
                        SelectionKey key = iterator.next();
                        iterator.remove();
                        
                        if (key.isReadable()) {
                            NioSocketWrapper wrapper = (NioSocketWrapper) key.attachment();
                            wrapper.process();
                        }
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
```

---

## 三、SocketWrapper

```java
public class NioSocketWrapper {
    private SocketChannel channel;
    private ByteBuffer readBuffer = ByteBuffer.allocate(8192);
    private ByteBuffer writeBuffer = ByteBuffer.allocate(8192);
    
    public NioSocketWrapper(SocketChannel channel) {
        this.channel = channel;
    }
    
    public void process() throws IOException {
        int len = channel.read(readBuffer);
        
        if (len > 0) {
            readBuffer.flip();
            byte[] data = new byte[readBuffer.remaining()];
            readBuffer.get(data);
            readBuffer.clear();
            
            // 处理HTTP请求
            String response = processHttpRequest(new String(data));
            
            // 返回响应
            writeBuffer.put(response.getBytes());
            writeBuffer.flip();
            channel.write(writeBuffer);
            writeBuffer.clear();
        } else if (len == -1) {
            channel.close();
        }
    }
}
```

---

*下一步：连接池管理*
