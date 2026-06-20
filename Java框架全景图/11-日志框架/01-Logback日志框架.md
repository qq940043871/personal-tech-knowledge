# Logback日志框架

> 模块：Java框架全景图 / 11-日志框架
> 更新时间：2026-06-20

---

## 一、概述

Logback是Log4j的继任者，是Spring Boot默认的日志框架，分为logback-core、logback-classic、logback-access三个模块。

### 核心特性
- **高性能** — 比Log4j更快
- **自动重载** — 配置文件修改后自动加载
- **过滤器** — 丰富的过滤器支持
- **异步日志** — AsyncAppender支持异步写入

---

## 二、Spring Boot配置

### 2.1 application.yml

```yaml
logging:
  level:
    root: INFO
    com.example: DEBUG
    org.springframework: WARN
  file:
    name: logs/application.log
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  logback:
    rollingpolicy:
      max-file-size: 100MB
      max-history: 30
      total-size-cap: 1GB
```

### 2.2 logback-spring.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    
    <!-- 控制台输出 -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <!-- 文件输出 -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>logs/application.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>logs/application.%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
            <totalSizeCap>1GB</totalSizeCap>
        </rollingPolicy>
        <encoder>
            <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
    </appender>
    
    <!-- 异步Appender -->
    <appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
        <appender-ref ref="FILE" />
        <queueSize>512</queueSize>
        <discardingThreshold>0</discardingThreshold>
    </appender>
    
    <!-- 日志级别 -->
    <root level="INFO">
        <appender-ref ref="CONSOLE" />
        <appender-ref ref="ASYNC" />
    </root>
    
    <logger name="com.example" level="DEBUG" />
    <logger name="org.springframework" level="WARN" />
    
</configuration>
```

---

## 三、日志级别

| 级别 | 说明 | 使用场景 |
|------|------|---------|
| TRACE | 最详细 | 开发调试 |
| DEBUG | 调试信息 | 开发调试 |
| INFO | 一般信息 | 生产环境 |
| WARN | 警告信息 | 潜在问题 |
| ERROR | 错误信息 | 异常错误 |

---

## 四、MDC（Mapped Diagnostic Context）

```java
// 设置上下文信息
MDC.put("userId", "12345");
MDC.put("requestId", UUID.randomUUID().toString());

log.info("处理用户请求");

// 清理
MDC.clear();
```

```xml
<pattern>%d{yyyy-MM-dd HH:mm:ss} [%X{requestId}] [%X{userId}] %-5level %logger{36} - %msg%n</pattern>
```

---

## 五、过滤器

```xml
<appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
    <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
        <level>INFO</level>
    </filter>
</appender>

<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <filter class="ch.qos.logback.classic.filter.LevelFilter">
        <level>ERROR</level>
        <onMatch>ACCEPT</onMatch>
        <onMismatch>DENY</onMismatch>
    </filter>
</appender>
```

---

## 六、最佳实践

1. **使用slf4j门面** — 面向接口编程
2. **合理设置日志级别** — 生产环境INFO，开发环境DEBUG
3. **使用异步日志** — 提升性能
4. **配置日志切割** — 避免日志文件过大
5. **使用MDC** — 追踪请求链路

---

## 七、日志门面SLF4J

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

private static final Logger log = LoggerFactory.getLogger(MyClass.class);

log.info("用户登录成功: {}", username);
log.error("处理请求异常", exception);
```

---

*Logback是Spring Boot默认日志框架，建议配合SLF4J使用。*
