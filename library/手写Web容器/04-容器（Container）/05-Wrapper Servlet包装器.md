# Wrapper Servlet包装器

> 模块：容器（Container）
> 更新时间：2026-03-29

---

## 一、Wrapper职责

```
Wrapper是最底层容器：
  - 封装单个Servlet实例
  - 管理Servlet生命周期
  - 处理Servlet请求
```

---

## 二、实现代码

```java
public class StandardWrapper extends ContainerBase implements Wrapper {
    private Servlet instance;
    private String servletClass;
    private boolean singleThreadModel = false;
    private Stack<Servlet> instancePool;
    private int maxInstances = 20;
    private AtomicInteger countAllocated = new AtomicInteger(0);
    
    public StandardWrapper() {
        super();
        pipeline.setBasic(new StandardWrapperValve());
    }
    
    @Override
    public String getServletClass() {
        return servletClass;
    }
    
    @Override
    public void setServletClass(String servletClass) {
        this.servletClass = servletClass;
    }
    
    @Override
    public Servlet allocate() throws ServletException {
        if (singleThreadModel) {
            synchronized (this) {
                if (instancePool == null) {
                    instancePool = new Stack<>();
                }
                if (!instancePool.isEmpty()) {
                    return instancePool.pop();
                }
                if (countAllocated.get() < maxInstances) {
                    countAllocated.incrementAndGet();
                    return loadServlet();
                }
            }
        } else {
            if (instance == null) {
                instance = loadServlet();
            }
            return instance;
        }
        return null;
    }
    
    @Override
    public void deallocate(Servlet servlet) {
        if (singleThreadModel && instancePool != null) {
            instancePool.push(servlet);
        }
    }
    
    private Servlet loadServlet() throws ServletException {
        try {
            Class<?> clazz = Class.forName(servletClass);
            Servlet servlet = (Servlet) clazz.newInstance();
            
            // 初始化Servlet
            ServletConfig config = new StandardServletConfig(this);
            servlet.init(config);
            
            return servlet;
        } catch (Exception e) {
            throw new ServletException("Failed to load servlet", e);
        }
    }
    
    private class StandardWrapperValve extends ValveBase {
        @Override
        public void invoke(Request request, Response response) throws IOException {
            try {
                Servlet servlet = allocate();
                
                // 应用Filter链
                FilterChain chain = new ApplicationFilterChain(servlet);
                
                // 执行Filter和Servlet
                chain.doFilter(request, response);
                
                deallocate(servlet);
            } catch (ServletException e) {
                throw new IOException("Servlet error", e);
            }
        }
    }
}
```

---

*下一步：Servlet接口与生命周期*
