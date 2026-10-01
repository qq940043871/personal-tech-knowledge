# Redis安装与基础操作

> 模块：Redis学习指南 / 01-基础入门
> 更新时间：2026-06-20

---

## 一、Redis简介

Redis（Remote Dictionary Server）是开源的内存数据结构存储系统，可用作数据库、缓存和消息队列。

### 核心特性
- **高性能** — 读写10万+ QPS
- **丰富数据结构** — String/List/Hash/Set/ZSet等
- **持久化** — RDB/AOF两种方式
- **高可用** — 主从复制、哨兵、集群

---

## 二、安装部署

### 2.1 Docker安装（推荐）

```bash
# 拉取镜像
docker pull redis:7-alpine

# 启动容器
docker run -d \
  --name redis \
  -p 6379:6379 \
  -v /data/redis:/data \
  redis:7-alpine redis-server --appendonly yes

# 连接Redis
docker exec -it redis redis-cli
```

### 2.2 源码编译安装

```bash
# 下载
wget https://download.redis.io/releases/redis-7.2.3.tar.gz
tar xzf redis-7.2.3.tar.gz
cd redis-7.2.3

# 编译
make

# 启动
src/redis-server redis.conf
```

### 2.3 配置文件

```conf
# redis.conf
bind 0.0.0.0
port 6379
daemonize yes
requirepass your_password
dir /data/redis
appendonly yes
maxmemory 1gb
maxmemory-policy allkeys-lru
```

---

## 三、基础命令

### 3.1 连接Redis

```bash
# 本地连接
redis-cli

# 远程连接
redis-cli -h 192.168.1.100 -p 6379 -a password

# 认证
AUTH password
```

### 3.2 Key操作

```bash
# 设置Key
SET user:1 "Alice"

# 获取Key
GET user:1

# 删除Key
DEL user:1

# 检查Key是否存在
EXISTS user:1

# 设置过期时间（秒）
EXPIRE user:1 3600

# 查看剩余时间
TTL user:1

# 查看所有Key
KEYS user:*

# 查看Key类型
TYPE user:1
```

### 3.3 数据库操作

```bash
# 切换数据库（0-15）
SELECT 0
SELECT 1

# 查看当前数据库Key数量
DBSIZE

# 清空当前数据库
FLUSHDB

# 清空所有数据库
FLUSHALL
```

---

## 四、数据类型概览

| 类型 | 说明 | 示例 |
|------|------|------|
| String | 字符串 | `SET name "Alice"` |
| List | 双向链表 | `LPUSH list "a" "b"` |
| Hash | 哈希表 | `HSET user name "Alice"` |
| Set | 无序集合 | `SADD set "a" "b"` |
| ZSet | 有序集合 | `ZADD rank 100 "Alice"` |

---

## 五、图形化工具

### 5.1 RedisInsight

Redis官方GUI工具，支持数据浏览、监控、CLI。

### 5.2 Another Redis Desktop Manager

开源免费的Redis桌面客户端，支持Windows/Mac/Linux。

### 5.3 Redis Commander

Web端Redis管理工具，Docker部署：

```bash
docker run -d --name redis-commander \
  -p 8081:8081 \
  --env REDIS_HOSTS=local:redis:6379 \
  rediscommander/redis-commander
```

---

## 六、安全配置

```conf
# 设置密码
requirepass your_password

# 绑定地址
bind 127.0.0.1

# 禁用危险命令
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""

# 启用TLS
tls-port 6380
tls-cert-file /path/to/redis.crt
tls-key-file /path/to/redis.key
```

---

## 七、性能测试

```bash
# 使用redis-benchmark
redis-benchmark -h 127.0.0.1 -p 6379 -c 100 -n 100000

# 测试结果
SET: 112359.55 requests per second
GET: 113636.36 requests per second
```

---

## 八、常见问题

| 问题 | 解决方案 |
|------|---------|
| 连接被拒绝 | 检查bind配置和防火墙 |
| 认证失败 | 检查requirepass配置 |
| 内存不足 | 调整maxmemory或淘汰策略 |
| 持久化失败 | 检查磁盘空间和权限 |

---

*建议从Docker方式安装Redis开始学习。*
