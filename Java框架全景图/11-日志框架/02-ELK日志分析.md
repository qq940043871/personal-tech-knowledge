# ELK日志分析

> 模块：Java框架全景图 / 11-日志框架
> 更新时间：2026-06-20

---

## 一、概述

ELK是Elasticsearch + Logstash + Kibana的日志分析解决方案，用于集中收集、存储、分析和可视化日志数据。

### 架构组成
- **Elasticsearch** — 分布式搜索引擎，存储和索引日志
- **Logstash** — 数据收集和处理引擎
- **Kibana** — 数据可视化平台

---

## 二、架构方案

### 2.1 经典架构

```
应用 → Logstash → Elasticsearch → Kibana
```

### 2.2 轻量架构（推荐）

```
应用 → Filebeat → Elasticsearch → Kibana
```

### 2.3 完整架构

```
应用 → Filebeat → Logstash → Elasticsearch → Kibana
```

---

## 三、Filebeat配置

### 3.1 filebeat.yml

```yaml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/application/*.log
    fields:
      app: my-application
      env: production
    multiline.pattern: '^\d{4}-\d{2}-\d{2}'
    multiline.negate: true
    multiline.match: after

output.elasticsearch:
  hosts: ["http://es-node1:9200", "http://es-node2:9200"]
  index: "app-logs-%{+yyyy.MM.dd}"

setup.template.name: "app-logs"
setup.template.pattern: "app-logs-*"
```

### 3.2 Docker部署

```yaml
version: '3'
services:
  filebeat:
    image: docker.elastic.co/beats/filebeat:8.11.0
    volumes:
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml
      - /var/log:/var/log
```

---

## 四、Logstash配置

### 4.1 logstash.conf

```ruby
input {
  beats {
    port => 5044
  }
}

filter {
  grok {
    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} \[%{DATA:thread}\] %{LOGLEVEL:level} %{DATA:logger} - %{GREEDYDATA:msg}" }
  }
  
  date {
    match => [ "timestamp", "yyyy-MM-dd HH:mm:ss" ]
  }
  
  mutate {
    remove_field => [ "timestamp" ]
  }
}

output {
  elasticsearch {
    hosts => ["http://es-node1:9200"]
    index => "app-logs-%{+YYYY.MM.dd}"
  }
}
```

---

## 五、Spring Boot集成

### 5.1 logback-spring.xml

```xml
<appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <destination>logstash-host:5044</destination>
    <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <customFields>{"app":"my-application","env":"production"}</customFields>
    </encoder>
</appender>
```

### 5.2 Maven依赖

```xml
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>7.4</version>
</dependency>
```

---

## 六、Kibana查询

### 6.1 KQL查询

```
# 按级别查询
level: "ERROR"

# 按应用查询
app: "my-application"

# 按时间范围
@timestamp >= "2024-01-01" and @timestamp <= "2024-01-31"

# 组合查询
level: "ERROR" and app: "my-application"
```

### 6.2 Lucene查询

```
# 模糊搜索
message: "exception"

# 精确搜索
level: "ERROR"

# 通配符
message: "time*out"
```

---

## 七、监控告警

### 7.1 ElastAlert

```yaml
name: error-alert
type: frequency
index: app-logs-*
num_events: 10
timeframe:
  minutes: 5
filter:
- term:
    level: "ERROR"
alert:
- "email"
email:
- "admin@example.com"
```

---

## 八、最佳实践

1. **结构化日志** — 使用JSON格式输出日志
2. **合理设置索引** — 按日期切割索引
3. **配置生命周期** — 自动删除过期索引
4. **监控集群健康** — 关注ES集群状态
5. **优化查询性能** — 使用合适的查询语句

---

## 九、与Loki对比

| 特性 | ELK | Loki |
|------|-----|------|
| 存储成本 | 高 | 低 |
| 查询能力 | 强 | 中 |
| 全文索引 | 支持 | 不支持 |
| 适用场景 | 复杂日志分析 | 简单日志查询 |

---

*ELK适合需要复杂日志分析的场景，简单场景可考虑Loki。*
