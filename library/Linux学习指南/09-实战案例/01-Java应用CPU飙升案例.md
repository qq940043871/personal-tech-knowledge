# Java应用CPU飙升案例

> 模块：实战案例
> 更新时间：2026-03-29

---

## 问题描述

```
服务器CPU使用率突然飙升到100%
应用响应变慢,部分接口超时
```

---

## 排查过程

### 第一步：确定进程

```bash
# top查看整体
top
# 发现java进程CPU 980%

# 按CPU排序进程
ps aux --sort=-%cpu | head -10
# PID 12345 java进程CPU 980%
```

### 第二步：定位线程

```bash
# 查看java进程的线程
top -H -p 12345

# 发现线程12346 CPU 450%
#       线程12347 CPU 450%
#       线程12348 CPU 80%
```

### 第三步：获取堆栈

```bash
# 导出堆栈
jstack 12345 > /tmp/jstack.log

# 线程ID转16进制
printf "%x\n" 12346
# 输出: 303a

printf "%x\n" 12347
# 输出: 303b

# 查找对应堆栈
grep -A 50 "nid=0x303a" /tmp/jstack.log
grep -A 50 "nid=0x303b" /tmp/jstack.log
```

### 第四步：分析结果

```
发现两个热点线程:
1. nid=0x303a: 
   java.lang.Thread.sleep(Native Method)
   com.example.Utils.parseData()

2. nid=0x303b:
   java.util.regex.Pattern$Slice.match(Pattern.java:...)
   com.example.Parser.process()
```

### 第五步：代码审查

```java
// 发现问题代码
public class Parser {
    // 问题: 正则表达式每次调用都编译
    public boolean parse(String input) {
        Pattern pattern = Pattern.compile("^(\\w+)-(\\d+)-(\\w+)$");
        // 每次调用都创建Pattern对象
        return pattern.matcher(input).matches();
    }
}
```

---

## 解决方案

```java
// 修复后
public class Parser {
    // 预编译正则表达式
    private static final Pattern PATTERN = 
        Pattern.compile("^(\\w+)-(\\d+)-(\\w+)$");
    
    public boolean parse(String input) {
        // 复用预编译对象
        return PATTERN.matcher(input).matches();
    }
}
```

---

## 根因分析

```
根因: 正则表达式在循环中被重复编译
影响: 每次编译耗时约1ms,循环1亿次=100秒CPU时间
修复: 预编译正则,消除重复编译开销
```

---

## 预防措施

```bash
# 1. 添加正则检查到代码规范
# 禁止在循环/高频方法中调用Pattern.compile()

# 2. 使用SpotBugs/FindBugs检测
<plugin>
    <groupId>com.github.spotbugs</groupId>
    <artifactId>spotbugs-maven-plugin</artifactId>
</plugin>

# 3. 添加APM监控
# Pinpoint/SkyWalking/Zipkin
```

---

## 总结

```
排查工具: top → jstack → grep → 代码审查
关键命令:
- top -H -p PID
- jstack PID
- printf "%x\n" TID
```

---

*案例完成*
