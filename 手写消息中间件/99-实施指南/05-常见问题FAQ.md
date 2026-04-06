# 常见问题 FAQ

> 本文档汇总消息中间件设计与开发中的常见问题及解答。

---

## 一、数据库设计类

### Q1: 消息体（Payload）应该存在哪里？

**A:** 根据消息大小选择存储方式：

| 消息大小 | 推荐存储方式 |
|---------|------------|
| < 1KB | 直接存在 `message.payload` 列（MySQL MEDIUMBLOB）|
| 1KB - 1MB | 存在本地文件系统，数据库存引用路径 |
| > 1MB | 存对象存储（MinIO/S3），数据库存对象地址 |

> 本文档采用 `payload_ref` 字段支持外部存储引用。

---

### Q2: 消息 ID 应该用什么生成策略？

**A:** 推荐使用分布式 ID 生成器：

```java
// 方案1: Twitter Snowflake
SnowflakeIdGenerator.generate(); // 64位: 时间+机器+序列

// 方案2: ULID（比 Snowflake 更友好排序）
ULID.random(); // 26字符, 时间可读

// 方案3: UUID v7（新版，MySQL 8.0+ 支持）
UUID.randomUUID(); // 时间有序
```

**不要用普通 UUID**，因为会打乱 B+Tree 索引。

---

### Q3: 消息状态为什么要单独建表？

**A:** 分离原因：
- 消息表是写入热点，不宜频繁 UPDATE 状态
- 生命周期事件有独立审计需求
- 减少主表锁竞争，提升并发写入性能

---

### Q4: 偏移量（Offset）存数据库还是 Kafka/RocketMQ？

**A:** 根据场景选择：

| 场景 | 推荐存储 |
|------|---------|
| 简单队列，Consumer 数量少 | Redis |
| 复杂 Consumer Group，多消费者 | PostgreSQL/MySQL |
| 超大规模，日志级场景 | 自研 CommitLog |
| 分布式事务一致性要求高 | 嵌入消息存储同一引擎 |

---

### Q5: 如何处理消息乱序问题？

**A:** 三种解决方案：

1. **单分区**：强制同一队列只有一个分区，所有消息有序
2. **序列号**：消息携带全局序列号，消费端按序列号排序
3. **版本向量**：分布式场景下，用向量时钟追踪因果顺序

---

## 二、性能优化类

### Q6: 如何提升消息写入吞吐量？

**A:** 关键优化手段：

```sql
-- 1. 批量写入，减少 IO 次数
INSERT INTO message (...) VALUES (...), (...), (...) -- 批量

-- 2. 异步刷盘，不强求每条同步落盘
ALTER TABLE ... SET innodb_flush_log_at_trx_commit = 2;

-- 3. 减少索引（写入时维护索引开销大）
-- 只建必要的索引，避免冗余

-- 4. 使用顺序追加写入
-- Commit Log 设计，避免随机写
```

---

### Q7: 如何降低消息消费延迟？

**A:** 关键手段：

| 优化方向 | 具体做法 |
|---------|---------|
| 预取优化 | 设置合理的 `prefetch_count`（建议 10-50）|
| 并行消费 | 增加消费者数量 |
| 减少确认延迟 | 使用异步 ACK |
| 减少网络开销 | 批量拉取消息 |
| 热点优化 | Consumer 部署就近 |

---

### Q8: 大队列（百万级以上消息）如何优化？

**A:** 关键手段：

1. **懒加载队列**（Lazy Queue）：消息只在被消费时才加载到内存
2. **分层存储**：热数据存内存/SSD，冷数据归档到对象存储
3. **分桶处理**：将队列按时间/哈希拆分为多个子队列
4. **TTL + 定期清理**：设置合理的消息过期时间

---

## 三、高可用类

### Q9: 如何保证消息不丢失？

**A:** 4 个关键环节都必须做：

```
生产者 ── Broker ── 存储 ── 消费者
```

