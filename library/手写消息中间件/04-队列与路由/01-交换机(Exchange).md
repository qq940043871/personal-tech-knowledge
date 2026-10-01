# 4.1 交换机 (Exchange)

## 概述

交换机（Exchange）是消息路由的核心枢纽。生产者将消息发送到交换机，交换机根据路由规则将消息转发到一个或多个队列。交换机本身不存储消息。

## 数据库设计

### 表结构：exchange_info（交换机元数据表）

```sql
CREATE TABLE exchange_info (
    exchange_id        VARCHAR(64)       NOT NULL COMMENT '交换机ID(UUID)',
    exchange_name      VARCHAR(255)      NOT NULL COMMENT '交换机名称',
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/' COMMENT '虚拟主机',
    
    -- 交换机类型
    exchange_type      ENUM('direct', 'fanout', 'topic', 'headers') NOT NULL COMMENT '交换机类型',
    durable            BOOLEAN           NOT NULL DEFAULT TRUE COMMENT '是否持久化',
    auto_delete        BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '无绑定关系时自动删除',
    internal           BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否为内部交换机(不可直接接收消息)',
    
    -- 配置
    arguments          JSON             DEFAULT NULL COMMENT '扩展参数',
    alternate_exchange VARCHAR(255)      DEFAULT NULL COMMENT '备用交换机(路由失败时转发)',
    
    -- 统计
    binding_count      INT               NOT NULL DEFAULT 0 COMMENT '绑定数量',
    message_in_count   BIGINT            NOT NULL DEFAULT 0 COMMENT '累计接收消息数',
    message_out_count  BIGINT            NOT NULL DEFAULT 0 COMMENT '累计转发消息数',
    message_drop_count BIGINT            NOT NULL DEFAULT 0 COMMENT '累计丢弃消息数',
    
    -- 状态
    status             ENUM('running', 'stopped', 'deleted') DEFAULT 'running',
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at         DATETIME(3)       DEFAULT NULL,
    
    PRIMARY KEY (exchange_id),
    UNIQUE KEY uk_vhost_name (vhost, exchange_name),
    INDEX idx_type (exchange_type),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '交换机元数据表';
```

### 表结构：exchange_stats（交换机统计表）

```sql
CREATE TABLE exchange_stats (
    stat_id            BIGINT            NOT NULL AUTO_INCREMENT,
    exchange_id        VARCHAR(64)       NOT NULL COMMENT '交换机ID',
    stat_time          DATETIME(3)       NOT NULL COMMENT '统计时间',
    
    -- 吞吐量
    messages_in        BIGINT            NOT NULL DEFAULT 0 COMMENT '入站消息数',
    messages_out       BIGINT            NOT NULL DEFAULT 0 COMMENT '出站消息数',
    messages_dropped   BIGINT            NOT NULL DEFAULT 0 COMMENT '丢弃消息数',
    rate_in            DECIMAL(10,2)    DEFAULT 0 COMMENT '入站速率(msg/s)',
    rate_out           DECIMAL(10,2)    DEFAULT 0 COMMENT '出站速率(msg/s)',
    
    -- 绑定
    active_bindings    INT               NOT NULL DEFAULT 0 COMMENT '活跃绑定数',
    
    PRIMARY KEY (stat_id),
    UNIQUE KEY uk_exchange_time (exchange_id, stat_time)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '交换机运行时统计表';
```

---

## 交换机类型与路由规则

### Direct（直连交换机）

精确匹配 Routing Key 与 Binding Key。

```
Binding: queue-A ← key: "order.created"
Binding: queue-B ← key: "order.cancelled"

消息 Routing Key = "order.created"  → queue-A
消息 Routing Key = "order.cancelled" → queue-B
消息 Routing Key = "order.updated"  → 无匹配，丢弃
```

### Fanout（广播交换机）

忽略 Routing Key，投递到所有绑定队列。

```
Binding: queue-A, queue-B, queue-C

任何消息 → queue-A, queue-B, queue-C
```

### Topic（主题交换机）

通配符匹配 Routing Key。

```
Binding: queue-A ← pattern: "order.*.pay"      (* 匹配一个词)
Binding: queue-B ← pattern: "order.#"           (# 匹配零或多个词)
Binding: queue-C ← pattern: "*.created"          (* 匹配一个词)

"order.created.pay"     → queue-A, queue-B
"order.created"          → queue-C, queue-B
"user.created"           → queue-C
"user.created.info"      → 无匹配
```

### Headers（首部交换机）

根据消息头匹配（不使用 Routing Key）。

```json
{
  "binding_args": {
    "x-match": "all",
    "type": "notification",
    "priority": "high"
  }
}
```

---

## 备用交换机（Alternate Exchange）

当消息无法路由到任何队列时，转发到备用交换机。

```
消息 ──▶ 主交换机 ──无匹配──▶ 备用交换机 ──▶ 未路由队列
          │ 有匹配
          ▼
      目标队列
```

配置示例：
```json
{
  "exchange_name": "main.exchange",
  "alternate_exchange": "unrouted.exchange"
}
```

---

## API 操作

### 创建交换机

```json
POST /api/v1/exchanges
{
  "exchange_name": "order.exchange",
  "vhost": "/",
  "exchange_type": "topic",
  "durable": true,
  "alternate_exchange": "dlx.exchange"
}
```

### 列出交换机

```json
GET /api/v1/exchanges?vhost=/&type=topic
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
