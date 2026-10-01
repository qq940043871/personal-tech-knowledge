# 5.4 消费确认 (ACK)

## 概述

消费确认（Acknowledgment, ACK）是保证消息可靠消费的核心机制。消费者成功处理消息后发送 ACK，Broker 收到 ACK 后才删除该消息。如果消费者处理失败，可以发送 NACK 或 Reject，消息将被重新投递或进入死信队列。

## 确认类型

| 类型 | 说明 | 消息处理 |
|------|------|---------|
| ACK | 确认成功 | Broker 删除消息 |
| NACK | 否定确认 | 消息重新入队 |
| Reject | 拒绝 | 重新入队或进入 DLX |

## 数据库设计

### 表结构：delivery_record（投递记录表）

```sql
CREATE TABLE delivery_record (
    delivery_id        VARCHAR(64)       NOT NULL COMMENT '投递记录ID',
    message_id         VARCHAR(64)       NOT NULL COMMENT '消息ID',
    consumer_id        VARCHAR(64)       NOT NULL COMMENT '消费者ID',
    queue_id           VARCHAR(64)       NOT NULL COMMENT '队列ID',
    
    -- 投递信息
    delivery_tag       BIGINT            NOT NULL COMMENT '投递标签(信道内唯一)',
    delivery_count     INT               NOT NULL DEFAULT 1 COMMENT '投递次数',
    redelivered        BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否重投',
    
    -- 时间
    delivered_at       DATETIME(3)       NOT NULL COMMENT '投递时间',
    ack_timeout_ms     INT               NOT NULL DEFAULT 30000 COMMENT '确认超时(毫秒)',
    ack_deadline       DATETIME(3)       NOT NULL COMMENT '确认截止时间',
    
    -- 确认结果
    ack_status         ENUM('pending', 'acked', 'nacked', 'rejected', 'expired') DEFAULT 'pending',
    acked_at           DATETIME(3)       DEFAULT NULL COMMENT '确认时间',
    ack_latency_ms     DECIMAL(10,2)     DEFAULT NULL COMMENT '确认耗时(毫秒)',
    
    -- NACK/Reject 详情
    nack_reason        VARCHAR(512)      DEFAULT NULL COMMENT 'NACK原因',
    requeue            BOOLEAN           DEFAULT TRUE COMMENT '是否重新入队',
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (delivery_id),
    UNIQUE KEY uk_consumer_delivery_tag (consumer_id, delivery_tag),
    INDEX idx_message (message_id),
    INDEX idx_queue (queue_id),
    INDEX idx_ack_status (ack_status),
    INDEX idx_ack_deadline (ack_status, ack_deadline)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '消息投递记录表';
```

---

## 确认流程

### 正常确认

```
Broker ──▶ Deliver(msg) ──▶ Consumer
Consumer ──▶ Process ──▶ ACK ──▶ Broker
Broker ──▶ 删除消息
```

### 处理失败

```
Broker ──▶ Deliver(msg) ──▶ Consumer
Consumer ──▶ Process Failed ──▶ NACK(requeue=true) ──▶ Broker
Broker ──▶ 消息重新入队
```

### 确认超时

```
Broker ──▶ Deliver(msg, deadline=30s) ──▶ Consumer
   │         │
   │    30秒无ACK
   │         │
   ▼         ▼
Broker 收回消息 → 重新投递(或进入DLX)
```

---

## 确认超时扫描

```sql
-- 查找超时未确认的消息
SELECT * FROM delivery_record
WHERE ack_status = 'pending'
  AND ack_deadline < NOW()
ORDER BY delivered_at ASC
LIMIT 100;
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
