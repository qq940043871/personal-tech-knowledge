# 一个请求是如何抵达后端服务器的

## 概述

当用户在浏览器中点击一个按钮、提交一个表单、或者直接输入 URL 访问一个网站时，一个 HTTP 请求就诞生了。这个请求需要穿越重重关卡——DNS、网络设备、防火墙、负载均衡器、API 网关、服务发现——最终才能抵达后端应用服务器，被业务代码处理。本文将完整拆解这条链路中的每一个环节。

## 请求链路全景图

```
 用户浏览器                    互联网                   企业基础设施                  后端服务
+-----------+           +--------------+           +------------------+          +------------+
|           |           |              |           |                  |          |            |
| 1.输入URL  | --DNS--> | 2.DNS 解析   |           |                  |          |            |
|           |           |              |           |                  |          |            |
| 3.TCP握手 | --SYN---> | 4.网络路由   |           |                  |          |            |
|           |           |              |           |                  |          |            |
| 5.TLS握手 |           |              |           |                  |          |            |
|           |           |              |           |                  |          |            |
| 6.发送    | ========> | ==========>  | 7.防火墙  | -> 8.CDN         |          |            |
| HTTP请求  |           | 运营商骨干网  |           |    (静态资源)    |          |            |
|           |           |              |           |                  |          |            |
|           |           |              |           | 9.负载均衡       |          |            |
|           |           |              |           |   (Nginx/LVS)    |          |            |
|           |           |              |           |                  |          |            |
|           |           |              |           | 10.API网关       |          |            |
|           |           |              |           |   (鉴权/限流)    |          |            |
|           |           |              |           |                  |          |            |
|           |           |              |           | 11.服务发现      |          |            |
|           |           |              |           |    (Nacos/Eureka) |          |            |
|           |           |              |           |                  |          |            |
|           |           |              |           | ===============> | 12.后端  |         |
|           |           |              |           |                  | 应用服务器 |        |
|           |           |              |           |                  |          |            |
|           |           |              |           |                  | 13.中间件  |        |
|           |           |              |           |                  | (认证/日志) |       |
|           |           |              |           |                  |          |            |
|           |           |              |           |                  | 14.业务逻辑 |       |
|           |           |              |           |                  | Controller |        |
|           |           |              |           |                  |  Service   |        |
|           |           |              |           |                  |    DAO     |        |
|           |           |              |           |                  |          |            |
| <=======  | <======== | <=========  | <===============            | <======== |            |
| 15.响应返回|           |              |           |                  |          |            |
+-----------+           +--------------+           +------------------+          +------------+
```

---

## 第一阶段：浏览器端 —— 请求的诞生

### 1. URL 输入与解析

用户在地址栏输入 `https://www.example.com/api/order/create`，浏览器首先解析这个 URL：

| 组成部分 | 内容 | 说明 |
|---------|------|------|
| 协议 | `https` | 使用 HTTPS 协议（HTTP + TLS） |
| 域名 | `www.example.com` | 需要解析为 IP 地址 |
| 端口 | `443` | HTTPS 默认端口（HTTP 默认 80） |
| 路径 | `/api/order/create` | 后端接口路径 |

浏览器还会检查 HSTS（HTTP Strict Transport Security）列表，如果该域名在列表中，则强制使用 HTTPS。

### 2. DNS 域名解析

浏览器拿到域名后，需要将其解析为 IP 地址。整个 DNS 解析过程是一个**逐级缓存查询**的过程：

```
浏览器 DNS 缓存
       |
       v (未命中)
操作系统 DNS 缓存 (hosts 文件)
       |
       v (未命中)
本地 DNS 服务器 (运营商/公司)
       |
       v (未命中)
根域名服务器 → .com 顶级域名服务器 → example.com 权威 DNS 服务器
       |
       v
返回 IP: 93.184.216.34
```

**关键点：**
- 每个环节都有缓存，TTL（Time To Live）控制缓存有效期
- DNS 解析通常使用 UDP 协议（端口 53），超过 512 字节时切换为 TCP
- 现代应用常用 HTTPDNS 绕过运营商 DNS 劫持，直接向 HTTP DNS 服务器查询

### 3. TCP 三次握手

拿到 IP 地址后，浏览器通过 TCP 协议与服务器建立连接：

