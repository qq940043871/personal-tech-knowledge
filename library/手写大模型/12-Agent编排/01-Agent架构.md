# Agent架构

> 模块：Agent编排
> 更新时间：2026-03-29

---

## 一、Agent定义

```python
class Agent:
    """Agent基类"""
    
    def __init__(self, name: str, role: str, 
                 tools: List[Tool] = None):
        self.name = name
        self.role = role
        self.tools = tools or []
        self.memory = Memory()
        self.llm = LLM()
    
    async def plan(self, task: str, context: Dict) -> Plan:
        """制定计划"""
        prompt = f"""角色：{self.role}
任务：{task}
可用工具：{[t.name for t in self.tools]}

请分析任务并制定执行计划。"""
        
        response = await self.llm.generate(prompt)
        return Plan.parse(response)
    
    async def execute(self, plan: Plan) -> Result:
        """执行计划"""
        results = []
        for step in plan.steps:
            if step.uses_tool:
                tool = self._find_tool(step.tool_name)
                result = await tool.execute(step.arguments)
                results.append(result)
            else:
                result = await self.llm.generate(step.instruction)
                results.append(result)
        
        return Result(results=results)
```

---

## 二、ReAct模式

```python
class ReActAgent:
    """ReAct Agent（推理+行动）"""
    
    def __init__(self, tools: List[Tool]):
        self.tools = tools
    
    async def run(self, task: str) -> str:
        """执行任务"""
        observation = ""
        thought = ""
        
        for _ in range(10):  # 最大步数
            # 1. 推理
            prompt = f"""任务：{task}
观察：{observation}

请思考下一步行动。"""
            response = await self.llm.think(prompt)
            
            # 解析动作
            if response.action == "finish":
                return response.result
            
            # 2. 执行
            tool = self._get_tool(response.tool)
            observation = await tool.execute(response.tool_input)
        
        return "任务未完成"
```

---

*下一步：任务规划*
