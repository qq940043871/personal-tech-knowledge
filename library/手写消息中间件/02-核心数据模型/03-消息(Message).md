# 2.3 消息 (Message)

## 概述

消息（Message）是消息中间件传输的数据单元，承载业务信息。消息包含消息体（Payload）和消息属性（Properties），并在整个流转生命周期中携带元数据。

## 消息结构

```
┌─────────────────────────────────────────────┐
│                 Message                      │
├──────────────┬──────────────────────────────┤
│  System Headers │     Properties (用户定义)   │
│  message_id    │  content_type               │
│  timestamp     │  content_encoding            │
│  exchange      │  headers                     │
│  routing_key   │  delivery_mode (持久性)       │
│  correlation_id│  priority (优先级)           │
│  reply_to      │  expiration (过期时间)        │
│  TTL           │  user_id / app_id            │
├──────────────┴──────────────────────────────┤
│              Payload (消息体)                │
│     二进制数据 / JSON / Protobuf / XML       │
└─────────────────────────────────────────────┘
```

## 数据库设计

### 表结构：message（消息主表）

```sql
CREATE TABLE message (
    message_id           VARCHAR(64)         NOT NULL COMMENT '消息唯一标识(UUID)',
    
    -- 路由信息
    vhost                VARCHAR(128)       NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    exchange_name        VARCHAR(255)       NOT NULL COMMENT '入站交换机',
    routing_key          VARCHAR(1024)      NOT NULL COMMENT '入站路由键',
    destination_type     ENUM('queue', 'topic') NOT NULL COMMENT '目的地类型',
    destination_id       VARCHAR(64)        NOT NULL COMMENT '目的地ID(队列或主题ID)',
    
    -- 消息属性
    content_type         VARCHAR(128)       DEFAULT 'application/json' COMMENT '内容类型',
    content_encoding     VARCHAR(64)        DEFAULT 'utf-8' COMMENT '内容编码',
    delivery_mode        TINYINT            NOT NULL DEFAULT 1 COMMENT '1=非持久, 2=持久',
    priority             TINYINT            NOT NULL DEFAULT 5 COMMENT '优先级 0-9',
    message_timestamp     DATETIME(3)        NOT NULL COMMENT '消息创建时间',
    
    -- 消息体
    payload_size         INT                NOT NULL COMMENT '消息体大小(字节)',
    payload_checksum     VARCHAR(32)        DEFAULT NULL COMMENT '消息体校验和(MD5)',
    payload_ref          VARCHAR(512)       DEFAULT NULL COMMENT '大消息体引用(外部存储)',
    
    -- 生产者信息
    producer_id          VARCHAR(64)        NOT NULL COMMENT '生产者ID',
    producer_session_id  VARCHAR(64)        DEFAULT NULL COMMENT '生产者会话ID',
    user_id              VARCHAR(128)       DEFAULT NULL COMMENT '应用级用户ID',
    
    -- 消息状态
    message_status       ENUM('pending', 'delivered', 'acknowledged', 'dead', 'expired') 
                         NOT NULL DEFAULT 'pending' COMMENT '消息状态',
    redelivered          BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否重投',
    redelivery_count     INT                NOT NULL DEFAULT 0 COMMENT '重投次数',
    
    -- 时间控制
    expiration           BIGINT             DEFAULT NULL COMMENT '消息过期时间(毫秒Unix时间戳)',
    ttl                  BIGINT             DEFAULT NULL COMMENT 'TTL(毫秒)',
    delivery_start_time  DATETIME(3)        DEFAULT NULL COMMENT '可开始投递时间(延迟消息)',
    
    -- 事务
    transaction_id       VARCHAR(64)        DEFAULT NULL COMMENT '所属事务ID',
    is_transactional     BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否事务消息',
    
    -- 关联ID
    correlation_id       VARCHAR(255)       DEFAULT NULL COMMENT '关联ID(用于响应链)',
    reply_to             VARCHAR(255)       DEFAULT NULL COMMENT '回复目标地址',
    
    -- 审计
    created_at           DATETIME(3)         NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at           DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (message_id),
    INDEX idx_destination (destination_type, destination_id),
    INDEX idx_status (message_status),
    INDEX idx_expiration (expiration),
    INDEX idx_delivery_start (delivery_start_time),
    INDEX idx_timestamp (message_timestamp),
    INDEX idx_producer (producer_id),
    INDEX idx_routing_key (routing_key(255)),
    INDEX idx_transaction (transaction_id),
    INDEX idx_correlation (correlation_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '消息主表';
```

### 表结构：message_header（消息扩展属性表）