```
  客户端 (Client)                    服务器 (Server)
       |                                    |
       |  ------ SYN (seq=x) ------------>  |  第1次：客户端请求建立连接
       |                                    |
       |  <--- SYN+ACK (seq=y, ack=x+1) --  |  第2次：服务器同意并请求连接
       |                                    |
       |  ------ ACK (ack=y+1) ---------->  |  第3次：客户端确认，连接建立
       |                                    |
       |       TCP 连接已建立，可以传输数据    |
```

> **为什么是三次握手？** 保证双方都具备收发能力。两次握手会导致历史连接的混淆；四次握手则冗余。

### 4. TLS/SSL 握手（HTTPS）

如果是 HTTPS 请求，在 TCP 连接之上还需要进行 TLS 握手：

```
  客户端                              服务器
    |                                    |
    | -- ClientHello (支持的加密套件) --> |
    |                                    |
    | <-- ServerHello + 证书 ----------  |
    |                                    |
    | -- 验证证书 + 生成密钥 -----------> |
    |                                    |
    | <-- 加密通信就绪 ----------------- |
    |                                    |
    |  后续数据均以对称密钥加密传输       |
```

TLS 1.3 将握手优化为 1-RTT（一次往返），大幅减少延迟。

---

## 第二阶段：网络传输 —— 穿越互联网

### 5. HTTP 请求构造与发送

TCP 连接建立后，浏览器构造一个 HTTP 请求报文：

```http
POST /api/order/create HTTP/1.1
Host: www.example.com
Content-Type: application/json
Cookie: session_id=abc123
Authorization: Bearer eyJhbG...
User-Agent: Mozilla/5.0 ...
Content-Length: 156

{
  "productId": 10086,
  "quantity": 2,
  "addressId": 3388
}
```

请求报文被 TCP 分段，添加 TCP 头（源端口、目标端口、序列号），再添加 IP 头（源 IP、目标 IP），形成数据包，逐层向下封装，最终通过网卡以电信号/光信号发出。

### 6. 数据包经过的路由

数据包从用户电脑出发，沿途经过：

```
家庭路由器 → 小区交换机 → 运营商接入层 → 运营商汇聚层
    → 运营商骨干网 → 互联网交换中心 (IXP)
    → 目标运营商骨干网 → 数据中心边界路由器
```

每个节点通过路由表决定下一跳，BGP（边界网关协议）负责跨运营商的路由选择。一个典型的跨省请求可能经过 10-20 个路由节点。

---

## 第三阶段：企业基础设施 —— 层层把关

### 7. 防火墙 (Firewall)

请求到达数据中心后，首先经过防火墙：

- **网络层防火墙**：基于 IP + 端口过滤（如 iptables、安全组规则）
- **应��层防火墙 (WAF)**：检测 SQL 注入、XSS、CSRF 等攻击
- **DDoS 防护**：识别并清洗流量攻击

```
  Internet → [DDoS 清洗] → [WAF] → [网络防火墙] → 内网
```

### 8. CDN 边缘节点（可选）

对于静态资源（图片、CSS、JS），请求可能被 CDN 边缘节点直接响应，无需回源到后端：

```
  用户请求 static.example.com/logo.png
       |
       v
  CDN 边缘节点 (最近节点)
       |
       |-- 有缓存? → 直接返回
       |
       |-- 无缓存? → 回源到对象存储 (OSS/S3) → 缓存后返回
```

### 9. 负载均衡 (Load Balancer)

请求进入内网后，首先到达负载均衡器。它决定将请求转发到哪台服务器：

**四层负载均衡（L4，传输层）：**
- 基于 IP + 端口进行转发
- 代表：LVS、F5、云厂商 SLB
- 性能极高，但无法识别应用层内容

**七层负载均衡（L7，应用层）：**
- 基于 HTTP 头、URL、Cookie 等进行转发
- 代表：Nginx、HAProxy、Traefik
- 可实现更智能的路由策略

```
负载均衡算法：
  - 轮询 (Round Robin)        → 依次分配
  - 加权轮询 (Weighted)       → 按服务器性能权重分配
  - 最少连接 (Least Conn)     → 分配给连接数最少的服务器
  - IP Hash / 一致性哈希       → 同一用户固定到同一台服务器
```

**Nginx 反向代理配置示例：**

