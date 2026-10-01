# MCP协议概述

> 模块：MCP协议
> 更新时间：2026-03-29

---

## 一、MCP定义

```
MCP（Model Context Protocol）：
  - Anthropic推出的模型上下文协议
  - 标准化的工具/资源定义
  - 支持双向JSON-RPC通信
  - 类似OpenAI的Function Calling

核心概念：
  1. Resources（资源）
     - 可访问的外部数据
     - 文件、API、数据库等
  
  2. Tools（工具）
     - LLM可调用的函数
     - 带参数schema
  
  3. Prompts（提示模板）
     - 预定义的提示词
     - 可参数化
```

---

## 二、协议结构

```python
class MCPMessage:
    """MCP消息"""
    
    @dataclass
    class Request:
        jsonrpc: str = "2.0"
        id: Union[str, int] = None
        method: str = None
        params: Dict = None
    
    @dataclass
    class Response:
        jsonrpc: str = "2.0"
        id: Union[str, int] = None
        result: Any = None
        error: Dict = None


# 核心方法
MCP_METHODS = {
    # 初始化
    "initialize": "初始化连接",
    "initialized": "初始化完成",
    
    # 资源
    "resources/list": "列出资源",
    "resources/read": "读取资源",
    "resources/subscribe": "订阅资源",
    
    # 工具
    "tools/list": "列出工具",
    "tools/call": "调用工具",
    
    # 提示
    "prompts/list": "列出提示",
    "prompts/get": "获取提示",
}
```

---

## 三、集成架构

```
┌─────────────────────────────────────────────────────────┐
│                    LLM应用                               │
│  ┌─────────────────────────────────────────────────┐  │
│  │              MCP Client                            │  │
│  │  - 维护连接                                    │  │
│  │  - 序列化/反序列化                             │  │
│  │  - 重试/超时处理                              │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
                    JSON-RPC over
                    HTTP/SSE/WebSocket
                            │
┌─────────────────────────────────────────────────────────┐
│                    MCP Server                            │
│  ┌─────────────────────────────────────────────────┐  │
│  │              Tool Handler                         │  │
│  │  - 工具注册                                   │  │
│  │  - 参数验证                                   │  │
│  │  - 结果处理                                   │  │
│  └─────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

*下一步：MCP服务端*
