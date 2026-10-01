# Embedding生成

> 模块：RAG检索增强
> 更新时间：2026-03-29

---

## 一、Embedding模型

```python
class Embedder:
    """文本嵌入模型"""
    
    def __init__(self, model_name: str = "text-embedding-ada-002"):
        self.model_name = model_name
        self.dimension = 1536  # ADA-002
    
    async def embed(self, texts: Union[str, List[str]]) -> List[float]:
        """生成嵌入向量"""
        if isinstance(texts, str):
            texts = [texts]
        
        # 调用API或本地模型
        embeddings = await self._call_model(texts)
        
        return embeddings
    
    async def embed_batch(self, texts: List[str], 
                          batch_size: int = 100) -> List[List[float]]:
        """批量嵌入"""
        results = []
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i+batch_size]
            embeddings = await self.embed(batch)
            results.extend(embeddings)
        return results
```

---

*下一步：检索排序*
