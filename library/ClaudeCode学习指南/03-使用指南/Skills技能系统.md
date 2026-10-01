# Skills 技能系统

## 什么是 Skills

Skills 是预封装的工作流，就像游戏中的"技能包"，用完即走，不占用上下文。

## 内置 Skills

### 代码开发

| Skill | 说明 |
|-------|------|
| `code-review` | 代码审查 |
| `test-generator` | 测试生成 |
| `doc-writer` | 文档生成 |
| `refactor` | 代码重构 |

### Git 操作

| Skill | 说明 |
|-------|------|
| `smart-commit` | 智能提交 |
| `pr-creator` | PR 创建 |
| `conflict-resolver` | 冲突解决 |

### 项目管理

| Skill | 说明 |
|-------|------|
| `project-init` | 项目初始化 |
| `dependency-check` | 依赖检查 |
| `security-scan` | 安全扫描 |

## 使用 Skills

### 直接调用

```
用户: 使用 code-review 审查 src/

Claude Code: 正在使用 code-review 技能...
[审查结果]
```

### 通过命令调用

```
用户: /skill code-review src/

Claude Code: 执行 code-review 技能...
[审查结果]
```

## 安装 Skills

### 从官方仓库安装

```bash
claude skill install <skill-name>
```

### 从本地安装

```bash
claude skill install ./my-skill
```

### 从 Git 安装

```bash
claude skill install https://github.com/user/skill.git
```

## 管理 Skills

### 查看已安装

```bash
claude skill list
```

```
已安装技能：
名称            | 版本  | 说明
----------------|-------|------------------
code-review     | 1.2.0 | 代码审查
test-generator  | 1.0.0 | 测试生成
doc-writer      | 1.1.0 | 文档生成
```

### 更新技能

```bash
claude skill update <skill-name>
```

### 卸载技能

```bash
claude skill uninstall <skill-name>
```

## Skill 开发

### 目录结构

```
my-skill/
├── skill.json      # 元数据
├── index.ts        # 入口
├── prompts/        # 提示词
└── tools/          # 工具
```

### skill.json

```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "自定义技能",
  "triggers": ["my-skill", "ms"],
  "permissions": ["fs:read", "fs:write"]
}
```

### 入口文件

```typescript
// index.ts
import { Skill, Tool } from '@anthropic-ai/claude-code-sdk'

export default new Skill({
  name: 'my-skill',
  tools: [
    new Tool({
      name: 'analyze',
      description: '分析代码',
      parameters: { ... },
      execute: async (params, context) => { ... }
    })
  ],
  execute: async (input, context) => { ... }
})
```

## 官方 Skills 仓库

GitHub: https://github.com/anthropics/skills

- 32k+ Stars
- 100+ 官方技能
- 社区贡献
