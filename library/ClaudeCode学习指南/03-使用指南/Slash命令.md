# Slash 命令

## 命令概览

Claude Code 提供了多种内置 Slash 命令，用于快速执行各种操作。

## 核心命令

### 会话管理

```
/clear          清空当前对话
/compact        压缩对话上下文
/resume         恢复上一次会话
```

### 模型控制

```
/model          显示当前模型
/model <name>   切换模型（如 opus, sonnet, haiku）
```

### 系统操作

```
/help           显示帮助
/doctor         运行诊断
/cost           显示费用统计
/config         打开配置
```

### Git 操作

```
/commit         创建 Git 提交
```

### 技能操作

```
/<skill-name>   执行已注册的技能（如 /init, /review, /commit）
```

## 命令详解

### /clear

```
用户: /clear

Claude Code: 对话已清空，开始新的会话。
```

### /compact

```
用户: /compact

Claude Code: 上下文压缩完成：
- 原始大小: 45KB
- 压缩后: 8KB
- 压缩比: 82%
```

### /model

```
# 查看当前模型
用户: /model
Claude Code: 当前模型: claude-sonnet-4-6

# 切换模型
用户: /model opus
Claude Code: 已切换到模型: claude-opus-4-7
```

可用模型：
- `opus` — Claude Opus 4.7，最强能力
- `sonnet` — Claude Sonnet 4.6，平衡性能与速度
- `haiku` — Claude Haiku 4.5，最快速度

### /commit

```
用户: /commit

Claude Code: 分析当前变更...

建议提交信息：
```
feat: add user authentication

- Add login/logout functionality
- Implement JWT token handling
- Add authentication middleware
```

使用此提交信息？[Y/n/e]
```

### /doctor

```
用户: /doctor

Claude Code: 正在运行诊断...

✓ Node.js 版本: v20.10.0
✓ Git 配置: 正常
✓ API 连接: 正常
✓ 文件权限: 正常
⚠ 磁盘空间: 仅剩 5GB

诊断完成，发现 1 个警告。
```

### /cost

```
用户: /cost

Claude Code: 本月费用统计：

| 模型 | 请求数 | Token数 | 费用 |
|------|--------|---------|------|
| claude-sonnet-4-6 | 156 | 1.2M | $12.34 |
| claude-opus-4-7 | 23 | 456K | $4.56 |

总计: $16.90
```

### /config

```
用户: /config

Claude Code: 打开配置文件...
# 会打开 .claude/settings.json 进行编辑
```

## 自定义命令

### 创建自定义命令

在 `.claude/commands/` 目录下创建 Markdown 文件：

```markdown
<!-- .claude/commands/review.md -->
请审查以下代码，关注：
1. 代码质量和最佳实践
2. 潜在的安全问题
3. 性能优化建议

文件路径: $ARGUMENTS
```

### 使用自定义命令

```
用户: /project:review src/
```

自定义命令会作为 `/project:<name>` 或 `/user:<name>` 可用，取决于文件放在项目目录还是用户目录。

## 常用技巧

### 快速切换模型

```
# 使用 Tab 补全
用户: /model son[Tab]
Claude Code: 已切换到模型: claude-sonnet-4-6
```

### 压缩长对话

当对话上下文过长时，使用 `/compact` 压缩：

```
用户: /compact 请保留关于认证模块的讨论
Claude Code: 上下文压缩完成，保留了认证模块相关内容。
```

### 恢复历史会话

```
用户: /resume
Claude Code: 选择要恢复的会话：
1. [2026-05-19] 修复登录Bug
2. [2026-05-18] 添加API接口
...
```
