# Hooks 钩子系统

## 概述

Hooks 允许在特定事件发生时执行自定义逻辑，扩展 Claude Code 的能力。

## Hook 类型

| 事件 | 说明 |
|------|------|
| `before:query` | 查询执行前 |
| `after:query` | 查询执行后 |
| `before:tool` | 工具执行前 |
| `after:tool` | 工具执行后 |
| `on:error` | 错误发生时 |
| `on:file_change` | 文件变更时 |

## 配置 Hooks

### 配置文件

```json
// ~/.claude/hooks.json
{
  "hooks": [
    {
      "event": "before:query",
      "handler": "echo 'Query starting...'"
    },
    {
      "event": "after:tool",
      "handler": "./scripts/log-tool.sh"
    }
  ]
}
```

### 项目级配置

```json
// .claude/hooks.json
{
  "hooks": [
    {
      "event": "after:query",
      "handler": "npm run lint"
    }
  ]
}
```

## Hook 开发

### Shell 脚本

```bash
#!/bin/bash
# scripts/log-tool.sh

echo "Tool: $TOOL_NAME" >> ~/.claude/logs/tools.log
echo "Time: $(date)" >> ~/.claude/logs/tools.log
echo "---" >> ~/.claude/logs/tools.log
```

### TypeScript

```typescript
// .claude/hooks/logging.ts
import { Hook } from '@anthropic-ai/claude-code-sdk'

export const loggingHook: Hook = {
  event: 'after:query',
  priority: 100,
  
  async handler(context) {
    await context.logger.info('Query completed', {
      duration: context.duration,
      tokens: context.tokenUsage
    })
  }
}
```

## 使用场景

### 自动格式化

```json
{
  "hooks": [
    {
      "event": "after:file_change",
      "handler": "prettier --write $FILE_PATH"
    }
  ]
}
```

### 自动测试

```json
{
  "hooks": [
    {
      "event": "after:query",
      "filter": { "filesChanged": true },
      "handler": "npm run test:related"
    }
  ]
}
```

### 通知发送

```typescript
// .claude/hooks/notify.ts
export const notifyHook: Hook = {
  event: 'after:query',
  
  async handler(context) {
    if (context.result.success) {
      await fetch('https://api.slack.com/...', {
        method: 'POST',
        body: JSON.stringify({
          text: `Task completed: ${context.query}`
        })
      })
    }
  }
}
```

### 审计日志

```typescript
// .claude/hooks/audit.ts
export const auditHook: Hook = {
  event: 'after:tool',
  
  async handler(context) {
    await context.db.insert('audit_log', {
      timestamp: Date.now(),
      tool: context.toolName,
      params: context.params,
      result: context.result
    })
  }
}
```

## Hook 上下文

```typescript
interface HookContext {
  event: string
  query?: string
  toolName?: string
  params?: any
  result?: any
  duration?: number
  tokenUsage?: TokenUsage
  filesChanged?: string[]
  error?: Error
  
  logger: Logger
  db: Database
  fs: FileSystem
}
```

## Hook 优先级

```json
{
  "hooks": [
    {
      "event": "before:query",
      "priority": 100,
      "handler": "high-priority.sh"
    },
    {
      "event": "before:query",
      "priority": 50,
      "handler": "normal-priority.sh"
    }
  ]
}
```

优先级越高越先执行。
