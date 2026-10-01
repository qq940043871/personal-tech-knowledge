# Kafka存储架构与日志

> 模块：存储机制
> 更新时间：2026-04-06

---

## 一、Kafka存储架构

### 1.1 存储结构

```
Kafka存储层次结构:

┌─────────────────────────────────────────────────────────────┐
│                         Broker                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    Log Dir                           │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │           Topic-Partition                    │    │    │
│  │  │  ┌─────────┐ ┌─────────┐ ┌─────────┐        │    │    │
│  │  │  │Segment 0│ │Segment 1│ │Segment 2│  ...   │    │    │
│  │  │  │ .log    │ │ .log    │ │ .log    │        │    │    │
│  │  │  │ .index  │ │ .index  │ │ .index  │        │    │    │
│  │  │  │ .timeidx│ │ .timeidx│ │ .timeidx│        │    │    │
│  │  │  └─────────┘ └─────────┘ └─────────┘        │    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 日志目录结构

```bash
/kafka-logs/
├── my-topic-0/
│   ├── 00000000000000000000.log      # 日志数据
│   ├── 00000000000000000000.index    # 偏移量索引
│   ├── 00000000000000000000.timeindex # 时间戳索引
│   ├── 00000000000000000000.snapshot
│   └── leader-epoch-checkpoint
├── my-topic-1/
│   └── ...
├── __consumer_offsets-0/
│   └── ...
└── meta.properties
```

---

## 二、日志段(Log Segment)

### 2.1 Segment概念

```
每个分区由多个Segment组成:

Partition (my-topic-0):
┌──────────────────────────────────────────────────────────┐
│  Segment 0          │  Segment 1          │  Segment 2  │
│  offset: 0-999999   │  offset: 1000000+   │  (active)   │
│  (已关闭)           │  (已关闭)           │  (写入中)   │
└──────────────────────────────────────────────────────────┘

Segment文件:
- .log      : 实际消息数据
- .index    : 偏移量索引(稀疏索引)
- .timeindex: 时间戳索引
```

### 2.2 Segment配置

```properties
log.segment.bytes=1073741824
log.segment.ms=604800000
log.roll.ms=604800000
```

### 2.3 索引机制

```
偏移量索引(.index):
┌────────────┬────────────┐
│  Offset    │  Position  │
├────────────┼────────────┤
│     0      │      0     │
│   1024     │   8192     │
│   2048     │  16384     │
│   ...      │    ...     │
└────────────┴────────────┘

查找流程:
1. 二分查找定位到目标Segment
2. 在.index中查找最近的offset
3. 从.log的对应位置顺序扫描
```

---

## 三、消息格式

### 3.1 消息结构

```
Record:
┌─────────────────────────────────────────────────────────┐
│ Length │ CRC │ Magic │ Attributes │ Timestamp │ Key ... │
├─────────────────────────────────────────────────────────┤
│ ... Key │ Value │ Headers                            │
└─────────────────────────────────────────────────────────┘

字段说明:
- Length    : 消息总长度
- CRC       : 校验和
- Magic     : 版本号(0/1/2)
- Attributes: 属性(压缩类型等)
- Timestamp : 时间戳
- Key       : 消息Key
- Value     : 消息体
- Headers   : 自定义头信息
```

### 3.2 批量消息

```
Record Batch:
┌─────────────────────────────────────────────────────────┐
│ Base Offset │ Length │ Partition Leader Epoch │ Magic  │
├─────────────────────────────────────────────────────────┤
│ CRC │ Attributes │ Last Offset Delta │ First Timestamp │
├─────────────────────────────────────────────────────────┤
│ Max Timestamp │ Producer ID │ Producer Epoch │ ...     │
├─────────────────────────────────────────────────────────┤
│ Records (多条消息)                                       │
└─────────────────────────────────────────────────────────┘
```

---

## 四、日志清理策略

### 4.1 删除策略(Delete)

```properties
log.cleanup.policy=delete

log.retention.hours=168
log.retention.minutes=10080
log.retention.ms=604800000

log.retention.bytes=1073741824

log.retention.check.interval.ms=300000
```

### 4.2 压缩策略(Compact)

```properties
log.cleanup.policy=compact

log.cleaner.enable=true
log.cleaner.threads=1
log.cleaner.io.max.bytes.per.second=Double.MaxValue
log.cleaner.dedupe.buffer.size=134217728
log.cleaner.io.buffer.size=524288
log.cleaner.backoff.ms=15000
log.cleaner.min.cleanable.ratio=0.5
log.cleaner.delete.retention.ms=86400000
```

### 4.3 压缩原理

```
Log Compaction过程:

原始日志:
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ K1:1│ K2:2│ K1:3│ K3:4│ K2:5│ K1:6│ K4:7│ K3:8│
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘

压缩后:
┌─────┬─────┬─────┬─────┐
│ K1:6│ K2:5│ K3:8│ K4:7│
└─────┴─────┴─────┴─────┘

保留每个Key的最新值
```

---

## 五、日志分段与滚动

### 5.1 滚动条件

```properties
log.segment.bytes=1073741824

log.roll.ms=604800000
log.roll.hours=168

log.roll.jitter.ms=0
```

### 5.2 文件管理

```bash
kafka-run-class.sh kafka.tools.DumpLogSegments \
  --files /kafka-logs/my-topic-0/00000000000000000000.log \
  --print-data-log

kafka-run-class.sh kafka.tools.DumpLogSegments \
  --files /kafka-logs/my-topic-0/00000000000000000000.index

kafka-log-dirs.sh --describe \
  --bootstrap-server localhost:9092 \
  --topic-list my-topic
```

---

## 六、磁盘存储优化

### 6.1 多目录配置

```properties
log.dirs=/data1/kafka-logs,/data2/kafka-logs,/data3/kafka-logs
```

### 6.2 文件系统建议

```
推荐文件系统: XFS 或 ext4

XFS挂载选项:
mount -o noatime,nodiratime,logbufs=8,logbsize=256k /dev/sdb /data

ext4挂载选项:
mount -o noatime,nodiratime,data=writeback /dev/sdb /data
```

### 6.3 关键配置

```properties
log.flush.interval.messages=10000
log.flush.interval.ms=1000
log.flush.offset.checkpoint.interval.ms=60000
log.flush.scheduler.interval.ms=3000

num.io.threads=8
num.network.threads=3
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
```

---

## 七、存储监控

### 7.1 关键指标

| 指标 | 说明 |
|------|------|
| LogEndOffset | 日志末端偏移量 |
| LogStartOffset | 日志起始偏移量 |
| Size | 分区大小 |
| NumLogSegments | Segment数量 |
| UnderReplicatedPartitions | 副本不足的分区数 |

### 7.2 监控命令

```bash
kafka-log-dirs.sh --describe \
  --bootstrap-server localhost:9092 \
  --topic-list my-topic

kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic my-topic
```

---

*下一步：集群配置与运维*
