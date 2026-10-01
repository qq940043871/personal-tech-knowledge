# INSERT更新

> 模块：SQL支持
> 更新时间：2026-03-29

---

## 一、INSERT执行器

```java
public class InsertExecutor {
    private Catalog catalog;
    private BufferPool bufferPool;
    private LockManager lockManager;
    private LogManager logManager;
    
    public int execute(InsertStatement stmt) {
        TableSchema schema = catalog.getTableSchema(stmt.getTable());
        Transaction tx = TransactionContext.getCurrent();
        
        int count = 0;
        for (List<Expression> values : stmt.getValuesLists()) {
            // 1. 生成行数据
            Row row = buildRow(schema, stmt.getColumns(), values);
            
            // 2. 获取锁
            lockManager.acquireLock(tx.getId(), row.getResourceId(), LockMode.X);
            
            // 3. 检查主键冲突
            if (hasPrimaryKeyConflict(schema, row)) {
                throw new DuplicateKeyException("Duplicate primary key");
            }
            
            // 4. 写Undo日志
            long undoLSN = logManager.logInsert(tx.getId(), row);
            
            // 5. 插入数据页
            insertRow(schema, row);
            
            count++;
        }
        
        return count;
    }
    
    private Row buildRow(TableSchema schema, List<String> columns, 
                         List<Expression> values) {
        Row row = new Row();
        Object[] rowData = new Object[schema.getColumnCount()];
        
        // 填充默认值
        for (int i = 0; i < schema.getColumnCount(); i++) {
            rowData[i] = schema.getColumn(i).getDefaultValue();
        }
        
        // 填充插入值
        for (int i = 0; i < columns.size(); i++) {
            String colName = columns.get(i);
            int idx = schema.getColumnIndex(colName);
            rowData[idx] = Evaluator.evaluate(values.get(i));
        }
        
        // 生成主键（如果需要）
        if (schema.hasAutoIncrement()) {
            int autoIdx = schema.getAutoIncrementColumn();
            if (rowData[autoIdx] == null) {
                rowData[autoIdx] = generateNextId(schema);
            }
        }
        
        row.setValues(rowData);
        return row;
    }
}
```

---

*下一步：UPDATE修改*
