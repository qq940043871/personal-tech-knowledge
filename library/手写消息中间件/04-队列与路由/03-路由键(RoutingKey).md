# 4.3 路由键 (Routing Key)

## 概述

路由键（Routing Key）是消息路由的核心机制。生产者发送消息时指定路由键，交换机根据路由键与绑定键的匹配规则决定消息投递到哪些队列。

## 数据库设计

### 表结构：routing_rule（路由规则表）

```sql
CREATE TABLE routing_rule (
    rule_id            VARCHAR(64)       NOT NULL COMMENT '规则ID',
    vhost              VARCHAR(128)      NOT NULL DEFAULT '/',
    exchange_name      VARCHAR(255)      NOT NULL COMMENT '交换机名称',
    
    -- 规则定义
    rule_name          VARCHAR(255)      NOT NULL COMMENT '规则名称',
    rule_type          ENUM('exact', 'prefix', 'suffix', 'wildcard', 'regex', 'composite') 
                      NOT NULL DEFAULT 'exact' COMMENT '规则类型',
    pattern            VARCHAR(1024)     NOT NULL COMMENT '匹配模式',
    
    -- 目标
    target_queue       VARCHAR(255)      NOT NULL COMMENT '目标队列',
    priority           INT               NOT NULL DEFAULT 0 COMMENT '规则优先级(高优先级先匹配)',
    
    -- 条件
    condition_headers  JSON             DEFAULT NULL COMMENT '附加头条件',
    condition_script    TEXT             DEFAULT NULL COMMENT '条件脚本(可选)',
    
    -- 状态
    active             BOOLEAN           NOT NULL DEFAULT TRUE,
    
    -- 统计
    match_count        BIGINT            NOT NULL DEFAULT 0 COMMENT '匹配次数',
    last_match_at      DATETIME(3)       DEFAULT NULL COMMENT '最后匹配时间',
    
    -- 审计
    created_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at         DATETIME(3)       NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    
    PRIMARY KEY (rule_id),
    INDEX idx_exchange (exchange_name),
    INDEX idx_target (target_queue),
    INDEX idx_priority (exchange_name, priority DESC)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '路由规则表';
```

---

## 路由规则类型

### Exact（精确匹配）

```json
{
  "rule_type": "exact",
  "pattern": "order.created"
}
```
只有 `routing_key = "order.created"` 才匹配。

### Prefix（前缀匹配）

```json
{
  "rule_type": "prefix",
  "pattern": "order."
}
```
所有 `order.*` 开头的都匹配。

### Wildcard（通配符匹配）

```json
{
  "rule_type": "wildcard",
  "pattern": "order.*.pay"
}
```
- `order.created.pay` → ✅ 匹配
- `order.cancelled.pay` → ✅ 匹配
- `order.pay` → ❌ 不匹配

### Regex（正则表达式）

```json
{
  "rule_type": "regex",
  "pattern": "^order\\.(created|updated|cancelled)$"
}
```

### Composite（组合条件）

```json
{
  "rule_type": "composite",
  "pattern": "order.*",
  "condition_headers": {
    "x-match": "any",
    "priority": ["high", "medium"],
    "source": "order-service"
  }
}
```

---

## 路由决策流程

```
消息到达交换机
      │
      ▼
加载该交换机的所有活跃规则（按优先级排序）
      │
      ▼
遍历规则列表
      │
      ├─ 规则1: 匹配? ──是──▶ 投递到目标队列
      │                              │
      │               ├─ stop_on_first = true ──▶ 停止
      │               └─ stop_on_first = false ──▶ 继续下一条规则
      │
      └─ 不匹配 ──▶ 继续下一条规则
```

---

## 路由键命名规范

| 约定 | 格式 | 示例 |
|------|------|------|
| 领域.实体.事件 | `domain.entity.event` | `order.item.added` |
| 环境.服务.动作 | `env.service.action` | `prod.payment.process` |
| 层级路由 | `parent.child.grandchild` | `system.app.module.task` |

最佳实践：使用点分隔的层级结构，最左侧为最宽泛的分类。

---

*文档版本：v1.0 | 更新日期：2026-03-29*
