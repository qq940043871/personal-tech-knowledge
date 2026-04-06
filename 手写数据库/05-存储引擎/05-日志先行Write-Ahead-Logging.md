# 日志先行（Write-Ahead Logging）

> 模块：存储引擎
> 更新时间：2026-03-29

---

## 一、WAL原理

```
WAL核心原则：
  日志必须先写入磁盘，然后才能修改数据页

优势：
  1. 随机写变顺序写
  2. 提高并发性能
  3. 支持崩溃恢复
```

---

## 二、日志结构

```java
public class LogRecord {
    private long LSN;           // 日志序列号
    private long transactionId; // 事务ID
    private short type;         // 日志类型
    private long pageId;        // 页ID
    private byte[] data;        // 日志数据
    
    // 日志类型
    public static final short UPDATE = 1;
    public static final short INSERT = 2;
    public static final short DELETE = 3;
    public static final short COMMIT = 4;
    public static final short ROLLBACK = 5;
    public static final short BEGIN = 6;
}
```

---

## 三、日志写入

```java
public class WALogManager {
    private LogBuffer logBuffer;
    private LogFile logFile;
    private long currentLSN = 0;
    
    public long logUpdate(long txId, long pageId, byte[] oldData, byte[] newData) {
        LogRecord record = new LogRecord();
        record.setLSN(++currentLSN);
        record.setTransactionId(txId);
        record.setType(LogRecord.UPDATE);
        record.setPageId(pageId);
        record.setOldData(oldData);
        record.setNewData(newData);
        
        // 写入日志缓冲区
        byte[] logBytes = record.toBytes();
        logBuffer.append(logBytes);
        
        // 如果需要，刷新到磁盘
        if (logBuffer.shouldFlush()) {
            flushLog();
        }
        
        return currentLSN;
    }
    
    public void commit(long txId) {
        LogRecord record = new LogRecord();
        record.setLSN(++currentLSN);
        record.setTransactionId(txId);
        record.setType(LogRecord.COMMIT);
        
        logBuffer.append(record.toBytes());
        flushLog();
        
        // 清理事务
        transactionManager.commit(txId);
    }
    
    public void flushLog() {
        logBuffer.flush();
        logFile.sync();
    }
}
```

---

## 四、LSN与Checkpoint

```
LSN（Log Sequence Number）：
  - 递增的日志序列号
  - 用于定位日志位置
  - 关联数据页和日志

Checkpoint（检查点）：
  - 将内存中的脏页刷新到磁盘
  - 记录检查点位置
  - 缩短恢复时间
```

---

*下一步：查询计划生成*
