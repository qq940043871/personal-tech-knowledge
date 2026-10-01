# 自定义 Skills 开发

## 开发环境准备

### 安装 SDK

```bash
npm install openclaw-sdk
# 或
pnpm add openclaw-sdk
```

### 项目初始化

```bash
# 创建技能项目
mkdir my-skill && cd my-skill
npm init -y

# 安装开发依赖
pnpm add -D typescript @types/node vitest
```

## Skill 结构

### 目录结构

```
my-skill/
├── skill.json          # 技能元数据
├── src/
│   ├── index.ts        # 入口文件
│   ├── tools/          # 工具定义
│   │   └── main.ts
│   ├── prompts/        # 提示词模板
│   │   └── system.md
│   └── utils/          # 工具函数
│       └── helper.ts
├── tests/
│   └── index.test.ts
└── package.json
```

### skill.json 配置

```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "我的自定义技能",
  "author": "Your Name",
  "license": "MIT",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "triggers": ["my-skill", "ms"],
  "keywords": ["automation", "productivity"],
  "permissions": [
    "fs:read",
    "fs:write"
  ],
  "dependencies": {},
  "config": {
    "apiKey": {
      "type": "string",
      "required": false,
      "description": "可选的 API 密钥"
    }
  }
}
```

## 核心 API

### Skill 类

```typescript
import { Skill, Tool, Prompt } from 'openclaw-sdk'

const skill = new Skill({
  name: 'my-skill',
  description: '自定义技能描述',
  version: '1.0.0',
  
  triggers: ['my-skill', 'ms'],
  
  tools: [
    // 工具列表
  ],
  
  prompts: [
    // 提示词列表
  ],
  
  async execute(input, context) {
    // 主执行逻辑
  }
})

export default skill
```

### Tool 类

```typescript
import { Tool } from 'openclaw-sdk'

const myTool = new Tool({
  name: 'my-tool',
  description: '工具描述',
  
  parameters: {
    type: 'object',
    properties: {
      path: {
        type: 'string',
        description: '文件路径'
      },
      options: {
        type: 'object',
        properties: {
          recursive: { type: 'boolean' },
          ignore: { type: 'array', items: { type: 'string' } }
        }
      }
    },
    required: ['path']
  },
  
  async execute(params, context) {
    const { path, options } = params
    
    context.logger.info('Executing tool', { path })
    
    const result = await context.fs.readFile(path)
    
    return {
      success: true,
      data: result
    }
  }
})
```

### Prompt 类

```typescript
import { Prompt } from 'openclaw-sdk'

const systemPrompt = new Prompt({
  name: 'system',
  template: `你是一个专业的代码分析助手。

使用以下工具完成任务：
- my-tool: 用于读取文件

请按照以下步骤执行：
1. 分析用户需求
2. 选择合适的工具
3. 执行并返回结果`,
  
  variables: {
    language: '中文'
  }
})
```

## 完整示例

### 代码分析技能

```typescript
// src/index.ts
import { Skill, Tool, Prompt } from 'openclaw-sdk'
import { analyzeCode, detectIssues } from './utils/analyzer'

const analyzeTool = new Tool({
  name: 'analyze-code',
  description: '分析代码质量和潜在问题',
  
  parameters: {
    type: 'object',
    properties: {
      path: {
        type: 'string',
        description: '要分析的文件或目录路径'
      },
      rules: {
        type: 'array',
        items: { type: 'string' },
        description: '要应用的规则列表'
      },
      severity: {
        type: 'string',
        enum: ['error', 'warning', 'info'],
        description: '最低严重级别'
      }
    },
    required: ['path']
  },
  
  async execute(params, context) {
    const { path, rules, severity = 'warning' } = params
    
    context.logger.info('Analyzing code', { path, rules })
    
    const files = await context.fs.glob(path, '**/*.{ts,tsx,js,jsx}')
    
    const results = []
    for (const file of files) {
      const content = await context.fs.readFile(file)
      const issues = await analyzeCode(content, { rules, severity })
      results.push({ file, issues })
    }
    
    return {
      success: true,
      summary: {
        filesAnalyzed: files.length,
        totalIssues: results.reduce((sum, r) => sum + r.issues.length, 0)
      },
      details: results
    }
  }
})

const fixTool = new Tool({
  name: 'fix-issues',
  description: '自动修复检测到的问题',
  
  parameters: {
    type: 'object',
    properties: {
      issues: {
        type: 'array',
        items: {
          type: 'object',
          properties: {
            file: { type: 'string' },
            line: { type: 'number' },
            fix: { type: 'string' }
          }
        },
        description: '要修复的问题列表'
      }
    },
    required: ['issues']
  },
  
  async execute(params, context) {
    const { issues } = params
    const fixed = []
    
    for (const issue of issues) {
      const content = await context.fs.readFile(issue.file)
      const lines = content.split('\n')
      lines[issue.line - 1] = issue.fix
      await context.fs.writeFile(issue.file, lines.join('\n'))
      fixed.push(issue)
    }
    
    return {
      success: true,
      fixedCount: fixed.length
    }
  }
})

const systemPrompt = new Prompt({
  name: 'system',
  template: `你是一个专业的代码质量分析师。

