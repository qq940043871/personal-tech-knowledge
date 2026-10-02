# 09-技术知识库

架构师知识库站点（原 `hello_my_profile`）。

- 入口：`index.html`
- Markdown：`md-viewer.html?file=pages/...`
- 主题归属：**架构学习笔记 + 工作经历叙事**

## 结构

```text
09-技术知识库/
├── index.html          # 侧栏导航 + iframe
├── md-viewer.html
├── pages/
│   ├── 00_overview/    # 规范、模板、学习路径
│   ├── 01_hardware/ … 05_system_architect/
│   ├── 06_ai/          # 导读 + 桩页（链接 blog）
│   └── work-experience/  # 已迁出 → personal-investment-notes/resume/pages/work-experience/
└── assets/ css/
```

## 边界

- AI 技术笔记与博文 → `blog/`（博客「码潮 CodeTide」）  
- 面试真题与八股 → `interview-kit/banks/`（含 face-exp）  
- 本库 `06_ai` 只保留导读与链接桩页

---

## 🔗 配套实战经验笔记(../17年技术经验总结/)

> 本库图文重「从零理解原理」;同主题的「理论 + 生产实战案例」见上一级 `17年技术经验总结/`(总导读:[00-总纲.md](../00-总纲.md))。

| 本库章节 | 对应经验笔记 |
|---|---|
| `pages/01_hardware/` 计算机底层 | [01-计算机组成原理](../01-计算机组成原理/04-生产环境实际问题.md)(CPU/内存/IO + 生产案例) |
| `pages/02_linux/` 程序与系统 | [02-操作系统](../02-操作系统/05-生产环境实际问题.md)(进程线程/内存/文件系统/内核调优) |
| `pages/00_overview/` 渲染与网络 | [03-浏览器与Web技术](../03-浏览器与Web技术/04-生产环境实际问题.md) |
| `pages/05_system_architect/distributed/` Docker/K8s | [04-虚拟化与容器](../04-虚拟化与容器/04-生产环境实际问题.md) |
| `pages/05_system_architect/database/` MySQL/Redis/ES/Mongo | [05-MySQL](../05-MySQL数据库/06-生产环境实际问题.md) · [06-Redis](../06-Redis中间件/04-集群与分布式.md) |
| `pages/05_system_architect/mq/` 消息中间件 | [07-消息中间件](../07-消息中间件/05-生产环境实际问题.md)(核心概念/RabbitMQ/Kafka/可靠性) |
| `pages/05_system_architect/high-concurrency/` 高并发 | [08-架构设计与工程实践](../08-架构设计与工程实践/04-技术选型决策记录.md) |
