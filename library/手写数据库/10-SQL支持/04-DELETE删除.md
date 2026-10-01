# CREATE表创建

> 模块：SQL支持
> 更新时间：2026-03-29

---

## 一、CREATE TABLE执行器

```java
public class CreateTableExecutor {
    private Catalog catalog;
    private DiskManager diskManager;
    
    public void execute(CreateTableStatement stmt) {
        // 1. 检查表是否已存在
        if (catalog.existsTable(stmt.getTableName())) {
            throw new SqlException("Table already exists: " + stmt.getTableName());
        }
        
        // 2. 构建表schema
        TableSchema schema = buildSchema(stmt);
        
        // 3. 创建数据文件
        createTableFile(stmt.getTableName());
        
        // 4. 创建主键索引
        if (schema.hasPrimaryKey()) {
            indexManager.createPrimaryKeyIndex(stmt.getTableName(), 
                schema.getPrimaryKeyColumns());
        }
        
        // 5. 注册到目录
        catalog.registerTable(stmt.getTableName(), schema);
        
        // 6. 写DDL日志
        logManager.logDDL("CREATE TABLE " + stmt.getTableName());
    }
    
    private TableSchema buildSchema(CreateTableStatement stmt) {
        TableSchema schema = new TableSchema();
        schema.setName(stmt.getTableName());
        
        for (ColumnDefinition col : stmt.getColumns()) {
            schema.addColumn(new ColumnInfo(
                col.getName(),
                col.getType(),
                col.getLength(),
                col.isNullable(),
                col.isPrimaryKey(),
                col.isAutoIncrement(),
                col.getDefaultValue()
            ));
        }
        
        // 处理约束
        for (Constraint constraint : stmt.getConstraints()) {
            if (constraint.getType() == ConstraintType.PRIMARY_KEY) {
                schema.setPrimaryKey(constraint.getColumns());
            } else if (constraint.getType() == ConstraintType.UNIQUE) {
                schema.addUniqueKey(constraint.getColumns());
            } else if (constraint.getType() == ConstraintType.FOREIGN_KEY) {
                schema.addForeignKey(constraint.getColumns(), 
                    constraint.getReferenceTable(),
                    constraint.getReferenceColumns());
            }
        }
        
        return schema;
    }
    
    private void createTableFile(String tableName) {
        String fileName = "data/" + tableName + ".dat";
        File file = new File(fileName);
        file.getParentFile().mkdirs();
        
        // 写入表头页
        Page headerPage = new Page();
        headerPage.setPageType(Page.TYPE_DATA);
        headerPage.setTableName(tableName);
        
        diskManager.createPage(headerPage);
    }
}
```

---

## 二、DDL语句支持

```java
public class DDLExecutor {
    
    public void executeDropTable(String tableName) {
        // 1. 检查表是否存在
        if (!catalog.existsTable(tableName)) {
            throw new SqlException("Table does not exist: " + tableName);
        }
        
        // 2. 删除数据文件
        deleteTableFile(tableName);
        
        // 3. 删除索引
        indexManager.dropIndexes(tableName);
        
        // 4. 从目录移除
        catalog.dropTable(tableName);
        
        // 5. 写DDL日志
        logManager.logDDL("DROP TABLE " + tableName);
    }
    
    public void executeAlterTable(AlterTableStatement stmt) {
        TableSchema schema = catalog.getTableSchema(stmt.getTableName());
        
        switch (stmt.getOperation()) {
            case ADD_COLUMN:
                schema.addColumn(stmt.getNewColumn());
                break;
            case DROP_COLUMN:
                schema.removeColumn(stmt.getColumnName());
                break;
            case ADD_INDEX:
                indexManager.createIndex(stmt.getTableName(), 
                    stmt.getIndexName(), stmt.getColumns());
                break;
        }
        
        // 写DDL日志
        logManager.logDDL(stmt.toString());
    }
}
```

---

*下一步：SQL命令行客户端*
