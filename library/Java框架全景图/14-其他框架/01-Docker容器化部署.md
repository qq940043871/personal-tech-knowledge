# Docker

> 模块：容器化部署
> 更新时间：2026-03-29

---

## 一、框架介绍

Docker是一个开源的容器化平台，让开发者可以打包应用及其依赖到一个可移植的容器中。

**官网**：[https://www.docker.com](https://www.docker.com)

**核心概念**：
- **镜像（Image）**：应用的只读模板
- **容器（Container）**：镜像的运行实例
- **仓库（Registry）**：存储镜像的地方

---

## 二、实际业务应用场景

### 场景1：Spring Boot项目Dockerfile

```dockerfile
# 基础镜像
FROM openjdk:17-slim

# 设置工作目录
WORKDIR /app

# 复制jar包
COPY target/myapp-1.0.0.jar app.jar

# 配置
ENV JAVA_OPTS="-Xms256m -Xmx512m"

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### 场景2：多阶段构建

```dockerfile
# 构建阶段
FROM maven:3.8-openjdk-17 AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# 运行阶段
FROM openjdk:17-slim
WORKDIR /app
COPY --from=builder /build/target/myapp.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 场景3：Docker Compose编排

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/test
    depends_on:
      - mysql
      - redis
  
  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=123456
      - MYSQL_DATABASE=test
    volumes:
      - mysql-data:/var/lib/mysql
  
  redis:
    image: redis:7
    ports:
      - "6379:6379"

volumes:
  mysql-data:
```

---

## 三、常用命令

```bash
# 构建镜像
docker build -t myapp:1.0 .

# 运行容器
docker run -d -p 8080:8080 --name myapp myapp:1.0

# 查看日志
docker logs -f myapp

# 进入容器
docker exec -it myapp /bin/bash

# 构建并启动
docker-compose up -d

# 停止并删除
docker-compose down
```

---

## 四、总结

Docker是现代云原生开发的基础，配合Kubernetes实现容器编排。

**学习要点**：
1. Dockerfile编写
2. Docker Compose编排
3. 镜像优化
4. 网络配置

---

*文档完成！*
