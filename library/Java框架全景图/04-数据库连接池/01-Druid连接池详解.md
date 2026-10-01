# Druid连接池

> 模块：数据库连接池
> 更新时间：2026-03-29

---

## 一、框架介绍

Druid是阿里巴巴开源的数据库连接池，提供强大的监控和扩展功能。

**官网**：[https://github.com/alibaba/druid](https://github.com/alibaba/druid)

**核心特性**：
- 高性能数据库连接池
- 实时监控
- SQL防火墙
- 连接泄漏检测

---

## 二、实际业务应用场景

### 场景1：配置

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/test
    username: root
    password: 123456
    # Druid连接池配置
    druid:
      initial-size: 5
      min-idle: 5
      max-active: 20
      max-wait: 60000
      time-between-eviction-runs-millis: 60000
      min-evictable-idle-time-millis: 300000
      validation-query: SELECT 1
      test-while-idle: true
      test-on-borrow: false
      test-on-return: false
      pool-prepared-statements: true
      max-pool-prepared-statement-per-connection-size: 20
      filters: stat,wall,slf4j
      # Web监控
      web-stat-filter:
        enabled: true
      stat-view-servlet:
        enabled: true
        url-pattern: /druid/*
        login-username: admin
        login-password: admin123
```

### 场景2：多数据源配置

```java
@Configuration
public class DataSourceConfig {
    
    @Bean
    @ConfigurationProperties("spring.datasource.druid.master")
    public DataSource masterDataSource() {
        return DruidDataSourceFactory.createDataSource();
    }
    
    @Bean
    @ConfigurationProperties("spring.datasource.druid.slave")
    public DataSource slaveDataSource() {
        return DruidDataSourceFactory.createDataSource();
    }
    
    @Bean
    public DataSource routingDataSource(@Qualifier("masterDataSource") DataSource master,
                                       @Qualifier("slaveDataSource") DataSource slave) {
        Map<Object, Object> targetDataSources = new HashMap<>();
        targetDataSources.put("master", master);
        targetDataSources.put("slave", slave);
        
        RoutingDataSource routingDataSource = new RoutingDataSource();
        routingDataSource.setDefaultTargetDataSource(master);
        routingDataSource.setTargetDataSources(targetDataSources);
        return routingDataSource;
    }
}
```

---

## 三、总结

Druid是国内使用最广泛的数据库连接池，监控功能是其最大亮点。

---

*下一步：Sentinel熔断器*
