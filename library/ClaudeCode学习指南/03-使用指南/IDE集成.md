# IDE 集成

## VS Code 集成

### 安装扩展

```bash
# 方法 1: 在 VS Code 终端中启动
claude

# 方法 2: 手动安装
# 在扩展市场搜索 "Claude Code" 安装
```

### 功能特性

| 功能 | 说明 |
|------|------|
| Inline Diff | 内联差异显示 |
| @ 引用 | 引用文件和目录 |
| 计划审阅 | 可视化计划 |
| 对话历史 | 多会话管理 |
| 终端输出 | 引用终端输出 |

### 使用方式

```
在 VS Code 中：

1. 打开命令面板 (Cmd+Shift+P)
2. 输入 "Claude Code"
3. 选择操作

或使用快捷键：
- Cmd+K: 快速提问
- Cmd+Shift+K: 打开侧边栏
```

### Inline Diff

```
修改代码时，Claude Code 会显示内联差异：

- 红色背景: 删除的代码
- 绿色背景: 新增的代码
- 黄色背景: 修改的代码

点击 "Accept" 或 "Reject" 确认更改。
```

## JetBrains 集成

### 安装插件

1. 打开 Settings → Plugins
2. 搜索 "Claude Code"
3. 点击 Install

### 功能特性

- 代码智能提示
- 内联代码建议
- 项目分析
- Git 集成

## Desktop 应用

### 安装

```bash
# macOS
brew install --cask claude-code

# Windows
winget install Anthropic.ClaudeCode
```

### 功能特性

| 功能 | 说明 |
|------|------|
| 多会话并行 | 同时管理多个会话 |
| 可视化 Diff | 图形化差异对比 |
| Schedule | 定时任务 |
| Dispatch | 拉起会话 |

## Web 端

### 访问方式

访问 https://claude.ai/code

### 功能特性

- 云端代码会话
- 长任务执行
- 定时任务
- 本地会话接力

### 远程控制

```
在网页端可以：
1. 查看本地 CLI 状态
2. 发送任务到本地
3. 查看执行结果
4. 接力继续工作
```

## 移动端

### 功能

- 查看会话状态
- 接收通知
- 简单指令
- 会话接力

### 使用方式

1. 安装 Claude App
2. 登录账户
3. 查看 Code 标签页

## 配置同步

### 跨设备同步

```json
{
  "sync": {
    "enabled": true,
    "include": [
      "skills",
      "commands",
      "settings"
    ]
  }
}
```

### 会话恢复

```
在任意设备上：

/restore <session-id>

恢复之前的会话上下文。
```
