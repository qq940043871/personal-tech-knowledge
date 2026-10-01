# Kafka/Hadoop集成

> 模块：应用场景
> 更新时间：2026-04-06

---

## 一、ZooKeeper与Kafka

### 1.1 Kafka依赖ZooKeeper

```
Kafka使用ZooKeeper管理:

┌─────────────────────────────────────────────────────────────┐
│                    ZooKeeper                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ Broker注册  │  │ Topic元数据 │  │ Controller  │         │
│  │ /brokers    │  │ /brokers/   │  │ 选举        │         │
│  │             │  │ topics      │  │             │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │ 消费组Offset│  │ ACL权限     │  │ 配额管理    │         │
│  │ /consumer   │  │ /kafka-acl  │  │ /config     │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 ZooKeeper存储结构

```bash
zkCli.sh -server localhost:2181

ls /brokers/ids
ls /brokers/topics
ls /controller
ls /controller_epoch
ls /admin
ls /config
ls /cluster

get /controller
get /brokers/ids/0
ls /brokers/topics/my-topic/partitions
```

### 1.3 Broker注册

```
Broker启动流程:

1. 在/brokers/ids下创建临时节点
   /brokers/ids/[broker_id]

2. 节点内容:
   {
     "listener_security_protocol_map": {"PLAINTEXT":"PLAINTEXT"},
     "endpoints": ["PLAINTEXT://host:port"],
     "jmx_port": 9999,
     "host": "kafka1",
     "timestamp": "1234567890",
     "port": 9092,
     "version": 4
   }

3. Broker下线时临时节点自动删除
```

### 1.4 Topic元数据

```bash
ls /brokers/topics

ls /brokers/topics/my-topic/partitions

get /brokers/topics/my-topic

get /brokers/topics/my-topic/partitions/0/state
```

### 1.5 Controller选举

```
Controller选举过程:

1. Broker启动时尝试创建/controller临时节点
2. 创建成功的Broker成为Controller
3. 其他Broker监听/controller节点
4. Controller故障时，临时节点删除
5. 其他Broker收到事件，重新竞争创建

/controller节点内容:
{
  "version": 1,
  "brokerid": 1,
  "timestamp": "1234567890"
}
```

---

## 二、ZooKeeper与Hadoop

### 2.1 Hadoop HA架构

```
HDFS HA架构:

┌─────────────────────────────────────────────────────────────┐
│                      ZooKeeper                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Active NameNode选举                    │    │
│  │  /hadoop-ha/nameservice1                            │    │
│  │  ├── ActiveStandbyElectorLock                       │    │
│  │  └── ActiveBreadCrumb                               │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
        ▼                                   ▼
┌───────────────┐                   ┌───────────────┐
│ NameNode1     │                   │ NameNode2     │
│ (Active)      │                   │ (Standby)     │
└───────────────┘                   └───────────────┘
        │                                   │
        └─────────────────┬─────────────────┘
                          │
                  ┌───────▼───────┐
                  │  JournalNode  │
                  │   (共享存储)   │
                  └───────────────┘
```

### 2.2 Hadoop配置

```xml
<property>
  <name>ha.zookeeper.quorum</name>
  <value>zk1:2181,zk2:2181,zk3:2181</value>
</property>

<property>
  <name>ha.zookeeper.session-timeout.ms</name>
  <value>5000</value>
</property>

<property>
  <name>dfs.ha.automatic-failover.enabled</name>
  <value>true</value>
</property>
```

### 2.3 HBase依赖

```
HBase使用ZooKeeper:

1. Master选举
   - 选举Active Master
   - /hbase/master

2. RegionServer注册
   - RegionServer上线注册
   - /hbase/rs

3. 元数据位置
   - hbase:meta表位置
   - /hbase/meta-region-server

4. 集群状态
   - 集群运行状态
   - /hbase/running
```

### 2.4 HBase配置

```xml
<property>
  <name>hbase.zookeeper.quorum</name>
  <value>zk1,zk2,zk3</value>
</property>

<property>
  <name>hbase.zookeeper.property.clientPort</name>
  <value>2181</value>
</property>

<property>
  <name>zookeeper.session.timeout</name>
  <value>90000</value>
</property>

<property>
  <name>hbase.zookeeper.znode.parent</name>
  <value>/hbase</value>
</property>
```

---

## 三、其他系统集成

### 3.1 Dubbo注册中心

```xml
<dubbo:registry address="zookeeper://127.0.0.1:2181" />

<dubbo:registry protocol="zookeeper" address="zk1:2181,zk2:2181,zk3:2181" />
```

```
Dubbo在ZooKeeper的节点结构:

/dubbo
├── com.example.UserService
│   ├── providers
│   │   └── URL编码的服务提供者地址
│   ├── consumers
│   │   └── URL编码的服务消费者地址
│   ├── routers
│   │   └── 路由规则
│   └── configurators
│       └── 动态配置
```

### 3.2 Spring Cloud集成

```yaml
spring:
  cloud:
    zookeeper:
      connect-string: localhost:2181
      discovery:
        enabled: true
        register: true
        instance-id: ${spring.application.name}:${server.port}
        root: /services
```

```java
@SpringBootApplication
@EnableDiscoveryClient
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

### 3.3 Kafka KRaft模式

```
Kafka 2.8+ 支持KRaft模式，不再依赖ZooKeeper:

优点:
1. 简化架构
2. 减少运维复杂度
3. 提高扩展性

配置:
process.roles=broker,controller
controller.quorum.voters=1@host1:9093,2@host2:9093,3@host3:9093

注意:
- 新部署推荐使用KRaft模式
- 现有集群可迁移
- ZooKeeper模式仍支持
```

---

## 四、监控与运维

### 4.1 监控ZooKeeper

```bash
echo mntr | nc localhost 2181

echo stat | nc localhost 2181

echo cons | nc localhost 2181

echo wchs | nc localhost 2181

echo dump | nc localhost 2181
```

### 4.2 关键指标

| 指标 | 说明 | 告警阈值 |
|------|------|----------|
| zk_avg_latency | 平均延迟 | > 10ms |
| zk_max_latency | 最大延迟 | > 100ms |
| zk_packets_received | 收包数 | - |
| zk_packets_sent | 发包数 | - |
| zk_num_alive_connections | 活跃连接数 | - |
| zk_outstanding_requests | 待处理请求数 | > 10 |
| zk_znode_count | ZNode数量 | - |
| zk_watch_count | Watch数量 | - |

### 4.3 运维命令

```bash
zkServer.sh start
zkServer.sh stop
zkServer.sh restart
zkServer.sh status

zkCleanup.sh /data/zookeeper 3

zkTxnLogToolkit.sh dump /data/zookeeper/version-2/log.1
```

---

*文档完成*
