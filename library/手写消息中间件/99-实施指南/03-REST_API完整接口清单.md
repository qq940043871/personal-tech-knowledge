# REST API 完整接口清单

> 本文件列出消息中间件所有 REST API 接口，按模块组织。

---

## 认证与用户

### 用户管理

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/users` | 创建用户 | `{"username","password","auth_type","vhost","tags"}` | User |
| GET | `/api/v1/users` | 用户列表 | `?vhost=&status=&page=&page_size=` | User[] |
| GET | `/api/v1/users/{user_id}` | 用户详情 | - | User |
| PUT | `/api/v1/users/{user_id}` | 更新用户 | `{"status","tags"}` | User |
| DELETE | `/api/v1/users/{user_id}` | 删除用户 | - | - |
| PUT | `/api/v1/users/{user_id}/password` | 修改密码 | `{"old_password","new_password"}` | - |

### 认证

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/auth/login` | 登录 | `{"username","password"}` | `{token,expires_at}` |
| POST | `/api/v1/auth/logout` | 登出 | - | - |
| POST | `/api/v1/auth/refresh` | 刷新Token | `{"refresh_token"}` | `{token,expires_at}` |

---

## 虚拟主机 (VHost)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/vhosts` | 创建VHost | `{"vhost_name","description"}` | VHost |
| GET | `/api/v1/vhosts` | VHost列表 | `?status=&page=&page_size=` | VHost[] |
| GET | `/api/v1/vhosts/{vhost}` | VHost详情 | - | VHost |
| PUT | `/api/v1/vhosts/{vhost}` | 更新VHost | `{"description","status"}` | VHost |
| DELETE | `/api/v1/vhosts/{vhost}` | 删除VHost | - | - |

---

## 交换机 (Exchange)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/exchanges` | 创建交换机 | 见下方 | Exchange |
| GET | `/api/v1/exchanges` | 交换机列表 | `?vhost=&type=&page=&page_size=` | Exchange[] |
| GET | `/api/v1/exchanges/{exchange_id}` | 交换机详情 | - | Exchange |
| PUT | `/api/v1/exchanges/{exchange_id}` | 更新交换机 | `{"arguments","status"}` | Exchange |
| DELETE | `/api/v1/exchanges/{exchange_id}` | 删除交换机 | - | - |
| GET | `/api/v1/exchanges/{exchange_id}/bindings` | 绑定列表 | `?page=&page_size=` | Binding[] |

**创建交换机请求体：**

```json
{
  "exchange_name": "order.exchange",
  "vhost": "/",
  "exchange_type": "topic",
  "durable": true,
  "auto_delete": false,
  "internal": false,
  "alternate_exchange": "dlx.exchange",
  "arguments": {}
}
```

---

## 队列 (Queue)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/queues` | 创建队列 | 见下方 | Queue |
| GET | `/api/v1/queues` | 队列列表 | `?vhost=&type=&status=&page=&page_size=` | Queue[] |
| GET | `/api/v1/queues/{queue_id}` | 队列详情 | - | Queue |
| GET | `/api/v1/queues/{queue_id}/stats` | 队列统计 | `?period=hour` | QueueStats |
| PUT | `/api/v1/queues/{queue_id}` | 更新队列 | `{"arguments","max_length","overflow_policy"}` | Queue |
| DELETE | `/api/v1/queues/{queue_id}` | 删除队列 | `?if_empty=true` | - |
| PUT | `/api/v1/queues/{queue_id}/pause` | 暂停队列 | - | - |
| PUT | `/api/v1/queues/{queue_id}/resume` | 恢复队列 | - | - |
| DELETE | `/api/v1/queues/{queue_id}/messages` | 清空队列消息 | - | `{purged_count}` |
| GET | `/api/v1/queues/{queue_id}/messages` | 查看队列消息 | `?offset=&limit=` | Message[] |

**创建队列请求体：**

