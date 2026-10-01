# Zookeeper安装与数据结构

> 模块：基础概念
> 更新时间：2026-03-29

---

## 一、ZooKeeper概述

### 核心作用

```
分布式系统协调中心

┌────────────────────────────────────────────────────────────┐
│                      ZooKeeper                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ 配置管理  │  │  命名服务 │  │  分布式锁 │  │Leader选举 │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└────────────────────────────────────────────────────────────┘
                              ▲
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
    ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
    │  Kafka  │          │ Hadoop  │          │  Dubbo  │
    └─────────┘          └─────────┘          └─────────┘
```

---

## 二、安装部署

### 1. 单机安装

```bash
# 下载
wget https://archive.apache.org/dist/zookeeper/zookeeper-3.8.0/apache-zookeeper-3.8.0-bin.tar.gz
tar -xzf apache-zookeeper-3.8.0-bin.tar.gz
cd apache-zookeeper-3.8.0-bin

# 配置
cp conf/zoo_sample.cfg conf/zoo.cfg

# 编辑zoo.cfg
cat > conf/zoo.cfg << EOF
tickTime=2000
dataDir=/tmp/zookeeper
clientPort=2181
initLimit=10
syncLimit=5
EOF

# 启动
bin/zkServer.sh start

# 连接
bin/zkCli.sh -server localhost:2181
```

### 2. 集群安装

```bash
# zoo.cfg配置
cat > conf/zoo.cfg << EOF
tickTime=2000
dataDir=/data/zookeeper
clientPort=2181
initLimit=10
syncLimit=5

server.1=192.168.1.10:2888:3888
server.2=192.168.1.11:2888:3888
server.3=192.168.1.12:2888:3888
EOF

# 每个节点创建myid
echo "1" > /data/zookeeper/myid  # 节点1
echo "2" > /data/zookeeper/myid  # 节点2
echo "3" > /data/zookeeper/myid  # 节点3
```

### 3. Docker部署

```bash
# docker-compose.yml
version: '3'
services:
  zookeeper:
    image: zookeeper:3.8
    ports:
      - "2181:2181"
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=0.0.0.0:2888:3888;2181 server.2=zookeeper2:2888:3888;2181 server.3=zookeeper3:2888:3888;2181
```

---

## 三、ZNode数据结构

### 节点类型

```bash
# 持久节点（PERSISTENT）- 默认
create /node1 "data"

# 临时节点（EPHEMERAL）- 客户端断开后自动删除
create -e /temp-node "temp"

# 持久顺序节点（EPHEMERAL_SEQUENTIAL）
create -s /seq-node "seq"

# 临时顺序节点（EPHEMERAL_SEQUENTIAL）
create -e -s /temp-seq "tempseq"
```

### 节点信息

```bash
# 查看节点详细信息
get -s /zookeeper

# 输出示例
cZxid = 0x0                    # 创建时的事务ID
ctime = Thu Jan 01 00:00:00 UTC 1970  # 创建时间
mZxid = 0x0                    # 修改时的事务ID
mtime = Thu Jan 01 00:00:00 UTC 1970  # 修改时间
pZxid = 0x0                    # 子节点列表最后修改的事务ID
cversion = 0                   # 子节点版本号
dataVersion = 0               # 数据版本号
aclVersion = 0                # ACL版本号
ephemeralOwner = 0x0          # 临时节点所有者（0x0表示非临时节点）
dataLength = 0                # 数据长度
numChildren = 1               # 子节点数量
```

---

## 四、基本操作

### CLI命令

```bash
# 连接
zkCli.sh -server localhost:2181

# 查看根节点
ls /

# 查看子节点
ls /zookeeper

# 创建节点
create /test "hello"
create /test/child "child data"

# 获取数据
get /test

# 设置数据
set /test "new data"
set /test "version2" 2  # 指定版本号更新

# 监听变化
get -w /test  # 监控数据变化
ls -w /test   # 监控子节点变化

# 删除
delete /test/child
delete /test  # 只能删除没有子节点的节点
rmr /test     # 递归删除
```

### Java客户端（Curator）

```xml
<dependency>
    <groupId>org.apache.curator</groupId>
    <artifactId>curator-recipes</artifactId>
    <version>5.4.0</version>
</dependency>
```

```java
import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.retry.ExponentialBackoffRetry;

public class ZKClientDemo {
    public static void main(String[] args) throws Exception {
        // 创建客户端
        CuratorFramework client = CuratorFrameworkFactory.builder()
            .connectString("localhost:2181")
            .sessionTimeoutMs(5000)
            .retryPolicy(new ExponentialBackoffRetry(1000, 3))
            .build();
        
        client.start();
        
        // 创建节点
        client.create()
            .withMode(CreateMode.PERSISTENT)
            .forPath("/my-node", "data".getBytes());
        
        // 获取数据
        byte[] data = client.getData().forPath("/my-node");
        System.out.println(new String(data));
        
        // 监听变化
        client.getData().usingWatcher(
            (CuratorWatcher) event -> System.out.println("Changed: " + event)
        ).forPath("/my-node");
        
        // 删除节点
        client.delete().forPath("/my-node");
        
        client.close();
    }
}
```

---

## 五、Watch机制

### 原理

```
1. 客户端注册Watch到ZooKeeper
2. 当节点数据变化时，ZooKeeper通知客户端
3. Watch触发后自动失效（一次性）

特点：
- Watch是轻量级的
- Watch在服务端注册，客户端存储
- Watch异步发送，但保证顺序
```

### 事件类型

```bash
# None (-1)        # 客户端连接状态变化
# NodeCreated (1)  # 节点创建
# NodeDeleted (2)  # 节点删除
# NodeDataChanged (3)  # 数据变化
# NodeChildrenChanged (4)  # 子节点变化
```

---

*下一步：分布式协调*
