# Kafka集群配置与运维

> 模块：运维与集群
> 更新时间：2026-04-06

---

## 一、集群架构

### 1.1 集群拓扑

```
┌─────────────────────────────────────────────────────────────┐
│                      Kafka Cluster                          │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Broker 1 │  │ Broker 2 │  │ Broker 3 │  │ Broker 4 │    │
│  │ Leader   │  │ Follower │  │ Follower │  │ Follower │    │
│  │ P0, P2   │  │ P1, P3   │  │ P0, P2   │  │ P1, P3   │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       │             │             │             │           │
│       └─────────────┴──────┬──────┴─────────────┘           │
│                            │                                │
│                    ┌───────┴───────┐                        │
│                    │   ZooKeeper   │                        │
│                    │   Cluster     │                        │
│                    └───────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 副本机制

```
Topic: my-topic (Partition=3, Replication=3)

Partition 0:
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Broker 1 │  │ Broker 2 │  │ Broker 3 │
│ Leader   │  │ Follower │  │ Follower │
│  ISR     │  │  ISR     │  │  ISR     │
└──────────┘  └──────────┘  └──────────┘

ISR (In-Sync Replicas): 与Leader保持同步的副本集合
```

---

## 二、集群部署

### 2.1 Docker Compose集群

```yaml
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    hostname: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"

  kafka1:
    image: confluentinc/cp-kafka:7.4.0
    hostname: kafka1
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka1:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 3
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2

  kafka2:
    image: confluentinc/cp-kafka:7.4.0
    hostname: kafka2
    depends_on:
      - zookeeper
    ports:
      - "9093:9092"
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka2:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3

  kafka3:
    image: confluentinc/cp-kafka:7.4.0
    hostname: kafka3
    depends_on:
      - zookeeper
    ports:
      - "9094:9092"
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka3:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3
```

### 2.2 Broker配置文件

```properties
broker.id=1

listeners=PLAINTEXT://0.0.0.0:9092
advertised.listeners=PLAINTEXT://kafka1:9092

log.dirs=/data/kafka-logs

num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600

num.partitions=3
default.replication.factor=3

log.retention.hours=168
log.retention.bytes=1073741824
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000

zookeeper.connect=zookeeper1:2181,zookeeper2:2181,zookeeper3:2181
zookeeper.connection.timeout.ms=18000

group.initial.rebalance.delay.ms=0
```

---

## 三、Controller与Leader选举

### 3.1 Controller

```
Controller职责:
1. 管理分区状态
2. 执行分区重分配
3. 管理副本ISR
4. 处理Topic创建/删除

选举过程:
1. Broker启动时尝试在ZK创建/controller临时节点
2. 创建成功的Broker成为Controller
3. 其他Broker监听/controller节点变化
4. Controller故障时重新选举
```

### 3.2 Leader选举

```properties
auto.leader.rebalance.enable=true
leader.imbalance.per.broker.percentage=10
leader.imbalance.check.interval.seconds=300

unclean.leader.election.enable=false

min.insync.replicas=2
```

### 3.3 副本同步

```properties
replica.lag.time.max.ms=30000
replica.socket.timeout.ms=30000
replica.socket.receive.buffer.bytes=65536
replica.fetch.max.bytes=1048576
replica.fetch.wait.max.ms=500
replica.fetch.min.bytes=1
replica.fetch.backoff.ms=1000
replica.fetch.response.max.bytes=10485760
```

---

## 四、集群运维命令

### 4.1 集群信息

```bash
kafka-broker-api-versions.sh --bootstrap-server localhost:9092

kafka-cluster.sh cluster-id --bootstrap-server localhost:9092

kafka-metadata-quorum.sh describe --bootstrap-server localhost:9092
```

### 4.2 Topic运维

```bash
kafka-topics.sh --create \
  --topic my-topic \
  --bootstrap-server localhost:9092 \
  --partitions 6 \
  --replication-factor 3

kafka-topics.sh --describe \
  --topic my-topic \
  --bootstrap-server localhost:9092

kafka-topics.sh --alter \
  --topic my-topic \
  --partitions 12 \
  --bootstrap-server localhost:9092
```

### 4.3 分区重分配

```bash
kafka-reassign-partitions.sh --generate \
  --topics-to-move-json-file topics.json \
  --broker-list "1,2,3" \
  --bootstrap-server localhost:9092

kafka-reassign-partitions.sh --execute \
  --reassignment-json-file reassign.json \
  --bootstrap-server localhost:9092

kafka-reassign-partitions.sh --verify \
  --reassignment-json-file reassign.json \
  --bootstrap-server localhost:9092
```

### 4.4 副本迁移

```json
{
  "version": 1,
  "partitions": [
    {
      "topic": "my-topic",
      "partition": 0,
      "replicas": [1, 2, 3]
    },
    {
      "topic": "my-topic",
      "partition": 1,
      "replicas": [2, 3, 1]
    }
  ]
}
```

---

## 五、监控与告警

### 5.1 关键监控指标

| 指标 | 说明 | 告警阈值 |
|------|------|----------|
| UnderReplicatedPartitions | 副本不足分区数 | > 0 |
| OfflinePartitionsCount | 离线分区数 | > 0 |
| ActiveControllerCount | 活跃Controller数 | != 1 |
| BytesInPerSec | 入站流量 | 根据容量 |
| BytesOutPerSec | 出站流量 | 根据容量 |
| MessagesInPerSec | 消息速率 | 根据容量 |
| RequestLatencyAvg | 请求延迟 | > 100ms |

### 5.2 JMX监控

```bash
export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote \
  -Dcom.sun.management.jmxremote.port=9999 \
  -Dcom.sun.management.jmxremote.ssl=false \
  -Dcom.sun.management.jmxremote.authenticate=false"

bin/kafka-server-start.sh config/server.properties
```

### 5.3 Prometheus + Grafana

```yaml
scrape_configs:
  - job_name: 'kafka'
    static_configs:
      - targets: ['kafka1:9999', 'kafka2:9999', 'kafka3:9999']
```

---

## 六、性能调优

### 6.1 JVM配置

```bash
export KAFKA_HEAP_OPTS="-Xms6g -Xmx6g"
export KAFKA_JVM_PERFORMANCE_OPTS="-XX:+UseG1GC -XX:MaxGCPauseMillis=20 \
  -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent"
```

### 6.2 OS调优

```bash
vm.swappiness=1
vm.dirty_ratio=80
vm.dirty_background_ratio=5
vm.max_map_count=262144
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=65535
net.core.netdev_max_backlog=65535
```

### 6.3 磁盘调优

```bash
blockdev --setra 4096 /dev/sdb

mount -o noatime,nodiratime /dev/sdb /data
```

---

## 七、故障处理

### 7.1 Broker故障

```bash
kafka-broker-api-versions.sh --bootstrap-server localhost:9092

kafka-preferred-replica-election.sh \
  --bootstrap-server localhost:9092
```

### 7.2 数据恢复

```bash
kafka-run-class.sh kafka.tools.DumpLogSegments \
  --files /kafka-logs/my-topic-0/00000000000000000000.log \
  --print-data-log
```

### 7.3 常见问题排查

```bash
kafka-consumer-groups.sh --describe \
  --group my-group \
  --bootstrap-server localhost:9092

kafka-dump-log.sh --files /kafka-logs/my-topic-0/*.log

kafka-run-class.sh kafka.tools.StateChangeLogMerger \
  --logs /kafka-logs/state-change.log \
  --topic my-topic
```

---

*文档完成*
