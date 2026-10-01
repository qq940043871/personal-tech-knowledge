# Kafka学习指南 - 总纲

> 更新时间：2026-03-29

---

## 📋 文档概述

Kafka是由Apache软件基金会开发的分布式事件流平台，广泛用于日志收集、消息系统、流处理等场景。

---

## 🗂️ 文档结构

```
Kafka学习指南/
├── 00-总览/
│   └── 00-Kafka总纲.md
├── 01-基础入门/
│   └── 01-Kafka安装与快速入门.md
├── 02-核心概念/
│   ├── 01-Topic与Partition.md
│   └── 02-消息偏移量与消费组.md
├── 03-生产者消费者/
│   ├── 01-生产者配置与优化.md
│   └── 02-消费者配置与Rebalance.md
├── 04-存储机制/
│   └── 01-Kafka存储架构与日志.md
└── 05-运维与集群/
    └── 01-Kafka集群配置与运维.md
```

---

## 🎯 核心知识点

| 模块 | 内容 |
|------|------|
| 基础 | 安装、Broker、Topic、分区 |
| 生产者 | acks、retries、压缩 |
| 消费者 | 消费组、Rebalance、偏移量 |
| 存储 | 日志分段、索引、清理策略 |
| 集群 | Controller、副本机制 |

---

## ⚡ 快速命令

```bash
# 创建Topic
kafka-topics.sh --create --topic my-topic --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# 查看Topic列表
kafka-topics.sh --list --bootstrap-server localhost:9092

# 发送消息
kafka-console-producer.sh --topic my-topic --bootstrap-server localhost:9092

# 消费消息
kafka-console-consumer.sh --topic my-topic --from-beginning --bootstrap-server localhost:9092
```

---

## 📊 Kafka架构图

```
Producer → Broker1(P0,R1) → Broker2(P1,R0) → Broker3(P2,R1)
   ↓         ↓                    ↓                    ↓
        ZooKeeper ←───────────────┘
        
P=Partition, R=Replica
```
