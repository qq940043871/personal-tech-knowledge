# 4.4 死信队列 (DLX)

## 概述

死信队列（Dead Letter Exchange, DLX）是处理异常消息的兜底机制。当消息因被拒绝、超时或超过最大重投次数而无法正常消费时，消息会被转发到死信交换机，进而进入死信队列等待人工干预或自动重处理。

## 死信触发条件

| 条件 | 说明 |
|------|------|
| 消费者 Reject（requeue=false） | 消费者明确拒绝且不重新入队 |
| 消息 TTL 过期 | 消息超过存活时间 |
| 队列达到最大长度 | 队列溢出策略为 drop-head 时最旧消息被移除 |
| 超过最大重投次数 | redelivery_count > max_redeliveries |

## 数据库设计

### 表结构：dlx_config（死信配置表）

```sql
CREATE TABLE dlx_config (
    config_id          VARCHAR(64)       NOT NULL COMMENT '配置ID',
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/',
    
    -- 死信交换机
    dlx_exchange_name  VARCHAR(255)      NOT NULL COMMENT '死信交换机名称',
    dlx_exchange_type  ENUM('direct', 'fanout', 'topic') DEFAULT 'fanout' COMMENT '死信交换机类型',
    dlx_routing_key    VARCHAR(1024)     DEFAULT NULL COMMENT '死信路由键模板',
    
    -- 关联源队列
    source_queue_id    VARCHAR(64)       DEFAULT NULL COMMENT '关联的源队列ID(NULL表示全局)',
    source_queue_name  VARCHAR(255)      DEFAULT NULL COMMENT '关联的源队列名称',
    
    -- 重投策略
    max_redeliveries   INT               NOT NULL DEFAULT 10 COMMENT '最大重投次数',
    retry_strategy     ENUM('fixed', 'exponential', 'custom') DEFAULT 'exponential' COMMENT '重试策略',
    retry_delay_ms     BIGINT            NOT NULL DEFAULT 5000 COMMENT '重试延迟(毫秒)',
    retry_multiplier    DECIMAL(5,2)     DEFAULT 2.0 COMMENT '指数退避乘数',
    max_retry_delay_ms BIGINT            NOT NULL DEFAULT 3600000 COMMENT '最大重试延迟(1小时)',
    
    -- 自动处理
    auto_reprocess      BOOLEAN          NOT NULL DEFAULT FALSE COMMENT '是否自动重新处理',
    reprocess_delay_ms  BIGINT           DEFAULT NULL COMMENT '自动重新处理延迟',
    
    -- 告警
    alert_enabled      BOOLEAN           NOT NULL DEFAULT TRUE COMMENT '是否启用死信告警',
    alert_threshold     INT              DEFAULT 100 COMMENT '告警阈值(死信数)',
    alert_channels     JSON             DEFAULT NULL COMMENT '告警通知渠道',
    
    -- 状态
    status             ENUM('active', 'paused') DEFAULT 'active',
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (config_id),
    UNIQUE KEY uk_vhost_exchange (vhost, dlx_exchange_name),
    INDEX idx_source_queue (source_queue_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '死信队列配置表';
```

### 表结构：dlx_message（死信消息表）

```sql
CREATE TABLE dlx_message (
    dlx_record_id      VARCHAR(64)       NOT NULL COMMENT '死信记录ID',
    original_message_id VARCHAR(64)      NOT NULL COMMENT '原始消息ID',
    
    -- 来源信息
    source_exchange    VARCHAR(255)      NOT NULL COMMENT '原始交换机',
    source_queue       VARCHAR(255)      NOT NULL COMMENT '原始队列',
    source_routing_key VARCHAR(1024)     NOT NULL COMMENT '原始路由键',
    source_consumer_id VARCHAR(64)       DEFAULT NULL COMMENT '最后处理该消息的消费者ID',
    
    -- 死信原因
    dead_reason        ENUM('rejected', 'expired', 'max_redeliveries', 'queue_full', 'consumer_crash', 'invalid_payload') 
                      NOT NULL COMMENT '死信原因',
    error_message      TEXT              DEFAULT NULL COMMENT '错误详情',
    
    -- 消息快照(用于人工排查)
    message_headers    JSON             DEFAULT NULL COMMENT '原始消息头快照',
    payload_preview    VARCHAR(1024)     DEFAULT NULL COMMENT '消息体预览',
    
    -- 重投信息
    redelivery_count   INT               NOT NULL DEFAULT 0 COMMENT '累计重投次数',
    next_retry_at      DATETIME(3)       DEFAULT NULL COMMENT '下次重试时间',
    
    -- 处理状态
    status             ENUM('pending', 'retrying', 'reprocessed', 'archived', 'discarded') DEFAULT 'pending',
    resolution         VARCHAR(512)      DEFAULT NULL COMMENT '处理结果说明',
    resolved_by        VARCHAR(128)      DEFAULT NULL COMMENT '处理人(系统或人工)',
    resolved_at        DATETIME(3)       DEFAULT NULL COMMENT '处理时间',
    
    -- 审计
    first_failed_at    DATETIME(3)       NOT NULL COMMENT '首次失败时间',
    dead_at            DATETIME(3)       NOT NULL COMMENT '进入死信时间',
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (dlx_record_id),
    INDEX idx_original_message (original_message_id),
    INDEX idx_status (status),
    INDEX idx_reason (dead_reason),
    INDEX idx_source_queue (source_queue),
    INDEX idx_next_retry (status, next_retry_at),
    INDEX idx_dead_at (dead_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '死信消息记录表';
```

---

## 重试策略对比

### Fixed（固定间隔）

```
失败 → 5s → 失败 → 5s → 失败 → 5s → ... → DLX
```

### Exponential（指数退避）

```
失败 → 5s → 失败 → 10s → 失败 → 20s → 失败 → 40s → ... → max(1h) → DLX
```

### Custom（自定义）

```json
{
  "retry_delays": [1000, 5000, 30000, 300000, 1800000]
}
```

---

## 死信处理流程

```
消息消费失败
      │
      ▼
 redelivery_count < max?
      │
  ┌───┴───┐
  是       否
  │        │
  ▼        ▼
重投入队   进入死信队列
  │        │
  │        ▼
  │     告警通知
  │        │
  │     ┌──┴──┐
  │   自动    人工
  │   重处理   处理
  │     │      │
  │     ▼      ▼
  │   重新投递  修复后重新投递
  │     │      │
  │     ▼      ▼
  └──── 消费成功 ────▶ 完成
```

---

## API 操作

### 查询死信消息

```json
GET /api/v1/dead-letters?status=pending&reason=max_redeliveries&page=1&page_size=20
```

### 重新投递死信

```json
POST /api/v1/dead-letters/{dlx_record_id}/reprocess
{
  "target_queue": "order.retry.queue",
  "delay_ms": 0
}
```

### 批量归档死信

```json
POST /api/v1/dead-letters/batch-archive
{
  "filters": {
    "dead_at_before": "2026-03-01T00:00:00.000Z"
  }
}
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
