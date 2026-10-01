# QueryEngine 核心引擎

## 概述

QueryEngine 是 Claude Code 最核心的模块，每个对话实例创建一个 QueryEngine 实例。负责把用户的输入变成一次完整的 AI 交互。

## 核心职责

```
┌─────────────────────────────────────────────────────────────┐
│                    QueryEngine 职责                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 上下文组装                                              │
│     - 加载历史对话                                          │
│     - 注入系统提示词                                        │
│     - 检索相关记忆                                          │
│                                                             │
│  2. 工具调用决策                                            │
│     - 分析用户意图                                          │
│     - 选择合适工具                                          │
│     - 执行工具调用                                          │
│                                                             │
│  3. 对话流程控制                                            │
│     - 管理对话状态                                          │
│     - 处理多轮交互                                          │
│     - 生成响应                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 执行流程

```
用户输入
    │
    ▼
┌─────────────┐
│ 解析输入    │ ─── 解析命令/自然语言
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 构建上下文  │ ─── 组装消息、工具、记忆
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 调用 AI API │ ─── 发送请求
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│ 检查工具调用 │────▶│ 执行工具    │
└─────────────┘     └──────┬──────┘
       │                   │
       │ 无工具调用        │
       ▼                   │
┌─────────────┐            │
│ 生成响应    │◀───────────┘
└──────┬──────┘
       │
       ▼
用户输出
```

## 核心代码结构

```typescript
class QueryEngine {
  private context: ContextManager
  private tools: ToolRegistry
  private memory: MemoryStore
  
  async query(input: string): Promise<Response> {
    // 1. 构建上下文
    const context = await this.buildContext(input)
    
    // 2. 循环处理
    while (!this.isComplete) {
      // 3. 调用 AI
      const response = await this.callAI(context)
      
      // 4. 检查工具调用
      if (response.toolCalls?.length > 0) {
        const results = await this.executeTools(response.toolCalls)
        context.appendToolResults(results)
        continue
      }
      
      // 5. 返回响应
      return response
    }
  }
  
  private async buildContext(input: string): Promise<Context> {
    const messages = await this.context.getMessages()
    const tools = this.tools.getDefinitions()
    const systemPrompt = await this.getSystemPrompt()
    
    return {
      messages: [...messages, { role: 'user', content: input }],
      tools,
      system: systemPrompt
    }
  }
  
  private async executeTools(calls: ToolCall[]): Promise<ToolResult[]> {
    return Promise.all(
      calls.map(async call => {
        const tool = this.tools.get(call.name)
        const validated = this.validateParams(tool, call.params)
        return tool.execute(validated)
      })
    )
  }
}
```

## 上下文管理

### 消息结构

```typescript
interface Message {
  role: 'user' | 'assistant' | 'system'
  content: string | ContentBlock[]
}

interface ContentBlock {
  type: 'text' | 'tool_use' | 'tool_result'
  text?: string
  toolUseId?: string
  name?: string
  input?: any
  content?: string
}
```

### 上下文压缩

```typescript
class ContextCompressor {
  async compress(messages: Message[]): Promise<Message[]> {
    if (this.getTokenCount(messages) < this.threshold) {
      return messages
    }
    
    // 生成摘要
    const summary = await this.summarize(messages)
    
    return [
      { role: 'assistant', content: summary },
      ...messages.slice(-this.keepRecent)
    ]
  }
}
```

## 工具调用流程

```
┌─────────────────────────────────────────────────────────────┐
│                    工具调用流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. AI 返回工具调用请求                                     │
│     { name: 'file_read', input: { path: '...' } }          │
│                                                             │
│  2. 权限检查                                                │
│     - 检查用户权限                                          │
│     - 请求确认（如需要）                                    │
│                                                             │
│  3. 参数验证                                                │
│     - 验证参数类型                                          │
│     - 验证参数格式                                          │
│                                                             │
│  4. 执行工具                                                │
│     - 调用工具执行函数                                      │
│     - 捕获执行结果                                          │
│                                                             │
│  5. 返回结果                                                │
│     { tool_use_id: '...', content: '...' }                 │
│                                                             │
│  6. 继续对话                                                │
│     - 将结果添加到上下文                                    │
│     - 继续调用 AI                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 状态管理

```typescript
interface QueryState {
  status: 'idle' | 'processing' | 'waiting' | 'complete'
  currentTurn: number
  toolCalls: ToolCall[]
  messages: Message[]
  metadata: {
    startTime: number
    tokenUsage: TokenUsage
  }
}
```

## 错误处理

```typescript
class QueryEngine {
  async query(input: string): Promise<Response> {
    try {
      return await this.execute(input)
    } catch (error) {
      if (error instanceof RateLimitError) {
        await this.waitForRateLimit()
        return this.query(input)
      }
      
      if (error instanceof ToolExecutionError) {
        return this.handleToolError(error)
      }
      
      throw error
    }
  }
}
```
