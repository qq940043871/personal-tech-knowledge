# 网络协议与HTTP

> 模块：浏览器与Web技术
> 更新时间：2026-03-28

---

## 一、理论基础

### 1. TCP/IP协议栈

```
OSI七层模型 vs TCP/IP四层模型：

OSI七层            TCP/IP四层        协议/技术
─────────────────────────────────────────────────────
应用层        ───►  应用层           HTTP/2, HTTPS, WebSocket
表示层             (合并到应用层)     TLS/SSL, JSON, XML
会话层                                  NetBIOS, RPC
传输层        ───►  传输层           TCP, UDP, QUIC
网络层        ───►  网络层           IP, ICMP, ARP, BGP
数据链路层    ───►  网络接口层        Ethernet, PPP, WiFi
物理层                               光纤, 双绞线, 无线信号
```

### 2. TCP三次握手与四次挥手

```
三次握手（建立连接）：

Client                              Server
  │                                   │
  │ ─── SYN=1, seq=x ──────────────► │  客户端发送SYN
  │   (客户端进入SYN_SENT)            │
  │                                   │
  │ ◄── SYN=1, ACK=1, seq=y, ack=x+1 │  服务端发送SYN+ACK
  │   (服务端进入SYN_RCVD)             │
  │                                   │
  │ ─── ACK=1, seq=x+1, ack=y+1 ───► │  客户端发送ACK
  │   (双方进入ESTABLISHED)            │
  │                                   │

为什么三次：
  - 第一次：服务端确认"客户端能发送"
  - 第二次：客户端确认"服务端能接收+发送"
  - 第三次：服务端确认"客户端能接收"
  → 至少需要三次确认

四次挥手（断开连接）：

Client                              Server
  │                                   │
  │ ─── FIN=1, seq=u ──────────────► │  客户端请求关闭
  │   (客户端进入FIN_WAIT_1)           │
  │                                   │
  │ ◄── ACK=1, ack=u+1 ──────────────│  服务端发送ACK
  │   (客户端进入FIN_WAIT_2)           │  (服务端可能还有数据发送)
  │                                   │
  │ ◄── FIN=1, seq=w ────────────────│  服务端发送FIN
  │   (服务端进入LAST_ACK)             │
  │                                   │
  │ ─── ACK=1, ack=w+1 ──────────────►│  客户端发送ACK
  │   (客户端进入TIME_WAIT，等待2MSL)   │
  │   (服务端进入CLOSED)               │
```

### 3. HTTP协议演进

```
HTTP/0.9（1991）
  - 纯文本，GET请求
  - 无请求头/响应头
  - 无状态

HTTP/1.0（1996）
  - 引入请求头/响应头
  - 支持多种请求方法（GET, POST, HEAD）
  - 每次请求建立TCP连接

HTTP/1.1（1999）
  - 持久连接（Connection: keep-alive）
  - 管道化（Pipeline）
  - 断点续传（Range）
  - 缓存控制（Cache-Control, ETag）
  - Host头（虚拟主机支持）

HTTP/2（2015）
  - 二进制分帧（Binary Framing）
  - 多路复用（Multiplexing）
  - 服务器推送（Server Push）
  - 头部压缩（HPACK）
  - 流优先级（Stream Priority）

HTTP/3（2022，QUIC）
  - 基于UDP，无队头阻塞
  - 0-RTT连接建立
  - 连接迁移（网络切换不掉线）
  - 内置TLS 1.3
```

### 4. HTTPS工作原理

```
TLS 1.2握手过程：

Client                              Server
  │                                   │
  │ ─── ClientHello ────────────────► │
  │   支持的加密套件、TLS版本          │
  │                                   │
  │ ◄── ServerHello ───────────────────│
  │   选定加密套件、证书                │
  │                                   │
  │ ◄── Certificate ───────────────────│
  │   服务器证书（含公钥）             │
  │                                   │
  │ ◄── ServerHelloDone ──────────────│
  │                                   │
  │ ─── ClientKeyExchange ───────────► │
  │   发送PreMasterSecret（用公钥加密）│
  │                                   │
  │ ─── ChangeCipherSpec ───────────► │
  │ ─── Finished ───────────────────► │
  │                                   │
  │ ◄── ChangeCipherSpec ─────────────│
  │ ◄── Finished ─────────────────────│
  │                                   │
  │         加密通信开始               │

证书验证链：
  根证书 → 中间证书 → 服务器证书

对称密钥协商：
  - RSA：客户端生成随机数，服务器用公钥加密
  - ECDHE：椭圆曲线 Diffie-Hellman（前向安全）
```

### 5. DNS解析过程

```
DNS查询流程：

1. 浏览器缓存 ──► 命中？直接返回
                       ↓ 否
2. 系统缓存 ──► 命中？直接返回（查hosts文件）
                       ↓ 否
3. 本地DNS服务器 ──► 缓存命中？直接返回
                       ↓ 否
4. 递归查询开始：
   根DNS(.): 无权限 ──► 返回com DNS
   com DNS: 无权限 ──► 返回example.com DNS
   example.com DNS: 权威答案 ──► 返回IP
5. 返回结果，缓存

DNS记录类型：
  A：域名 → IPv4
  AAAA：域名 → IPv6
  CNAME：域名 → 另一个域名
  MX：域名 → 邮件服务器
  TXT：域名 → 文本信息
  NS：域名 → DNS服务器
```

---

## 二、实践应用

### 1. HTTP请求分析

```bash
# curl发送请求
curl -v http://example.com          # 详细输出
curl -X POST http://example.com/api \
  -H "Content-Type: application/json" \
  -d '{"name": "test"}'            # POST JSON
curl -H "Authorization: Bearer xxx" \
  http://example.com/api            # 带Token

# 查看响应头
curl -I http://example.com          # HEAD请求
curl -D - http://example.com       # 显示响应头

# 下载文件
curl -O http://example.com/file.zip
curl -o output.zip http://example.com/file.zip
```

