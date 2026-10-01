# NIO与多路复用

> 模块：网络基础
> 更新时间：2026-03-29

---

## 一、IO模型对比

```
BIO（阻塞IO）：
  - 一个连接一个线程
  - 简单但并发受限
  - 适合连接数少的场景

NIO（非阻塞IO）：
  - 单线程处理多连接
  - Selector多路复用
  - 适合高并发场景

AIO（异步IO）：
  - 操作系统回调
  - 真正异步
  - 实现复杂
```

---

## 二、Selector核心

```java
public class NioEndpoint {
    private Selector selector;
    private ServerSocketChannel serverChannel;
    
    public void start() throws IOException {
        selector = Selector.open();
        serverChannel = ServerSocketChannel.open();
        serverChannel.bind(new InetSocketAddress(8080));
        serverChannel.configureBlocking(false);
        serverChannel.register(selector, SelectionKey.OP_ACCEPT);
        
        while (true) {
            int ready = selector.select();
            if (ready == 0) continue;
            
            Set<SelectionKey> keys = selector.selectedKeys();
            Iterator<SelectionKey> iterator = keys.iterator();
            
            while (iterator.hasNext()) {
                SelectionKey key = iterator.next();
                iterator.remove();
                
                if (key.isAcceptable()) {
                    accept(key);
                } else if (key.isReadable()) {
                    read(key);
                } else if (key.isWritable()) {
                    write(key);
                }
            }
        }
    }
    
    private void accept(SelectionKey key) throws IOException {
        ServerSocketChannel server = (ServerSocketChannel) key.channel();
        SocketChannel client = server.accept();
        client.configureBlocking(false);
        client.register(selector, SelectionKey.OP_READ);
    }
    
    private void read(SelectionKey key) throws IOException {
        SocketChannel client = (SocketChannel) key.channel();
        ByteBuffer buffer = ByteBuffer.allocate(8192);
        int len = client.read(buffer);
        
        if (len > 0) {
            buffer.flip();
            processRequest(buffer, client);
        } else if (len == -1) {
            client.close();
        }
    }
}
```

---

## 三、Buffer操作

```java
ByteBuffer buffer = ByteBuffer.allocate(1024);

// 写入数据
buffer.put(data);

// 切换读模式
buffer.flip();

// 读取数据
byte[] result = new byte[buffer.remaining()];
buffer.get(result);

// 清空/重置
buffer.clear();   // 清空
buffer.rewind();  // 重置position
```

---

*下一步：线程模型设计*
