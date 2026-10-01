# Flash-Attention

> 模块：Attention机制
> 更新时间：2026-03-29

---

## 一、原理

```
Flash Attention：
  - IO感知注意力算法
  - 将注意力计算分块
  - 减少HBM读写
  - 加速2-4倍，显存减少10-20倍

核心思想：
  1. 分块计算，避免一次性加载大矩阵
  2. 在线计算softmax
  3. 反向传播时可重新计算
```

---

## 二、实现

```python
def flash_attention(Q: Tensor, K: Tensor, V: Tensor, 
                   block_size: int = 128) -> Tensor:
    """分块注意力"""
    batch_size, num_heads, seq_len, head_dim = Q.shape
    
    # 输出矩阵
    O = torch.zeros_like(Q)
    l = torch.zeros(batch_size, num_heads, seq_len, 1)  # softmax归一化因子
    m = torch.full((batch_size, num_heads, seq_len, 1), -float('inf'))  # max
    
    # 外循环：K、V分块
    for j in range(0, seq_len, block_size):
        # 内循环：Q分块
        for i in range(0, seq_len, block_size):
            # 读取Q、K、V块
            Q_block = Q[..., i:i+block_size, :]
            K_block = K[..., j:j+block_size, :]
            V_block = V[..., j:j+block_size, :]
            
            # 计算S = QK^T
            S_block = torch.matmul(Q_block, K_block.transpose(-2, -1))
            S_block = S_block / math.sqrt(head_dim)
            
            # 在线softmax更新
            m_block = torch.maximum(m[..., i:i+block_size, :], 
                                   torch.max(S_block, dim=-1, keepdim=True)[0])
            S_block_shifted = S_block - m_block
            P_block = torch.exp(S_block_shifted)
            
            alpha = torch.exp(m[..., i:i+block_size, :] - m_block)
            P_block_scale = P_block * alpha
            
            l[..., i:i+block_size, :] = alpha * l[..., i:i+block_size, :] + \
                                        P_block.sum(dim=-1, keepdim=True)
            
            O[..., i:i+block_size, :] = \
                alpha * O[..., i:i+block_size, :] + \
                torch.matmul(P_block_scale, V_block)
    
    # 归一化
    O = O / l
    return O
```

---

*下一步：Skill架构*
