# Redis集群搭建与运维

> 模块：Redis学习指南 / 03-集群与运维
> 更新时间：2026-06-20

---

## 一、Redis集群模式

### 1.1 主从复制

```
Master (读写)
    ↓ 复制
Slave1 (只读)
Slave2 (只读)
```

### 1.2 哨兵模式

```
Sentinel1  Sentinel2  Sentinel3
    ↓          ↓          ↓
Master ←→ Slave1 ←→ Slave2
```

### 1.3 Cluster集群

```
Node1 (slot 0-5460)
Node2 (slot 5461-10922)
Node3 (slot 10923-16383)
```

---

## 二、主从复制配置

### 2.1 配置方式

```conf
# slave配置
replicaof 192.168.1.100 6379
masterauth your_password

# 只读模式
replica-read-only yes

# 复制积压缓冲区
repl-backlog-size 256mb
```

### 2.2 动态配置

```bash
# 设置主从关系
REPLICAOF 192.168.1.100 6379

# 取消主从关系
REPLICAOF NO ONE

# 查看复制信息
INFO replication
```

---

## 三、哨兵模式配置

### 3.1 sentinel.conf

```conf
port 26379
sentinel monitor mymaster 192.168.1.100 6379 2
sentinel auth-pass mymaster your_password
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
```

### 3.2 启动哨兵

```bash
redis-sentinel sentinel.conf
```

### 3.3 哨兵命令

```bash
# 查看主节点信息
SENTINEL master mymaster

# 查看从节点
SENTINEL replicas mymaster

# 手动故障转移
SENTINEL failover mymaster
```

---

## 四、Cluster集群配置

### 4.1 集群配置

```conf
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
```

### 4.2 创建集群

```bash
# 创建6节点集群（3主3从）
redis-cli --cluster create \
  192.168.1.101:6379 \
  192.168.1.102:6379 \
  192.168.1.103:6379 \
  192.168.1.104:6379 \
  192.168.1.105:6379 \
  192.168.1.106:6379 \
  --cluster-replicas 1
```

### 4.3 集群操作

```bash
# 查看集群信息
redis-cli -c -h 192.168.1.101 cluster info

# 查看节点信息
redis-cli -c -h 192.168.1.101 cluster nodes

# 添加节点
redis-cli --cluster add-node 192.168.1.107:6379 192.168.1.101:6379

# 删除节点
redis-cli --cluster del-node 192.168.1.101:6379 <node-id>

# 重新分片
redis-cli --cluster reshard 192.168.1.101:6379
```

---

## 五、集群运维

### 5.1 监控指标

```bash
# 集群状态
INFO cluster

# 节点信息
INFO replication

# 内存使用
INFO memory

# 连接数
INFO clients
```

### 5.2 集群健康检查

```bash
# 检查集群
redis-cli --cluster check 192.168.1.101:6379

# 修复集群
redis-cli --cluster fix 192.168.1.101:6379
```

### 5.3 数据迁移

```bash
# 在线迁移槽位
redis-cli --cluster reshard \
  --cluster-from <source-node-id> \
  --cluster-to <target-node-id> \
  --cluster-slots 1000 \
  --cluster-yes 192.168.1.101:6379
```

---

## 六、故障处理

### 6.1 主节点故障

```
1. 哨兵检测到主节点下线
2. 哨兵选举新主节点
3. 其他从节点指向新主节点
4. 客户端重连新主节点
```

### 6.2 集群节点故障

```
1. 集群检测到节点下线
2. 如果是主节点，从节点提升为主节点
3. 如果是从节点，不影响服务
4. 修复后重新加入集群
```

---

## 七、性能优化

### 7.1 复制优化

```conf
# 增大复制积压缓冲区
repl-backlog-size 256mb

# 无盘复制
repl-diskless-sync yes

# 复制缓冲区
client-output-buffer-limit replica 256mb 64mb 60
```

### 7.2 集群优化

```conf
# 节点超时时间
cluster-node-timeout 15000

# 集群总线端口
cluster-bus-port 16379
```

---

## 八、备份恢复

### 8.1 备份策略

```bash
# RDB备份
BGSAVE

# AOF备份
BGREWRITEAOF

# 复制数据文件
cp dump.rdb dump.rdb.bak
```

### 8.2 恢复步骤

```bash
# 1. 停止Redis
redis-cli shutdown

# 2. 替换数据文件
cp dump.rdb.bak dump.rdb

# 3. 启动Redis
redis-server redis.conf
```

---

## 九、最佳实践

1. **使用Cluster** — 生产环境推荐Cluster模式
2. **监控告警** — 监控内存、连接、集群状态
3. **定期备份** — 配置自动备份策略
4. **容量规划** — 预留30%内存空间
5. **网络优化** — 使用专用网络，减少延迟

---

*生产环境建议使用Cluster模式，配合监控告警系统使用。*
