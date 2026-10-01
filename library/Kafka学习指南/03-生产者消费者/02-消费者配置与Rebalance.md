# 消费者配置与Rebalance

> 模块：生产者消费者
> 更新时间：2026-04-06

---

## 一、消费者核心参数

### 1.1 基础配置

```java
Properties props = new Properties();

props.put("bootstrap.servers", "localhost:9092");
props.put("group.id", "my-consumer-group");
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

props.put("client.id", "my-consumer");
```

### 1.2 消费配置

```java
props.put("auto.offset.reset", "earliest");
props.put("auto.offset.reset", "latest");
props.put("auto.offset.reset", "none");

props.put("enable.auto.commit", true);
props.put("auto.commit.interval.ms", 5000);

props.put("enable.auto.commit", false);

props.put("max.poll.records", 500);
props.put("max.poll.interval.ms", 300000);
props.put("fetch.min.bytes", 1);
props.put("fetch.max.bytes", 52428800);
props.put("fetch.max.wait.ms", 500);
```

### 1.3 会话与心跳配置

```java
props.put("session.timeout.ms", 10000);
props.put("heartbeat.interval.ms", 3000);
props.put("max.poll.interval.ms", 300000);
```

---

## 二、消费者订阅方式

### 2.1 订阅Topic

```java
consumer.subscribe(Arrays.asList("topic1", "topic2"));

consumer.subscribe(Pattern.compile("topic-.*"));

consumer.assign(Arrays.asList(
    new TopicPartition("topic", 0),
    new TopicPartition("topic", 1)
));
```

### 2.2 消费消息

```java
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    
    for (ConsumerRecord<String, String> record : records) {
        System.out.printf("topic=%s, partition=%d, offset=%d, key=%s, value=%s%n",
            record.topic(), record.partition(), record.offset(), 
            record.key(), record.value());
    }
}
```

### 2.3 按分区消费

```java
ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));

for (TopicPartition partition : records.partitions()) {
    List<ConsumerRecord<String, String>> partitionRecords = records.records(partition);
    
    for (ConsumerRecord<String, String> record : partitionRecords) {
        System.out.printf("partition=%d, offset=%d, value=%s%n",
            record.partition(), record.offset(), record.value());
    }
    
    long lastOffset = partitionRecords.get(partitionRecords.size() - 1).offset();
    consumer.commitSync(Collections.singletonMap(
        partition, new OffsetAndMetadata(lastOffset + 1)
    ));
}
```

---

## 三、Offset提交策略

### 3.1 自动提交

```java
props.put("enable.auto.commit", true);
props.put("auto.commit.interval.ms", 5000);

KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    for (ConsumerRecord<String, String> record : records) {
        processMessage(record);
    }
}
```

### 3.2 同步提交

```java
props.put("enable.auto.commit", false);

while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    
    for (ConsumerRecord<String, String> record : records) {
        processMessage(record);
    }
    
    try {
        consumer.commitSync();
    } catch (CommitFailedException e) {
        log.error("提交失败", e);
    }
}
```

### 3.3 异步提交

```java
while (true) {
    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
    
    for (ConsumerRecord<String, String> record : records) {
        processMessage(record);
    }
    
    consumer.commitAsync((offsets, exception) -> {
        if (exception != null) {
            log.error("异步提交失败", exception);
        }
    });
}

try {
    consumer.commitSync();
} finally {
    consumer.close();
}
```

### 3.4 指定Offset提交

```java
ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));

Map<TopicPartition, OffsetAndMetadata> offsets = new HashMap<>();

for (ConsumerRecord<String, String> record : records) {
    processMessage(record);
    
    offsets.put(
        new TopicPartition(record.topic(), record.partition()),
        new OffsetAndMetadata(record.offset() + 1)
    );
}

consumer.commitSync(offsets);
```

---

## 四、Rebalance详解

### 4.1 Rebalance触发条件

```
1. 新消费者加入消费组
2. 消费者主动离开
3. 消费者崩溃（session.timeout.ms超时）
4. 消费者处理超时（max.poll.interval.ms超时）
5. Topic分区数变化
6. 订阅的Topic变化
```

### 4.2 Rebalance问题

