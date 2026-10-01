# MCP 协议集成

## 概述

MCP (Model Context Protocol) 是 Anthropic 推出的模型上下文协议，Claude Code 完整支持 MCP 协议。

## MCP 架构

```
┌─────────────────────────────────────────────────────────────┐
│                    MCP 架构                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐         ┌─────────────┐                   │
│  │ Claude Code │ ◀─────▶ │ MCP Server  │                   │
│  │   (Client)  │         │             │                   │
│  └─────────────┘         └──────┬──────┘                   │
│                                 │                           │
│                    ┌────────────┼────────────┐             │
│                    │            │            │             │
│                    ▼            ▼            ▼             │
│             ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│             │ Database │ │   API    │ │  Tools   │        │
│             │ Server   │ │ Services │ │          │        │
│             └──────────┘ └──────────┘ └──────────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 传输方式

| 方式 | 说明 | 适用场景 |
|------|------|----------|
| stdio | 标准输入输出 | 本地进程 |
| SSE | Server-Sent Events | HTTP 服务 |
| WebSocket | 双向通信 | 实时交互 |
| HTTP | REST API | 简单集成 |

## 配置 MCP Server

### stdio 方式

```json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["server.js"],
      "env": {
        "API_KEY": "your-key"
      }
    }
  }
}
```

### SSE 方式

```json
{
  "mcpServers": {
    "my-server": {
      "url": "http://localhost:3000/sse",
      "headers": {
        "Authorization": "Bearer token"
      }
    }
  }
}
```

## MCP Server 开发

### Node.js 示例

```typescript
import { Server } from '@modelcontextprotocol/sdk'

const server = new Server({
  name: 'my-mcp-server',
  version: '1.0.0'
})

// 注册工具
server.tool('query_database', {
  description: '查询数据库',
  parameters: {
    type: 'object',
    properties: {
      sql: { type: 'string' }
    },
    required: ['sql']
  }
}, async (params) => {
  const result = await db.query(params.sql)
  return { content: JSON.stringify(result) }
})

// 注册资源
server.resource('database_schema', {
  description: '数据库结构',
  mimeType: 'application/json'
}, async () => {
  const schema = await db.getSchema()
  return { content: JSON.stringify(schema) }
})

server.start()
```

## 使用 MCP 工具

```
用户: 使用 query_database 查询用户表

Claude Code: 正在调用 MCP 工具...

[MCP] query_database 执行中...
[MCP] 返回结果: 123 条记录

查询结果：
| id | name | email |
|----|------|-------|
| 1  | 张三 | ...   |
...
```

## MCP 资源访问

```
用户: 显示数据库结构

Claude Code: 正在获取 MCP 资源...

[MCP] 获取 database_schema...

数据库结构：
- users: 用户表
- orders: 订单表
- products: 产品表
```

## 内置 MCP 集成

| 集成 | 说明 |
|------|------|
| PostgreSQL | 数据库操作 |
| SQLite | 本地数据库 |
| GitHub | GitHub API |
| Google Drive | 云存储 |
| Slack | 消息通知 |

## MCP 最佳实践

### 1. 错误处理

```typescript
server.tool('my_tool', {}, async (params) => {
  try {
    const result = await doSomething(params)
    return { content: JSON.stringify(result) }
  } catch (error) {
    return {
      isError: true,
      content: error.message
    }
  }
})
```

### 2. 权限控制

```typescript
server.tool('sensitive_tool', {}, async (params, context) => {
  if (!context.auth.hasPermission('admin')) {
    return { isError: true, content: 'Permission denied' }
  }
  // ...
})
```

### 3. 缓存

```typescript
const cache = new Map()

server.resource('expensive_data', {}, async () => {
  if (cache.has('data')) {
    return cache.get('data')
  }
  
  const data = await fetchExpensiveData()
  cache.set('data', data)
  return data
})
```