```sql
CREATE TABLE message_header (
    id              BIGINT            NOT NULL AUTO_INCREMENT COMMENT '属性ID',
    message_id      VARCHAR(64)       NOT NULL COMMENT '消息ID',
    header_key      VARCHAR(255)      NOT NULL COMMENT '属性键',
    header_value    TEXT              NOT NULL COMMENT '属性值(JSON序列化)',
    header_type     ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string' COMMENT '值类型',
    is_system       BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否系统属性',
    created_at      DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (id),
    UNIQUE KEY uk_message_header (message_id, header_key),
    INDEX idx_message (message_id),
    INDEX idx_header_key (header_key)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '消息扩展属性表';
```

### 表结构：message_dead_letter（死信消息表）

```sql
CREATE TABLE message_dead_letter (
    dead_letter_id   VARCHAR(64)       NOT NULL COMMENT '死信记录ID',
    message_id       VARCHAR(64)       NOT NULL COMMENT '原始消息ID',
    original_queue   VARCHAR(255)       NOT NULL COMMENT '原始队列名称',
    original_exchange VARCHAR(255)     NOT NULL COMMENT '原始交换机',
    
    -- 死信原因
    reason           ENUM('rejected', 'expired', 'max_redeliveries', 'consumer_crash', 'invalid_payload') 
                      NOT NULL COMMENT '死信原因',
    error_message    TEXT              DEFAULT NULL COMMENT '错误详情',
    stack_trace      TEXT              DEFAULT NULL COMMENT '异常堆栈',
    
    -- 处理记录
    dlx_exchange     VARCHAR(255)       DEFAULT NULL COMMENT '死信交换机',
    dlx_routing_key  VARCHAR(255)       DEFAULT NULL COMMENT '死信路由键',
    retry_count      INT               NOT NULL DEFAULT 0 COMMENT '重试次数',
    
    -- 状态
    status           ENUM('pending', 'retrying', 'archived', 'discarded') DEFAULT 'pending',
    
    -- 审计
    first_failed_at  DATETIME(3)        NOT NULL COMMENT '首次失败时间',
    last_failed_at   DATETIME(3)        NOT NULL COMMENT '最近失败时间',
    resolved_at      DATETIME(3)        DEFAULT NULL COMMENT '解决时间',
    
    PRIMARY KEY (dead_letter_id),
    INDEX idx_message (message_id),
    INDEX idx_status (status),
    INDEX idx_first_failed (first_failed_at),
    INDEX idx_reason (reason)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '死信消息记录表';
```

### 表结构：message_idempotency（消息幂等表）

```sql
CREATE TABLE message_idempotency (
    idempotency_key   VARCHAR(255)     NOT NULL COMMENT '幂等键(producer_id + message_key)',
    message_id        VARCHAR(64)      NOT NULL COMMENT '已存储的消息ID',
    producer_id       VARCHAR(64)      NOT NULL COMMENT '生产者ID',
    created_at        DATETIME(3)      NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    expires_at        DATETIME(3)      NOT NULL COMMENT '幂等键过期时间',
    
    PRIMARY KEY (idempotency_key),
    INDEX idx_producer (producer_id),
    INDEX idx_expires (expires_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '消息幂等去重表';
```

---

## 消息优先级映射

| Priority 值 | 级别名称 | 描述 |
|-------------|---------|------|
| 0 | Lowest | 最低优先级 |
| 1-3 | Low | 低优先级 |
| 4 | Normal | 普通优先级（默认值）|
| 5-6 | Medium | 中优先级 |
| 7-8 | High | 高优先级 |
| 9 | Highest | 最高优先级 |

---

## 消息流转状态机

```
                      ┌──────────────┐
                      │   Pending    │ ← 生产者发送
                      └──────┬───────┘
                             │
                    delivery_start_time <= now?
                    (延迟消息判断)
                             │
                             ▼
                      ┌──────────────┐
            ┌────────│   Delivered   │────────┐
            │        └──────┬─────────┘        │
            │               │                 │
         ACK成功        NACK/超时         Reject
            │               │                 │
            ▼               ▼                 ▼
     ┌────────────┐  ┌────────────┐   ┌────────────┐
     │Acknowledged│  │Redelivered │   │ Dead Letter│ ← 重投超过上限
     └────────────┘  └─────┬──────┘   └────────────┘
                           │ redelivery_count > max?
                           ▼
              (回到 Delivered 重新投递)
```

---

## API 操作

### 发送消息

```json
POST /api/v1/messages
{
  "exchange": "order.exchange",
  "routing_key": "order.created",
  "destination": {
    "type": "queue",
    "id": "queue-uuid-xxx"
  },
  "properties": {
    "content_type": "application/json",
    "delivery_mode": 2,
    "priority": 5,
    "expiration": 86400000,
    "headers": {
      "trace_id": "abc123",
      "source": "order-service"
    }
  },
  "payload": "base64_encoded_data...",
  "idempotency_key": "order-12345-001"
}
```

### 查询消息详情

```json
GET /api/v1/messages/{message_id}
```

### 批量查询死信

```json
GET /api/v1/dead-letters?status=pending&page=1&page_size=20
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