```json
{
  "queue_name": "order.pay.queue",
  "vhost": "/",
  "queue_type": "classic",
  "durable": true,
  "exclusive": false,
  "auto_delete": false,
  "max_length": 100000,
  "max_bytes": 1073741824,
  "overflow_policy": "reject-publish",
  "message_ttl": 86400000,
  "dead_letter_exchange": "dlx.exchange",
  "dead_letter_routing_key": "order.dead",
  "arguments": {}
}
```

---

## 主题 (Topic)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/topics` | 创建主题 | `{"topic_name","vhost","topic_type","retention_days"}` | Topic |
| GET | `/api/v1/topics` | 主题列表 | `?vhost=&page=&page_size=` | Topic[] |
| GET | `/api/v1/topics/{topic_id}` | 主题详情 | - | Topic |
| PUT | `/api/v1/topics/{topic_id}` | 更新主题 | `{"retention_days","message_ttl"}` | Topic |
| DELETE | `/api/v1/topics/{topic_id}` | 删除主题 | - | - |

---

## 绑定 (Binding)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/bindings` | 创建绑定 | 见下方 | Binding |
| GET | `/api/v1/bindings` | 绑定列表 | `?exchange=&queue=&vhost=` | Binding[] |
| DELETE | `/api/v1/bindings/{binding_id}` | 删除绑定 | - | - |

**创建绑定请求体：**

```json
{
  "source_exchange": "order.exchange",
  "destination_type": "queue",
  "destination_name": "order.pay.queue",
  "vhost": "/",
  "binding_key": "order.*.pay",
  "arguments": {}
}
```

---

## 消息 (Message)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/messages` | 发送消息 | 见下方 | Message |
| GET | `/api/v1/messages/{message_id}` | 消息详情 | - | Message |
| GET | `/api/v1/messages/{message_id}/lifecycle` | 生命周期 | - | Lifecycle |
| DELETE | `/api/v1/messages/{message_id}` | 删除消息 | - | - |
| POST | `/api/v1/messages/batch` | 批量发送 | `{"messages": [...]}` | `{sent,failed}` |

**发送消息请求体：**

```json
{
  "exchange": "order.exchange",
  "routing_key": "order.created.pay",
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

---

## 延迟消息 (Delayed Message)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/delayed-messages` | 发送延迟消息 | `{"delay_ms": 1800000, ...}` | DelayedMessage |
| POST | `/api/v1/delayed-messages/scheduled` | 发送定时消息 | `{"scheduled_time": "...", ...}` | ScheduledMessage |
| GET | `/api/v1/delayed-messages/{message_id}` | 查询延迟状态 | - | DelayedMessage |
| DELETE | `/api/v1/delayed-messages/{message_id}` | 取消延迟消息 | - | - |

---

## 消费者 (Consumer)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/api/v1/consumers` | 消费者列表 | `?vhost=&status=&page=&page_size=` | Consumer[] |
| GET | `/api/v1/consumers/{consumer_id}` | 消费者详情 | - | Consumer |
| GET | `/api/v1/consumers/{consumer_id}/subscriptions` | 订阅列表 | - | Subscription[] |
| GET | `/api/v1/consumers/{consumer_id}/lag` | 消费滞后 | - | `{lag,message_count}` |
| PUT | `/api/v1/consumers/{consumer_id}/pause` | 暂停消费者 | - | - |
| PUT | `/api/v1/consumers/{consumer_id}/resume` | 恢复消费者 | - | - |
| GET | `/api/v1/consumers/{consumer_id}/stats` | 消费者统计 | `?period=hour` | ConsumerStats |

---

## 消费者分组 (Consumer Group)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/consumer-groups` | 创建分组 | `{"group_name","vhost","rebalance_strategy"}` | Group |
| GET | `/api/v1/consumer-groups` | 分组列表 | `?vhost=&page=&page_size=` | Group[] |
| GET | `/api/v1/consumer-groups/{group_id}` | 分组详情 | - | Group |
| GET | `/api/v1/consumer-groups/{group_id}/members` | 成员列表 | - | Member[] |
| POST | `/api/v1/consumer-groups/{group_id}/rebalance` | 手动触发Rebalance | - | `{generation_id}` |
| DELETE | `/api/v1/consumer-groups/{group_id}/members/{member_id}` | 移除成员 | - | - |