```
问题1：消费暂停
- Rebalance期间所有消费者停止消费

问题2：重复消费
- Rebalance可能导致已处理但未提交的消息被重新消费

问题3：消费延迟
- 大量消费者同时Rebalance导致延迟增加
```

### 4.3 Rebalance监听器

```java
consumer.subscribe(Arrays.asList("my-topic"), new ConsumerRebalanceListener() {
    
    @Override
    public void onPartitionsRevoked(Collection<TopicPartition> partitions) {
        System.out.println("分区被回收: " + partitions);
        consumer.commitSync();
    }
    
    @Override
    public void onPartitionsAssigned(Collection<TopicPartition> partitions) {
        System.out.println("分区被分配: " + partitions);
    }
});
```

### 4.4 Rebalance优化配置

```java
props.put("session.timeout.ms", 10000);
props.put("heartbeat.interval.ms", 3000);
props.put("max.poll.interval.ms", 300000);
props.put("max.poll.records", 100);

props.put("partition.assignment.strategy", 
    "org.apache.kafka.clients.consumer.CooperativeStickyAssignor");
```

---

## 五、分区分配策略

### 5.1 RangeAssignor（默认）

```
按分区范围分配

Topic: T1 (3 partitions), T2 (3 partitions)
Consumers: C1, C2

分配结果:
C1: T1-P0, T1-P1, T2-P0, T2-P1
C2: T1-P2, T2-P2
```

### 5.2 RoundRobinAssignor

```
轮询分配

Topic: T1 (3 partitions), T2 (3 partitions)
Consumers: C1, C2

分配结果:
C1: T1-P0, T1-P2, T2-P1
C2: T1-P1, T2-P0, T2-P2
```

### 5.3 StickyAssignor

```
粘性分配 - 尽量保持原有分配

优点:
1. Rebalance时尽量保持原有分配
2. 减少不必要的分区迁移
```

### 5.4 CooperativeStickyAssignor

```
协作粘性分配 - 渐进式Rebalance

优点:
1. 避免Stop-The-World
2. 逐步迁移分区
3. 减少消费中断时间
```

---

## 六、消费者配置详解

### 6.1 完整配置示例

```java
Properties props = new Properties();

props.put("bootstrap.servers", "kafka1:9092,kafka2:9092,kafka3:9092");
props.put("group.id", "order-consumer-group");
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");

props.put("auto.offset.reset", "earliest");
props.put("enable.auto.commit", false);

props.put("max.poll.records", 500);
props.put("max.poll.interval.ms", 300000);
props.put("fetch.min.bytes", 1);
props.put("fetch.max.bytes", 52428800);
props.put("fetch.max.wait.ms", 500);

props.put("session.timeout.ms", 10000);
props.put("heartbeat.interval.ms", 3000);

props.put("partition.assignment.strategy", 
    "org.apache.kafka.clients.consumer.CooperativeStickyAssignor");

props.put("client.id", "order-service-consumer");

KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
```

### 6.2 参数说明表

| 参数 | 默认值 | 说明 |
|------|--------|------|
| group.id | - | 消费组ID（必填） |
| auto.offset.reset | latest | 无Offset时的行为 |
| enable.auto.commit | true | 是否自动提交 |
| auto.commit.interval.ms | 5000 | 自动提交间隔 |
| max.poll.records | 500 | 单次拉取最大记录数 |
| max.poll.interval.ms | 300000 | 两次poll最大间隔 |
| session.timeout.ms | 10000 | 会话超时时间 |
| heartbeat.interval.ms | 3000 | 心跳间隔 |

---

## 七、消费者最佳实践

### 7.1 高吞吐配置

```java
props.put("max.poll.records", 1000);
props.put("fetch.min.bytes", 1024 * 1024);
props.put("fetch.max.wait.ms", 1000);
```

### 7.2 低延迟配置

```java
props.put("max.poll.records", 100);
props.put("fetch.min.bytes", 1);
props.put("fetch.max.wait.ms", 100);
```

### 7.3 优雅关闭

```java
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    consumer.wakeup();
}));

try {
    while (true) {
        ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
        // 处理消息
    }
} catch (WakeupException e) {
    // 忽略，正常关闭
} finally {
    try {
        consumer.commitSync();
    } finally {
        consumer.close();
    }
}
```

---

*下一步：存储机制*