| 环节 | 保证手段 |
|------|---------|
| 生产者 | 开启 `publisher_confirms`，确认写入后再发送下一条 |
| Broker | 消息持久化（`delivery_mode=2`）+ 副本复制 |
| 存储 | 同步刷盘 + 多副本（Quorum）|
| 消费者 | 手动 ACK，处理成功后再确认 |

---

### Q10: 如何处理"重复消费"问题？

**A:** 幂等消费是唯一出路：

```java
// 方案1: 业务去重表
if (!dedupService.checkAndSet(msgId)) {
    // 已处理过，跳过
    return;
}

// 方案2: 数据库唯一约束
INSERT INTO processed_messages (msg_id, processed_at)
VALUES (#{msgId}, NOW())
ON DUPLICATE KEY UPDATE msg_id = msg_id; // 失败则跳过

// 方案3: 业务状态机
// 订单状态：待支付 → 已支付 → 完成
// 只有"待支付"时才能处理，避免重复
```

---

### Q11: 如何设计故障时的消息重试？

**A:** 指数退避 + 死信兜底：

```python
retry_delays = [
    1000,    # 1秒
    5000,    # 5秒
    30000,   # 30秒
    300000,  # 5分钟
    1800000, # 30分钟
]

for attempt in range(max_attempts):
    try:
        process_message(msg)
        return  # 成功
    except Exception as e:
        if attempt < max_attempts - 1:
            sleep(retry_delays[attempt])
        else:
            send_to_dlx(msg, reason=e)  # 最终死信
```

---

## 四、安全类

### Q12: TLS 双向认证如何配置？

**A:** 流程：

```
客户端                          Broker
  │                               │
  ├── ClientHello ──────────────▶ │
  │                               │
  │◀─── ServerHello + 证书 ──────│
  │                               │
  ├── 验证服务器证书               │
  ├── 发送客户端证书 ────────────▶ │
  │                               │
  │                               ├── 验证客户端证书
  │                               │
  ├── 密钥交换 (加密通道建立) ────▶ │
```

配置文件：
```yaml
security:
  tls:
    enabled: true
    verify_client: require        # 强制双向认证
    cert_file: /path/to/server.crt
    key_file: /path/to/server.key
    ca_file: /path/to/ca.crt     # 客户端证书签发CA
```

---

### Q13: 如何防止未授权访问队列？

**A:** 分层防护：

```
1. 网络层：VPC/防火墙隔离
2. 认证层：用户名密码 / TLS证书
3. ACL层：资源级权限控制
4. 应用层：业务数据校验
```

---

## 五、运维类

### Q14: 如何监控消息延迟？

**A:** 关键指标采集：

```
端到端延迟 = 消费确认时间 - 消息创建时间

lag延迟 = 队列消息数 / 消费速率

指标采集点:
- 消息入队时间戳 (message_timestamp)
- 消息投递时间戳 (delivery_start_time)  
- 消费确认时间戳 (acked_at)
```

Prometheus 查询：
```promql
# 端到端延迟 P99
histogram_quantile(0.99, 
  rate(message_delivery_duration_seconds_bucket[5m])
)

# 消费滞后
queue_messages_ready - consumer_offset
```

---

### Q15: 如何做数据迁移？

**A:** 推荐步骤：

```
1. 迁移前：全量备份 + 记录迁移起始位置
2. 迁移中：新老系统并行运行，实时同步
3. 切换：验证数据一致性后，DNS 切换流量
4. 迁移后：观察一段时间，确认无问题后关闭老系统
```

> 不要在业务高峰期做迁移！

---

### Q16: 如何评估需要多少节点？

**A:** 容量规划公式：

```python
# 吞吐量估算
节点数 = ceil(目标吞吐量 / 单节点吞吐 × 冗余系数)

# 存储估算
存储空间(TB) = (日消息量 × 平均消息大小) / 压缩率 × 保留天数

# 内存估算
内存(GB) = (热点消息数 × 平均消息大小) + 连接缓冲 + JVM堆
```

基准参考（单节点）：
- 小消息 (256B)：10万 msg/s
- 中消息 (1KB)：5万 msg/s  
- 大消息 (10KB)：1万 msg/s

---

*文档版本：v1.0 | 更新日期：2026-03-29*
