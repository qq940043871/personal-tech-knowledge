# SQL词法规则

> 模块：词法分析器
> 更新时间：2026-03-29

---

## 一、Token类型

```
关键字：
  SELECT, FROM, WHERE, AND, OR, NOT, IN, LIKE, BETWEEN
  INSERT, INTO, VALUES, UPDATE, SET, DELETE
  CREATE, TABLE, DATABASE, INDEX, DROP, ALTER
  JOIN, LEFT, RIGHT, INNER, OUTER, ON
  GROUP, BY, HAVING, ORDER, ASC, DESC, LIMIT, OFFSET
  UNION, ALL, DISTINCT, AS, NULL, DEFAULT
  PRIMARY, KEY, FOREIGN, REFERENCES, CONSTRAINT, UNIQUE
  AUTO_INCREMENT, UNSIGNED, ZEROFILL
  INT, INTEGER, BIGINT, SMALLINT, TINYINT, FLOAT, DOUBLE, DECIMAL
  CHAR, VARCHAR, TEXT, BLOB, DATE, DATETIME, TIMESTAMP

标识符：
  表名、列名、数据库名

字面量：
  整数：123, -456
  浮点：3.14, -2.5e10
  字符串：'hello', "world"
  布尔：TRUE, FALSE, NULL

运算符：
  + - * / % = <> != < > <= >= ( ) , . ; :
  && || !

注释：
  -- 单行注释
  /* 多行注释 */
```

---

## 二、关键字表

```java
public class Keywords {
    public static final Set<String> SQL_KEYWORDS = new HashSet<>(Arrays.asList(
        "SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN", "LIKE", "BETWEEN",
        "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE",
        "CREATE", "TABLE", "DATABASE", "INDEX", "DROP", "ALTER",
        "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON",
        "GROUP", "BY", "HAVING", "ORDER", "ASC", "DESC", "LIMIT", "OFFSET",
        "UNION", "ALL", "DISTINCT", "AS", "NULL", "DEFAULT",
        "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "CONSTRAINT", "UNIQUE",
        "AUTO_INCREMENT", "INT", "INTEGER", "BIGINT", "FLOAT", "DOUBLE", 
        "DECIMAL", "CHAR", "VARCHAR", "TEXT", "BLOB", "DATE", "DATETIME"
    ));
    
    public static boolean isKeyword(String word) {
        return SQL_KEYWORDS.contains(word.toUpperCase());
    }
}
```

---

## 三、词法规则

```
标识符规则：
  [a-zA-Z_][a-zA-Z0-9_]*
  最大长度64

数字规则：
  整数：[0-9]+
  浮点：[0-9]*.[0-9]+
  科学计数：[0-9]+.[0-9]*[eE][+-]?[0-9]+

字符串规则：
  单引号：'[^']*'
  双引号："[^"]*"

运算符规则：
  单字符运算符：+ - * / % ( ) , ; . :
  双字符运算符：<= >= <> != || &&
  三字符运算符：!=
```

---

## 四、Token定义

```java
public class Token {
    public enum Type {
        // 关键字
        SELECT, FROM, WHERE, AND, OR, NOT, IN, LIKE, BETWEEN,
        INSERT, INTO, VALUES, UPDATE, SET, DELETE,
        CREATE, TABLE, DATABASE, INDEX, DROP, ALTER,
        JOIN, LEFT, RIGHT, INNER, OUTER, ON,
        GROUP, BY, HAVING, ORDER, ASC, DESC, LIMIT, OFFSET,
        UNION, ALL, DISTINCT, AS, NULL, DEFAULT,
        PRIMARY, KEY, FOREIGN, REFERENCES, UNIQUE,
        AUTO_INCREMENT, INT, VARCHAR, TEXT, DATE, DATETIME,
        
        // 字面量
        IDENTIFIER,    // 标识符
        STRING,        // 字符串
        INTEGER,       // 整数
        FLOAT,         // 浮点数
        BOOLEAN,       // TRUE/FALSE
        
        // 运算符
        PLUS, MINUS, STAR, SLASH, PERCENT,  // + - * / %
        EQ, NE, LT, GT, LE, GE,             // = <> < > <= >=
        LPAREN, RPAREN,                     // ( )
        COMMA, DOT, SEMICOLON,              // , . ;
        
        // 其他
        EOF, ERROR
    }
    
    public Type type;
    public String value;
    public int position;
    public int line;
    public int column;
}
```

---

*下一步：Token识别实现*
