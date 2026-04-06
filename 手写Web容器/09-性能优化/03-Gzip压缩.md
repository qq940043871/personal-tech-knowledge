# Gzip压缩

> 模块：性能优化
> 更新时间：2026-03-29

---

## 一、Gzip压缩原理

```
优势：
  - 减少传输大小（通常50-80%）
  - 减少带宽消耗
  - 加快页面加载

缺点：
  - 增加CPU消耗
  - 不适合已压缩的文件（图片、视频）
```

---

## 二、实现代码

```java
public class GzipFilter implements Filter {
    private int minSize = 1024;  // 最小压缩大小
    
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, 
                        FilterChain chain) throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        
        // 检查客户端是否支持gzip
        String acceptEncoding = httpRequest.getHeader("Accept-Encoding");
        if (acceptEncoding == null || !acceptEncoding.contains("gzip")) {
            chain.doFilter(request, response);
            return;
        }
        
        // 包装响应
        GzipResponseWrapper wrapper = new GzipResponseWrapper(httpResponse);
        
        chain.doFilter(request, wrapper);
        
        // 获取响应数据
        byte[] data = wrapper.getBuffer();
        
        // 检查是否需要压缩
        String contentType = wrapper.getContentType();
        if (shouldCompress(contentType, data.length)) {
            // 压缩数据
            byte[] compressed = compress(data);
            
            // 设置响应头
            httpResponse.setHeader("Content-Encoding", "gzip");
            httpResponse.setContentLength(compressed.length);
            
            // 写入压缩数据
            httpResponse.getOutputStream().write(compressed);
        } else {
            // 直接写入
            httpResponse.getOutputStream().write(data);
        }
    }
    
    private boolean shouldCompress(String contentType, int size) {
        if (size < minSize) {
            return false;
        }
        
        // 不压缩已压缩的文件
        if (contentType != null) {
            if (contentType.contains("image") || 
                contentType.contains("video") ||
                contentType.contains("gzip")) {
                return false;
            }
        }
        
        return true;
    }
    
    private byte[] compress(byte[] data) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        GZIPOutputStream gzos = new GZIPOutputStream(baos);
        gzos.write(data);
        gzos.close();
        return baos.toByteArray();
    }
}
```

---

*下一步：Keep-Alive长连接*
