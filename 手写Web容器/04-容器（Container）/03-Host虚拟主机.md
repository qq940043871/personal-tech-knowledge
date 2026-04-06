# Host虚拟主机

> 模块：容器（Container）
> 更新时间：2026-03-29

---

## 一、Host职责

```
Host对应一个虚拟主机：
  - 管理多个Web应用（Context）
  - 支持域名绑定
  - 支持多域名映射同一Host
```

---

## 二、实现代码

```java
public class StandardHost extends ContainerBase implements Host {
    private String appBase = "webapps";
    private String[] aliases;
    private boolean autoDeploy = true;
    
    public StandardHost() {
        super();
        pipeline.setBasic(new StandardHostValve());
    }
    
    @Override
    public String getAppBase() {
        return appBase;
    }
    
    @Override
    public void setAppBase(String appBase) {
        this.appBase = appBase;
    }
    
    @Override
    public String[] getAliases() {
        return aliases;
    }
    
    @Override
    public void addAlias(String alias) {
        if (aliases == null) {
            aliases = new String[] { alias };
        } else {
            String[] newAliases = new String[aliases.length + 1];
            System.arraycopy(aliases, 0, newAliases, 0, aliases.length);
            newAliases[aliases.length] = alias;
            aliases = newAliases;
        }
    }
    
    private class StandardHostValve extends ValveBase {
        @Override
        public void invoke(Request request, Response response) throws IOException {
            // 根据Context Path找到对应的Context容器
            String uri = request.getRequestURI();
            String contextPath = getContextPath(uri);
            
            Context context = (Context) findChild(contextPath);
            if (context == null) {
                context = (Context) findChild("");
            }
            
            if (context != null) {
                request.setContext(context);
                context.invoke(request, response);
            } else {
                response.sendError(404, "Context not found");
            }
        }
        
        private String getContextPath(String uri) {
            int secondSlash = uri.indexOf('/', 1);
            return secondSlash > 0 ? uri.substring(0, secondSlash) : uri;
        }
    }
}
```

---

*下一步：Context应用上下文*
