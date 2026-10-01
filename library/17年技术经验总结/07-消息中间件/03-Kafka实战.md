# Kafka实战

> 模块：消息中间件
> 更新时间：2026-03-28

---

## 一、核心概念

### 1. 架构

```
┌──────────────────────────────────────────────────────────┐
│                    Kafka Cluster                         │
│                                                          │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │   Broker 1      │  │   Broker 2      │              │
│  │  ┌───────────┐  │  │  ┌───────────┐  │              │
│  │  │ Partition 0│  │  │  │ Partition 1│  │              │
│  │  │ (Leader)   │  │  │  │ (Leader)   │  │              │
│  │  └───────────┘  │  │  └───────────┘  │              │
│  │  ┌───────────┐  │  │  ┌───────────┐  │              │
│  │  │ Partition 1│  │  │  │ Partition 0│  │              │
│  │  │ (Follower)│  │  │  │ (Follower)│  │              │
│  │  └───────────┘  │  │  └───────────┘  │              │
│  └─────────────────┘  └─────────────────┘              │
└──────────────────────────────────────────────────────────┘
        ▲                                        │
        │              Producer                  │
        └────────────────────────────────────────┘
        
        ┌────────────────────────────────────────┐
        │              Consumer Group            │
        │  ┌─────────┐  ┌─────────┐  ┌────────┐│
        │  │Consumer1│  │Consumer2│  │Consumer3││
        │  │ partition0│ │ partition1│ │ partition2││
        │  └─────────┘  └─────────┘  └────────┘│
        └────────────────────────────────────────┘
```

### 2. 关键配置

```properties
# broker配置
broker.id=0
listeners=PLAINTEXT://:9092
log.dirs=/data/kafka-logs
num.partitions=3
default.replication.factor=3
min.insync.replicas=2

# 生产者配置
acks=all                    # 等待所有ISR确认
retries=3                   # 重试次数
batch.size=16384            # 批量发送大小
linger.ms=5                 # 等待时间
compression.type=lz4        # 压缩算法

# 消费者配置
group.id=order-group
enable.auto.commit=false    # 手动提交offset
auto.offset.reset=earliest  # 从最早开始消费
max.poll.records=500        # 单次拉取最大记录数
session.timeout.ms=30000    # 会话超时
```

---

## 二、Spring Boot集成

### 1. 配置

```yaml
spring:
  kafka:
    bootstrap-servers: localhost:9092
    producer:
      key-serializer: org.apache.kafka.common.serialization.StringSerializer
      value-serializer: org.apache.kafka.common.serialization.StringSerializer
      acks: all
      retries: 3
    consumer:
      group-id: order-group
      key-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      value-deserializer: org.apache.kafka.common.serialization.StringDeserializer
      auto-offset-reset: earliest
      enable-auto-commit: false
```

### 2. 生产者

```java
@Service
public class OrderProducer {
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    public void sendOrder(Order order) {
        String orderJson = JSON.toJSONString(order);
        
        // 发送消息
        ListenableFuture<SendResult<String, String>> future = 
            kafkaTemplate.send("order-topic", order.getId(), orderJson);
        
        // 回调
        future.addCallback(
            result -> System.out.println("发送成功: " + result.getRecordMetadata()),
            ex -> System.out.println("发送失败: " + ex.getMessage())
        );
    }
    
    // 带分区的发送
    public void sendToPartition(String topic, Integer partition, String key, String value) {
        kafkaTemplate.send(topic, partition, key, value);
    }
}
```

### 3. 消费者

```java
@Component
public class OrderConsumer {
    
    @KafkaListener(topics = "order-topic", groupId = "order-group")
    public void consume(ConsumerRecord<String, String> record, Acknowledgment ack) {
        try {
            Order order = JSON.parseObject(record.value(), Order.class);
            
            // 处理订单
            processOrder(order);
            
            // 手动提交offset
            ack.acknowledge();
        } catch (Exception e) {
            // 处理失败，不提交offset，消息会重新消费
            System.out.println("处理失败: " + e.getMessage());
        }
    }
    
    // 批量消费
    @KafkaListener(topics = "order-topic", containerFactory = "batchFactory")
    public void consumeBatch(List<ConsumerRecord<String, String>> records, Acknowledgment ack) {
        try {
            List<Order> orders = records.stream()
                .map(r -> JSON.parseObject(r.value(), Order.class))
                .collect(Collectors.toList());
            
            // 批量处理
            processOrders(orders);
            
            ack.acknowledge();
        } catch (Exception e) {
            System.out.println("批量处理失败: " + e.getMessage());
        }
    }
}
```

---

## 三、常见问题

### 1. 消息丢失

```java
// 生产者端：
// 配置acks=all，确保所有ISR确认
props.put("acks", "all");
props.put("retries", 3);

// Broker端：
// 配置min.insync.replicas >= 2
// 确保至少2个副本确认

// 消费者端：
// 手动提交offset
props.put("enable.auto.commit", "false");

// 消费成功后再提交
consumer.commitSync();
```

### 2. 消息重复

```java
// 幂等性保证
@Service
public class OrderConsumer {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    @KafkaListener(topics = "order-topic")
    public void consume(ConsumerRecord<String, String> record, Acknowledgment ack) {
        String orderId = extractOrderId(record.value());
        String key = "kafka:order:processed:" + orderId;
        
        // 检查是否已处理
        Boolean isNew = redisTemplate.opsForValue()
            .setIfAbsent(key, "1", Duration.ofDays(7));
        
        if (!isNew) {
            // 已处理，直接确认
            ack.acknowledge();
            return;
        }
        
        try {
            // 处理订单
            processOrder(record.value());
            ack.acknowledge();
        } catch (Exception e) {
            // 处理失败，删除标记
            redisTemplate.delete(key);
        }
    }
}
```

### 3. 消息积压

```bash
# 查看消费者组状态
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group order-group

# 输出：
# TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG
# order-topic     0          1000            50000           49000
# order-topic     1          1000            50000           49000

# LAG就是积压数量

# 解决方案：
# 1. 增加消费者数量
# 2. 增加分区数
# 3. 批量消费
# 4. 异步处理
```

---

## 四、监控运维

### 1. 关键指标

```
Broker指标：
  - MessagesInPerSec：每秒消息数
  - BytesInPerSec：每秒字节数
  - UnderReplicatedPartitions：未同步分区数
  - OfflinePartitionsCount：离线分区数

Producer指标：
  - record-send-rate：发送速率
  - record-error-rate：错误率
  - request-latency-avg：请求延迟

Consumer指标：
  - records-consumed-rate：消费速率
  - records-lag-max：最大延迟
  - commit-rate：提交频率
```

### 2. 常用命令

```bash
# 创建Topic
kafka-topics.sh --create --topic order-topic \
  --partitions 3 --replication-factor 3 \
  --bootstrap-server localhost:9092

# 查看Topic详情
kafka-topics.sh --describe --topic order-topic \
  --bootstrap-server localhost:9092

# 查看消费者组
kafka-consumer-groups.sh --list --bootstrap-server localhost:9092

# 重置offset
kafka-consumer-groups.sh --reset-offsets --to-earliest \
  --topic order-topic --group order-group \
  --bootstrap-server localhost:9092 --execute
```

---

*下一步：消息可靠性与顺序性*
