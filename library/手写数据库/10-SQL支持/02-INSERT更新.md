# UPDATE修改

> 模块：SQL支持
> 更新时间：2026-03-29

---

## 一、UPDATE执行器

```java
public class UpdateExecutor {
    
    public int execute(UpdateStatement stmt) {
        TableSchema schema = catalog.getTableSchema(stmt.getTable());
        Transaction tx = TransactionContext.getCurrent();
        
        // 1. 查找要更新的行
        List<RowPointer> pointers = findRows(stmt.getTable(), stmt.getWhere());
        
        int count = 0;
        for (RowPointer pointer : pointers) {
            // 2. 获取锁
            lockManager.acquireLock(tx.getId(), pointer.getResourceId(), LockMode.X);
            
            // 3. 读取当前行
            Row currentRow = readRow(pointer);
            
            // 4. 生成新行
            Row newRow = applyUpdates(currentRow, stmt.getAssignments());
            
            // 5. 写Undo日志
            logManager.logUpdate(tx.getId(), currentRow, newRow);
            
            // 6. 写入新行
            writeRow(pointer, newRow);
            
            count++;
        }
        
        return count;
    }
    
    private Row applyUpdates(Row row, Map<String, Expression> assignments) {
        Row newRow = row.copy();
        
        for (Map.Entry<String, Expression> entry : assignments.entrySet()) {
            String colName = entry.getKey();
            Expression expr = entry.getValue();
            
            int idx = schema.getColumnIndex(colName);
            Object newValue = Evaluator.evaluate(expr, row);
            newRow.setValue(idx, newValue);
        }
        
        return newRow;
    }
}
```

---

*下一步：DELETE删除*
