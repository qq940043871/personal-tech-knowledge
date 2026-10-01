# Skill架构

> 模块：Skill系统
> 更新时间：2026-03-29

---

## 一、Skill定义

```python
class Skill:
    """Skill基类"""
    
    def __init__(self, name: str, description: str, version: str = "1.0.0"):
        self.name = name
        self.description = description
        self.version = version
        self.enabled = True
        self.permission_level = PermissionLevel.USER
    
    async def execute(self, context: SkillContext) -> SkillResult:
        """执行Skill"""
        raise NotImplementedError
    
    def get_schema(self) -> Dict:
        """返回OpenAPI schema"""
        return {
            "name": self.name,
            "description": self.description,
            "version": self.version,
            "parameters": self.get_parameters()
        }
    
    def get_parameters(self) -> Dict:
        """返回参数定义"""
        return {}


@dataclass
class SkillContext:
    """Skill执行上下文"""
    user_id: str
    session_id: str
    messages: List[Dict]
    parameters: Dict
    metadata: Dict


@dataclass
class SkillResult:
    """Skill执行结果"""
    success: bool
    output: Any = None
    error: str = None
    metadata: Dict = None
```

---

## 二、Skill管理器

```python
class SkillManager:
    """Skill管理器"""
    
    def __init__(self):
        self.skills: Dict[str, Skill] = {}
        self.registries: List[SkillRegistry] = []
    
    def register(self, skill: Skill):
        """注册Skill"""
        if skill.name in self.skills:
            raise ValueError(f"Skill {skill.name} already registered")
        self.skills[skill.name] = skill
    
    async def execute(self, skill_name: str, context: SkillContext) -> SkillResult:
        """执行Skill"""
        skill = self.skills.get(skill_name)
        if not skill:
            return SkillResult(success=False, error=f"Skill {skill_name} not found")
        
        if not skill.enabled:
            return SkillResult(success=False, error=f"Skill {skill_name} is disabled")
        
        try:
            result = await skill.execute(context)
            return result
        except Exception as e:
            return SkillResult(success=False, error=str(e))
    
    def get_skill(self, name: str) -> Skill:
        return self.skills.get(name)
    
    def list_skills(self) -> List[Dict]:
        return [
            {
                "name": s.name,
                "description": s.description,
                "version": s.version,
                "enabled": s.enabled
            }
            for s in self.skills.values()
        ]
```

---

*下一步：Skill注册*
