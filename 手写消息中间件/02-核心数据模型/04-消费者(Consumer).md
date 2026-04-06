# 2.4 消费者 (Consumer)

## 概述

消费者（Consumer）是从队列或主题订阅并处理消息的客户端应用。一个消费者可以同时订阅多个队列或主题，消息被消费后根据确认策略决定是否从存储中删除。

## 数据库设计

### 表结构：consumer_info（消费者元数据表）

```sql
CREATE TABLE consumer_info (
    consumer_id         VARCHAR(64)         NOT NULL COMMENT '消费者唯一标识(UUID)',
    consumer_tag        VARCHAR(255)       NOT NULL COMMENT '消费者标签(客户端指定)',
    
    -- 消费者归属
    vhost               VARCHAR(128)       NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    user_id             VARCHAR(128)       DEFAULT NULL COMMENT '所属用户ID',
    application_id      VARCHAR(128)      DEFAULT NULL COMMENT '应用ID',
    
    -- 连接信息
    connection_id      VARCHAR(64)        NOT NULL COMMENT '所属连接ID',
    remote_ip           VARCHAR(45)        DEFAULT NULL COMMENT '客户端IP',
    client_name         VARCHAR(255)       DEFAULT NULL COMMENT '客户端名称',
    client_version      VARCHAR(64)        DEFAULT NULL COMMENT '客户端版本',
    protocol_version    VARCHAR(16)        DEFAULT NULL COMMENT '协议版本',
    
    -- 消费模式
    consume_mode       ENUM('exclusive', 'shared', 'work') NOT NULL DEFAULT 'shared' COMMENT '消费模式',
    prefetch_count      INT                NOT NULL DEFAULT 10 COMMENT '预取消息数量',
    prefetch_size       INT                DEFAULT 0 COMMENT '预取大小(字节)',
    auto_ack            BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否自动确认',
    
    -- 状态
    status              ENUM('active', 'idle', 'paused', 'disconnected') DEFAULT 'active' COMMENT '消费者状态',
    last_heartbeat      DATETIME(3)        DEFAULT NULL COMMENT '最后心跳时间',
    
    -- 性能统计
    messages_consumed   BIGINT             NOT NULL DEFAULT 0 COMMENT '累计消费消息数',
    bytes_consumed      BIGINT             NOT NULL DEFAULT 0 COMMENT '累计消费字节数',
    avg_latency_ms      DECIMAL(10,3)      DEFAULT NULL COMMENT '平均消费延迟(毫秒)',
    
    -- 审计
    connected_at        DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '连接时间',
    disconnected_at     DATETIME(3)        DEFAULT NULL COMMENT '断开时间',
    created_at          DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at           DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (consumer_id),
    UNIQUE KEY uk_connection_tag (connection_id, consumer_tag),
    INDEX idx_vhost_user (vhost, user_id),
    INDEX idx_status (status),
    INDEX idx_connection (connection_id),
    INDEX idx_last_heartbeat (last_heartbeat)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '消费者元数据表';
```

### 表结构：consumer_subscription（消费者订阅关系表）

```sql
CREATE TABLE consumer_subscription (
    subscription_id   VARCHAR(64)       NOT NULL COMMENT '订阅关系ID',
    consumer_id       VARCHAR(64)       NOT NULL COMMENT '消费者ID',
    destination_type   ENUM('queue', 'topic') NOT NULL COMMENT '目的地类型',
    destination_id    VARCHAR(64)       NOT NULL COMMENT '队列或主题ID',
    
    -- 订阅配置
    subscription_mode ENUM('exclusive', 'shared', 'failover') DEFAULT 'shared' COMMENT '订阅模式',
    filter_pattern    VARCHAR(1024)     DEFAULT NULL COMMENT '消息过滤模式',
    filter_headers    JSON              DEFAULT NULL COMMENT '头过滤规则',
    no_local          BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '禁止接收自己生产的消息',
    
    -- 消费位置
    start_policy      ENUM('first', 'last', 'timestamp', 'sequence') DEFAULT 'last' COMMENT '消费起始策略',
    start_timestamp   DATETIME(3)       DEFAULT NULL COMMENT '起始时间戳',
    start_sequence    BIGINT            DEFAULT NULL COMMENT '起始序列号',
    
    -- 状态
    status            ENUM('active', 'paused', 'pending_rebalance') DEFAULT 'active',
    
    -- 审计
    subscribed_at     DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    unsubscribed_at    DATETIME(3)       DEFAULT NULL,
    
    PRIMARY KEY (subscription_id),
    UNIQUE KEY uk_consumer_destination (consumer_id, destination_type, destination_id),
    INDEX idx_destination (destination_type, destination_id),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '消费者订阅关系表';
```

### 表结构：consumer_offset（消费偏移量表）

