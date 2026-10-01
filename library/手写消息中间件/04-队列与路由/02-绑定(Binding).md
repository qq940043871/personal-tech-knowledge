# 4.2 绑定 (Binding)

## 概述

绑定（Binding）定义了交换机与队列之间的关联关系，包括路由规则。一条消息经过交换机时，根据绑定规则决定投递到哪些队列。

## 数据库设计

### 表结构：binding（绑定关系表）

```sql
CREATE TABLE binding (
    binding_id         VARCHAR(64)       NOT NULL COMMENT '绑定ID(UUID)',
    
    -- 绑定端点
    source_exchange    VARCHAR(255)      NOT NULL COMMENT '源交换机名称',
    destination_type   ENUM('queue', 'exchange') NOT NULL DEFAULT 'queue' COMMENT '目标类型',
    destination_name   VARCHAR(255)      NOT NULL COMMENT '目标队列或交换机名称',
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/',
    
    -- 路由规则
    binding_key        VARCHAR(1024)     DEFAULT '' COMMENT '绑定键(路由匹配规则)',
    
    -- Headers 匹配(Headers交换机使用)
    binding_headers    JSON             DEFAULT NULL COMMENT '头匹配规则',
    /*
    示例:
    {
      "x-match": "all",
      "type": "notification",
      "priority": "high"
    }
    */
    
    -- 绑定属性
    arguments          JSON             DEFAULT NULL COMMENT '扩展参数',
    is_dlx             BOOLEAN           NOT NULL DEFAULT FALSE COMMENT '是否为死信绑定',
    
    -- 状态
    active             BOOLEAN           NOT NULL DEFAULT TRUE COMMENT '是否激活',
    
    -- 统计
    messages_routed    BIGINT            NOT NULL DEFAULT 0 COMMENT '累计路由消息数',
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (binding_id),
    UNIQUE KEY uk_source_dest_key (vhost, source_exchange, destination_type, destination_name, binding_key),
    INDEX idx_source (source_exchange),
    INDEX idx_destination (destination_type, destination_name),
    INDEX idx_active (active)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '绑定关系表';
```

---

## 绑定路由逻辑

```
                    ┌─────────────────────┐
  消息 ───────────▶ │      Exchange       │
  routing_key="order.created.pay"        │
                    └─────────┬───────────┘
                              │
                    匹配所有 Binding 规则
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
    Binding 1:           Binding 2:       Binding 3:
    key="order.*.pay"    key="order.#"    key="*.created.pay"
              │               │               │
              ▼               ▼               ▼
           queue-A          queue-B         queue-C
```

---

## API 操作

### 创建绑定

```json
POST /api/v1/bindings
{
  "source_exchange": "order.exchange",
  "destination_type": "queue",
  "destination_name": "order.pay.queue",
  "binding_key": "order.*.pay"
}
```

### 查询绑定列表

```json
GET /api/v1/bindings?exchange=order.exchange
```

### 删除绑定

```json
DELETE /api/v1/bindings/{binding_id}
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
