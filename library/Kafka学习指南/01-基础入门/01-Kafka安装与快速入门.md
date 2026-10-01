# Kafka安装与快速入门

> 模块：基础入门
> 更新时间：2026-03-29

---

## 一、Kafka概述

### 核心概念

```
┌─────────┐     ┌─────────────────────────────────────┐     ┌──────────┐
│Producer │────▶│           Kafka Cluster            │◀────│ Consumer │
└─────────┘     │  Broker1 │ Broker2 │ Broker3 │ ... │     └──────────┘
                └─────────────────────────────────────┘
                              │
                      ┌───────┴───────┐
                      │  ZooKeeper    │
                      │  (协调服务)   │
                      └───────────────┘
```

### Kafka特点
- **高吞吐**：单节点可达百万级消息/秒
- **持久化**：消息持久化到磁盘
- **分布式**：多Broker集群、分区副本
- **流处理**：支持流处理API

---

## 二、安装方式

### 1. 单机安装（Docker）

```bash
# docker-compose.yml
version: '3'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
```

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down
```

### 2. 传统安装

```bash
# 下载
wget https://archive.apache.org/dist/kafka/3.4.0/kafka_2.13-3.4.0.tgz
tar -xzf kafka_2.13-3.4.0.tgz
cd kafka_2.13-3.4.0

# 启动ZooKeeper
bin/zookeeper-server-start.sh config/zookeeper.properties

# 新开窗口启动Kafka
bin/kafka-server-start.sh config/server.properties
```

---

## 三、快速命令

### Topic管理

```bash
# 创建Topic
kafka-topics.sh --create \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --partitions 3 \
  --replication-factor 1

# 查看Topic列表
kafka-topics.sh --list --bootstrap-server localhost:9092

# 查看Topic详情
kafka-topics.sh --describe --topic my-topic --bootstrap-server localhost:9092

# 删除Topic
kafka-topics.sh --delete --topic my-topic --bootstrap-server localhost:9092

# 修改Partition数
kafka-topics.sh --alter --topic my-topic --partitions 6 --bootstrap-server localhost:9092
```

### 生产消息

```bash
# 命令行生产者
kafka-console-producer.sh --topic my-topic --bootstrap-server localhost:9092
# 输入消息后回车发送

# 带Key的消息
kafka-console-producer.sh --topic my-topic --property "parse.key=true" --bootstrap-server localhost:9092
# 输入格式: key:value
```

### 消费消息

```bash
# 命令行消费者
kafka-console-consumer.sh --topic my-topic --from-beginning --bootstrap-server localhost:9092

# 带分组的消费者
kafka-console-consumer.sh --topic my-topic --group my-group --bootstrap-server localhost:9092

# 查看消费组
kafka-consumer-groups.sh --list --bootstrap-server localhost:9092

# 查看消费组详情
kafka-consumer-groups.sh --describe --group my-group --bootstrap-server localhost:9092
```

---

## 四、Kafka Java客户端

### Maven依赖

```xml
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka-clients</artifactId>
    <version>3.4.0</version>
</dependency>
```

### 生产者示例

```java
import org.apache.kafka.clients.producer.*;
import java.util.Properties;

public class KafkaProducerDemo {
    public static void main(String[] args) {
        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        
        // 可靠性配置
        props.put("acks", "all");           // 所有副本确认
        props.put("retries", 3);           // 重试次数
        props.put("enable.idempotence", true);  // 幂等性
        
        Producer<String, String> producer = new KafkaProducer<>(props);
        
        try {
            for (int i = 0; i < 10; i++) {
                String key = "key-" + i;
                String value = "message-" + i;
                
                ProducerRecord<String, String> record = 
                    new ProducerRecord<>("my-topic", key, value);
                
                // 同步发送
                RecordMetadata metadata = producer.send(record).get();
                System.out.printf("Sent to partition %d, offset %d%n",
                    metadata.partition(), metadata.offset());
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            producer.close();
        }
    }
}
```

### 消费者示例

```java
import org.apache.kafka.clients.consumer.*;
import java.time.Duration;
import java.util.Arrays;
import java.util.Properties;

public class KafkaConsumerDemo {
    public static void main(String[] args) {
        Properties props = new Properties();
        props.put("bootstrap.servers", "localhost:9092");
        props.put("group.id", "my-consumer-group");
        props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
        
        // 自动提交（简单场景）
        props.put("enable.auto.commit", true);
        props.put("auto.commit.interval.ms", 1000);
        
        // 手动提交（精确一次）
        // props.put("enable.auto.commit", false);
        
        KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props);
        consumer.subscribe(Arrays.asList("my-topic"));
        
        try {
            while (true) {
                ConsumerRecords<String, String> records = 
                    consumer.poll(Duration.ofMillis(100));
                
                for (ConsumerRecord<String, String> record : records) {
                    System.out.printf("topic=%s, partition=%d, offset=%d, key=%s, value=%s%n",
                        record.topic(), record.partition(),
                        record.offset(), record.key(), record.value());
                }
                
                // 手动提交偏移量
                // consumer.commitSync();
            }
        } finally {
            consumer.close();
        }
    }
}
```

---

*下一步：核心概念*
