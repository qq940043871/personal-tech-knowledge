# Skill执行

> 模块：Skill系统
> 更新时间：2026-03-29

---

## 一、执行流程

```python
class SkillExecutor:
    """Skill执行器"""
    
    def __init__(self, skill_manager: SkillManager, 
                 timeout: float = 30.0):
        self.skill_manager = skill_manager
        self.timeout = timeout
        self.execution_history = []
    
    async def execute(self, skill_name: str, 
                    parameters: Dict,
                    context: Dict) -> SkillResult:
        """执行单个Skill"""
        
        # 1. 参数验证
        skill = self.skill_manager.get_skill(skill_name)
        validated_params = self.validate_parameters(skill, parameters)
        
        # 2. 构建上下文
        skill_context = SkillContext(
            user_id=context.get("user_id"),
            session_id=context.get("session_id"),
            messages=context.get("messages", []),
            parameters=validated_params,
            metadata=context.get("metadata", {})
        )
        
        # 3. 执行（带超时）
        try:
            result = await asyncio.wait_for(
                self.skill_manager.execute(skill_name, skill_context),
                timeout=self.timeout
            )
            
            self.execution_history.append({
                "skill": skill_name,
                "params": validated_params,
                "success": result.success,
                "duration": result.metadata.get("duration", 0)
            })
            
            return result
            
        except asyncio.TimeoutError:
            return SkillResult(
                success=False,
                error=f"Skill execution timeout after {self.timeout}s"
            )
    
    def validate_parameters(self, skill: Skill, parameters: Dict) -> Dict:
        """参数验证"""
        schema = skill.get_parameters()
        validated = {}
        
        for param in schema:
            name = param["name"]
            required = param.get("required", False)
            
            if name in parameters:
                validated[name] = parameters[name]
            elif "default" in param:
                validated[name] = param["default"]
            elif required:
                raise ValueError(f"Missing required parameter: {name}")
        
        return validated
```

---

## 二、权限控制

```python
class PermissionLevel(Enum):
    USER = 1      # 用户级
    ADMIN = 2       # 管理员级
    SYSTEM = 3      # 系统级

class PermissionGuard:
    """权限守卫"""
    
    @staticmethod
    def check_permission(user_level: PermissionLevel, 
                         skill_level: PermissionLevel) -> bool:
        return user_level.value >= skill_level.value
    
    def require_permission(self, required_level: PermissionLevel):
        def decorator(func):
            @wraps(func)
            async def wrapper(self, context, *args, **kwargs):
                if not self.check_permission(context.user_level, required_level):
                    raise PermissionError(
                        f"Permission denied: requires level {required_level}"
                    )
                return await func(self, context, *args, **kwargs)
            return wrapper
        return decorator
```

---

*下一步：MCP协议概述*