```sql
CREATE TABLE consumer_offset (
    offset_id          VARCHAR(64)        NOT NULL COMMENT '偏移量记录ID',
    consumer_id        VARCHAR(64)        NOT NULL COMMENT '消费者ID',
    destination_type   ENUM('queue', 'topic') NOT NULL COMMENT '目的地类型',
    destination_id     VARCHAR(64)        NOT NULL COMMENT '目的地ID',
    
    -- 消费位置
    offset             BIGINT             NOT NULL COMMENT '当前消费偏移量',
    offset_type        ENUM('message_id', 'sequence', 'timestamp', 'log_offset') NOT NULL DEFAULT 'sequence' COMMENT '偏移量类型',
    partition_id       INT                DEFAULT NULL COMMENT '分区ID(分区队列)',
    
    -- 状态
    pending_offset     BIGINT             DEFAULT NULL COMMENT '待确认的偏移量(in-flight)',
    acknowledged_offset BIGINT            DEFAULT NULL COMMENT '已确认的最大偏移量',
    
    -- 消费追踪
    last_consumed_at   DATETIME(3)        DEFAULT NULL COMMENT '最后消费时间',
    lag                BIGINT             DEFAULT 0 COMMENT '当前消费滞后量',
    
    -- 审计
    created_at         DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (offset_id),
    UNIQUE KEY uk_consumer_destination (consumer_id, destination_type, destination_id, partition_id),
    INDEX idx_offset (destination_type, destination_id, partition_id, offset)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '消费者消费偏移量表';
```

### 表结构：consumer_stats（消费者统计表）

```sql
CREATE TABLE consumer_stats (
    stat_id           BIGINT            NOT NULL AUTO_INCREMENT COMMENT '统计ID',
    consumer_id       VARCHAR(64)       NOT NULL COMMENT '消费者ID',
    stat_time         DATETIME(3)       NOT NULL COMMENT '统计时间点',
    
    -- 吞吐量统计
    messages_consumed BIGINT            NOT NULL DEFAULT 0 COMMENT '周期内消费消息数',
    bytes_consumed    BIGINT            NOT NULL DEFAULT 0 COMMENT '周期内消费字节数',
    rate_msg_per_sec  DECIMAL(10,2)     DEFAULT 0 COMMENT '消费速率(条/秒)',
    
    -- 延迟统计
    avg_latency_ms    DECIMAL(10,2)     DEFAULT NULL COMMENT '平均延迟(毫秒)',
    p99_latency_ms    DECIMAL(10,2)     DEFAULT NULL COMMENT 'P99延迟(毫秒)',
    
    -- 错误统计
    error_count       INT               NOT NULL DEFAULT 0 COMMENT '处理错误次数',
    retry_count       INT               NOT NULL DEFAULT 0 COMMENT '重试次数',
    
    -- 滞后统计
    avg_lag           BIGINT             DEFAULT 0 COMMENT '平均消费滞后',
    
    PRIMARY KEY (stat_id),
    UNIQUE KEY uk_consumer_stat_time (consumer_id, stat_time),
    INDEX idx_stat_time (stat_time)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '消费者运行时统计表';
```

---

## 消费模式详解

### 1. Exclusive（独占模式）

```json
{
  "consume_mode": "exclusive",
  "description": "该队列同时只允许一个消费者，队列级别独占"
}
```

### 2. Shared（共享模式）

```json
{
  "consume_mode": "shared",
  "prefetch_count": 10,
  "description": "多个消费者共享消费同一队列，消息在消费者间负载均衡"
}
```

### 3. Work（工作队列模式）

```json
{
  "consume_mode": "work",
  "prefetch_count": 1,
  "description": "公平调度，每消费完一条才分配下一条，慢消费者不会被压垮"
}
```

---

## 消费者生命周期

```
  注册连接
      │
      ▼
  发起订阅 ─────────────────────────────────┐
      │                                        │
      ▼                                        │
  订阅成功 ──────── 等待消息                   │
      │                  │                     │
      │<───── ACK/NACK ──┘                     │
      │                  │                     │
      ▼                  ▼                     │
  更新Offset        业务处理                    │
      │                  │                     │
      │<───── ACK/NACK ──┘                     │
      │                  │                     │
      ▼                  ▼                     │
  继续消费 ◄───── 确认完成                    │
      │                                        │
      ▼                                        │
  取消订阅/断开连接                            │
      │                                        │
      ▼                                        │
  保存最终Offset                              │
```

---

## API 操作

### 注册消费者

```json
POST /api/v1/consumers
{
  "consumer_tag": "analytics-consumer-01",
  "vhost": "/",
  "consume_mode": "shared",
  "prefetch_count": 20,
  "auto_ack": false
}
```

### 创建订阅

```json
POST /api/v1/consumers/{consumer_id}/subscriptions
{
  "destination": {
    "type": "queue",
    "id": "queue-uuid-xxx"
  },
  "subscription_mode": "shared",
  "start_policy": "last"
}
```

### 查询消费者列表

```json
GET /api/v1/consumers?vhost=/&status=active&page=1&page_size=20
```

### 查询消费滞后

```json
GET /api/v1/consumers/{consumer_id}/lag
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
