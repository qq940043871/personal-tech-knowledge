# 2.1 队列 (Queue)

## 概述

队列（Queue）是消息中间件中用于存储消息的核心容器。在点对点（Point-to-Point）模式下，多个生产者向同一队列发送消息，一个消息只能被一个消费者获取。

## 数据库设计

### 表结构：queue_info（队列元数据表）

```sql
CREATE TABLE queue_info (
    queue_id         VARCHAR(64)         NOT NULL COMMENT '队列唯一标识(UUID)',
    queue_name       VARCHAR(255)       NOT NULL COMMENT '队列名称',
    vhost            VARCHAR(128)       NOT NULL DEFAULT '/'  COMMENT '虚拟主机',
    exchange_name    VARCHAR(255)       NOT NULL COMMENT '绑定的交换机名称',
    binding_key      VARCHAR(255)       NOT NULL COMMENT '绑定键',
    queue_type       ENUM('classic', 'quorum', 'stream') NOT NULL DEFAULT 'classic' COMMENT '队列类型',
    durable          BOOLEAN            NOT NULL DEFAULT TRUE COMMENT '是否持久化',
    auto_delete      BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '所有消费者断开后是否自动删除',
    exclusive        BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否独占队列',
    arguments        JSON               DEFAULT NULL COMMENT '队列扩展参数(JSON)',
    
    -- 容量控制
    max_length       BIGINT             DEFAULT NULL COMMENT '队列最大消息数，NULL表示无限制',
    max_bytes        BIGINT             DEFAULT NULL COMMENT '队列最大字节数，NULL表示无限制',
    overflow_policy  ENUM('reject-publish', 'drop-head', 'flow-control') DEFAULT NULL COMMENT '溢出策略',
    
    -- 消息处理
    dead_letter_exchange   VARCHAR(255)  DEFAULT NULL COMMENT '死信交换机名称',
    dead_letter_routing_key VARCHAR(255)  DEFAULT NULL COMMENT '死信路由键',
    message_ttl            BIGINT        DEFAULT NULL COMMENT '队列默认消息TTL(毫秒)',
    
    -- 状态与审计
    status            ENUM('running', 'suspending', 'deleted') DEFAULT 'running' COMMENT '队列状态',
    message_count     BIGINT             NOT NULL DEFAULT 0 COMMENT '当前消息数量',
    consumer_count    INT                NOT NULL DEFAULT 0 COMMENT '当前消费者数量',
    created_at        DATETIME(3)         NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    updated_at        DATETIME(3)         NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '更新时间',
    deleted_at        DATETIME(3)         DEFAULT NULL COMMENT '软删除时间',
    
    PRIMARY KEY (queue_id),
    UNIQUE KEY uk_vhost_queue_name (vhost, queue_name),
    INDEX idx_exchange_binding (exchange_name, binding_key),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '队列元数据表';
```

### 表结构：queue_stats（队列统计表）

```sql
CREATE TABLE queue_stats (
    stat_id          BIGINT             NOT NULL AUTO_INCREMENT COMMENT '统计记录ID',
    queue_id         VARCHAR(64)        NOT NULL COMMENT '队列ID',
    stat_time        DATETIME(3)        NOT NULL COMMENT '统计时间点',
    
    -- 消息统计
    message_count    BIGINT             NOT NULL DEFAULT 0 COMMENT '当前消息数',
    message_rate_in  DECIMAL(10,2)      DEFAULT 0 COMMENT '消息入队速率(条/秒)',
    message_rate_out DECIMAL(10,2)      DEFAULT 0 COMMENT '消息出队速率(条/秒)',
    
    -- 消费者统计
    consumer_count   INT                NOT NULL DEFAULT 0 COMMENT '消费者数量',
    unacked_count    BIGINT             NOT NULL DEFAULT 0 COMMENT '未确认消息数',
    
    -- 存储统计
    queue_size_bytes BIGINT             NOT NULL DEFAULT 0 COMMENT '队列总字节数',
    
    -- 性能指标
    avg_latency_ms   DECIMAL(10,2)      DEFAULT NULL COMMENT '平均消息延迟(毫秒)',
    
    PRIMARY KEY (stat_id),
    UNIQUE KEY uk_queue_stat_time (queue_id, stat_time),
    INDEX idx_stat_time (stat_time)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '队列运行时统计表';
```

---

## 队列类型详解

### 1. Classic Queue（经典队列）

最传统的队列类型，适用于大多数场景。

```json
{
  "queue_type": "classic",
  "arguments": {
    "x-queue-mode": "lazy",     // lazy: 懒加载，大队列优先磁盘
    "x-queue-version": 1
  }
}
```

### 2. Quorum Queue（仲裁队列）

基于 Raft 共识算法的复制队列，提供更强的数据安全性。

- **特点**：副本数量可配置，默认 5 副本
- **适用场景**：对数据可靠性要求极高的金融级应用
- **限制**：不支持非持久消息、优先级队列、消息 TTL

```json
{
  "queue_type": "quorum",
  "arguments": {
    "x-quorum-initial-group-size": 5
  }
}
```

### 3. Stream Queue（流队列）

支持消息回溯（Replay），可以从任意偏移量重新消费。

- **特点**：消息持久化存储，支持多消费者共享消费位置
- **适用场景**：事件溯源、日志聚合、实时分析

```json
{
  "queue_type": "stream",
  "arguments": {
    "x-stream-max-segment-size-bytes": 16777216
  }
}
```

---

## 溢出策略

| 策略 | 行为 | 使用场景 |
|------|------|----------|
| `reject-publish` | 拒绝新消息入队，返回错误 | 需要精确控制队列容量 |
| `drop-head` | 删除最旧的消息，腾出空间 | 优先新消息，丢弃旧数据 |
| `flow-control` | 生产者限流，等待消费 | 平衡生产与消费速度 |

---

## API 操作

### 创建队列

```json
POST /api/v1/queues
{
  "queue_name": "order.created",
  "vhost": "/",
  "durable": true,
  "max_length": 100000,
  "overflow_policy": "reject-publish",
  "message_ttl": 86400000,
  "dead_letter_exchange": "dlx.exchange",
  "dead_letter_routing_key": "order.dead"
}
```

### 查询队列列表

```json
GET /api/v1/queues?vhost=/&page=1&page_size=20
```

### 获取队列详情

```json
GET /api/v1/queues/{queue_id}
```

### 删除队列

```json
DELETE /api/v1/queues/{queue_id}
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
