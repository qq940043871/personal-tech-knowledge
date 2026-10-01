# Context应用上下文

> 模块：容器（Container）
> 更新时间：2026-03-29

---

## 一、Context职责

```
Context对应一个Web应用：
  - 管理多个Servlet（Wrapper）
  - 加载web.xml配置
  - 管理Session
  - 管理应用级资源
```

---

## 二、实现代码

```java
public class StandardContext extends ContainerBase implements Context {
    private String path;              // Context路径
    private String docBase;           // 应用目录
    private ServletContext servletContext;
    private Map<String, String> parameters = new HashMap<>();
    private Map<String, FilterConfig> filters = new HashMap<>();
    private SessionManager sessionManager;
    
    public StandardContext() {
        super();
        pipeline.setBasic(new StandardContextValve());
        this.servletContext = new ApplicationContext(this);
        this.sessionManager = new StandardSessionManager();
    }
    
    @Override
    public String getPath() {
        return path;
    }
    
    @Override
    public void setPath(String path) {
        this.path = path;
    }
    
    @Override
    public String getDocBase() {
        return docBase;
    }
    
    @Override
    public void setDocBase(String docBase) {
        this.docBase = docBase;
    }
    
    @Override
    public ServletContext getServletContext() {
        return servletContext;
    }
    
    @Override
    public void addParameter(String name, String value) {
        parameters.put(name, value);
    }
    
    @Override
    public String getParameter(String name) {
        return parameters.get(name);
    }
    
    private class StandardContextValve extends ValveBase {
        @Override
        public void invoke(Request request, Response response) throws IOException {
            // 包装请求，设置Context路径
            request.setContextPath(path);
            
            // 根据Servlet路径找到对应的Wrapper
            String servletPath = getServletPath(request.getRequestURI());
            Wrapper wrapper = (Wrapper) findChild(servletPath);
            
            if (wrapper == null) {
                // 查找默认Servlet
                wrapper = (Wrapper) findChild("/");
            }
            
            if (wrapper != null) {
                request.setWrapper(wrapper);
                wrapper.invoke(request, response);
            } else {
                response.sendError(404, "Servlet not found");
            }
        }
        
        private String getServletPath(String uri) {
            String pathWithoutContext = uri.substring(path.length());
            return pathWithoutContext.isEmpty() ? "/" : pathWithoutContext;
        }
    }
}
```

---

*下一步：Wrapper Servlet包装器*
