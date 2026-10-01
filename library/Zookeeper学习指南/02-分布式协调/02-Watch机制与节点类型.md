# Watch机制与节点类型

> 模块：分布式协调
> 更新时间：2026-04-06

---

## 一、Watch机制

### 1.1 Watch概述

```
Watch是ZooKeeper的事件监听机制

特点:
1. 一次性触发 - 触发后自动失效
2. 异步通知 - 事件异步推送给客户端
3. 轻量级 - 只通知事件类型，不传数据
```

### 1.2 Watch类型

```
┌─────────────────────────────────────────────────────────────┐
│                      Watch类型                              │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   数据Watch      │  │   子节点Watch    │                  │
│  │  (Data Watch)   │  │  (Child Watch)  │                  │
│  │                 │  │                 │                  │
│  │  监听节点数据变化 │  │  监听子节点变化   │                  │
│  │  get -w /path   │  │  ls -w /path    │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 事件类型

| 事件类型 | 触发条件 | Watch类型 |
|----------|----------|-----------|
| NodeCreated | 节点创建 | 数据Watch |
| NodeDeleted | 节点删除 | 数据Watch |
| NodeDataChanged | 数据变化 | 数据Watch |
| NodeChildrenChanged | 子节点变化 | 子节点Watch |
| None | 连接状态变化 | - |

### 1.4 CLI使用Watch

```bash
get -w /my-node

ls -w /my-node

stat -w /my-node
```

### 1.5 Java客户端Watch

```java
import org.apache.zookeeper.*;
import org.apache.zookeeper.data.Stat;

public class WatchDemo implements Watcher {
    private ZooKeeper zk;
    
    public void connect() throws Exception {
        zk = new ZooKeeper("localhost:2181", 3000, this);
    }
    
    public void watchData(String path) throws Exception {
        Stat stat = zk.exists(path, true);
        if (stat != null) {
            byte[] data = zk.getData(path, true, stat);
            System.out.println("Data: " + new String(data));
        }
    }
    
    public void watchChildren(String path) throws Exception {
        zk.getChildren(path, true);
    }
    
