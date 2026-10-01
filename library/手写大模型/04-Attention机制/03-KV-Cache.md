# KV-Cache

> 模块：Attention机制
> 更新时间：2026-03-29

---

## 一、Cache原理

```
KV-Cache：
  - 缓存已计算的Key和Value
  - 避免重复计算
  - 加速自回归生成

标准attention：O(n²) 每次生成
KV-Cache：O(n) 每次生成

原理：
  生成第n个token时，只需要计算新的Q、K、V
  K、V可以复用之前缓存的结果
```

---

## 二、实现

```python
class TransformerWithCache:
    """带KV-Cache的Transformer"""
    
    def __init__(self, model: TransformerModel):
        self.model = model
        self.kv_cache = {}
    
    def generate_with_cache(self, input_ids: Tensor, max_length: int) -> Tensor:
        batch_size = input_ids.size(0)
        seq_len = input_ids.size(1)
        
        # 首次前向传播
        past_key_values = None
        hidden_states = self.model.embed_tokens(input_ids)
        
        for _ in range(max_length):
            # 只处理最后一个token
            outputs = self.model.blocks(
                hidden_states[:, -1:],
                past_key_values=past_key_values,
                use_cache=True
            )
            
            hidden_states = outputs.last_hidden_state
            past_key_values = outputs.past_key_values
            
            # 采样
            logits = self.model.lm_head(hidden_states[:, -1:])
            next_token = torch.argmax(logits, dim=-1)
            
            if next_token.item() == self.eos_token_id:
                break
            
            # 更新隐藏状态
            hidden_states = torch.cat([hidden_states, self.model.embed_tokens(next_token)], dim=1)
        
        return hidden_states
```

---

*下一步：Flash-Attention*
