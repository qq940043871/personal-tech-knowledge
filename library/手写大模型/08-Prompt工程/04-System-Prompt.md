# System-Prompt

> 模块：Prompt工程
> 更新时间：2026-03-29

---

## 一、系统提示词

```python
class SystemPromptManager:
    """系统提示管理器"""
    
    def __init__(self):
        self.prompts: Dict[str, str] = {}
        self._register_defaults()
    
    def _register_defaults(self):
        """注册默认提示词"""
        self.prompts["assistant"] = """你是一个有用的AI助手。
请用清晰、专业的方式回答用户的问题。
如果不确定，请诚实说明。"""
        
        self.prompts["coder"] = """你是一个专业的程序员。
擅长各种编程语言和框架。
请提供高质量、可运行的代码。"""
        
        self.prompts["analyst"] = """你是一个数据分析专家。
擅长从数据中发现规律和洞察。
请用数据说话。"""
    
    def get(self, name: str) -> str:
        return self.prompts.get(name, self.prompts["assistant"])
    
    def build_messages(self, system_name: str, 
                     conversation: List[Dict]) -> List[Dict]:
        """构建完整消息列表"""
        return [{"role": "system", "content": self.get(system_name)}] + conversation
```

---

*下一步：RAG原理*
