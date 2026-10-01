# ServletContext实现

> 模块：Servlet规范实现
> 更新时间：2026-03-29

---

## 一、ServletContext接口

```java
public interface ServletContext {
    String getContextPath();
    ServletContext getContext(String uripath);
    
    String getInitParameter(String name);
    Enumeration<String> getInitParameterNames();
    
    Object getAttribute(String name);
    void setAttribute(String name, Object object);
    void removeAttribute(String name);
    Enumeration<String> getAttributeNames();
    
    String getRealPath(String path);
    InputStream getResourceAsStream(String path);
    
    RequestDispatcher getRequestDispatcher(String path);
    RequestDispatcher getNamedDispatcher(String name);
    
    String getMimeType(String file);
    
    void log(String msg);
    void log(String message, Throwable throwable);
}
```

---

## 二、ApplicationContext实现

```java
public class ApplicationContext implements ServletContext {
    private Context context;
    private Map<String, Object> attributes = new ConcurrentHashMap<>();
    private Map<String, String> initParameters = new HashMap<>();
    private String contextPath;
    
    public ApplicationContext(Context context) {
        this.context = context;
        this.contextPath = context.getPath();
    }
    
    @Override
    public String getContextPath() {
        return contextPath;
    }
    
    @Override
    public String getInitParameter(String name) {
        return initParameters.get(name);
    }
    
    @Override
    public Object getAttribute(String name) {
        return attributes.get(name);
    }
    
    @Override
    public void setAttribute(String name, Object object) {
        if (object == null) {
            removeAttribute(name);
        } else {
            attributes.put(name, object);
        }
    }
    
    @Override
    public void removeAttribute(String name) {
        attributes.remove(name);
    }
    
    @Override
    public String getRealPath(String path) {
        if (!path.startsWith("/")) {
            path = "/" + path;
        }
        return context.getDocBase() + path;
    }
    
    @Override
    public InputStream getResourceAsStream(String path) {
        String realPath = getRealPath(path);
        try {
            return new FileInputStream(realPath);
        } catch (FileNotFoundException e) {
            return null;
        }
    }
    
    @Override
    public RequestDispatcher getRequestDispatcher(String path) {
        Wrapper wrapper = (Wrapper) context.findChild(path);
        if (wrapper != null) {
            return new ApplicationRequestDispatcher(wrapper);
        }
        return null;
    }
    
    @Override
    public void log(String msg) {
        System.out.println("[" + contextPath + "] " + msg);
    }
}
```

---

*下一步：HttpSession实现*
