# 自定义 Skills

## 概述

Skills 是预封装的工作流，可以扩展 Claude Code 的能力。

## 目录结构

```
my-skill/
├── skill.json      # 元数据
├── index.ts        # 入口
├── prompts/        # 提示词
│   └── system.md
├── tools/          # 工具
│   └── main.ts
└── tests/
    └── index.test.ts
```

## skill.json

```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "自定义技能",
  "author": "Your Name",
  "triggers": ["my-skill", "ms"],
  "permissions": ["fs:read", "fs:write"],
  "dependencies": {}
}
```

## 入口文件

```typescript
// index.ts
import { Skill, Tool, Prompt } from '@anthropic-ai/claude-code-sdk'

const analyzeTool = new Tool({
  name: 'analyze',
  description: '分析代码',
  
  parameters: {
    type: 'object',
    properties: {
      path: { type: 'string' }
    },
    required: ['path']
  },
  
  async execute(params, context) {
    const content = await context.fs.readFile(params.path)
    const result = analyzeCode(content)
    return { result }
  }
})

const systemPrompt = new Prompt({
  name: 'system',
  template: `你是一个代码分析专家。`
})

export default new Skill({
  name: 'my-skill',
  description: '代码分析技能',
  triggers: ['analyze', 'code-review'],
  tools: [analyzeTool],
  prompts: [systemPrompt],
  
  async execute(input, context) {
    const result = await context.callTool('analyze', {
      path: input.path
    })
    return result
  }
})
```

## 工具定义

```typescript
const myTool = new Tool({
  name: 'my_tool',
  description: '工具描述',
  
  parameters: {
    type: 'object',
    properties: {
      input: { type: 'string', description: '输入' }
    },
    required: ['input']
  },
  
  async execute(params, context) {
    // 访问文件系统
    const content = await context.fs.readFile('file.txt')
    
    // 执行命令
    const result = await context.shell.execute('git status')
    
    // 记录日志
    context.logger.info('Tool executed', { params })
    
    return { success: true, data: result }
  }
})
```

## 提示词模板

```markdown
<!-- prompts/system.md -->
# 系统提示

你是一个专业的代码分析助手。

## 任务
1. 分析代码结构
2. 识别潜在问题
3. 提供优化建议

## 输出格式
使用 Markdown 格式输出分析报告。
```

## 安装使用

### 本地安装

```bash
claude skill install ./my-skill
```

### 从 Git 安装

```bash
claude skill install https://github.com/user/skill.git
```

### 使用

```
用户: /skill my-skill src/

Claude Code: 执行 my-skill 技能...
[分析结果]
```

## 发布

```bash
# 发布到官方仓库
claude skill publish

# 发布到私有仓库
claude skill publish --registry https://my-registry.com
```

## 测试

```typescript
// tests/index.test.ts
import { describe, it, expect } from 'vitest'
import skill from '../src/index'

describe('my-skill', () => {
  it('should analyze code', async () => {
    const result = await skill.execute(
      { path: 'test.ts' },
      mockContext
    )
    expect(result.success).toBe(true)
  })
})
```
