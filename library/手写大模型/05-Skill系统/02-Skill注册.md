# Skill注册

> 模块：Skill系统
> 更新时间：2026-03-29

---

## 一、装饰器注册

```python
class SkillRegistry:
    """Skill注册器"""
    
    @staticmethod
    def register(name: str, description: str, parameters: List[Dict] = None):
        """注册装饰器"""
        def decorator(skill_class):
            original_init = skill_class.__init__
            def new_init(self, *args, **kwargs):
                original_init(self, *args, **kwargs)
                self.name = name
                self.description = description
                self.parameters = parameters or []
                SkillManager().register(self)
            skill_class.__init__ = new_init
            return skill_class
        return decorator


# 使用示例
@SkillRegistry.register(
    name="weather",
    description="查询天气信息",
    parameters=[
        {
            "name": "city",
            "type": "string",
            "description": "城市名称",
            "required": True
        },
        {
            "name": "days",
            "type": "integer",
            "description": "预报天数",
            "required": False,
            "default": 3
        }
    ]
)
class WeatherSkill(Skill):
    
    async def execute(self, context: SkillContext) -> SkillResult:
        city = context.parameters.get("city")
        days = context.parameters.get("days", 3)
        
        weather_data = await self.get_weather(city, days)
        
        return SkillResult(success=True, output=weather_data)
```

---

## 二、动态注册

```python
class DynamicSkillLoader:
    """动态加载Skill"""
    
    def __init__(self, skill_dir: str):
        self.skill_dir = skill_dir
        self.module_cache = {}
    
    async def load_skill(self, module_path: str) -> Skill:
        """动态加载Skill模块"""
        if module_path not in self.module_cache:
            spec = importlib.util.spec_from_file_location(
                "skill_module", module_path
            )
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            self.module_cache[module_path] = module
        
        # 查找Skill类
        for name, obj in inspect.getmembers(self.module_cache[module_path]):
            if inspect.isclass(obj) and issubclass(obj, Skill) and obj != Skill:
                return obj()
        
        raise ValueError(f"No Skill class found in {module_path}")
    
    async def reload_skill(self, skill_name: str):
        """热重载Skill"""
        skill_path = self.find_skill_path(skill_name)
        skill = await self.load_skill(skill_path)
        SkillManager().register(skill)
```

---

*下一步：Skill执行*
