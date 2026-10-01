# 9.5 分布式追踪 (Tracing)

## 概述

分布式追踪通过 Trace ID 串联消息从生产到消费的完整路径，实现全链路可观测。

## 数据库设计

### 表结构：trace_record（追踪记录表）

```sql
CREATE TABLE trace_record (
    trace_id           VARCHAR(64)       NOT NULL COMMENT 'Trace ID',
    
    -- 基本信息
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/',
    first_service      VARCHAR(128)      NOT NULL COMMENT '首个服务名称',
    
    -- 时间
    start_time        DATETIME(3)       NOT NULL COMMENT 'Trace 开始时间',
    end_time           DATETIME(3)       DEFAULT NULL COMMENT 'Trace 结束时间',
    duration_ms        BIGINT            DEFAULT NULL COMMENT '总耗时(毫秒)',
    
    -- 结果
    status             ENUM('ok', 'error', 'in_progress') DEFAULT 'in_progress',
    error_count        INT               NOT NULL DEFAULT 0 COMMENT '错误数量',
    
    -- 采样
    sampling_rate      DECIMAL(5,2)     DEFAULT 1.0 COMMENT '采样率(0-1)',
    sampled            BOOLEAN          NOT NULL DEFAULT TRUE COMMENT '是否被采样',
    
    PRIMARY KEY (trace_id),
    INDEX idx_start_time (start_time),
    INDEX idx_status (status),
    INDEX idx_service (first_service)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '追踪Trace主表';
```

### 表结构：span_record（追踪Span记录表）

```sql
CREATE TABLE span_record (
    span_id            VARCHAR(64)       NOT NULL COMMENT 'Span ID',
    trace_id           VARCHAR(64)       NOT NULL COMMENT 'Trace ID',
    
    -- Span 信息
    span_name          VARCHAR(256)      NOT NULL COMMENT 'Span名称',
    service_name       VARCHAR(128)      NOT NULL COMMENT '服务名称',
    operation_name     VARCHAR(256)      NOT NULL COMMENT '操作名称',
    
    -- 层级
    parent_span_id     VARCHAR(64)       DEFAULT NULL COMMENT '父Span ID',
    span_kind          ENUM('producer', 'consumer', 'client', 'server', 'internal') NOT NULL COMMENT 'Span类型',
    depth              INT               NOT NULL DEFAULT 0 COMMENT '调用深度',
    
    -- 时间
    start_time         DATETIME(3)       NOT NULL COMMENT 'Span开始时间',
    end_time           DATETIME(3)       DEFAULT NULL COMMENT 'Span结束时间',
    duration_ms        BIGINT            DEFAULT NULL COMMENT 'Span耗时(毫秒)',
    
    -- 消息追踪
    message_id         VARCHAR(64)       DEFAULT NULL COMMENT '关联消息ID',
    queue_id           VARCHAR(64)       DEFAULT NULL COMMENT '关联队列ID',
    node_name          VARCHAR(128)      DEFAULT NULL COMMENT '处理节点',
    
    -- 结果
    status_code        ENUM('ok', 'error') DEFAULT 'ok',
    error_type         VARCHAR(128)      DEFAULT NULL COMMENT '错误类型',
    error_message      TEXT              DEFAULT NULL COMMENT '错误信息',
    
    -- 标签
    tags               JSON              DEFAULT NULL COMMENT 'Span标签',
    /*
    {
      "messaging.system": "rabbitmq",
      "messaging.destination": "order.queue",
      "messaging.operation": "receive"
    }
    */
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (span_id),
    INDEX idx_trace (trace_id),
    INDEX idx_parent (parent_span_id),
    INDEX idx_service (service_name),
    INDEX idx_start_time (start_time)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '追踪Span明细表';
```

---

## Trace 传播协议

### W3C Trace Context（推荐）

```
Headers:
  traceparent: 00-<trace-id>-<span-id>-<trace-flags>
  tracestate: broker=v=1,node=broker-01
  
示例:
  traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
```

### B3 单头格式

```
Headers:
  X-B3-TraceId: 0af7651916cd43dd8448eb211c80319c
  X-B3-SpanId: b7ad6b7169203331
  X-B3-Sampled: 1
```

---

## 消息追踪 Span 命名规范

| 操作 | Span 名称 | Tags |
|------|---------|------|
| 消息发送 | `send to {exchange}` | `messaging.system`, `messaging.destination` |
| 消息路由 | `route to {queue}` | `messaging.routing_key` |
| 消息入队 | `enqueue {queue}` | `messaging.queue` |
| 消息投递 | `deliver to {consumer}` | `messaging.consumer_tag` |
| 消息消费 | `process {queue}` | `messaging.operation` |
| 消息确认 | `ack {queue}` | `messaging.ack_result` |
| 死信处理 | `dlx route` | `dlx.reason` |

---

## 全链路追踪示例

```
Trace: abc123-def456-ghi789

[Producer Service]         [Broker]           [Consumer Service]
      │                       │                      │
      │ send to order.ex      │                      │
      │ span: prod-send       │                      │
      │                       │                      │
      │──────────────────────▶│                      │
      │  publish(msg)          │                      │
      │                       │                      │
      │                       │ route order.*        │
      │                       │ span: routing        │
      │                       │                      │
      │                       │ enqueue order.pay    │
      │                       │ span: enqueue        │
      │                       │                      │
      │                       │◀─────────────────────│
      │                       │   deliver(msg)      │
      │                       │   span: deliver     │
      │                       │                      │
      │                       │─────────────────────▶│
      │                       │   process(order.pay) │
      │                       │   span: consumer    │
      │                       │                      │
      │                       │◀─────────────────────│
      │                       │   ack(msg)           │
      │                       │   span: ack         │
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