### 2. 网络调试

```javascript
// Fetch API使用
fetch('/api/data', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer xxx'
  },
  body: JSON.stringify({ name: 'test' }),
  credentials: 'include'  // 发送cookie
})
.then(res => {
  console.log(res.headers.get('X-Request-Id'));
  return res.json();
})
.catch(err => console.error(err));

// AbortController取消请求
const controller = new AbortController();
fetch('/api/data', { signal: controller.signal })
  .then(res => res.json())
  .catch(err => {
    if (err.name === 'AbortError') {
      console.log('Request cancelled');
    }
  });
// 取消
controller.abort();
```

### 3. 缓存控制

```javascript
// 缓存策略
// 1. 强缓存
//   - Cache-Control: max-age=3600（相对时间）
//   - Expires: Wed, 21 Oct 2026 07:28:00 GMT（绝对时间）

// 2. 协商缓存
//   - Last-Modified / If-Modified-Since
//   - ETag / If-None-Match

// Service Worker缓存
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(cached => {
        if (cached) return cached;
        return fetch(event.request)
          .then(response => {
            if (response.status === 200) {
              const clone = response.clone();
              caches.open('v1').then(cache => {
                cache.put(event.request, clone);
              });
            }
            return response;
          });
      })
  );
});
```

### 4. HTTP/2优化

```nginx
# Nginx HTTP/2配置
server {
    listen 443 ssl http2;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # HTTP/2优化
    http2_max_concurrent_streams 128;  # 单连接最大流数
    http2_recv_buffer_size 256k;       # 接收缓冲区
    
    # 资源合并（减少请求）
    location /static/ {
        # 将多个CSS合并
        # location ~* \.css$ { concat on; concat_max_filesize 10; }
    }
}
```

---

## 三、生产环境问题案例

### 案例1：HTTPS证书过期

**问题现象：**
用户无法访问网站，浏览器显示"证书无效"。

**分析过程：**
```bash
# 1. 浏览器开发者工具 → Security面板
# 查看证书详情，过期时间

# 2. 命令行检查
echo | openssl s_client -connect example.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# 3. 检查证书链
echo | openssl s_client -connect example.com:443 -showcerts 2>/dev/null | \
  openssl x509 -noout -subject -issuer

# 4. 检查OCSP
echo | openssl s_client -connect example.com:443 -status 2>/dev/null | \
  grep -A 17 "OCSP Response"
```

**解决方案：**
1. 续期证书（Let's Encrypt使用certbot renew）
2. 自动续期脚本
   ```bash
   # certbot-auto renew
   # 添加到crontab
   0 0 * * * /usr/bin/certbot renew --quiet
   ```
3. 使用ACME客户端自动管理

**经验教训：**
- 证书有效期监控
- 自动续期机制
- 保留备份证书

---

### 案例2：HTTP/2导致性能下降

**问题现象：**
开启HTTP/2后，部分用户反而变慢。

**分析过程：**
```bash
# 1. 检查HTTP/2支持
curl -I --http2 https://example.com

# 2. 分析请求
# DevTools → Network → 查看"Protocol"列
# h2 = HTTP/2, h3 = HTTP/3

# 3. 常见原因：
#   - 带宽不足，HTTP/2多路复用反而浪费
#   - 服务器配置不当
#   - 代理不支持HTTP/2
#   - 证书链过长

# 4. 检查服务器配置
nginx -t
# 查看worker_connections是否足够
```

**根因分析：**
HTTP/2多路复用虽然减少了连接数，但在一个连接上发送多个请求时，队头阻塞问题仍然存在（HTTP/2的队头阻塞）。

**解决方案：**
1. 评估网络环境：高速网络适合HTTP/2
2. 优化服务器配置
3. 使用HTTP/3（QUIC）避免队头阻塞
4. 根据情况启用/禁用HTTP/2

**经验教训：**
- HTTP/2不是银弹
- 需要测试对比效果
- 网络环境决定最优选择

---

### 案例3：DNS污染导致解析错误

**问题现象：**
部分用户解析到错误IP，无法访问服务。

**分析过程：**
```bash
# 1. 检查DNS解析
dig example.com
nslookup example.com

# 2. 查看不同DNS服务器结果
dig @8.8.8.8 example.com     # Google DNS
dig @1.1.1.1 example.com   # Cloudflare DNS

# 3. 检查hosts文件
cat /etc/hosts
# Windows: C:\Windows\System32\drivers\etc\hosts

# 4. 检查DNS传播
# 使用多地DNS查询工具
# nslookup.io, whatsmydns.net
```

**根因分析：**
DNS缓存被污染，或本地DNS服务器被劫持。

**解决方案：**
1. 使用可信DNS（Google 8.8.8.8, Cloudflare 1.1.1.1）
2. 配置DoH（DNS over HTTPS）
3. 增加DNS缓存层
4. 监控DNS解析结果

```javascript
// 浏览器端DoH配置示例（Chrome/Edge）
// 设置 → 隐私 → 安全 → 使用安全DNS

// 或通过系统配置
// Windows: 网络设置 → DNS服务器 → 手动设置DoH
```

**经验教训：**
- DNS是基础设施，可用性很重要
- 多DNS服务器冗余
- 监控DNS解析

---

## 四、延伸阅读

### 书籍
- 《TCP/IP详解》三卷
- 《HTTP权威指南》
- 《HTTPS权威指南》

### 工具
- Wireshark：网络抓包
- Postman：API调试
- Charles/Fiddler：代理调试
- curl/wget：命令行工具

---

*下一步：前端性能优化*
