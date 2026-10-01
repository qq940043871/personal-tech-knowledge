# 17年技术经验总结

> 一份从计算机基础到架构设计的完整技术知识库，涵盖17年一线开发经验的核心沉淀。

---

## 目录结构

```
17年技术经验总结/
├── 00-总纲.md                        # 总览与导读
├── 01-计算机组成原理/                  # 硬件基础
│   ├── 01-CPU架构与指令集.md
│   ├── 02-内存管理与缓存机制.md
│   ├── 03-存储层次与IO原理.md
│   └── 04-生产环境实际问题.md
├── 02-操作系统/                        # 系统底层
│   ├── 01-进程与线程管理.md
│   ├── 02-内存管理与虚拟内存.md
│   ├── 03-文件系统与IO模型.md
│   ├── 04-Linux内核调优.md
│   └── 05-生产环境实际问题.md
├── 03-浏览器与Web技术/                 # 前端与网络
│   ├── 01-浏览器渲染原理.md
│   ├── 02-网络协议与HTTP.md
│   ├── 03-前端性能优化.md
│   └── 04-生产环境实际问题.md
├── 04-虚拟化与容器/                    # 云原生基础
│   ├── 01-虚拟机技术原理.md
│   ├── 02-Docker容器化.md
│   ├── 03-Kubernetes编排.md
│   └── 04-生产环境实际问题.md
├── 05-MySQL数据库/                     # 关系型存储
│   ├── 01-架构与存储引擎.md
│   ├── 02-索引原理与优化.md
│   ├── 03-事务与锁机制.md
│   ├── 04-主从复制与高可用.md
│   ├── 05-性能调优实战.md
│   └── 06-生产环境实际问题.md
├── 06-Redis中间件/                     # 缓存与性能
│   ├── 01-数据结构与底层原理.md
│   ├── 02-持久化与高可用.md
│   ├── 03-缓存策略与问题.md
│   └── 04-集群与分布式.md
├── 07-消息中间件/                      # 异步架构
│   ├── 01-消息队列核心概念.md
│   ├── 02-RabbitMQ实战.md
│   ├── 03-Kafka实战.md
│   ├── 04-消息可靠性与顺序性.md
│   └── 05-生产环境实际问题.md
├── 08-架构设计与工程实践/               # 高层设计
│   ├── 01-分布式系统设计.md
│   ├── 02-高并发系统设计.md
│   ├── 03-故障排查方法论.md
│   └── 04-技术选型决策记录.md
└── 09-技术知识库/                      # 知识库站点(门户 index.html,含硬件/OS/数据结构/Java/架构/AI 等章节)
```

---

## 模块概述

| 模块 | 核心内容 | 文件数 |
|------|---------|--------|
| **00-总纲** | 知识体系全景图与学习指南 | 1 |
| **01-计算机组成原理** | CPU、内存、存储、总线等硬件工作原理 | 4 |
| **02-操作系统** | 进程管理、内存管理、文件系统、I/O模型 | 5 |
| **03-浏览器与Web技术** | HTTP协议、浏览器渲染、前端工程化 | 4 |
| **04-虚拟化与容器** | Docker、Kubernetes、虚拟化技术原理 | 4 |
| **05-MySQL数据库** | 存储引擎、索引优化、事务与锁、高可用架构 | 6 |
| **06-Redis中间件** | 数据结构、持久化、集群、缓存策略 | 4 |
| **07-消息中间件** | Kafka、RabbitMQ、消息可靠性与架构模式 | 5 |
| **08-架构设计与工程实践** | 微服务、分布式系统、设计模式、工程方法论 | 4 |

---

## 学习路径建议

### 基础阶段
```
01-计算机组成原理 → 02-操作系统
```

### 应用阶段
```
03-浏览器与Web技术 → 05-MySQL数据库 → 06-Redis中间件
```

### 进阶阶段
```
04-虚拟化与容器 → 07-消息中间件 → 08-架构设计与工程实践
```

---

## 文档规范

每个文件遵循统一结构：
1. **理论基础** — 概念、原理、底层机制
2. **实践应用** — 配置、调优、最佳实践
3. **生产环境问题案例** — 问题描述 → 分析过程 → 解决方案 → 经验总结
4. **延伸阅读** — 推荐书籍、文章、工具

---

*建议从 `00-总纲.md` 开始阅读，了解整体脉络后再按需深入各模块。*

---

## 🔗 图文详解交叉索引(09-技术知识库)

> 经验笔记重「理论 + 生产实战」,知识库图文重「从零理解底层原理」,两相配合阅读。

| 经验笔记 | 配套图文详解(09-技术知识库/pages/) |
|---|---|
| 01-计算机组成原理 | [计算机如何运行:时钟→晶振→PLL→CPU](../09-技术知识库/pages/01_hardware/computer-fundamentals.md) · [硬件运行机制](../09-技术知识库/pages/01_hardware/hardware-operation.md) · [4位计算机](../09-技术知识库/pages/01_hardware/4bit-computer.md) |
| 02-操作系统 | [程序是怎么跑起来的](../09-技术知识库/pages/02_linux/program-run.md) · [Linux 工作机制](../09-技术知识库/pages/02_linux/linux-work.md) · [网络连接全流程](../09-技术知识库/pages/02_linux/network-connect.md) |
| 03-浏览器与Web技术 | [网页渲染原理](../09-技术知识库/pages/00_overview/web-rendering-principle.md) · [从请求到后端](../09-技术知识库/pages/00_overview/request-to-backend.md) · [浏览器渲染性能](../09-技术知识库/pages/00_overview/browser-rendering-performance.html) |
| 04-虚拟化与容器 | [Docker 原理/实战](../09-技术知识库/pages/05_system_architect/distributed/docker.md) · [K8s 原理/实战](../09-技术知识库/pages/05_system_architect/distributed/kubernetes.md) |
| 05-MySQL数据库 | [MySQL 核心原理](../09-技术知识库/pages/05_system_architect/database/mysql.md) · [SQL 执行全流程](../09-技术知识库/pages/05_system_architect/database/sql-execution.html) · [分库分表](../09-技术知识库/pages/05_system_architect/database/database-sharding.md) |
| 06-Redis中间件 | [Redis 核心原理](../09-技术知识库/pages/05_system_architect/database/redis.md) |
| 07-消息中间件 | (知识库暂无对应图文) |
| 08-架构设计与工程实践 | [分布式总览](../09-技术知识库/pages/05_system_architect/distributed/distributed-overview.md) · [高并发总览](../09-技术知识库/pages/05_system_architect/high-concurrency/high-concurrency-overview.md) · [缓存策略](../09-技术知识库/pages/05_system_architect/high-concurrency/caching-strategy.md) · [负载均衡](../09-技术知识库/pages/05_system_architect/high-concurrency/load-balancing.md) |