---

## 生产者 (Producer)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/api/v1/producers` | 生产者列表 | `?vhost=&status=&page=&page_size=` | Producer[] |
| GET | `/api/v1/producers/{producer_id}` | 生产者详情 | - | Producer |
| GET | `/api/v1/producers/{producer_id}/stats` | 生产者统计 | `?period=hour` | ProducerStats |

---

## 订阅 (Subscription)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/subscriptions` | 创建订阅 | `{"destination","filter","start_policy"}` | Subscription |
| GET | `/api/v1/subscriptions` | 订阅列表 | `?vhost=&status=&page=&page_size=` | Subscription[] |
| GET | `/api/v1/subscriptions/{subscription_id}` | 订阅详情 | - | Subscription |
| PUT | `/api/v1/subscriptions/{subscription_id}/pause` | 暂停订阅 | `{"reason"}` | - |
| PUT | `/api/v1/subscriptions/{subscription_id}/resume` | 恢复订阅 | - | - |
| DELETE | `/api/v1/subscriptions/{subscription_id}` | 删除订阅 | - | - |

---

## 事务 (Transaction)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/transactions` | 开启事务 | `{"transaction_type","timeout_ms"}` | Transaction |
| POST | `/api/v1/transactions/{transaction_id}/messages` | 事务内发送 | `{"messages": [...]}` | `{message_ids}` |
| POST | `/api/v1/transactions/{transaction_id}/commit` | 提交事务 | - | `{status,committed_count}` |
| POST | `/api/v1/transactions/{transaction_id}/rollback` | 回滚事务 | - | `{status,rolled_back_count}` |
| GET | `/api/v1/transactions/{transaction_id}` | 事务状态 | - | Transaction |

---

## 死信队列 (Dead Letter)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/api/v1/dead-letters` | 死信列表 | `?status=&reason=&page=&page_size=` | DeadLetter[] |
| GET | `/api/v1/dead-letters/{dlx_record_id}` | 死信详情 | - | DeadLetter |
| POST | `/api/v1/dead-letters/{dlx_record_id}/reprocess` | 重新处理 | `{"target_queue","delay_ms"}` | `{status}` |
| POST | `/api/v1/dead-letters/{dlx_record_id}/discard` | 丢弃 | `{"reason"}` | - |
| POST | `/api/v1/dead-letters/batch-reprocess` | 批量重新处理 | `{"filters","target_queue"}` | `{success_count,fail_count}` |
| POST | `/api/v1/dead-letters/batch-archive` | 批量归档 | `{"filters"}` | `{archived_count}` |

---

## 连接管理 (Connection)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/api/v1/connections` | 连接列表 | `?vhost=&protocol=&status=&page=&page_size=` | Connection[] |
| GET | `/api/v1/connections/{connection_id}` | 连接详情 | - | Connection |
| DELETE | `/api/v1/connections/{connection_id}` | 强制关闭连接 | `{"reason"}` | - |
| GET | `/api/v1/connections/{connection_id}/channels` | 信道列表 | - | Channel[] |

---

## 集群管理 (Cluster)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/api/v1/cluster/nodes` | 节点列表 | `?status=` | Node[] |
| GET | `/api/v1/cluster/nodes/{node_name}` | 节点详情 | - | Node |
| GET | `/api/v1/cluster/health` | 集群健康 | - | `{status,score,issues[]}` |
| POST | `/api/v1/cluster/nodes/{node_name}/restart` | 重启节点 | `{"reason"}` | `{task_id}` |
| GET | `/api/v1/cluster/failover-log` | 故障切换日志 | `?from=&to=` | FailoverRecord[] |
| POST | `/api/v1/cluster/rebalance` | 手动均衡 | - | `{task_id}` |

---

