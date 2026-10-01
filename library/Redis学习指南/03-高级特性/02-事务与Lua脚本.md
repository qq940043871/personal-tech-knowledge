# 事务与Lua脚本

> 模块：高级特性
> 更新时间：2026-04-06

---

## 一、Redis事务

### 1.1 事务概述

```
Redis事务是一组命令的集合

特点:
┌─────────────────────────────────────────────────────────────┐
│  1. 原子性     - 命令要么全部执行，要么全部不执行          │
│  2. 隔离性     - 事务执行期间不会被其他命令打断            │
│  3. 无回滚     - 不支持回滚，出错后继续执行                │
└─────────────────────────────────────────────────────────────┘

注意: Redis事务不是严格的ACID事务
```

### 1.2 事务命令

```bash
MULTI

EXEC

DISCARD

WATCH key1 key2

UNWATCH
```

### 1.3 事务执行流程

```
事务执行流程:

┌─────────────────────────────────────────────────────────────┐
│  Client                        Redis Server                 │
│    │                               │                        │
│    │──── MULTI ───────────────────▶│                        │
│    │                               │ 开始事务               │
│    │──── SET k1 v1 ───────────────▶│ 命令入队               │
│    │──── SET k2 v2 ───────────────▶│ 命令入队               │
│    │──── INCR k3 ─────────────────▶│ 命令入队               │
│    │──── EXEC ────────────────────▶│ 执行队列命令           │
│    │◀────────── 结果 ─────────────│ 返回结果               │
│    │                               │                        │
└─────────────────────────────────────────────────────────────┘
```

### 1.4 基本事务

```bash
MULTI
SET account:a 100
SET account:b 50
EXEC

MULTI
SET key1 value1
SET key2 value2
DISCARD
```

### 1.5 WATCH乐观锁

```bash
WATCH balance

balance = GET balance
if balance >= 100:
    MULTI
    DECRBY balance 100
    EXEC
else:
    UNWATCH

WATCH key
MULTI
SET key newvalue
EXEC
```

### 1.6 事务错误处理

```bash
MULTI
SET key value
INCR key
EXEC

MULTI
SET key value
INCR nonexist
SET key2 value2
EXEC
```

### 1.7 Java事务

```java
Transaction tx = jedis.multi();

tx.set("key1", "value1");
tx.set("key2", "value2");
tx.incr("counter");

List<Object> results = tx.exec();

tx.discard();
```

```java
jedis.watch("balance");

String balance = jedis.get("balance");
if (Integer.parseInt(balance) >= 100) {
    Transaction tx = jedis.multi();
    tx.decrBy("balance", 100);
    tx.exec();
} else {
    jedis.unwatch();
}
```

---

## 二、Lua脚本

### 2.1 Lua概述

```
Lua脚本在Redis中原子执行

优点:
┌─────────────────────────────────────────────────────────────┐
│  1. 原子性     - 整个脚本作为一个整体执行                  │
│  2. 减少网络   - 多个命令一次发送                          │
│  3. 复用性     - 脚本可缓存复用                            │
│  4. 灵活性     - 支持复杂逻辑                              │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 EVAL命令

```bash
EVAL script numkeys key1 key2 ... arg1 arg2 ...

EVAL "return redis.call('GET', KEYS[1])" 1 mykey

EVAL "return redis.call('SET', KEYS[1], ARGV[1])" 1 mykey myvalue

EVAL "return {KEYS[1], KEYS[2], ARGV[1], ARGV[2]}" 2 key1 key2 arg1 arg2
```

### 2.3 脚本缓存

```bash
SCRIPT LOAD script

SCRIPT LOAD "return redis.call('GET', KEYS[1])"
# 返回: "sha1_hash"

EVALSHA sha1 numkeys key1 key2 ... arg1 arg2 ...

EVALSHA "abc123..." 1 mykey

SCRIPT EXISTS sha1 sha2 ...

SCRIPT FLUSH

SCRIPT KILL
```

### 2.4 常用Lua脚本

```lua
if redis.call('GET', KEYS[1]) == ARGV[1] then
    return redis.call('DEL', KEYS[1])
else
    return 0
end
```

```lua
local current = redis.call('GET', KEYS[1])
if current == false then
    redis.call('SET', KEYS[1], ARGV[1])
    return 1
end
return 0
```

```lua
local current = redis.call('GET', KEYS[1])
if current == ARGV[1] then
    redis.call('SET', KEYS[1], ARGV[2])
    return 1
