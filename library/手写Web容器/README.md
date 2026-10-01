# 手写Web容器

> 从零实现类Tomcat的Web容器，涵盖网络基础、HTTP解析、连接器、容器、Servlet规范、类加载等核心模块。

---

## 目录结构

```
手写Web容器/
├── 00-总纲与架构设计.md                  # 整体架构与模块划分
├── 01-网络基础/
│   ├── 01-Socket编程.md                 # BIO/NIO/AIO对比
│   ├── 02-IO多路复用.md                 # select/poll/epoll
│   ├── 03-Reactor模式.md                # 单Reactor/多Reactor
│   └── 04-Netty基础.md                  # EventLoop/Channel/Pipeline
├── 02-HTTP解析引擎/
│   ├── 01-HTTP协议解析.md               # 请求行/请求头/请求体
│   ├── 02-请求解析器实现.md             # 状态机解析
│   ├── 03-响应构建器.md                 # 状态行/响应头/响应体
│   └── 04-Chunked传输.md               # 分块传输编码
├── 03-连接器（Connector）/
│   ├── 01-连接器架构.md                 # Endpoint/Processor/Adapter
│   ├── 02-NioEndpoint实现.md            # 非阻塞IO实现
│   ├── 03-协议处理器.md                 # HTTP/1.1/HTTP/2处理
│   └── 04-连接池管理.md                 # 长连接、超时、回收
├── 04-容器（Container）/
│   ├── 01-容器层级设计.md               # Engine/Host/Context/Wrapper
│   ├── 02-Pipeline与Valve.md            # 责任链模式实现
│   ├── 03-Host虚拟主机.md               # 多域名支持
│   ├── 04-Context应用上下文.md          # Web应用生命周期
│   └── 05-Wrapper包装器.md              # Servlet实例管理
├── 05-Servlet规范实现/
│   ├── 01-Servlet接口.md                # Servlet生命周期
│   ├── 02-HttpServletRequest实现.md     # 请求封装
│   ├── 03-HttpServletResponse实现.md    # 响应封装
│   ├── 04-Filter过滤器.md               # FilterChain实现
│   └── 05-Listener监听器.md             # 事件监听机制
├── 06-请求处理管道/
│   ├── 01-请求分发.md                   # URL映射与分发
│   ├── 02-静态资源处理.md               # 文件服务
│   └── 03-错误处理.md                   # 404/500页面
├── 07-类加载器/
│   ├── 01-WebAppClassLoader.md          # 应用隔离加载
│   ├── 02-类加载隔离.md                 # 依赖冲突解决
│   └── 03-热部署实现.md                 # 动态重载
├── 08-配置与启动/
│   ├── 01-server.xml配置.md             # 服务端配置
│   ├── 02-web.xml配置.md                # 应用配置
│   ├── 03-启动流程.md                   # Bootstrap→Catalina
│   └── 04-关闭流程.md                   # ShutdownHook
├── 09-性能优化/
│   ├── 01-线程池调优.md                 # maxThreads/minSpareThreads
│   ├── 02-连接优化.md                   # keepAlive、超时
│   ├── 03-压缩与缓存.md                 # gzip、ETag
│   └── 04-JVM调优.md                    # GC、堆栈配置
└── 10-扩展功能/
    ├── 01-Session管理.md                 # Cookie/Session实现
    ├── 02-WebSocket支持.md               # 协议升级
    ├── 03-JSP引擎.md                     # JSP编译与执行
    └── 04-安全管理.md                     # SSL/TLS、认证
```

---

## 各模块概述

| 模块 | 核心内容 | 文件数 |
|------|---------|--------|
| **00-总纲** | 整体架构设计 | 1 |
| **01-网络基础** | Socket编程、IO多路复用、Reactor模式 | 4 |
| **02-HTTP解析引擎** | HTTP协议解析、请求/响应构建 | 4 |
| **03-连接器** | Connector架构、NIO实现、连接池 | 4 |
| **04-容器** | 容器层级、Pipeline/Valve、生命周期 | 5 |
| **05-Servlet规范** | Servlet/Request/Response/Filter/Listener | 5 |
| **06-请求处理管道** | 请求分发、静态资源、错误处理 | 3 |
| **07-类加载器** | WebAppClassLoader、隔离、热部署 | 3 |
| **08-配置与启动** | 配置文件、启动/关闭流程 | 4 |
| **09-性能优化** | 线程池、连接、压缩、JVM调优 | 4 |
| **10-扩展功能** | Session、WebSocket、JSP、安全 | 4 |

---

## 学习路径建议

### 第一阶段：网络基础
```
01-网络基础 → 02-HTTP解析引擎
```

### 第二阶段：核心容器
```
03-连接器 → 04-容器 → 05-Servlet规范实现
```

### 第三阶段：工程完善
```
06-请求处理管道 → 07-类加载器 → 08-配置与启动
```

### 第四阶段：高级特性
```
09-性能优化 → 10-扩展功能
```

---

*建议从 `00-总纲与架构设计.md` 开始阅读。*
