# 特殊token

> 模块：Tokenizer分词器
> 更新时间：2026-03-29

---

## 一、特殊token类型

```
特殊token体系：
  1. BOS（Beginning of Sequence）
     - 序列开始标记
     - 告诉模型"从此开始生成"

  2. EOS（End of Sequence）
     - 序列结束标记
     - 生成到此token时停止

  3. PAD（Padding）
     - 填充标记
     - 将不同长度的序列对齐到相同长度

  4. UNK（Unknown）
     - 未知token
     - 词表中不存在的token用此替代

  5. MASK
     - 掩码标记
     - BERT等MLM预训练任务使用

  6. SEP（Separator）
     - 分隔标记
     - 分隔不同段落或对话角色
```

---

## 二、Chat Template设计

```python
from dataclasses import dataclass, field
from typing import List, Dict, Optional


@dataclass
class ChatMessage:
    """对话消息"""
    role: str        # system / user / assistant / tool
    content: str


@dataclass
class ChatTemplate:
    """Chat Template定义"""
    bos_token: str = "<s>"
    eos_token: str = "</s>"
    system_prefix: str = "<<SYS>>\n"
    system_suffix: str = "\n<</SYS>>\n\n"
    user_prefix: str = "[INST] "
    user_suffix: str = " [/INST] "
    assistant_suffix: str = " "
    default_system: str = "You are a helpful assistant."

    def apply(self, messages: List[ChatMessage]) -> str:
        """将消息列表转换为模型输入字符串"""
        parts = [self.bos_token]

        # 处理system prompt
        system_msgs = [m for m in messages if m.role == "system"]
        system_text = (system_msgs[0].content
                       if system_msgs else self.default_system)

        # 处理user/assistant对话
        dialog_msgs = [m for m in messages if m.role != "system"]
        for i, msg in enumerate(dialog_msgs):
            if msg.role == "user":
                content = msg.content
                if i == 0:
                    # 第一轮对话包含system prompt
                    content = (f"{self.system_prefix}{system_text}"
                               f"{self.system_suffix}{content}")
                parts.append(f"{self.user_prefix}{content}{self.user_suffix}")
            elif msg.role == "assistant":
                parts.append(f"{msg.content}{self.assistant_suffix}")

        return "".join(parts)


# 使用示例
template = ChatTemplate()
messages = [
    ChatMessage(role="system", system="你是一个Python专家"),
    ChatMessage(role="user", content="什么是装饰器？"),
]
prompt = template.apply(messages)
# <s><<SYS>>
# 你是一个Python专家
# <</SYS>>
#
# 什么是装饰器？ [/INST]
```

---

## 三、特殊token与训练

```python
class SpecialTokenManager:
    """特殊token管理器"""

    def __init__(self):
        self.special_tokens: Dict[str, int] = {}
        self.token_names: Dict[int, str] = {}

    def add_special_token(self, name: str, token_str: str,
                          token_id: int):
        """注册特殊token"""
        self.special_tokens[name] = token_id
        self.token_names[token_id] = name

    def get_bos_id(self) -> int:
        return self.special_tokens.get("bos", 1)

    def get_eos_id(self) -> int:
        return self.special_tokens.get("eos", 2)

    def get_pad_id(self) -> int:
        return self.special_tokens.get("pad", 0)

    def is_special_token(self, token_id: int) -> bool:
        """判断是否为特殊token"""
        return token_id in self.token_names

    def mask_non_special(self, token_ids: List[int]) -> List[int]:
        """将非特殊token替换为MASK，用于MLM预训练"""
        mask_id = self.special_tokens.get("mask", 4)
        return [tid if self.is_special_token(tid) else mask_id
                for tid in token_ids]
```

---

*下一步：Skill架构*
