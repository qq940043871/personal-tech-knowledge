# Agent SDK

## 概述

Claude Agent SDK（原 Claude Code SDK）提供编程接口，让开发者可以构建自定义的 AI Agent 应用。

## 安装

```bash
npm install @anthropic-ai/claude-agent-sdk
```

## 基本用法

```typescript
import { Agent } from '@anthropic-ai/claude-agent-sdk'

const agent = new Agent({
  model: 'claude-sonnet-4-5',
  apiKey: process.env.ANTHROPIC_API_KEY
})

// 执行任务
const result = await agent.execute('分析这个项目的结构')

console.log(result.output)
```

## 配置选项

```typescript
const agent = new Agent({
  model: 'claude-sonnet-4-5',
  apiKey: process.env.ANTHROPIC_API_KEY,
  
  // 工作目录
  cwd: '/path/to/project',
  
  // 权限模式
  permissionMode: 'interactive',
  
  // 工具配置
  tools: {
    fs: { enabled: true },
    shell: { enabled: true },
    git: { enabled: true }
  },
  
  // 超时设置
  timeout: 60000,
  
  // 日志级别
  logLevel: 'info'
})
```

## 工具注册

```typescript
import { Tool } from '@anthropic-ai/claude-agent-sdk'

const customTool = new Tool({
  name: 'query_database',
  description: '查询数据库',
  
  parameters: {
    type: 'object',
    properties: {
      sql: { type: 'string' }
    },
    required: ['sql']
  },
  
  async execute(params) {
    const result = await db.query(params.sql)
    return result
  }
})

agent.registerTool(customTool)
```

## 流式响应

```typescript
const stream = await agent.executeStream('分析代码')

for await (const chunk of stream) {
  if (chunk.type === 'text') {
    process.stdout.write(chunk.content)
  } else if (chunk.type === 'tool_use') {
    console.log(`工具调用: ${chunk.name}`)
  }
}
```

## 事件监听

```typescript
agent.on('tool_start', (event) => {
  console.log(`开始执行: ${event.tool}`)
})

agent.on('tool_end', (event) => {
  console.log(`执行完成: ${event.tool}`)
})

agent.on('error', (error) => {
  console.error('错误:', error)
})
```

## 子代理

```typescript
// 创建子代理
const subAgent = agent.createSubAgent({
  task: 'analyze-code',
  scope: './src'
})

// 并行执行
const results = await Promise.all([
  subAgent.execute('检查代码风格'),
  subAgent.execute('检查安全问题'),
  subAgent.execute('检查性能问题')
])
```

## 会话管理

```typescript
// 创建会话
const session = agent.createSession()

// 多轮对话
await session.query('分析这个文件')
await session.query('重构它')
await session.query('添加测试')

// 保存会话
await session.save('session-1')

// 加载会话
await agent.loadSession('session-1')
```

## 集成示例

### Express API

```typescript
import express from 'express'
import { Agent } from '@anthropic-ai/claude-agent-sdk'

const app = express()
const agent = new Agent()

app.post('/analyze', async (req, res) => {
  const { code } = req.body
  
  const result = await agent.execute(`分析这段代码:\n${code}`)
  
  res.json({ analysis: result.output })
})

app.listen(3000)
```

### CLI 工具

```typescript
#!/usr/bin/env node
import { Agent } from '@anthropic-ai/claude-agent-sdk'
import { program } from 'commander'

const agent = new Agent()

program
  .command('analyze <path>')
  .action(async (path) => {
    const result = await agent.execute(`分析 ${path}`)
    console.log(result.output)
  })

program.parse()
```

### GitHub Bot

```typescript
import { Agent } from '@anthropic-ai/claude-agent-sdk'

const agent = new Agent()

app.on('pull_request.opened', async (context) => {
  const diff = await context.octokit.pulls.listFiles({
    owner, repo, pull_number
  })
  
  const review = await agent.execute(`
    审查这个 PR 的变更:
    ${JSON.stringify(diff.data)}
  `)
  
  await context.octokit.issues.createComment({
    owner, repo,
    issue_number: pull_number,
    body: review.output
  })
})
```

## 错误处理

```typescript
try {
  const result = await agent.execute(task)
} catch (error) {
  if (error instanceof RateLimitError) {
    await sleep(60000)
    return agent.execute(task)
  }
  
  if (error instanceof PermissionDeniedError) {
    console.log('需要授权:', error.permission)
  }
  
  throw error
}
```

## 最佳实践

1. **设置超时**: 避免长时间运行
2. **限制权限**: 最小权限原则
3. **错误处理**: 捕获并处理异常
4. **日志记录**: 记录关键操作
5. **资源清理**: 及时释放资源
