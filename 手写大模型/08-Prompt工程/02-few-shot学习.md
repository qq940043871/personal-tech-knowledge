# few-shot学习

> 模块：Prompt工程
> 更新时间：2026-03-29

---

## 一、Few-Shot策略

```
Few-Shot示例：
  提供1-N个示例帮助模型理解任务

示例格式：
  输入 → 输出
  输入 → 输出
  输入 → ?

最佳实践：
  1. 示例要有代表性
  2. 格式要一致
  3. 3-5个示例通常足够
  4. 示例要覆盖边界情况
```

---

## 二、示例管理器

```python
class FewShotManager:
    """Few-Shot示例管理器"""
    
    def __init__(self, template: str):
        self.template = template
        self.examples: List[Dict] = []
    
    def add_example(self, input_text: str, output_text: str):
        """添加示例"""
        self.examples.append({
            "input": input_text,
            "output": output_text
        })
    
    def build_prompt(self, query: str, n: int = None) -> str:
        """构建Few-Shot提示"""
        if n is None:
            n = len(self.examples)
        
        examples_text = []
        for ex in self.examples[:n]:
            examples_text.append(self.template.format(
                input=ex["input"], output=ex["output"]
            ))
        
        return "\n\n".join(examples_text) + f"\n\n{self.template.format(input=query, output='')}"
    
    def build_messages(self, query: str, n: int = None) -> List[Dict]:
        """构建消息格式"""
        messages = []
        for ex in self.examples[:n or len(self.examples)]:
            messages.append({"role": "user", "content": ex["input"]})
            messages.append({"role": "assistant", "content": ex["output"]})
        messages.append({"role": "user", "content": query})
        return messages
```

---

*下一步：CoT思维链*
