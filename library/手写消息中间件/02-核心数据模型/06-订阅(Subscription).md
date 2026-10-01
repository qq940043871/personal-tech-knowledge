# 2.6 订阅 (Subscription)

## 概述

订阅（Subscription）是消费者与目的地（队列或主题）之间的关联关系。一个消费者可以建立多个订阅，同时从多个队列或主题消费消息。订阅决定了消息如何被过滤和分发。

## 数据库设计

### 表结构：subscription（订阅主表）

```sql
CREATE TABLE subscription (
    subscription_id     VARCHAR(64)       NOT NULL COMMENT '订阅ID(UUID)',
    subscription_name   VARCHAR(255)      NOT NULL COMMENT '订阅名称',
    
    -- 归属
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/',
    owner_type         ENUM('consumer', 'application', 'system') NOT NULL DEFAULT 'consumer' COMMENT '拥有者类型',
    owner_id           VARCHAR(64)       NOT NULL COMMENT '拥有者ID',
    
    -- 目的地
    destination_type   ENUM('queue', 'topic') NOT NULL COMMENT '目的地类型',
    destination_id     VARCHAR(64)       NOT NULL COMMENT '队列或主题ID',
    
    -- 过滤规则
    filter_type        ENUM('none', 'routing_key', 'header', 'sql') DEFAULT 'none' COMMENT '过滤类型',
    filter_pattern     VARCHAR(1024)     DEFAULT NULL COMMENT '过滤模式(路由键通配符)',
    filter_headers     JSON             DEFAULT NULL COMMENT '头过滤规则',
    filter_sql         TEXT             DEFAULT NULL COMMENT 'SQL过滤表达式',
    
    -- 订阅配置
    subscription_mode  ENUM('exclusive', 'shared', 'failover', 'cluster') DEFAULT 'shared' COMMENT '订阅模式',
    priority           INT               DEFAULT 0 COMMENT '订阅优先级(同目的地高优先级优先)',
    no_local          BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '不接收本地消息',
    
    -- 消费起始
    start_policy       ENUM('first', 'last', 'timestamp', 'sequence') DEFAULT 'last' COMMENT '起始策略',
    start_timestamp   DATETIME(3)       DEFAULT NULL COMMENT '起始时间',
    start_sequence    BIGINT            DEFAULT NULL COMMENT '起始序列号',
    
    -- 状态
    status             ENUM('active', 'paused', 'resuming', 'deleted') DEFAULT 'active',
    paused_reason      VARCHAR(255)      DEFAULT NULL COMMENT '暂停原因',
    
    -- 统计
    messages_delivered BIGINT            NOT NULL DEFAULT 0 COMMENT '累计投递消息数',
    bytes_delivered    BIGINT            NOT NULL DEFAULT 0 COMMENT '累计投递字节数',
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    deleted_at         DATETIME(3)       DEFAULT NULL,
    
    PRIMARY KEY (subscription_id),
    UNIQUE KEY uk_owner_destination (owner_id, destination_type, destination_id),
    INDEX idx_destination (destination_type, destination_id),
    INDEX idx_owner (owner_type, owner_id),
    INDEX idx_status (status)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '订阅主表';
```

### 表结构：subscription_route（订阅路由表）

```sql
CREATE TABLE subscription_route (
    route_id            VARCHAR(64)       NOT NULL COMMENT '路由ID',
    subscription_id    VARCHAR(64)       NOT NULL COMMENT '订阅ID',
    
    -- 源
    source_exchange     VARCHAR(255)      NOT NULL COMMENT '源交换机',
    source_routing_key  VARCHAR(1024)     DEFAULT NULL COMMENT '源路由键',
    
    -- 目标
    target_exchange     VARCHAR(255)      DEFAULT NULL COMMENT '目标交换机',
    target_routing_key  VARCHAR(1024)     DEFAULT NULL COMMENT '目标路由键',
    
    -- 转换
    transform_type     ENUM('none', 'header_rewrite', 'payload_transform') DEFAULT 'none' COMMENT '转换类型',
    transform_config   JSON              DEFAULT NULL COMMENT '转换配置',
    
    -- 状态
    active             BOOLEAN           NOT NULL DEFAULT TRUE,
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (route_id),
    INDEX idx_subscription (subscription_id),
    INDEX idx_source (source_exchange, source_routing_key)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '订阅路由表(消息流转路径)';
```

---

## 订阅模式对比

| 模式 | 英文 | 说明 | 适用场景 |
|------|------|------|----------|
| Shared | 共享订阅 | 多个消费者共享，消息负载均衡 | 任务分发 |
| Exclusive | 独占订阅 | 同一目的地仅一个消费者 | 顺序处理、独占消费 |
| Failover | 故障转移订阅 | 主消费者失效后自动切换备消费者 | 高可用消费 |
| Cluster | 集群订阅 | 消息广播到所有消费者 | 事件分发 |

---

## API 操作

### 创建订阅

```json
POST /api/v1/subscriptions
{
  "subscription_name": "order-processor",
  "vhost": "/",
  "owner_type": "application",
  "owner_id": "order-service-01",
  "destination": {
    "type": "topic",
    "id": "topic-uuid-xxx"
  },
  "filter": {
    "type": "routing_key",
    "pattern": "order.*"
  },
  "subscription_mode": "shared",
  "start_policy": "last"
}
```

### 查询订阅列表

```json
GET /api/v1/subscriptions?vhost=/&status=active&page=1&page_size=20
```

### 暂停订阅

```json
PUT /api/v1/subscriptions/{subscription_id}/pause
{
  "reason": "维护中，暂时停止消费"
}
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
