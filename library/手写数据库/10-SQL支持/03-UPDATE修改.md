# DELETE删除

> 模块：SQL支持
> 更新时间：2026-03-29

---

## 一、DELETE执行器

```java
public class DeleteExecutor {
    
    public int execute(DeleteStatement stmt) {
        TableSchema schema = catalog.getTableSchema(stmt.getTable());
        Transaction tx = TransactionContext.getCurrent();
        
        // 1. 查找要删除的行
        List<RowPointer> pointers = findRows(stmt.getTable(), stmt.getWhere());
        
        int count = 0;
        for (RowPointer pointer : pointers) {
            // 2. 获取锁
            lockManager.acquireLock(tx.getId(), pointer.getResourceId(), LockMode.X);
            
            // 3. 读取行数据
            Row row = readRow(pointer);
            
            // 4. 写Undo日志（标记删除）
            logManager.logDelete(tx.getId(), row);
            
            // 5. 标记删除
            markAsDeleted(pointer);
            
            // 6. 更新索引
            updateIndexes(schema, row, null);
            
            count++;
        }
        
        return count;
    }
}
```

---

*下一步：CREATE表创建*
