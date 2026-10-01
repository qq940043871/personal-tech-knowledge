# 智能体管理系统（AI Agent Manager）

> 一套完整的 AI 智能体管理平台，支持多租户隔离、知识库管理、工作流编排和多大模型接入。让团队能快速搭建、管理和对话自己的 AI 智能体。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Java](https://img.shields.io/badge/Java-17%2B-blue)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-brightgreen)](https://spring.io/projects/spring-boot)
[![Vue](https://img.shields.io/badge/Vue-3.x-42b883)](https://vuejs.org/)

---

## 为什么需要这个系统

企业落地 AI 时面临三个核心问题：

1. **多部门、多业务线需要各自的专属智能体**，但搭建和管理成本高
2. **知识库分散**，智能体无法沉淀和复用企业私有知识
3. **没有权限隔离**，不同租户的数据存在交叉风险

本系统解决上述三个问题：多租户隔离、统一知识库管理、灵活的工作流编排——让每个团队都能拥有自己的"专属 AI 助手"，同时对接 Llama、豆包等多款大模型。

---

## 快速开始

> 5 分钟内启动本地开发环境

**前提条件：**
- Java 17+
- MySQL 8.0+
- Node.js 18+（前端）
- Maven 3.8+

```bash
# 1. 克隆仓库
git clone https://github.com/your-org/agent-manager.git
cd agent-manager

# 2. 初始化数据库
mysql -u root -p < sql/init.sql
mysql -u root -p agent_db < sql/data.sql  # 导入测试数据

# 3. 配置数据库连接（复制示例配置后编辑）
cp ruoyi-agent/src/main/resources/application-example.yml \
   ruoyi-agent/src/main/resources/application-local.yml
# 编辑 application-local.yml，填入你的数据库地址和密码

# 4. 启动后端
cd ruoyi-agent
mvn spring-boot:run -Dspring.profiles.active=local

# 5. 启动前端（新开终端）
cd frontend
npm install && npm run dev
```

启动成功后：
- 前端：`http://localhost:5173`
- 后端 API：`http://localhost:8080`
- API 文档（Swagger）：`http://localhost:8080/swagger-ui.html`

默认管理员账号：`admin` / `admin123`（**生产环境务必修改**）

---

## 核心功能

| 模块 | 功能 | 状态 |
|------|------|------|
| **智能体管理** | 创建/编辑智能体，配置 Prompt、模型、知识库 | ✅ 已完成 |
| **知识库管理** | 上传文档（PDF/Word/MD），自动向量化，RAG 召回 | ✅ 已完成 |
| **工作流编排** | 可视化编排多步 AI 工作流 | 🚧 开发中 |
| **多模型接入** | 支持 Llama / 豆包 / DeepSeek 等模型动态切换 | ✅ 已完成 |
| **多租户隔离** | 租户数据完全隔离，独立配额管理 | ✅ 已完成 |
| **权限管理** | RBAC 权限模型，支持菜单/按钮/数据权限 | ✅ 已完成 |
| **对话上下文** | 多轮对话历史管理，支持会话继续 | ✅ 已完成 |

---

## 系统架构

```
┌──────────────────────────────────────────────────────┐
│                    前端层                              │
│     Vue 3 + Element Plus（Web）                       │
│     UniApp（移动端，可选）                             │
└─────────────────────┬────────────────────────────────┘
                      │ HTTP / WebSocket
┌─────────────────────▼────────────────────────────────┐
│                    网关层                              │
│     Spring Cloud Gateway + JWT 认证                   │
└──────┬───────────┬──────────────┬────────────────────┘
       │           │              │
┌──────▼──┐  ┌────▼─────┐  ┌────▼──────┐
│ 用户服务 │  │ 智能体服务│  │ 知识库服务 │
│  User   │  │  Agent   │  │ Knowledge │
└──────┬──┘  └────┬─────┘  └────┬──────┘
       │           │              │
┌──────▼───────────▼──────────────▼──────┐
│               数据层                    │
│  MySQL 8.0（业务数据）                  │
│  Redis 6.0（缓存 + Session）            │
│  MinIO（文件存储）                      │
│  向量数据库（知识库向量检索）             │
└────────────────────────────────────────┘
```

---

## 技术栈

| 层次 | 技术选型 | 版本 |
|------|---------|------|
| 后端框架 | Spring Boot | 3.x |
| 持久层 | MyBatis Plus | 3.5.x |
| 权限框架 | Sa-Token | 1.x |
| 数据库 | MySQL | 8.0 |
| 缓存 | Redis | 6.0+ |
| 文件存储 | MinIO | — |
| 消息队列 | 待定（Kafka / RocketMQ） | — |
| 前端框架 | Vue 3 + Vite | 3.x |
| UI 组件 | Element Plus | 2.x |
| 移动端 | UniApp | — |
| 大模型接入 | Deep Back API（兼容层） | — |

---

## 项目结构

```
agent-manager/
├── ruoyi-agent/                  # 后端服务（Spring Boot）
│   ├── src/main/java/
│   │   └── com.ruoyi.agent/
│   │       ├── controller/       # REST 接口层
│   │       ├── service/          # 业务逻辑层
│   │       ├── mapper/           # 数据访问层
│   │       ├── entity/           # 数据库实体
│   │       ├── dto/              # 数据传输对象
│   │       └── config/           # 配置类
│   └── src/main/resources/
│       ├── application.yml       # 主配置
│       └── mapper/               # MyBatis XML
├── frontend/                     # 前端（Vue 3）
├── sql/
│   ├── init.sql                  # 建表脚本
│   └── data.sql                  # 初始化数据
├── docs/                         # 详细文档
│   ├── getting-started.md        # 详细上手指南
│   ├── api/                      # API 参考文档
│   ├── guides/                   # 操作指南
│   └── design/                   # 设计文档
│       ├── 01-需求规格说明书.md
│       └── 02-数据库设计文档.md
└── README.md
```

---

## 多租户说明

系统采用**共享数据库、行级隔离**的多租户方案：

- 所有业务表包含 `tenant_id` 字段
- 请求头传入 `X-Tenant-ID` 后，后端自动过滤数据范围
- 租户管理员只能管理本租户下的用户、智能体和知识库
- 跨租户数据访问会返回 `404`（不泄露数据存在性）

---

## 文档

| 文档 | 说明 |
|------|------|
| [详细部署指南](docs/guides/deployment.md) | 含 Docker、K8s 部署方式 |
| [API 参考](docs/api/) | 完整接口文档 |
| [数据库设计](docs/design/02-数据库设计文档.md) | 数据库表结构说明 |
| [需求规格说明书](docs/design/01-需求规格说明书.md) | 功能模块详细说明 |
| [故障排查](docs/guides/troubleshooting.md) | 常见问题解决 |

---

## 贡献

提 Issue 或 PR 前，请阅读 [文档贡献指南](../../技术文档体系/CONTRIBUTING_DOCS.md)。

---

## License

MIT License © 2026 Your Team
