# Servlet接口与生命周期

> 模块：Servlet规范实现
> 更新时间：2026-03-29

---

## 一、Servlet生命周期

```
1. 加载：ClassLoader加载Servlet类
2. 实例化：创建Servlet实例
3. 初始化：调用init()方法
4. 服务：反复调用service()方法
5. 销毁：调用destroy()方法
```

---

## 二、Servlet接口

```java
public interface Servlet {
    void init(ServletConfig config) throws ServletException;
    
    ServletConfig getServletConfig();
    
    void service(ServletRequest request, ServletResponse response) 
        throws ServletException, IOException;
    
    String getServletInfo();
    
    void destroy();
}
```

---

## 三、HttpServlet实现

```java
public abstract class HttpServlet extends GenericServlet {
    
    @Override
    public void service(ServletRequest req, ServletResponse res) 
        throws ServletException, IOException {
        
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        
        service(request, response);
    }
    
    protected void service(HttpServletRequest request, HttpServletResponse response) 
        throws ServletException, IOException {
        
        String method = request.getMethod();
        
        if ("GET".equals(method)) {
            doGet(request, response);
        } else if ("POST".equals(method)) {
            doPost(request, response);
        } else if ("PUT".equals(method)) {
            doPut(request, response);
        } else if ("DELETE".equals(method)) {
            doDelete(request, response);
        } else if ("HEAD".equals(method)) {
            doHead(request, response);
        } else if ("OPTIONS".equals(method)) {
            doOptions(request, response);
        } else {
            response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        }
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
        throws ServletException, IOException {
        response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
        throws ServletException, IOException {
        response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
    }
    
    // 其他doXXX方法...
}
```

---

## 四、ServletConfig

```java
public class StandardServletConfig implements ServletConfig {
    private Wrapper wrapper;
    private Map<String, String> initParameters = new HashMap<>();
    
    public StandardServletConfig(Wrapper wrapper) {
        this.wrapper = wrapper;
    }
    
    @Override
    public String getServletName() {
        return wrapper.getName();
    }
    
    @Override
    public ServletContext getServletContext() {
        return wrapper.getParent().getServletContext();
    }
    
    @Override
    public String getInitParameter(String name) {
        return initParameters.get(name);
    }
    
    @Override
    public Enumeration<String> getInitParameterNames() {
        return Collections.enumeration(initParameters.keySet());
    }
}
```

---

*下一步：ServletContext实现*