你的任务是：
1. 使用 analyze-code 工具分析代码
2. 总结发现的问题
3. 提供修复建议
4. 在用户确认后使用 fix-issues 工具修复

分析规则：
- 检查代码风格
- 检查潜在 bug
- 检查安全问题
- 检查性能问题

输出格式：
使用 Markdown 格式，包含问题列表和修复建议。`
})

export default new Skill({
  name: 'code-analyzer',
  description: '代码质量分析和自动修复',
  version: '1.0.0',
  
  triggers: ['analyze', 'code-review', 'lint'],
  
  tools: [analyzeTool, fixTool],
  prompts: [systemPrompt],
  
  async execute(input, context) {
    const result = await context.callTool('analyze-code', {
      path: input.path || '.',
      rules: input.rules,
      severity: input.severity
    })
    
    if (result.summary.totalIssues > 0) {
      context.emit('issues-found', result)
    }
    
    return result
  }
})
```

## 上下文 API

### 文件系统

```typescript
// 读取文件
const content = await context.fs.readFile(path)

// 写入文件
await context.fs.writeFile(path, content)

// 删除文件
await context.fs.delete(path)

// 列出目录
const files = await context.fs.readdir(dir)

// 匹配文件
const matches = await context.fs.glob(dir, pattern)

// 检查存在
const exists = await context.fs.exists(path)
```

### Shell 执行

```typescript
// 执行命令
const result = await context.shell.execute('git status')

// 带选项执行
const result = await context.shell.execute('npm test', {
  cwd: '/path/to/project',
  timeout: 60000,
  env: { NODE_ENV: 'test' }
})
```

### 日志记录

```typescript
context.logger.debug('Debug message', { data })
context.logger.info('Info message', { data })
context.logger.warn('Warning message', { data })
context.logger.error('Error message', { error })
```

### 配置访问

```typescript
// 获取技能配置
const apiKey = context.config.get('apiKey')

// 获取全局配置
const model = context.config.get('global.model')
```

### 记忆操作

```typescript
// 存储记忆
await context.memory.add({
  content: '用户偏好使用 TypeScript',
  type: 'preference',
  metadata: { source: 'skill' }
})

// 检索记忆
const memories = await context.memory.search('TypeScript', { limit: 5 })
```

## 测试

### 单元测试

```typescript
// tests/index.test.ts
import { describe, it, expect, vi } from 'vitest'
import skill from '../src/index'

describe('code-analyzer skill', () => {
  it('should analyze code correctly', async () => {
    const mockContext = {
      fs: {
        glob: vi.fn().mockResolvedValue(['test.ts']),
        readFile: vi.fn().mockResolvedValue('const x = 1')
      },
      logger: { info: vi.fn() }
    }
    
    const result = await skill.execute(
      { path: '.' },
      mockContext as any
    )
    
    expect(result.success).toBe(true)
    expect(result.summary.filesAnalyzed).toBe(1)
  })
})
```

## 发布

### 打包

```bash
# 构建
pnpm build

# 打包
openclaw skill pack
```

### 发布到 ClawHub

```bash
# 登录
openclaw login

# 发布
openclaw skill publish
```

### 本地安装测试

```bash
# 从本地目录安装
openclaw skills install ./my-skill

# 测试
openclaw
> /skill my-skill
```
