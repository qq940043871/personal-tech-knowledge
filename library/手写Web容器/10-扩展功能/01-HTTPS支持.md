# HTTPS支持

> 模块：扩展功能
> 更新时间：2026-03-29

---

## 一、HTTPS原理

```
HTTP + SSL/TLS = HTTPS

流程：
  1. 客户端发起连接
  2. 服务端返回证书
  3. 客户端验证证书
  4. 协商加密算法
  5. 建立加密连接
  6. 传输加密数据
```

---

## 二、配置

```xml
<!-- server.xml -->
<Connector port="8443" 
           protocol="HTTPS"
           keyStoreFile="conf/keystore.jks"
           keyStorePassword="password"
           keyAlias="tomcat" />
```

---

## 三、实现代码

```java
public class HttpsConnector extends Connector {
    private String keyStoreFile;
    private String keyStorePassword;
    private String keyAlias;
    
    @Override
    public void start() throws Exception {
        // 创建SSLContext
        SSLContext sslContext = createSSLContext();
        
        // 创建SSLServerSocketFactory
        SSLServerSocketFactory factory = sslContext.getServerSocketFactory();
        
        // 创建SSLServerSocket
        SSLServerSocket serverSocket = (SSLServerSocket) factory.createServerSocket(port);
        
        // 启动接收线程
        while (running) {
            SSLSocket socket = (SSLSocket) serverSocket.accept();
            threadPool.execute(new SocketProcessor(socket));
        }
    }
    
    private SSLContext createSSLContext() throws Exception {
        // 加载密钥库
        KeyStore keyStore = KeyStore.getInstance("JKS");
        FileInputStream fis = new FileInputStream(keyStoreFile);
        keyStore.load(fis, keyStorePassword.toCharArray());
        fis.close();
        
        // 创建密钥管理器
        KeyManagerFactory kmf = KeyManagerFactory.getInstance("SunX509");
        kmf.init(keyStore, keyStorePassword.toCharArray());
        
        // 创建SSLContext
        SSLContext sslContext = SSLContext.getInstance("TLS");
        sslContext.init(kmf.getKeyManagers(), null, new SecureRandom());
        
        return sslContext;
    }
}
```

---

*下一步：WebSocket支持*