```nginx
upstream backend_servers {
    # 加权轮询
    server 192.168.1.101:8080 weight=3;
    server 192.168.1.102:8080 weight=2;
    server 192.168.1.103:8080 weight=1;
    
    # 健康检查
    keepalive 32;
}

server {
    listen 443 ssl;
    server_name api.example.com;
    
    location /api/ {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 10. API 网关

经过负载均衡后，请求到达 API 网关。API 网关是整个后端服务的**统一入口**：

```
请求进入 API 网关后的处理流程：

  Request
     |
     v
[1. 身份认证] -- JWT / OAuth2.0 / Session 校验
     |
     v
[2. 权限校验] -- RBAC / ABAC 权限模型
     |
     v
[3. 流量控制] -- 令牌桶 / 漏桶算法限流
     |
     v
[4. 请求校验] -- 参数校验、签名校验
     |
     v
[5. 协议转换] -- HTTP → gRPC / Dubbo（如有需要）
     |
     v
[6. 路由转发] -- 根据 Path 路由到对应的微服务
     |
     v
[7. 日志埋点] -- 记录请求日志、调用链 Trace
```

**主流 API 网关：**
| 网关 | 特点 | 适用场景 |
|------|------|---------|
| **Spring Cloud Gateway** | 基于 WebFlux、响应式编程 | Java 微服务体系 |
| **Kong** | 基于 Nginx + Lua、插件丰富 | 通用、混合技术栈 |
| **Nginx + Lua** | 高性能、灵活定制 | 极致性能要求 |
| **APISIX** | 云原生、动态路由 | 容器化/K8s 环境 |
| **Zuul** | Netflix 出品（已逐渐被 Gateway 替代） | 旧版 Spring Cloud |

### 11. 服务发现与注册

在微服务架构中，后端服务实例是动态变化的（扩缩容、故障转移）。API 网关需要知道目标服务的真实地址：

```
服务注册中心 (Nacos / Eureka / Consul / Zookeeper)
      |
      |-- 服务实例 A: 192.168.1.101:8080  [健康]
      |-- 服务实例 B: 192.168.1.102:8080  [健康]
      |-- 服务实例 C: 192.168.1.103:8080  [不健康 - 已剔除]
      |
      v
  API 网关查询注册中心 → 获取健康实例列表 → 负载均衡选择一台 → 转发请求
```

---

## 第四阶段：后端服务 —— 请求的终点

### 12. 请求到达应用服务器

经过以上所有环节，HTTP 请求终于到达后端应用服务器。以 Java Spring Boot 为例：

```
  HTTP Request
       |
       v
[Tomcat / Netty 线程池] -- 从线程池中分配一个 Worker 线程
       |
       v
[Servlet 容器 / WebFlux]
       |
       v
[Filter 过滤器链]
       |
       v
[Interceptor 拦截器链]
       |
       v
[DispatcherServlet] -- 根据 URL 路由到对应的 Controller
       |
       v
```

### 13. 中间件处理

在请求真正到达业务代码之前，一系列中间件依次执行：

```
  Request 进入
       |
       v
[认证拦截器] -- JWT Token 校验，提取用户信息到 ThreadLocal
       |
       v
[权限拦截器] -- 检查用户是否有该接口的访问权限
       |
       v
[参数校验]   -- @Valid 注解校验，请求参数格式验证
       |
       v
[日志拦截器] -- 记录请求 URL、参数、耗时
       |
       v
[分布式链路追踪] -- 生成/传递 TraceId 和 SpanId（如 SkyWalking、Jaeger）
       |
       v
[熔断降级]   -- Sentinel / Hystrix 检查资源是否过载
       |
       v
  Controller 方法
```

### 14. 业务逻辑处理

请求进入业务代码后，典型的 MVC 分层处理：

```java
// Controller 层 —— 接收请求、参数绑定、返回响应
@RestController
@RequestMapping("/api/order")
public class OrderController {
    
    @Autowired
    private OrderService orderService;
    
    @PostMapping("/create")
    public Result<OrderVO> createOrder(@RequestBody @Valid CreateOrderRequest request) {
        // 1. 从 ThreadLocal 获取当前用户
        UserInfo user = UserContext.getCurrentUser();
        
        // 2. 调用 Service 层
        OrderVO order = orderService.createOrder(user, request);
        
        // 3. 返回响应
        return Result.success(order);
    }
}

// Service 层 —— 业务逻辑编排
@Service
public class OrderService {
    