    @Override
    public void process(WatchedEvent event) {
        System.out.println("Event: " + event.getType());
        System.out.println("Path: " + event.getPath());
        System.out.println("State: " + event.getState());
        
        try {
            if (event.getType() == Event.EventType.NodeDataChanged) {
                watchData(event.getPath());
            } else if (event.getType() == Event.EventType.NodeChildrenChanged) {
                watchChildren(event.getPath());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

### 1.6 Curator Watch

```java
import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.framework.api.CuratorWatcher;
import org.apache.curator.retry.ExponentialBackoffRetry;
import org.apache.zookeeper.WatchedEvent;

public class CuratorWatchDemo {
    public static void main(String[] args) throws Exception {
        CuratorFramework client = CuratorFrameworkFactory.builder()
            .connectString("localhost:2181")
            .retryPolicy(new ExponentialBackoffRetry(1000, 3))
            .build();
        client.start();
        
        client.getData().usingWatcher(new CuratorWatcher() {
            @Override
            public void process(WatchedEvent event) throws Exception {
                System.out.println("Event: " + event.getType());
                client.getData().usingWatcher(this).forPath(event.getPath());
            }
        }).forPath("/my-node");
        
        PathChildrenCache cache = new PathChildrenCache(client, "/my-node", true);
        cache.getListenable().addListener((c, event) -> {
            System.out.println("Event: " + event.getType());
            System.out.println("Data: " + event.getData());
        });
        cache.start();
        
        Thread.sleep(Long.MAX_VALUE);
    }
}
```

---

## 二、节点类型

### 2.1 持久节点(Persistent)

```
特点:
- 创建后永久存在
- 客户端断开连接不会删除
- 需要手动删除

创建命令:
create /persistent-node "data"

Java代码:
zk.create("/persistent-node", "data".getBytes(),
    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT);
```

### 2.2 临时节点(Ephemeral)

```
特点:
- 客户端会话结束时自动删除
- 不能有子节点
- 用于服务注册、分布式锁

创建命令:
create -e /ephemeral-node "data"

Java代码:
zk.create("/ephemeral-node", "data".getBytes(),
    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL);
```

### 2.3 持久顺序节点(Persistent Sequential)

```
特点:
- 节点名后自动添加序号
- 序号单调递增
- 用于分布式队列、分布式锁

创建命令:
create -s /seq-node "data"
# 创建节点: /seq-node0000000001

Java代码:
zk.create("/seq-node", "data".getBytes(),
    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT_SEQUENTIAL);
```

### 2.4 临时顺序节点(Ephemeral Sequential)

```
特点:
- 结合临时节点和顺序节点特性
- 客户端断开自动删除
- 用于分布式锁、Leader选举

创建命令:
create -e -s /lock- "data"
# 创建节点: /lock-0000000001

Java代码:
zk.create("/lock-", "data".getBytes(),
    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL);
```

### 2.5 容器节点(Container)

```
特点:
- ZooKeeper 3.5+版本支持
- 最后一个子节点被删除后，容器节点自动删除
- 用于分组管理

Java代码:
zk.create("/container", "data".getBytes(),
    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.CONTAINER);
```

### 2.6 TTL节点

```
特点:
- ZooKeeper 3.6+版本支持
- 设置过期时间，到期自动删除
- 需要配置开启

创建命令:
create -t 10000 /ttl-node "data"

Java代码:
zk.create("/ttl-node", "data".getBytes(),
    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT_WITH_TTL, 10000);
```

---

## 三、节点类型对比

| 节点类型 | 持久性 | 顺序性 | 子节点 | 适用场景 |
|----------|--------|--------|--------|----------|
| PERSISTENT | 持久 | 无 | 可有 | 配置存储 |
| EPHEMERAL | 临时 | 无 | 无 | 服务注册 |
| PERSISTENT_SEQUENTIAL | 持久 | 有 | 可有 | 分布式队列 |
| EPHEMERAL_SEQUENTIAL | 临时 | 有 | 无 | 分布式锁 |
| CONTAINER | 持久 | 无 | 可有 | 分组管理 |
| TTL | 定时 | 无 | 可有 | 临时数据 |

---

## 四、ACL权限控制

### 4.1 ACL结构

```
ACL格式: scheme:id:permissions

scheme: 认证方式
- world   - 默认，所有人
- auth    - 已认证用户
- digest  - 用户名密码
- ip      - IP地址
- super   - 超级用户

permissions: 权限
- c (create) - 创建子节点
- r (read)   - 读取节点数据
- w (write)  - 写入节点数据
- d (delete) - 删除子节点
- a (admin)  - 设置ACL权限
```

### 4.2 ACL操作

```bash
getAcl /my-node

setAcl /my-node world:anyone:rwa

setAcl /my-node digest:user:password:crwa

addauth digest user:password
setAcl /my-node auth:user:crwa

setAcl /my-node ip:192.168.1.100:crwa
```

### 4.3 Java ACL

```java
import org.apache.zookeeper.ZooDefs;
import org.apache.zookeeper.data.ACL;
import org.apache.zookeeper.data.Id;
import org.apache.zookeeper.server.auth.DigestAuthenticationProvider;

List<ACL> acls = new ArrayList<>();
acls.add(new ACL(ZooDefs.Perms.ALL, ZooDefs.Ids.ANYONE_ID_UNSAFE));

zk.create("/node", "data".getBytes(), acls, CreateMode.PERSISTENT);

Id id = new Id("digest", DigestAuthenticationProvider.generateDigest("user:password"));
acls.add(new ACL(ZooDefs.Perms.ALL, id));
```

---

## 五、最佳实践

### 5.1 Watch使用建议

```
1. 重新注册Watch
   - Watch触发后需要重新注册
   - 使用Curator的Cache可以自动重新注册

2. 避免大量Watch
   - Watch占用服务端内存
   - 合理控制Watch数量

3. 处理连接断开
   - 连接断开后Watch失效
   - 重连后需要重新注册
```

### 5.2 节点选择建议

```
场景选择:

服务注册 → EPHEMERAL节点
- 服务下线自动删除

分布式锁 → EPHEMERAL_SEQUENTIAL节点
- 自动释放锁
- 顺序节点实现公平锁

配置存储 → PERSISTENT节点
- 持久化配置信息

分布式队列 → PERSISTENT_SEQUENTIAL节点
- 顺序保证
```

---

*下一步：应用场景*
