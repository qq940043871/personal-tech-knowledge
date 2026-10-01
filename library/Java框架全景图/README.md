# Java框架全景图

> 一套系统化的Java框架学习知识库，涵盖从基础核心到高级特性的全部主流框架。

---

## 目录结构

```
Java框架全景图/
├── 00-框架总纲.md                      # 框架分类总览与学习路线
├── 01-Spring框架/
│   ├── 01-SpringFramework详解.md       # IoC/AOP核心原理
│   └── 02-SpringBoot快速开发.md        # 自动配置与快速启动
├── 02-Web开发/                         # 待补充
├── 03-数据访问/
│   ├── 01-MyBatis数据持久层.md         # SQL映射与动态SQL
│   └── 02-SpringDataJPA详解.md         # JPA封装与ORM
├── 04-数据库连接池/
│   └── 01-Druid连接池详解.md           # 阿里Druid连接池
├── 05-微服务框架/
│   └── 01-SpringCloud微服务架构.md     # Nacos/Gateway/Sentinel
├── 06-消息中间件/
│   ├── 01-Redis分布式缓存.md           # 缓存与数据结构
│   ├── 02-RabbitMQ消息队列.md          # AMQP消息队列
│   └── 03-Kafka消息系统.md             # 高吞吐消息系统
├── 07-缓存框架/                        # 待补充
├── 08-搜索引擎/
│   └── 01-Elasticsearch全文搜索.md     # 全文搜索引擎
├── 09-构建工具/                        # 待补充
├── 10-测试框架/                        # 待补充
├── 11-日志框架/                        # 待补充
├── 12-工具类库/
│   ├── 01-SpringSecurity安全框架.md    # 认证与授权
│   ├── 02-Lombok简化代码.md            # 注解简化样板代码
│   └── 03-MySQL数据库.md               # 数据库基础
├── 13-安全框架/                        # 待补充
└── 14-其他框架/
    └── 01-Docker容器化部署.md           # 容器化打包与部署
```

---

## 框架分类概述

| 分类 | 核心框架 | 适用场景 |
|------|---------|---------|
| **Spring框架** | Spring Framework、Spring Boot | 所有Java项目的基础 |
| **数据访问** | MyBatis、Spring Data JPA | 数据库CRUD操作 |
| **数据库连接池** | Druid | 数据库连接管理与监控 |
| **微服务框架** | Spring Cloud、Dubbo | 分布式系统架构 |
| **消息中间件** | Redis、RabbitMQ、Kafka | 异步解耦、削峰填谷 |
| **搜索引擎** | Elasticsearch | 全文检索、日志分析 |
| **工具类库** | Spring Security、Lombok | 安全认证、代码简化 |
| **容器化部署** | Docker、Kubernetes | 应用打包与部署 |

---

## 学习路线建议

### 第一阶段：基础核心（1-2周）
1. Spring Framework — 理解IoC容器与AOP原理
2. Spring Boot — 掌握自动配置与快速启动
3. MySQL基础 — 复习SQL与数据库设计

### 第二阶段：数据层（2-3周）
4. MyBatis — 掌握SQL映射与动态SQL
5. Spring Data JPA — 理解ORM与JPA规范
6. Druid连接池 — 了解连接池原理与监控

### 第三阶段：中间件（3-4周）
7. Redis — 掌握缓存策略与分布式锁
8. RabbitMQ — 理解消息队列与异步解耦
9. Kafka — 了解高吞吐消息架构

### 第四阶段：分布式（3-4周）
10. Spring Cloud — 掌握微服务核心组件
11. Elasticsearch — 了解全文检索与聚合

---

## 技术选型参考

| 场景 | 推荐组合 |
|------|----------|
| 传统Web项目 | Spring Boot + MyBatis + Druid + MySQL |
| 微服务项目 | Spring Boot + Spring Cloud + Nacos + Redis |
| 高并发系统 | Spring Boot + Redis + Kafka + Elasticsearch |

---

## 版本对应关系

| Spring Boot | Spring Cloud | 建议JDK |
|-------------|--------------|---------|
| 3.x | 2023.x | JDK 17+ |
| 2.7.x | 2021.x | JDK 8-17 |
| 2.5.x | 2020.x | JDK 8-11 |

---

*本知识库持续更新中。*