    @Transactional
    public OrderVO createOrder(UserInfo user, CreateOrderRequest request) {
        // 1. 查询商品信息（调用商品服务 或 查 Redis 缓存）
        Product product = productService.getById(request.getProductId());
        
        // 2. 校验库存
        inventoryService.checkAndDeduct(product.getId(), request.getQuantity());
        
        // 3. 创建订单（写数据库）
        Order order = orderDao.insert(buildOrder(user, product, request));
        
        // 4. 发送订单创建消息（异步通知）
        mqProducer.sendOrderCreatedEvent(order);
        
        return convertToVO(order);
    }
}

// DAO 层 —— 数据访问
@Repository
public class OrderDao {
    @Autowired
    private JdbcTemplate jdbcTemplate;
    
    public Order insert(Order order) {
        // SQL 操作
        return order;
    }
}
```

### 15. 数据库与缓存交互

业务处理过程中，后端服务与数据层的交互：

```
  Service 层
       |
       |-- 读操作 --|
       |            v
       |         [Redis缓存]
       |            |-- 命中 → 直接返回
       |            |-- 未命中 → 查 MySQL → 回写缓存 → 返回
       |
       |-- 写操作 --|
       |            v
       |         [MySQL 主库]
       |            |
       |            v
       |         [Binlog 同步]
       |            |
       |            v
       |         [MySQL 从库]（用于读写分离的读操作）
       |            |
       |            v
       |         [Canal 监听 Binlog]
       |            |
       |            v
       |         [刷新 Redis / 同步 ES]
       |
       |-- 异步操作 --|
                    v
                 [消息队列] (Kafka / RocketMQ)
                    |
                    v
                 下游消费者（发短信、发邮件、数据统计...）
```

---

## 响应返回：原路返回

后端处理完成后，响应数据沿着来时的路径原路返回：

```
  Service → Controller → Filter → Servlet 容器
       |
       v
  API 网关 (添加统一响应头、脱敏处理)
       |
       v
  负载均衡 → 防火墙 → CDN → 运营商骨干网 → ...
       |
       v
  用户浏览器 (接收 HTTP Response，解析 JSON，渲染 UI)
```

---

## 你会被问到的高频问题

### Q1: DNS 劫持是什么？如何防范？

DNS 劫持是指运营商或恶意攻击者篡改 DNS 解析结果，将用户导向错误的 IP。

**防范方式：**
- 使用 **HTTPDNS**：通过 HTTP 协议直接请求可信 DNS 服务器
- 启用 **DNSSEC**：对 DNS 响应进行数字签名校验
- 使用 **DoH (DNS over HTTPS)** / **DoT (DNS over TLS)**：加密 DNS 请求

### Q2: 七层负载均衡能做什么四层做不到的事？

| 能力 | L4 (四层) | L7 (七层) |
|------|-----------|-----------|
| 按 URL 路径转发 | ❌ | ✅ |
| 按 Cookie/Session 保持 | ❌ | ✅ |
| 内容压缩与缓存 | ❌ | ✅ |
| SSL 卸载 | ❌ | ✅ |
| 请求改写与重定向 | ❌ | ✅ |
| WebSocket 支持 | ❌ | ✅ |

### Q3: API 网关和服务网格（Service Mesh）有什么区别？

- **API 网关**：管理**南北向流量**（外部→内部），处理鉴权、限流、协议转换
- **Service Mesh**：管理**东西向流量**（服务间调用），处理服务发现、熔断、可观测性

两者互补，而非替代关系。

### Q4: 一个请求从发起到响应，通常有多少个中间环节？

以典型的微服务架构为例：**15-25 个环节**。

如果包含跨服务调用（如订单服务调用库存服务、支付服务），链路会更长。这也是为什么**分布式链路追踪（APM）**如此重要。

---

## 总结

一个看似简单的 HTTP 请求，从浏览器出发到达后端服务器，经历了：

1. **DNS 解析**——域名变 IP
2. **TCP + TLS 握手**——建立安全通道
3. **网络路由**——穿越互联网
4. **防火墙 + WAF**——安全第一道关
5. **CDN（可选）**——边缘加速
6. **负载均衡**——流量分发
7. **API 网关**——统一入口、鉴权限流
8. **服务发现**——定位目标实例
9. **中间件链**——认证、日志、熔断
10. **业务代码**——到 Controller → Service → DAO 终于开始干活

理解这条链路，是成为架构师的基本功。每个环节都可能成为性能瓶颈或故障点，排查问题时也需要沿着这条链路逐段定位。
