# SQL语法规则

> 模块：语法分析器
> 更新时间：2026-03-29

---

## 一、SELECT语法

```
SELECT语法：
  SELECT [DISTINCT] column_list
  FROM table_list
  [WHERE condition]
  [GROUP BY column_list [HAVING condition]]
  [ORDER BY column_list [ASC|DESC]]
  [LIMIT [offset,] count]

示例：
  SELECT id, name, age FROM users WHERE age > 18 ORDER BY name ASC LIMIT 10
  
  SELECT COUNT(*), department 
  FROM employees 
  GROUP BY department 
  HAVING COUNT(*) > 5
```

---

## 二、INSERT语法

```
INSERT语法：
  INSERT INTO table_name (column_list) VALUES (value_list)
  
示例：
  INSERT INTO users (id, name, email) VALUES (1, '张三', 'zhangsan@example.com')
  
批量插入：
  INSERT INTO users (id, name) VALUES (1, 'A'), (2, 'B'), (3, 'C')
```

---

## 三、UPDATE语法

```
UPDATE语法：
  UPDATE table_name SET column = value [, column = value ...] [WHERE condition]
  
示例：
  UPDATE users SET age = 25, email = 'new@example.com' WHERE id = 1
```

---

## 四、DELETE语法

```
DELETE语法：
  DELETE FROM table_name [WHERE condition]
  
示例：
  DELETE FROM users WHERE id = 1
```

---

## 五、CREATE TABLE语法

```
CREATE TABLE语法：
  CREATE TABLE table_name (
    column_name datatype [constraints],
    column_name datatype [constraints],
    ...
    [PRIMARY KEY (column_list)]
    [FOREIGN KEY (column) REFERENCES other_table(column)]
  )

约束类型：
  PRIMARY KEY
  NOT NULL
  UNIQUE
  DEFAULT value
  AUTO_INCREMENT

示例：
  CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    age INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
```

---

## 六、语法规则定义

```
Statement ::=
    SelectStatement
  | InsertStatement
  | UpdateStatement
  | DeleteStatement
  | CreateTableStatement
  | DropTableStatement

SelectStatement ::=
    SELECT [DISTINCT] ExpressionList
    FROM TableReference
    [WHERE Condition]
    [GROUP BY ExpressionList [HAVING Condition]]
    [ORDER BY ExpressionList]
    [LIMIT Integer [(,|OFFSET) Integer]]

InsertStatement ::=
    INSERT INTO Identifier (IdentifierList) VALUES (ExpressionListList)

UpdateStatement ::=
    UPDATE Identifier SET AssignmentList [WHERE Condition]

DeleteStatement ::=
    DELETE FROM Identifier [WHERE Condition]

CreateTableStatement ::=
    CREATE TABLE Identifier ( ColumnDefinitionList )
```

---

*下一步：递归下降解析*
