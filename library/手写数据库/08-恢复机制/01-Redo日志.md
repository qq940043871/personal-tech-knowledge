# Redo日志

> 模块：恢复机制
> 更新时间：2026-03-29

---

## 一、Redo日志原理

```
Redo日志作用：
  - 记录修改后的数据
  - 用于崩溃恢复
  - 实现持久性

特点：
  - 顺序写入，性能高
  - 记录修改后的值
  - 重做已提交事务的修改
```

---

## 二、日志记录

```java
public class RedoLogRecord {
    private long LSN;           // 日志序列号
    private long txId;          // 事务ID
    private long pageId;        // 页ID
    private int offset;         // 行偏移
    private byte[] afterImage;  // 修改后的数据
    private LogType type;      // 日志类型
    
    public byte[] toBytes() {
        ByteBuffer buffer = ByteBuffer.allocate(8 + 8 + 8 + 4 + afterImage.length + 4);
        buffer.putLong(LSN);
        buffer.putLong(txId);
        buffer.putLong(pageId);
        buffer.putInt(offset);
        buffer.put(afterImage);
        buffer.putInt(type.ordinal());
        return buffer.array();
    }
}
```

---

## 三、恢复流程

```java
public class RedoLogRecovery {
    private LogManager logManager;
    
    public void recover() {
        // 1. 找到最后一个检查点
        CheckpointRecord checkpoint = findLastCheckpoint();
        
        // 2. 从检查点开始重做
        long startLSN = checkpoint.getLSN();
        
        // 3. 读取所有日志
        for (LogRecord record : logManager.scanFrom(startLSN)) {
            if (record.getType() == LogType.UPDATE) {
                // 重做修改
                redoUpdate(record);
            }
        }
    }
    
    private void redoUpdate(LogRecord record) {
        // 从磁盘读取页
        Page page = diskManager.readPage(record.getPageId());
        
        // 应用修改
        page.applyUpdate(record.getOffset(), record.getAfterImage());
        
        // 标记为脏页
        bufferPool.markDirty(record.getPageId());
    }
}
```

---

*下一步：Undo日志*
