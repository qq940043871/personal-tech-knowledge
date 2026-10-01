# Skills 技能系统

## 什么是 Skills

Skills（技能）是 Openclaw 的核心扩展机制，类似于游戏中的"技能包"。每个 Skill 封装了特定的工作流和能力，让 AI 能够执行各种复杂任务。

### 核心特点

- **即插即用**: 安装后立即可用
- **用完即走**: 不占用上下文空间
- **可组合**: 多个 Skill 可以协同工作
- **可定制**: 支持自定义开发

## 内置 Skills

### 系统操作类

| Skill | 说明 |
|-------|------|
| `file-manager` | 文件管理操作 |
| `shell-executor` | Shell 命令执行 |
| `process-manager` | 进程管理 |
| `browser-control` | 浏览器自动化 |

### 开发工具类

| Skill | 说明 |
|-------|------|
| `code-review` | 代码审查 |
| `git-helper` | Git 操作辅助 |
| `test-runner` | 测试执行 |
| `doc-generator` | 文档生成 |

### 生产力工具类

| Skill | 说明 |
|-------|------|
| `email-manager` | 邮件管理 |
| `calendar` | 日历管理 |
| `task-scheduler` | 任务调度 |
| `note-taking` | 笔记管理 |

### 数据处理类

| Skill | 说明 |
|-------|------|
| `data-analyzer` | 数据分析 |
| `web-scraper` | 网页抓取 |
| `api-client` | API 调用 |
| `database` | 数据库操作 |

## 安装 Skills

### 从 ClawHub 安装

```bash
# 列出可用技能
openclaw skills search <keyword>

# 安装技能
openclaw skills install <skill-name>

# 示例
openclaw skills install code-review
```

### 从本地安装

```bash
# 安装本地技能包
openclaw skills install ./my-skill
```

### 从 Git 仓库安装

```bash
# 从 Git 仓库安装
openclaw skills install https://github.com/user/skill-name.git
```

## 使用 Skills

### 直接调用

```
用户: 使用 code-review 审查 src/ 目录

Openclaw: 正在使用 code-review 技能...
[审查结果]
```

### 通过命令调用

```
用户: /skill code-review src/

Openclaw: 执行 code-review 技能...
[审查结果]
```

### 带参数调用

```
用户: /skill web-scraper --url https://example.com --selector ".content"

Openclaw: 正在抓取网页...
[抓取结果]
```

## 管理 Skills

### 查看已安装技能

```bash
openclaw skills list
```

```
已安装技能：
名称            | 版本  | 说明
----------------|-------|------------------
code-review     | 1.2.0 | 代码审查
git-helper      | 1.0.0 | Git 操作辅助
email-manager   | 2.1.0 | 邮件管理
web-scraper     | 1.5.0 | 网页抓取
```

### 更新技能

```bash
# 更新单个技能
openclaw skills update <skill-name>

# 更新所有技能
openclaw skills update --all
```

### 卸载技能

```bash
openclaw skills uninstall <skill-name>
```

### 技能信息

```bash
openclaw skills info <skill-name>
```

```
技能: code-review
版本: 1.2.0
作者: Openclaw Team
描述: 自动化代码审查工具

功能:
- 代码质量分析
- 安全漏洞检测
- 性能问题识别
- 最佳实践建议

依赖:
- eslint >= 8.0.0
- prettier >= 3.0.0
```

## Skill 配置

### 全局配置

在 `~/.openclaw/config/skills.json` 中配置：

```json
{
  "skills": {
    "code-review": {
      "enabled": true,
      "rules": ["eslint:recommended", "security"],
      "exclude": ["node_modules", "dist"]
    },
    "web-scraper": {
      "timeout": 30000,
      "userAgent": "Openclaw/1.0",
      "maxPages": 100
    }
  }
}
```

### 项目级配置

在项目根目录创建 `.openclaw/skills.json`：

```json
{
  "extends": ["~/.openclaw/config/skills.json"],
  "skills": {
    "code-review": {
      "rules": ["local-rules"],
      "exclude": ["vendor"]
    }
  }
}
```

## Skill 开发

### 目录结构

```
my-skill/
├── skill.json        # 技能元数据
├── index.ts          # 入口文件
├── prompts/          # 提示词模板
│   └── main.md
├── tools/            # 工具函数
│   └── helper.ts
└── tests/            # 测试文件
    └── index.test.ts
```

### skill.json

```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "我的自定义技能",
  "author": "Your Name",
  "main": "index.ts",
  "dependencies": {
    "some-package": "^1.0.0"
  },
  "permissions": [
    "file:read",
    "file:write",
    "shell:execute"
  ],
  "triggers": ["my-skill", "ms"]
}
```

### 入口文件

```typescript
// index.ts
import { Skill, Tool } from 'openclaw-sdk'

export default new Skill({
  name: 'my-skill',
  
  tools: [
    new Tool({
      name: 'analyze',
      description: '分析指定文件',
      parameters: {
        type: 'object',
        properties: {
          path: { type: 'string', description: '文件路径' }
        },
        required: ['path']
      },
      execute: async (params, context) => {
        const content = await context.fs.readFile(params.path)
        return { content, analysis: '...' }
      }
    })
  ],
  
  execute: async (input, context) => {
    const result = await context.callTool('analyze', { path: input.path })
    return result
  }
})
```

### 发布技能

```bash
# 发布到 ClawHub
openclaw skills publish

# 发布到私有仓库
openclaw skills publish --registry https://my-registry.com
```

## 热门 Skills 推荐

### 开发效率

| Skill | Stars | 说明 |
|-------|-------|------|
| `code-review` | 15k+ | 智能代码审查 |
| `test-generator` | 12k+ | 自动生成测试 |
| `refactor-helper` | 8k+ | 代码重构辅助 |
| `doc-writer` | 6k+ | 文档自动生成 |

### 自动化

| Skill | Stars | 说明 |
|-------|-------|------|
| `web-automation` | 10k+ | 网页自动化 |
| `email-bot` | 7k+ | 邮件自动处理 |
| `file-organizer` | 5k+ | 文件自动整理 |
| `backup-manager` | 4k+ | 自动备份 |

### 数据处理

| Skill | Stars | 说明 |
|-------|-------|------|
| `data-pipeline` | 9k+ | 数据管道 |
| `report-generator` | 6k+ | 报告生成 |
| `api-tester` | 5k+ | API 测试 |

## Skill 最佳实践

### 1. 按需安装

只安装真正需要的技能，避免资源浪费。

### 2. 定期更新

```bash
# 每周更新一次
openclaw skills update --all
```

### 3. 检查权限

安装前检查技能请求的权限：

```bash
openclaw skills info <skill-name> --permissions
```

### 4. 使用沙箱

测试新技能时使用沙箱模式：

```bash
openclaw --sandbox
```
