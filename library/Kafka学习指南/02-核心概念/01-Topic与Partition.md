# Topic与Partition

> 模块：核心概念
> 更新时间：2026-04-06

---

## 一、Topic概述

### 1.1 Topic概念

```
Topic是Kafka中消息的逻辑分类

┌─────────────────────────────────────────────────────────────┐
│                      Topic: orders                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ Partition 0 │  │ Partition 1 │  │ Partition 2 │          │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │          │
│  │ │ msg1    │ │  │ │ msg2    │ │  │ │ msg3    │ │          │
│  │ │ msg4    │ │  │ │ msg5    │ │  │ │ msg6    │ │          │
│  │ │ msg7    │ │  │ │ msg8    │ │  │ │ msg9    │ │          │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Topic特点

- **逻辑分类**：消息的第一级分类
- **多分区**：一个Topic可分为多个Partition
- **并行处理**：不同Partition可并行消费
- **顺序保证**：同一Partition内消息有序

---

## 二、Partition详解

### 2.1 Partition作用

```
1. 提高并发能力 - 多分区可并行读写
2. 扩展存储 - 分区分布在不同Broker
3. 容错能力 - 每个分区有多个副本
```

### 2.2 分区策略

```java
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

Producer<String, String> producer = new KafkaProducer<>(props);

producer.send(new ProducerRecord<>("topic", "key", "value"));

producer.send(new ProducerRecord<>("topic", 0, "key", "value"));

producer.send(new ProducerRecord<>("topic", null, "value"));
```

### 2.3 自定义分区器

```java
import org.apache.kafka.clients.producer.Partitioner;
import org.apache.kafka.common.Cluster;
import org.apache.kafka.common.PartitionInfo;
import java.util.List;
import java.util.Map;

public class CustomPartitioner implements Partitioner {
    
    @Override
    public int partition(String topic, Object key, byte[] keyBytes,
                         Object value, byte[] valueBytes, Cluster cluster) {
        List<PartitionInfo> partitions = cluster.partitionsForTopic(topic);
        int numPartitions = partitions.size();
        
        if (key == null) {
            return 0;
        }
        
        String keyStr = key.toString();
        if (keyStr.startsWith("order_")) {
            return 0;
        } else if (keyStr.startsWith("payment_")) {
            return 1;
        } else {
            return Math.abs(key.hashCode()) % numPartitions;
        }
    }
    
    @Override
    public void close() {}
    
    @Override
    public void configure(Map<String, ?> configs) {}
}

props.put("partitioner.class", "com.example.CustomPartitioner");
```

---

## 三、Topic管理

### 3.1 创建Topic

```bash
kafka-topics.sh --create \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 2

kafka-topics.sh --create \
  --topic orders \
  --bootstrap-server localhost:9092 \
  --partitions 6 \
  --replication-factor 3 \
  --config retention.ms=86400000 \
  --config cleanup.policy=delete
```

### 3.2 查看Topic

```bash
kafka-topics.sh --list --bootstrap-server localhost:9092

kafka-topics.sh --describe --topic my-topic --bootstrap-server localhost:9092

kafka-topics.sh --describe --bootstrap-server localhost:9092
```

### 3.3 修改Topic

```bash
kafka-topics.sh --alter \
  --topic my-topic \
  --partitions 6 \
  --bootstrap-server localhost:9092

kafka-configs.sh --alter \
  --entity-type topics \
  --entity-name my-topic \
  --add-config retention.ms=604800000 \
  --bootstrap-server localhost:9092

kafka-configs.sh --alter \
  --entity-type topics \
  --entity-name my-topic \
  --delete-config retention.ms \
  --bootstrap-server localhost:9092
```

### 3.4 删除Topic

```bash
kafka-topics.sh --delete --topic my-topic --bootstrap-server localhost:9092
```

---

## 四、分区数量设计

### 4.1 分区数计算

```
分区数 = 目标吞吐量 / 单分区吞吐量

示例：
- 目标吞吐量：100 MB/s
- 单分区吞吐量：20 MB/s
- 分区数 = 100 / 20 = 5
```

### 4.2 分区数建议

| 场景 | 建议分区数 | 说明 |
|------|-----------|------|
| 小规模 | 3-6 | 单机或小集群 |
| 中规模 | 12-24 | 多Broker集群 |
| 大规模 | 48-96 | 大型集群 |
| 超大规模 | 100+ | 需要评估性能影响 |

### 4.3 分区数过多的问题

```
1. 客户端内存占用增加
2. 故障恢复时间变长
3. 文件句柄开销增加
4. ZooKeeper负载增加
```

---

## 五、Topic配置参数

### 5.1 常用配置

| 参数 | 默认值 | 说明 |
|------|--------|------|
| num.partitions | 1 | 默认分区数 |
| default.replication.factor | 1 | 默认副本数 |
| retention.ms | 604800000(7天) | 消息保留时间 |
| retention.bytes | -1 | 每个分区保留字节数 |
| segment.bytes | 1073741824(1GB) | 日志段大小 |
| cleanup.policy | delete | 清理策略(delete/compact) |
| max.message.bytes | 1048588 | 单条消息最大字节数 |

### 5.2 配置示例

```bash
kafka-topics.sh --create \
  --topic important-events \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 3 \
  --config retention.ms=2592000000 \
  --config cleanup.policy=compact \
  --config min.cleanable.dirty.ratio=0.1
```

---

## 六、Java操作Topic

```java
import org.apache.kafka.clients.admin.*;
import java.util.*;

public class TopicAdminDemo {
    public static void main(String[] args) throws Exception {
        Properties props = new Properties();
        props.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        
        AdminClient admin = AdminClient.create(props);
        
        NewTopic newTopic = new NewTopic("new-topic", 3, (short) 1);
        admin.createTopics(Collections.singleton(newTopic));
        
        DescribeTopicsResult result = admin.describeTopics(Collections.singleton("new-topic"));
        result.all().get().forEach((name, desc) -> {
            System.out.println("Topic: " + name);
            System.out.println("Partitions: " + desc.partitions().size());
        });
        
        ListTopicsResult topics = admin.listTopics();
        topics.names().get().forEach(System.out::println);
        
        admin.deleteTopics(Collections.singleton("new-topic"));
        
        admin.close();
    }
}
```

---

*下一步：消息偏移量与消费组*