## HA 与镜像 (High Availability)

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/api/v1/ha/policies` | HA策略列表 | - | Policy[] |
| POST | `/api/v1/ha/policies` | 创建HA策略 | `{"pattern","ha_mode","ha_node_count"}` | Policy |
| GET | `/api/v1/ha/mirrors` | 镜像状态 | `?queue_id=` | Mirror[] |
| PUT | `/api/v1/ha/policies/{policy_id}` | 更新HA策略 | `{"ha_mode","ha_node_count"}` | Policy |
| DELETE | `/api/v1/ha/policies/{policy_id}` | 删除HA策略 | - | - |

---

## 安全与权限

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/api/v1/roles` | 角色列表 | - | Role[] |
| POST | `/api/v1/roles` | 创建角色 | `{"role_name","description","parent_role_id"}` | Role |
| GET | `/api/v1/roles/{role_id}` | 角色详情 | - | Role |
| GET | `/api/v1/roles/{role_id}/permissions` | 角色权限 | - | Permission[] |
| POST | `/api/v1/roles/{role_id}/permissions` | 添加权限 | `{"resource_type","resource_name","actions"}` | Permission |
| DELETE | `/api/v1/roles/{role_id}/permissions/{permission_id}` | 删除权限 | - | - |
| POST | `/api/v1/users/{user_id}/roles` | 分配角色 | `{"role_id","vhost"}` | - |
| DELETE | `/api/v1/users/{user_id}/roles/{role_id}` | 撤销角色 | - | - |

---

## 监控指标

| 方法 | 路径 | 说明 | 响应格式 |
|------|------|------|----------|
| GET | `/metrics` | Prometheus格式指标 | Prometheus text |
| GET | `/api/v1/metrics` | JSON格式指标 | `{"metrics": [...]}` |
| GET | `/api/v1/metrics/query` | 查询指标 | `?name=&labels=&from=&to=` | Metric[] |
| GET | `/api/v1/metrics/summary` | 指标汇总 | `?period=hour` | Summary |

---

## 告警

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | `/api/v1/alerts/rules` | 告警规则列表 | - | AlertRule[] |
| POST | `/api/v1/alerts/rules` | 创建告警规则 | 见告警模块 | AlertRule |
| GET | `/api/v1/alerts/rules/{rule_id}` | 规则详情 | - | AlertRule |
| PUT | `/api/v1/alerts/rules/{rule_id}` | 更新规则 | `{"threshold","severity","enabled"}` | AlertRule |
| DELETE | `/api/v1/alerts/rules/{rule_id}` | 删除规则 | - | - |
| GET | `/api/v1/alerts` | 告警记录 | `?status=&severity=&page=&page_size=` | Alert[] |
| PUT | `/api/v1/alerts/{alert_id}/acknowledge` | 确认告警 | `{"note"}` | Alert |
| PUT | `/api/v1/alerts/{alert_id}/silence` | 静默告警 | `{"duration_minutes"}` | Alert |

---

## 运维操作

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/backup/metadata` | 导出元数据备份 | - | BackupFile |
| POST | `/api/v1/backup/queues` | 导出队列配置 | `{"queue_ids": [...]}` | BackupFile |
| POST | `/api/v1/restore/metadata` | 恢复元数据 | `{"backup_file_id"}` | `{restored_count}` |
| GET | `/api/v1/ops/history` | 运维历史 | `?operator=&type=&from=&to=` | OpsRecord[] |

---

## 响应格式

### 成功响应

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "page_size": 20,
    "total": 100,
    "total_pages": 5
  },
  "timestamp": "2026-03-29T20:00:00.000Z"
}
```

### 分页响应

```json
{
  "success": true,
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 100,
    "has_next": true,
    "has_prev": false
  },
  "timestamp": "2026-03-29T20:00:00.000Z"
}
```

### 错误响应

```json
{
  "success": false,
  "error": {
    "code": "QUEUE_NOT_FOUND",
    "message": "队列不存在",
    "detail": "queue_id: xxx 不存在于 vhost: /",
    "trace_id": "abc123def456"
  },
  "timestamp": "2026-03-29T20:00:00.000Z"
}
```

---

*文档版本：v1.0 | 更新日期：2026-03-29*
