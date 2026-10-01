# 多Agent协作

> 模块：Agent编排
> 更新时间：2026-03-29

---

## 一、协作模式

```
多Agent模式：
  1. 主管-执行者
     - 主管分解任务
     - 执行者执行子任务
  
  2. 辩论
     - 多个Agent讨论
     - 投票决定
  
  3. 层级
     - Manager → Team Lead → Member
```

---

## 二、实现

```python
class MultiAgentOrchestrator:
    """多Agent编排"""
    
    def __init__(self):
        self.agents: Dict[str, Agent] = {}
        self.manager = None
    
    def add_agent(self, agent: Agent):
        self.agents[agent.name] = agent
    
    def set_manager(self, agent: Agent):
        self.manager = agent
    
    async def run(self, task: str) -> str:
        """运行协作"""
        if not self.manager:
            raise ValueError("No manager set")
        
        # 1. 规划
        plan = await self.manager.plan(task, {
            "available_agents": list(self.agents.keys())
        })
        
        # 2. 分配任务
        for subtask in plan.subtasks:
            agent = self._select_agent(subtask)
            result = await agent.execute(subtask)
            await self.manager.report(result)
        
        # 3. 汇总
        return await self.manager.summarize()
```

---

*下一步：模型量化*
