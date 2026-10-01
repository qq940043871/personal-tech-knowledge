# MCP客户端

> 模块：MCP协议
> 更新时间：2026-03-29

---

## 一、客户端实现

```python
class MCPClient:
    """MCP客户端"""
    
    def __init__(self, server_url: str):
        self.server_url = server_url
        self.session_id = str(uuid.uuid4())
        self.tools: List[Dict] = []
        self.resources: List[Dict] = []
    
    async def connect(self):
        """连接服务器"""
        async with aiohttp.ClientSession() as session:
            # 初始化
            response = await session.post(
                f"{self.server_url}/mcp/v1/method",
                json={
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "initialize",
                    "params": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {"roots": {}, "sampling": {}},
                        "clientInfo": {"name": "my-app", "version": "1.0.0"}
                    }
                }
            )
            result = await response.json()
            
            # 获取工具列表
            await self.refresh_tools()
    
    async def refresh_tools(self):
        """刷新工具列表"""
        async with aiohttp.ClientSession() as session:
            response = await session.post(
                f"{self.server_url}/mcp/v1/method",
                json={
                    "jsonrpc": "2.0",
                    "id": 2,
                    "method": "tools/list"
                }
            )
            result = await response.json()
            self.tools = result.get("tools", [])
    
    async def call_tool(self, tool_name: str, arguments: Dict) -> Any:
        """调用工具"""
        async with aiohttp.ClientSession() as session:
            response = await session.post(
                f"{self.server_url}/mcp/v1/method",
                json={
                    "jsonrpc": "2.0",
                    "id": 3,
                    "method": "tools/call",
                    "params": {
                        "name": tool_name,
                        "arguments": arguments
                    }
                }
            )
            result = await response.json()
            return result.get("content", [{}])[0].get("text")
```

---

## 二、集成到LLM

```python
class MCPToolIntegration:
    """MCP工具集成"""
    
    def __init__(self, mcp_client: MCPClient):
        self.mcp_client = mcp_client
    
    def get_tools_for_llm(self) -> List[Dict]:
        """转换为LLM工具格式"""
        tools = []
        for tool in self.mcp_client.tools:
            tools.append({
                "type": "function",
                "function": {
                    "name": tool["name"],
                    "description": tool["description"],
                    "parameters": tool["inputSchema"]
                }
            })
        return tools
    
    async def handle_tool_call(self, tool_call: Dict) -> str:
        """处理LLM的工具调用"""
        tool_name = tool_call["function"]["name"]
        arguments = tool_call["function"]["arguments"]
        
        return await self.mcp_client.call_tool(tool_name, arguments)
```

---

*下一步：函数调用原理*
