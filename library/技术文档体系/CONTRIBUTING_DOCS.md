# 文档贡献指南

> 感谢你为文档做贡献！好的文档和好的代码同样重要。
> 本指南帮助你快速上手，避免反复修改。

---

## 什么需要写文档？

**以下情况必须同步更新文档（与代码 PR 在同一 MR 中）：**

| 场景 | 需要更新的文档 |
|------|-------------|
| 新增功能模块 | README、对应功能模块文档、API 参考 |
| 新增 API 接口 | API 参考文档 |
| 修改现有接口（参数/返回值） | API 参考文档 + 如破坏性变更则加迁移指南 |
| 修改配置项 | 配置说明文档 |
| 修复影响使用方式的 Bug | 相关操作指南或 FAQ |
| 版本发布 | CHANGELOG.md |

**文档 PR 审查不通过 = 代码不合并。**

---

## 快速上手流程

### Step 1：找到对应文档位置

```
docs/
├── getting-started.md      ← 快速上手相关
├── architecture.md         ← 架构设计相关
├── api/                    ← 所有 API 参考文档
│   ├── overview.md
│   └── [模块名].md
├── guides/                 ← 操作指南（部署、配置、排查）
│   ├── deployment.md
│   ├── configuration.md
│   └── troubleshooting.md
└── design/                 ← 功能设计文档
    └── [功能名].md
```

如果是新功能，从对应模板新建文档：
- API 文档 → 复制 `技术文档体系/templates/api-reference-template.md`
- 功能文档 → 复制 `技术文档体系/templates/feature-doc-template.md`
- 新项目 README → 复制 `技术文档体系/templates/readme-template.md`

### Step 2：写文档

**对照写作规范（[WRITING_GUIDE.md](./WRITING_GUIDE.md)）写**，核心要点：

1. 结论前置，说清楚"这部分讲什么"
2. 代码示例必须可运行
3. 使用第二人称"你"，不用"我们"
4. 格式：代码块指定语言，表格有表头

### Step 3：自查

提交前对照以下清单：

- [ ] 内容准确（如果描述接口，先实际调通）
- [ ] 代码示例可运行（在干净环境中验证过）
- [ ] 链接有效（包括文档内部链接）
- [ ] 格式符合规范（参考 WRITING_GUIDE.md）
- [ ] 如有截图，图片已提交到 `docs/assets/images/`

### Step 4：提交 PR

PR 描述中注明：
- 对应代码 PR 的链接（如果有）
- 更新了哪些文档，为什么

---

## 文档目录与命名规范

### 文件命名

- 全部小写，单词间用连字符 `-` 分隔
- 操作指南类：动词开头，如 `deploy-to-production.md`、`configure-redis.md`
- API 参考类：模块名，如 `user.md`、`agent.md`
- 功能设计类：功能名，如 `multi-tenant.md`、`workflow.md`

```
# ✅ 好的命名
getting-started.md
deploy-to-docker.md
api/user.md

# ❌ 不好的命名
GettingStarted.md
部署说明.md
api文档.md
```

### 图片文件命名

格式：`{功能}-{操作}-{序号}.png`

```
# 示例
agent-create-step1.png
login-oauth-flow.png
dashboard-overview.png
```

---

## 常见文档类型写法指导

### 写操作指南

操作指南的核心是"帮读者完成一个具体任务"。

**结构：**
1. 标题：说清楚"做什么"（动词 + 宾语）
2. 前提条件（如果有）
3. 步骤（有序列表，每步只做一件事）
4. 验证结果（告诉读者怎么确认操作成功了）
5. 后续步骤（可选，指向相关文档）

**示例结构：**
```markdown
# 如何配置 Redis 缓存

本指南介绍如何为项目启用 Redis 缓存。完成后，热点数据查询响应时间将降低约 80%。

**前提条件：**
- 已部署 Redis 6.0+
- 已有可用的 Redis 连接地址

## 步骤

### 1. 添加 Redis 依赖

在 `pom.xml` 中添加：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
\```

### 2. 配置连接信息

...

## 验证

启动服务后，执行以下命令确认缓存已连接：

\```bash
redis-cli ping
# 预期输出：PONG
\```
```

---

### 写故障排查文档

**结构：**
1. 症状描述（用户看到的错误或现象）
2. 可能原因（列出 2-5 种常见原因）
3. 逐一排查步骤
4. 解决方案

**示例：**
```markdown
## 启动时报 "Cannot connect to database"

**症状**：应用启动时日志出现 `HikariPool-1 - Exception during pool initialization`

**可能原因**：
1. 数据库地址或端口配置错误
2. 数据库未启动
3. 用户名密码错误
4. 网络不通（防火墙拦截）

**排查步骤**：

**1. 检查配置文件**

确认 `application.yml` 中的连接信息：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/your_db  # 检查这里
    username: root                            # 和这里
    password: your_password                   # 和这里
\```

**2. 验证数据库是否运行**

```bash
mysql -u root -p -h localhost -P 3306
# 如果连接失败，说明数据库未启动或端口不对
\```
```

---

### 写 CHANGELOG

每次发版，在 `CHANGELOG.md` 文件顶部追加本次版本记录。

**格式规范**（基于 [Keep a Changelog](https://keepachangelog.com/)）：

```markdown
## [v1.2.0] - 2026-04-22

### 新增
- 智能体支持多模型切换，可在对话中实时更换底层模型
- 新增知识库文件批量上传接口（最多 50 个文件/次）

### 变更
- 分页接口默认 pageSize 从 10 调整为 20
- JWT Token 有效期从 12 小时延长至 24 小时

### 修复
- 修复多租户场景下用户查询可能看到其他租户数据的问题（安全修复）
- 修复删除知识库文件时关联向量数据未清理的问题

### 废弃
- `/api/v1/agent/run`（旧版同步执行接口）将在 v2.0 移除，请迁移到 `/api/v1/agent/execute`

### 移除
- 移除已废弃的 `/api/v0/` 接口前缀
```

**分类说明：**
- `新增`：新功能
- `变更`：对现有功能的改动（非破坏性）
- `废弃`：标记为将在未来版本移除
- `移除`：已移除的功能
- `修复`：Bug 修复
- `安全`：安全相关修复（单独标出）

---

## 文档审查标准

文档 PR 的 Reviewer 应按以下标准进行审查：

| 审查项 | 标准 |
|--------|------|
| 技术准确性 | 代码示例可运行，描述与代码行为一致 |
| 完整性 | 参数、返回值、错误码无遗漏 |
| 清晰度 | 在合理时间内能看懂（建议 Reviewer 实际跟着操作一遍） |
| 格式规范 | 符合 WRITING_GUIDE.md 要求 |
| 链接有效 | 所有链接可访问 |

---

## 发现文档问题？

如果你发现文档有错误、过时或不清晰的地方：

1. **小改动**：直接提 PR 修复
2. **大范围问题**：先提 Issue 讨论，说明问题范围和建议方案
3. **紧急错误**（如错误的命令会导致数据丢失）：立即提 Issue 并 `@` 文档负责人

> 💡 **发现文档问题就是贡献**。你遇到的困惑，下一个人也会遇到。修它！
