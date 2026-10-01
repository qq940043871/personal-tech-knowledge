# 主从复制与Sentinel

> 模块：集群与高可用
> 更新时间：2026-04-06

---

## 一、主从复制

### 1.1 主从复制概述

```
主从复制实现数据冗余和读写分离

架构:
┌─────────────────────────────────────────────────────────────┐
│                      主从架构                               │
│                                                             │
│                    ┌───────────┐                            │
│                    │  Master   │                            │
│                    │  (读写)   │                            │
│                    └─────┬─────┘                            │
│                          │ 复制                             │
│           ┌──────────────┼──────────────┐                   │
│           │              │              │                   │
│           ▼              ▼              ▼                   │
│    ┌───────────┐  ┌───────────┐  ┌───────────┐             │
│    │  Slave 1  │  │  Slave 2  │  │  Slave 3  │             │
│    │  (只读)   │  │  (只读)   │  │  (只读)   │             │
│    └───────────┘  └───────────┘  └───────────┘             │
└─────────────────────────────────────────────────────────────┘

优点:
1. 数据冗余 - 多副本存储
2. 读写分离 - 读操作分散到从节点
3. 高可用基础 - 配合Sentinel实现故障转移
```

### 1.2 复制配置

```bash
replicaof 192.168.1.100 6379

replicaof no one

replica-read-only yes

repl-diskless-sync no

repl-diskless-sync-delay 5

repl-timeout 60

repl-backlog-size 1mb

repl-backlog-ttl 3600
```

### 1.3 复制过程

```
主从复制流程:

┌─────────────────────────────────────────────────────────────┐
│  1. 从节点连接主节点                                        │
│     └── 发送 PSYNC 命令                                     │
│                                                             │
│  2. 主节点执行 BGSAVE 生成 RDB                              │
│     └── 发送 RDB 文件给从节点                               │
│                                                             │
│  3. 从节点加载 RDB 文件                                     │
│     └── 清空数据，加载快照                                  │
│                                                             │
│  4. 主节点发送积压缓冲区命令                                │
│     └── 同步期间的写命令                                    │
│                                                             │
│  5. 进入持续同步状态                                        │
│     └── 主节点转发写命令给从节点                            │
└─────────────────────────────────────────────────────────────┘
```

### 1.4 复制命令

```bash
INFO replication

ROLE

REPLICAOF host port

REPLICAOF NO ONE
```

---

## 二、Sentinel哨兵

### 2.1 Sentinel概述

```
Sentinel监控Redis实例，实现自动故障转移

功能:
┌─────────────────────────────────────────────────────────────┐
│  1. 监控(Monitoring)                                        │
│     - 持续检查主从节点运行状态                              │
│                                                             │
│  2. 通知(Notification)                                      │
│     - 实例故障时通知管理员或其他应用                        │
│                                                             │
│  3. 自动故障转移(Automatic Failover)                        │
│     - 主节点故障时自动选举新主节点                          │
│                                                             │
│  4. 配置提供者(Configuration Provider)                      │
│     - 为客户端提供当前主节点地址                            │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Sentinel架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Sentinel架构                             │
│                                                             │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐               │
│  │ Sentinel1 │  │ Sentinel2 │  │ Sentinel3 │               │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘               │
│        │              │              │                      │
│        └──────────────┼──────────────┘                      │
│                       │ 监控                                │
│        ┌──────────────┴──────────────┐                      │
│        │                             │                      │
│  ┌─────▼─────┐                 ┌─────▼─────┐               │
│  │  Master   │ ──────────────▶ │  Slave 1  │               │
│  └───────────┘    复制         └───────────┘               │
│        │                                                    │
│        │ 复制                                               │
│        ▼                                                    │
│  ┌───────────┐                                             │
│  │  Slave 2  │                                             │
│  └───────────┘                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 Sentinel配置

```bash
port 26379

sentinel monitor mymaster 192.168.1.100 6379 2

sentinel down-after-milliseconds mymaster 30000

sentinel parallel-syncs mymaster 1

sentinel failover-timeout mymaster 180000

sentinel auth-pass mymaster password

sentinel notification-script mymaster /path/to/script.sh

sentinel client-reconfig-script mymaster /path/to/script.sh
```

### 2.4 Sentinel命令

```bash
SENTINEL masters

SENTINEL slaves mymaster

SENTINEL master mymaster

SENTINEL get-master-addr-by-name mymaster

SENTINEL reset mymaster

SENTINEL failover mymaster

SENTINEL ckquorum mymaster
```

### 2.5 故障转移流程

```
故障转移流程:

