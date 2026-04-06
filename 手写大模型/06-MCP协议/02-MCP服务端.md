# MCP服务端

> 模块：MCP协议
> 更新时间：2026-03-29

---

## 一、服务端实现

```python
class MCPServer:
    """MCP服务器"""
    
    def __init__(self, host: str = "localhost", port: int = 8080):
        self.host = host
        self.port = port
        self.tools: Dict[str, Tool] = {}
        self.resources: Dict[str, Resource] = {}
        self.prompts: Dict[str, Prompt] = {}
        self.app = FastAPI()
        self.setup_routes()
    
    def setup_routes(self):
        """设置路由"""
        
        @self.app.post("/mcp/v1/method")
        async def handle_method(request: MCPRequest):
            """处理MCP请求"""
            method = request.method
            params = request.params or {}
            
            if method == "tools/list":
                return await self.list_tools()
            elif method == "tools/call":
                return await self.call_tool(params)
            elif method == "resources/list":
                return await self.list_resources()
            elif method == "initialize":
                return await self.initialize(params)
            else:
                raise ValueError(f"Unknown method: {method}")
        
        @self.app.get("/mcp/v1/events")
        async def events(request: Request):
            """SSE事件流"""
            async def event_generator():
                # 实现SSE推送
                ...
            return EventSourceResponse(event_generator())
    
    async def register_tool(self, tool: Tool):
        """注册工具"""
        self.tools[tool.name] = tool
    
    async def call_tool(self, params: Dict) -> Dict:
        """调用工具"""
        tool_name = params.get("name")
        arguments = params.get("arguments", {})
        
        tool = self.tools.get(tool_name)
        if not tool:
            raise ValueError(f"Tool not found: {tool_name}")
        
        result = await tool.execute(arguments)
        return {"content": [{"type": "text", "text": str(result)}]}
```

---

## 二、工具定义

```python
@dataclass
class Tool:
    """MCP工具"""
    name: str
    description: str
    input_schema: Dict  # JSON Schema
    
    async def execute(self, arguments: Dict) -> Any:
        raise NotImplementedError


class WeatherTool(Tool):
    """天气查询工具"""
    
    name = "weather"
    description = "查询指定城市的天气信息"
    input_schema = {
        "type": "object",
        "properties": {
            "city": {
                "type": "string",
                "description": "城市名称"
            },
            "country": {
                "type": "string",
                "description": "国家代码"
            }
        },
        "required": ["city"]
    }
    
    async def execute(self, arguments: Dict) -> Dict:
        city = arguments["city"]
        country = arguments.get("country", "CN")
        return await self.weather_api.get_weather(city, country)
```

---

*下一步：MCP客户端*
