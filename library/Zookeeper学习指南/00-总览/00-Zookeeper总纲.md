# Zookeeper学习指南 - 总纲

> 更新时间：2026-03-29

---

## 📋 文档概述

ZooKeeper是一个分布式协调服务，用于管理大型分布式系统中的配置信息、命名服务、分布式锁和Leader选举等。

---

## 🗂️ 文档结构

```
Zookeeper学习指南/
├── 00-总览/
│   └── 00-Zookeeper总纲.md
├── 01-基础概念/
│   └── 01-Zookeeper安装与数据结构.md
├── 02-分布式协调/
│   ├── 01-ZAB协议与Leader选举.md
│   └── 02-Watch机制与节点类型.md
└── 03-应用场景/
    ├── 01-分布式锁实现.md
    └── 02-Kafka/Hadoop集成.md
```

---

## 🎯 核心知识点

| 模块 | 内容 |
|------|------|
| 数据结构 | ZNode、临时节点、序列节点 |
| Watcher | 事件监听、一次性触发 |
| 分布式锁 | 临时顺序节点、Watch抢锁 |
| Leader选举 | ZAB协议、过半机制 |
| 应用 | Kafka依赖、Dubbo注册中心 |

---

## ⚡ 快速命令

```bash
# 连接ZooKeeper
zkCli.sh -server localhost:2181

# 查看节点
ls /

# 创建节点
create /my-node "hello"

# 获取数据
get /my-node

# 监听变化
get -w /my-node

# 删除节点
delete /my-node
```

---

## 📊 Zookeeper架构

```
        Client1 ──┐
        Client2 ──┼──▶  ZooKeeper Cluster  ◀── Client3
        Client3 ──┘        (Leader/Follower)
                           
Leader节点负责写操作
Follower节点负责读操作
Observer节点用于扩展读性能
```
