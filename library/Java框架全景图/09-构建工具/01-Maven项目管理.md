# Maven项目管理

> 模块：Java框架全景图 / 09-构建工具
> 更新时间：2026-06-20

---

## 一、概述

Maven是Java领域最主流的项目构建和依赖管理工具，通过POM（Project Object Model）文件管理项目的构建、依赖、文档等。

### 核心特性
- **依赖管理** — 自动下载和管理项目依赖
- **构建生命周期** — 编译、测试、打包、部署标准化
- **插件体系** — 丰富的插件扩展构建能力
- **多模块支持** — 支持大型项目的模块化管理

---

## 二、POM文件结构

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    
    <modelVersion>4.0.0</modelVersion>
    
    <!-- 项目坐标 -->
    <groupId>com.example</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <!-- 父项目 -->
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
    </parent>
    
    <!-- 属性 -->
    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>
    
    <!-- 依赖 -->
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
    </dependencies>
    
    <!-- 构建配置 -->
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

---

## 三、依赖管理

### 3.1 依赖范围

| Scope | 编译 | 测试 | 运行 | 打包 |
|-------|------|------|------|------|
| compile | ✅ | ✅ | ✅ | ✅ |
| test | ❌ | ✅ | ❌ | ❌ |
| provided | ✅ | ✅ | ❌ | ❌ |
| runtime | ❌ | ✅ | ✅ | ✅ |
| system | ✅ | ✅ | ❌ | ❌ |

### 3.2 依赖传递

```
A → B → C (compile)
A 自动依赖 C
```

### 3.3 排除依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <exclusions>
        <exclusion>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-tomcat</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

### 3.4 依赖版本管理

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.google.guava</groupId>
            <artifactId>guava</artifactId>
            <version>32.1.3-jre</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

---

## 四、构建生命周期

### 4.1 默认生命周期

```
validate → compile → test → package → verify → install → deploy
```

### 4.2 常用命令

```bash
# 编译
mvn compile

# 运行测试
mvn test

# 打包
mvn package

# 安装到本地仓库
mvn install

# 部署到远程仓库
mvn deploy

# 清理
mvn clean

# 组合命令
mvn clean package -DskipTests
```

---

## 五、多模块项目

```xml
<!-- 父项目POM -->
<modules>
    <module>common</module>
    <module>service</module>
    <module>web</module>
</modules>
```

```
parent/
├── pom.xml
├── common/
│   └── pom.xml
├── service/
│   └── pom.xml
└── web/
    └── pom.xml
```

---

## 六、常用插件

```xml
<build>
    <plugins>
        <!-- 编译插件 -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.11.0</version>
            <configuration>
                <source>17</source>
                <target>17</target>
            </configuration>
        </plugin>
        
        <!-- 测试插件 -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.2.2</version>
        </plugin>
        
        <!-- 打包插件 -->
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```

---

## 七、最佳实践

1. **使用dependencyManagement** — 统一管理依赖版本
2. **合理设置依赖范围** — 避免不必要的依赖传递
3. **多模块拆分** — 按职责拆分模块
4. **使用Maven Wrapper** — 确保构建环境一致
5. **配置私服** — 使用Nexus/Artifactory管理私有依赖

---

## 八、与Gradle对比

| 特性 | Maven | Gradle |
|------|-------|--------|
| 构建速度 | 较慢 | 更快 |
| 配置方式 | XML | Groovy/Kotlin DSL |
| 灵活性 | 较低 | 高 |
| 学习曲线 | 低 | 中 |
| 生态成熟度 | 成熟 | 成熟 |

---

*Maven适合传统Java项目，Gradle适合Android和需要高性能构建的项目。*
