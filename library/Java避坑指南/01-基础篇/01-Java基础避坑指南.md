# Java基础避坑指南

> 模块：基础篇
> 更新时间：2026-03-29

---

## 一、String的"+"拼接与StringBuilder

### ❌ 错误示例
```java
// 在循环中拼接字符串
String result = "";
for (int i = 0; i < 1000; i++) {
    result += "item" + i;  // 每次都创建新对象！
}
```

### ✅ 正确做法
```java
// 使用StringBuilder
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 1000; i++) {
    sb.append("item").append(i);
}
String result = sb.toString();

// 或者在明确场景下直接用 +
String a = "hello" + "world";  // 编译期优化，无问题
```

### 📝 原理说明
String是不可变对象，`+=` 每次都会创建新String对象，在循环中会导致频繁GC。

---

## 二、BigDecimal的比较

### ❌ 错误示例
```java
BigDecimal a = new BigDecimal("0.1");
BigDecimal b = new BigDecimal("0.10");
System.out.println(a.equals(b));  // false！精度不同
System.out.println(a == b);        // false！
```

### ✅ 正确做法
```java
// 方法1：使用compareTo
System.out.println(a.compareTo(b) == 0);  // true

// 方法2：使用stripTrailingZeros
System.out.println(a.stripTrailingZeros()
    .equals(b.stripTrailingZeros()));  // true

// 最佳实践：使用String构造器，避免double
BigDecimal c = new BigDecimal("0.1");  // 精确
BigDecimal d = BigDecimal.valueOf(0.1);  // 推荐
```

---

## 三、包装类型与基本类型混合运算

### ❌ 错误示例
```java
Integer a = null;
int b = a + 1;  // NullPointerException！
```

### ✅ 正确做法
```java
Integer a = null;
if (a != null) {
    int b = a + 1;
}

// 或者使用Optional
Optional<Integer> optA = Optional.ofNullable(a);
int b = optA.orElse(0) + 1;
```

---

## 四、循环中创建对象

### ❌ 错误示例
```java
List<User> users = new ArrayList<>();
for (int i = 0; i < 10000; i++) {
    users.add(new User());  // 每次都new对象
}
```

### ✅ 正确做法
```java
// 预估容量，避免扩容
List<User> users = new ArrayList<>(10000);
for (int i = 0; i < 10000; i++) {
    users.add(new User());
}
```

---

## 五、Date与LocalDateTime混用

### ❌ 错误示例
```java
Date date = new Date();
LocalDateTime ldt = date.toInstant()  // 错误的转换
    .atZone(ZoneId.systemDefault())
    .toLocalDateTime();
```

### ✅ 正确做法
```java
// Java 8+ 使用 LocalDateTime
LocalDateTime ldt = LocalDateTime.now();

// Date 转 LocalDateTime
Date date = new Date();
LocalDateTime ldt = date.toInstant()
    .atZone(ZoneId.systemDefault())
    .toLocalDateTime();

// LocalDateTime 转 Date
LocalDateTime ldt2 = LocalDateTime.now();
Date date2 = Date.from(ldt2.atZone(ZoneId.systemDefault()).toInstant());

// 时间格式化
DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
String str = ldt.format(formatter);
LocalDateTime parsed = LocalDateTime.parse(str, formatter);
```

---

## 六、流未关闭

### ❌ 错误示例
```java
public String readFile(String path) {
    FileReader reader = new FileReader(path);
    char[] buffer = new char[1024];
    reader.read(buffer);  // 如果抛异常，流不会关闭！
    return new String(buffer);
}
```

### ✅ 正确做法
```java
// 方法1：try-with-resources（推荐）
public String readFile(String path) {
    try (FileReader reader = new FileReader(path)) {
        char[] buffer = new char[1024];
        reader.read(buffer);
        return new String(buffer);
    } catch (IOException e) {
        throw new RuntimeException(e);
    }
}

// 方法2：多个资源都要关闭
public void copyFile(String src, String dest) throws IOException {
    try (InputStream is = new FileInputStream(src);
         OutputStream os = new FileOutputStream(dest)) {
        is.transferTo(os);
    }
}
```

---

## 七、捕获并吞掉异常

### ❌ 错误示例
```java
try {
    doSomething();
} catch (Exception e) {
    // 什么都不做！异常被吞掉了
}
```

### ✅ 正确做法
```java
try {
    doSomething();
} catch (SpecificException e) {
    // 记录日志
    log.error("执行失败", e);
    // 决定是继续抛出还是返回默认值
    throw new BusinessException("操作失败", e);
    // 或者返回空值
    return null;
}
```

---

## 八、异常丢失

### ❌ 错误示例
```java
try {
    doSomething();
} catch (IOException e) {
    throw new RuntimeException(e);  // 原始异常作为cause传入
} catch (Exception e) {
    throw new RuntimeException("未知错误");  // 原始异常丢失了！
}
```

### ✅ 正确做法
```java
try {
    doSomething();
} catch (IOException e) {
    throw new BusinessException("IO操作失败", e);
} catch (Exception e) {
    throw new BusinessException("未知错误", e);  // 保留原始异常
}
```

---

## 九、泛型类型擦除

### ❌ 错误示例
```java
public class GenericClass<T> {
    public T getValue() {
        // 编译后变成 Object
        return new Object();  // ClassCastException！
    }
}
```

### ✅ 正确做法
```java
public class GenericClass<T> {
    public T getValue() {
        return null;  // 返回null是安全的
    }
}

// 如果需要创建泛型实例，使用反射
public T createInstance() {
    try {
        return (T) type.getDeclaredConstructor().newInstance();
    } catch (Exception e) {
        throw new RuntimeException(e);
    }
}
```

---

## 十、泛型数组

### ❌ 错误示例
```java
List<String>[] array = new List<String>[10];  // 编译错误！
```

### ✅ 正确做法
```java
// 使用通配符
List<?>[] array = new List<?>[10];
array[0] = new ArrayList<String>();
array[1] = new ArrayList<Integer>();

// 或者使用包装类
List<List<String>> list = new ArrayList<>();
```

---

*下一步：集合与并发篇*