end
return 0
```

### 2.5 Java执行Lua

```java
String script = "if redis.call('GET', KEYS[1]) == ARGV[1] then " +
                "    return redis.call('DEL', KEYS[1]) " +
                "else " +
                "    return 0 " +
                "end";

Object result = jedis.eval(script, 
    Collections.singletonList("lock:key"), 
    Collections.singletonList("uuid"));

String sha = jedis.scriptLoad(script);
Object result = jedis.evalsha(sha, 
    Collections.singletonList("lock:key"), 
    Collections.singletonList("uuid"));
```

---

## 三、分布式锁实现

### 3.1 简单分布式锁

```lua
if redis.call('SETNX', KEYS[1], ARGV[1]) == 1 then
    redis.call('EXPIRE', KEYS[1], ARGV[2])
    return 1
end
return 0
```

### 3.2 Redisson分布式锁

```java
import org.redisson.Redisson;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.redisson.config.Config;

Config config = new Config();
config.useSingleServer()
    .setAddress("redis://localhost:6379")
    .setPassword("password");

RedissonClient redisson = Redisson.create(config);

RLock lock = redisson.getLock("myLock");

try {
    lock.lock();
    
    lock.lock(10, TimeUnit.SECONDS);
    
    if (lock.tryLock(5, 10, TimeUnit.SECONDS)) {
        try {
            System.out.println("获得锁");
        } finally {
            lock.unlock();
        }
    }
} finally {
    lock.unlock();
}
```

### 3.3 公平锁

```java
RLock fairLock = redisson.getFairLock("fairLock");

fairLock.lock();
try {
    System.out.println("公平锁");
} finally {
    fairLock.unlock();
}
```

### 3.4 读写锁

```java
RReadWriteLock rwLock = redisson.getReadWriteLock("rwLock");

rwLock.readLock().lock();
try {
    System.out.println("读锁");
} finally {
    rwLock.readLock().unlock();
}

rwLock.writeLock().lock();
try {
    System.out.println("写锁");
} finally {
    rwLock.writeLock().unlock();
}
```

---

## 四、Pipeline管道

### 4.1 Pipeline概述

```
Pipeline批量执行命令，减少网络往返

普通模式:
┌─────────────────────────────────────────────────────────────┐
│  Client                        Redis Server                 │
│    │──── 命令1 ─────────────────▶│                          │
│    │◀───── 响应1 ────────────────│                          │
│    │──── 命令2 ─────────────────▶│                          │
│    │◀───── 响应2 ────────────────│                          │
│    │──── 命令3 ─────────────────▶│                          │
│    │◀───── 响应3 ────────────────│                          │
│    共6次网络往返                                           │
└─────────────────────────────────────────────────────────────┘

Pipeline模式:
┌─────────────────────────────────────────────────────────────┐
│  Client                        Redis Server                 │
│    │──── 命令1 ─────────────────▶│                          │
│    │──── 命令2 ─────────────────▶│                          │
│    │──── 命令3 ─────────────────▶│                          │
│    │◀───── 响应1 ────────────────│                          │
│    │◀───── 响应2 ────────────────│                          │
│    │◀───── 响应3 ────────────────│                          │
│    共2次网络往返                                           │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Java Pipeline

```java
Pipeline pipeline = jedis.pipelined();

pipeline.set("key1", "value1");
pipeline.set("key2", "value2");
pipeline.set("key3", "value3");
pipeline.get("key1");
pipeline.get("key2");
pipeline.get("key3");

List<Object> results = pipeline.syncAndReturnAll();

pipeline.sync();
```

### 4.3 Pipeline事务

```java
Pipeline pipeline = jedis.pipelined();
pipeline.multi();

pipeline.set("key1", "value1");
pipeline.set("key2", "value2");
pipeline.incr("counter");

Response<List<Object>> response = pipeline.exec();
pipeline.sync();

List<Object> results = response.get();
```

---

## 五、最佳实践

### 5.1 事务使用建议

```
1. 避免大事务
   - 事务命令不宜过多
   - 避免长时间阻塞

2. WATCH使用场景
   - 适合读多写少场景
   - 冲突率高时考虑其他方案

3. 错误处理
   - 注意命令语法错误
   - 处理EXEC返回结果
```

### 5.2 Lua脚本建议

```
1. 脚本不宜过长
   - 避免复杂计算
   - 控制执行时间

2. 使用SCRIPT LOAD
   - 缓存脚本减少传输
   - 使用EVALSHA执行

3. 参数化
   - 使用KEYS和ARGV传参
   - 避免硬编码
```

---

*下一步：主从复制与Sentinel*
