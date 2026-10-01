# MCP工具定义

> 模块：MCP协议
> 更新时间：2026-03-29

---

## 一、Tool Schema规范

```
MCP工具定义结构：
  - name：工具唯一标识（如 "weather.get_forecast"）
  - description：工具功能描述（供LLM理解何时调用）
  - inputSchema：JSON Schema格式的参数定义
    - type: "object"
    - properties: 参数字段定义
    - required: 必填字段列表
```

---

## 二、Tool定义实现

```python
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Callable
import jsonschema


@dataclass
class ToolParameter:
    """工具参数定义"""
    name: str
    type: str              # string / number / integer / boolean / array / object
    description: str
    required: bool = True
    enum: Optional[List[str]] = None
    default: Any = None


@dataclass
class ToolDefinition:
    """MCP工具定义"""
    name: str
    description: str
    parameters: List[ToolParameter] = field(default_factory=list)
    handler: Optional[Callable] = None

    def to_schema(self) -> Dict:
        """导出为JSON Schema格式"""
        properties = {}
        required = []

        for param in self.parameters:
            prop = {
                "type": param.type,
                "description": param.description,
            }
            if param.enum:
                prop["enum"] = enum
            if param.default is not None:
                prop["default"] = param.default

            properties[param.name] = prop
            if param.required:
                required.append(param.name)

        return {
            "name": self.name,
            "description": self.description,
            "inputSchema": {
                "type": "object",
                "properties": properties,
                "required": required,
            }
        }

    def validate_input(self, arguments: Dict) -> bool:
        """校验输入参数"""
        schema = self.to_schema()["inputSchema"]
        try:
            jsonschema.validate(instance=arguments, schema=schema)
            return True
        except jsonschema.ValidationError as e:
            raise ValueError(f"参数校验失败: {e.message}")
```

---

## 三、工具注解与注册

```python
from functools import wraps


class ToolRegistry:
    """工具注册中心"""

    def __init__(self):
        self.tools: Dict[str, ToolDefinition] = {}

    def tool(self, name: str, description: str,
             parameters: List[ToolParameter] = None):
        """工具注册装饰器"""
        def decorator(func: Callable):
            definition = ToolDefinition(
                name=name,
                description=description,
                parameters=parameters or [],
                handler=func,
            )
            self.tools[name] = definition

            @wraps(func)
            async def wrapper(*args, **kwargs):
                return await func(*args, **kwargs)
            return wrapper
        return decorator

    def get_tool(self, name: str) -> Optional[ToolDefinition]:
        return self.tools.get(name)

    def list_tools(self) -> List[Dict]:
        """列出所有工具的Schema"""
        return [tool.to_schema() for tool in self.tools.values()]

    async def call_tool(self, name: str, arguments: Dict) -> Any:
        """调用工具"""
        tool = self.tools.get(name)
        if not tool:
            raise ValueError(f"Tool not found: {name}")

        # 参数校验
        tool.validate_input(arguments)

        # 执行
        if tool.handler:
            return await tool.handler(**arguments)
        raise ValueError(f"Tool {name} has no handler")


# 使用示例
registry = ToolRegistry()

@registry.tool(
    name="weather.get_forecast",
    description="获取指定城市的天气预报",
    parameters=[
        ToolParameter(
            name="city",
            type="string",
            description="城市名称",
            required=True,
        ),
        ToolParameter(
            name="days",
            type="integer",
            description="预报天数（1-7）",
            required=False,
            default=3,
        ),
    ]
)
async def get_forecast(city: str, days: int = 3) -> Dict:
    return {"city": city, "days": days, "forecast": "晴天"}
```

---

*下一步：Prompt模板*
