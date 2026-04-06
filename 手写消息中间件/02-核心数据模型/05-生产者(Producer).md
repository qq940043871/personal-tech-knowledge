# 2.5 生产者 (Producer)

## 概述

生产者（Producer）负责将业务消息发送到消息中间件。生产者通常是无状态的，可以是后台服务、API 网关或数据采集器。一个生产者可以向多个交换机发送消息。

## 数据库设计

### 表结构：producer_info（生产者元数据表）

```sql
CREATE TABLE producer_info (
    producer_id         VARCHAR(64)         NOT NULL COMMENT '生产者唯一标识(UUID)',
    producer_name       VARCHAR(255)       NOT NULL COMMENT '生产者名称(客户端指定)',
    
    -- 生产者归属
    vhost               VARCHAR(128)       NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    user_id             VARCHAR(128)       DEFAULT NULL COMMENT '所属用户ID',
    application_id      VARCHAR(128)      DEFAULT NULL COMMENT '应用ID',
    
    -- 连接信息
    connection_id       VARCHAR(64)        NOT NULL COMMENT '所属连接ID',
    remote_ip           VARCHAR(45)        DEFAULT NULL COMMENT '客户端IP',
    client_name         VARCHAR(255)       DEFAULT NULL COMMENT '客户端名称',
    client_version      VARCHAR(64)        DEFAULT NULL COMMENT '客户端版本',
    protocol_version    VARCHAR(16)        DEFAULT NULL COMMENT '协议版本',
    
    -- 生产配置
    publisher_confirms  BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否启用发布确认',
    publisher_returns   BOOLEAN            NOT NULL DEFAULT FALSE COMMENT '是否启用退回消息',
    channel_max         INT                DEFAULT 0 COMMENT '最大信道数',
    
    -- 状态
    status              ENUM('active', 'idle', 'blocked', 'disconnected') DEFAULT 'active',
    last_heartbeat      DATETIME(3)        DEFAULT NULL COMMENT '最后心跳时间',
    
    -- 性能统计
    messages_sent       BIGINT             NOT NULL DEFAULT 0 COMMENT '累计发送消息数',
    bytes_sent          BIGINT             NOT NULL DEFAULT 0 COMMENT '累计发送字节数',
    confirm_success     BIGINT             NOT NULL DEFAULT 0 COMMENT '确认成功次数',
    confirm_failed      BIGINT             NOT NULL DEFAULT 0 COMMENT '确认失败次数',
    return_count        BIGINT             NOT NULL DEFAULT 0 COMMENT '退回消息次数',
    
    -- 审计
    connected_at        DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    disconnected_at     DATETIME(3)        DEFAULT NULL,
    created_at          DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at          DATETIME(3)        NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (producer_id),
    UNIQUE KEY uk_connection_name (connection_id, producer_name),
    INDEX idx_vhost_user (vhost, user_id),
    INDEX idx_status (status),
    INDEX idx_connection (connection_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '生产者元数据表';
```

### 表结构：producer_transaction（生产者事务表）

```sql
CREATE TABLE producer_transaction (
    transaction_id      VARCHAR(64)       NOT NULL COMMENT '事务ID',
    producer_id         VARCHAR(64)       NOT NULL COMMENT '生产者ID',
    vhost               VARCHAR(128)      NOT NULL DEFAULT '/',
    
    -- 事务内容
    operation_type      ENUM('publish', 'ack', 'nack', 'commit', 'rollback') NOT NULL COMMENT '操作类型',
    message_ids         JSON              DEFAULT NULL COMMENT '事务包含的消息ID列表',
    exchange_name       VARCHAR(255)       DEFAULT NULL COMMENT '目标交换机',
    routing_keys        JSON              DEFAULT NULL COMMENT '路由键列表',
    
    -- 事务状态
    transaction_status  ENUM('pending', 'committing', 'committed', 'rolled_back', 'failed') DEFAULT 'pending',
    timeout_at          DATETIME(3)        DEFAULT NULL COMMENT '事务超时时间',
    
    -- 审计
    created_at          DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    completed_at        DATETIME(3)       DEFAULT NULL,
    
    PRIMARY KEY (transaction_id),
    INDEX idx_producer (producer_id),
    INDEX idx_status (transaction_status),
    INDEX idx_timeout (timeout_at)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '生产者事务表';
```

### 表结构：producer_stats（生产者统计表）

```sql
CREATE TABLE producer_stats (
    stat_id             BIGINT            NOT NULL AUTO_INCREMENT COMMENT '统计ID',
    producer_id         VARCHAR(64)       NOT NULL COMMENT '生产者ID',
    stat_time           DATETIME(3)       NOT NULL COMMENT '统计时间点',
    
    -- 吞吐量
    messages_sent       BIGINT            NOT NULL DEFAULT 0 COMMENT '周期内发送消息数',
    bytes_sent          BIGINT            NOT NULL DEFAULT 0 COMMENT '周期内发送字节数',
    rate_msg_per_sec    DECIMAL(10,2)    DEFAULT 0 COMMENT '发送速率(条/秒)',
    
    -- 延迟
    avg_latency_ms      DECIMAL(10,2)    DEFAULT NULL COMMENT '平均发送延迟(毫秒)',
    p99_latency_ms      DECIMAL(10,2)    DEFAULT NULL COMMENT 'P99发送延迟(毫秒)',
    
    -- 错误统计
    error_count         INT               NOT NULL DEFAULT 0 COMMENT '发送失败次数',
    confirm_failed      INT               NOT NULL DEFAULT 0 COMMENT '确认失败次数',
    return_count        INT               NOT NULL DEFAULT 0 COMMENT '退回消息次数',
    
    PRIMARY KEY (stat_id),
    UNIQUE KEY uk_producer_stat_time (producer_id, stat_time),
    INDEX idx_stat_time (stat_time)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '生产者运行时统计表';
```

---

## 生产者消息发送流程

```
  业务系统
     │
     ▼
  构建消息 ──▶ 附加属性 ──▶ 设置路由键
     │
     ▼
  消息序列化 ──▶ 计算幂等Key
     │
     ▼
  检查幂等 ──▶ 已存在? ──是──▶ 返回历史消息ID
     │ 否
     ▼
  消息持久化 ──▶ 记录幂等Key
     │
     ▼
  发送至交换机
     │
     ├─── 开启Publisher Confirms? ──是──▶ 等待Broker确认
     │                                      │
     │◀──── 确认成功 ────────────────────────┘
     │◀──── 确认失败 ──▶ 触发重试/告警
     │
     ├─── 开启Publisher Returns? ──是──▶ 路由失败 ──▶ 接收退回消息
     │
     ▼
  返回发送结果
```

---

## API 操作

### 查询生产者列表

```json
GET /api/v1/producers?vhost=/&status=active&page=1&page_size=20
```

### 查询生产者详情

```json
GET /api/v1/producers/{producer_id}
```

### 查询生产者统计

```json
GET /api/v1/producers/{producer_id}/stats?period=hour
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
