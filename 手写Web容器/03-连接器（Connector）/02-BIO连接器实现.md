# BIO连接器实现

> 模块：连接器（Connector）
> 更新时间：2026-03-29

---

## 一、BIO模型

```
特点：
  - 阻塞IO
  - 一连接一线程
  - 实现简单
  - 适合连接数少的场景

缺点：
  - 线程数 = 连接数
  - 线程切换开销大
  - 扩展性差
```

---

## 二、实现代码

```java
public class BioEndpoint {
    private int port = 8080;
    private ServerSocket serverSocket;
    private ExecutorService threadPool;
    private volatile boolean running = false;
    private Handler handler;
    
    public void start() throws IOException {
        serverSocket = new ServerSocket(port);
        threadPool = Executors.newCachedThreadPool();
        running = true;
        
        System.out.println("BIO Endpoint started on port " + port);
        
        while (running) {
            try {
                Socket socket = serverSocket.accept();
                threadPool.execute(new SocketProcessor(socket));
            } catch (IOException e) {
                if (running) {
                    e.printStackTrace();
                }
            }
        }
    }
    
    public void stop() throws IOException {
        running = false;
        threadPool.shutdown();
        serverSocket.close();
    }
    
    private class SocketProcessor implements Runnable {
        private Socket socket;
        
        public SocketProcessor(Socket socket) {
            this.socket = socket;
        }
        
        @Override
        public void run() {
            try {
                handler.process(socket);
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                try {
                    socket.close();
                } catch (IOException e) {}
            }
        }
    }
}
```

---

## 三、性能测试

```
测试环境：
  - CPU: 8核
  - 内存: 16GB
  - 并发: 1000连接

测试结果：
  - QPS: 3000-5000
  - 延迟: 50-100ms
  - CPU使用率: 60%
  - 线程数: 1000+

结论：
  - BIO适合连接数<500的场景
  - 高并发场景建议使用NIO
```

---

*下一步：NIO连接器实现*