┌─────────────────────────────────────────────────────────────┐
│  1. 主观下线(SDOWN)                                         │
│     - 单个Sentinel检测到主节点不可达                        │
│                                                             │
│  2. 客观下线(ODOWN)                                         │
│     - 多数Sentinel确认主节点不可达                          │
│                                                             │
│  3. 选举领导者Sentinel                                      │
│     - Sentinel之间选举领导者执行故障转移                    │
│                                                             │
│  4. 选举新主节点                                            │
│     - 从健康从节点中选择新主节点                            │
│     - 选择条件: 偏移量大、优先级高                          │
│                                                             │
│  5. 故障转移                                                │
│     - 新主节点执行SLAVEOF NO ONE                            │
│     - 其他从节点复制新主节点                                │
│     - 更新Sentinel配置                                      │
│                                                             │
│  6. 通知客户端                                              │
│     - 客户端获取新主节点地址                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 三、Docker部署

### 3.1 主从复制部署

```yaml
version: '3.8'

services:
  redis-master:
    image: redis:7
    container_name: redis-master
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes

  redis-slave1:
    image: redis:7
    container_name: redis-slave1
    ports:
      - "6380:6379"
    command: redis-server --replicaof redis-master 6379 --appendonly yes
    depends_on:
      - redis-master

  redis-slave2:
    image: redis:7
    container_name: redis-slave2
    ports:
      - "6381:6379"
    command: redis-server --replicaof redis-master 6379 --appendonly yes
    depends_on:
      - redis-master
```

### 3.2 Sentinel部署

```yaml
version: '3.8'

services:
  redis-master:
    image: redis:7
    container_name: redis-master
    ports:
      - "6379:6379"

  redis-slave:
    image: redis:7
    container_name: redis-slave
    ports:
      - "6380:6379"
    command: redis-server --replicaof redis-master 6379

  sentinel1:
    image: redis:7
    container_name: sentinel1
    ports:
      - "26379:26379"
    command: redis-sentinel /etc/redis/sentinel.conf
    volumes:
      - ./sentinel1.conf:/etc/redis/sentinel.conf
    depends_on:
      - redis-master

  sentinel2:
    image: redis:7
    container_name: sentinel2
    ports:
      - "26380:26379"
    command: redis-sentinel /etc/redis/sentinel.conf
    volumes:
      - ./sentinel2.conf:/etc/redis/sentinel.conf
    depends_on:
      - redis-master

  sentinel3:
    image: redis:7
    container_name: sentinel3
    ports:
      - "26381:26379"
    command: redis-sentinel /etc/redis/sentinel.conf
    volumes:
      - ./sentinel3.conf:/etc/redis/sentinel.conf
    depends_on:
      - redis-master
```

---

## 四、Java客户端连接

### 4.1 Jedis连接Sentinel

```java
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisSentinelPool;
import java.util.HashSet;
import java.util.Set;

Set<String> sentinels = new HashSet<>();
sentinels.add("192.168.1.100:26379");
sentinels.add("192.168.1.101:26379");
sentinels.add("192.168.1.102:26379");

JedisSentinelPool pool = new JedisSentinelPool("mymaster", sentinels);

try (Jedis jedis = pool.getResource()) {
    jedis.set("key", "value");
    String value = jedis.get("key");
}

pool.close();
```

### 4.2 Lettuce连接Sentinel

```java
import io.lettuce.core.RedisClient;
import io.lettuce.core.RedisURI;
import io.lettuce.core.api.StatefulRedisConnection;
import io.lettuce.core.sentinel.api.StatefulRedisSentinelConnection;

RedisURI redisUri = RedisURI.Builder
    .sentinel("192.168.1.100", 26379, "mymaster")
    .withSentinel("192.168.1.101", 26379)
    .withSentinel("192.168.1.102", 26379)
    .build();

RedisClient client = RedisClient.create(redisUri);
StatefulRedisConnection<String, String> connection = client.connect();

connection.sync().set("key", "value");
String value = connection.sync().get("key");

connection.close();
client.shutdown();
```

---

## 五、监控与运维

### 5.1 监控指标

```bash
INFO replication

SENTINEL master mymaster
```

| 指标 | 说明 | 告警阈值 |
|------|------|----------|
| connected_slaves | 从节点数量 | < 预期值 |
| master_repl_offset | 复制偏移量 | - |
| slave_repl_offset | 从节点偏移量 | 差异过大 |
| num-other-sentinels | 其他Sentinel数 | < 2 |
| flags | 实例状态 | s_down/o_down |

### 5.2 运维命令

```bash
redis-cli -p 26379 SENTINEL masters
redis-cli -p 26379 SENTINEL slaves mymaster
redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster
redis-cli -p 26379 SENTINEL failover mymaster
```

---

*下一步：缓存与分布式锁*
