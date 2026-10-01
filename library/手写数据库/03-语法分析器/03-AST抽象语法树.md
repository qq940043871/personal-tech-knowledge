# AST抽象语法树

> 模块：语法分析器
> 更新时间：2026-03-29

---

## 一、AST节点结构

```
Statement（语句）
├── SelectStatement（查询）
│   ├── columns: List<Expression>
│   ├── from: TableReference
│   ├── where: Expression
│   ├── groupBy: List<Expression>
│   ├── having: Expression
│   └── orderBy: List<OrderByItem>
│
├── InsertStatement（插入）
│   ├── table: String
│   ├── columns: List<String>
│   └── values: List<Expression>
│
├── UpdateStatement（更新）
│   ├── table: String
│   ├── assignments: Map<String, Expression>
│   └── where: Expression
│
├── DeleteStatement（删除）
│   ├── table: String
│   └── where: Expression
│
└── CreateTableStatement（建表）
    ├── name: String
    ├── columns: List<ColumnDefinition>
    └── constraints: List<Constraint>

Expression（表达式）
├── ColumnExpression（列引用）
├── LiteralExpression（字面量）
├── BinaryExpression（二元运算）
├── FunctionExpression（函数调用）
└── StarExpression（*）
```

---

## 二、节点定义

```java
// 语句基类
public interface Statement {}

// SELECT语句
public class SelectStatement implements Statement {
    private List<Expression> columns;
    private TableReference from;
    private Expression where;
    private List<Expression> groupBy;
    private Expression having;
    private List<OrderByItem> orderBy;
    private Integer limit;
    private Integer offset;
    private boolean distinct;
}

// INSERT语句
public class InsertStatement implements Statement {
    private String table;
    private List<String> columns;
    private List<List<Expression>> valuesLists;
}

// UPDATE语句
public class UpdateStatement implements Statement {
    private String table;
    private Map<String, Expression> assignments;
    private Expression where;
}

// DELETE语句
public class DeleteStatement implements Statement {
    private String table;
    private Expression where;
}

// CREATE TABLE语句
public class CreateTableStatement implements Statement {
    private String tableName;
    private List<ColumnDefinition> columns;
    private List<Constraint> constraints;
}
```

---

## 三、表达式定义

```java
// 表达式基类
public interface Expression {}

// 列引用
public class ColumnExpression implements Expression {
    private String table;
    private String column;
}

// 字面量
public class LiteralExpression implements Expression {
    private Object value;
    
    public LiteralExpression(Object value) {
        this.value = value;
    }
}

// 二元运算
public class BinaryExpression implements Expression {
    public enum Op { EQ, NE, LT, GT, LE, GE, AND, OR, PLUS, MINUS, STAR, SLASH }
    
    private Op op;
    private Expression left;
    private Expression right;
}

// 函数调用
public class FunctionExpression implements Expression {
    private String name;
    private List<Expression> args;
}

// 星号表达式
public class StarExpression implements Expression {}
```

---

## 四、树遍历

```java
public class AstVisitor {
    
    public Object visit(SelectStatement stmt) {
        // 访问子节点
        for (Expression col : stmt.getColumns()) {
            visitExpression(col);
        }
        
        if (stmt.getFrom() != null) {
            visitTableReference(stmt.getFrom());
        }
        
        if (stmt.getWhere() != null) {
            visitExpression(stmt.getWhere());
        }
        
        return null;
    }
    
    public void visitExpression(Expression expr) {
        if (expr instanceof ColumnExpression) {
            visitColumn((ColumnExpression) expr);
        } else if (expr instanceof LiteralExpression) {
            visitLiteral((LiteralExpression) expr);
        } else if (expr instanceof BinaryExpression) {
            visitBinary((BinaryExpression) expr);
        } else if (expr instanceof FunctionExpression) {
            visitFunction((FunctionExpression) expr);
        }
    }
}
```

---

*下一步：符号表管理*
