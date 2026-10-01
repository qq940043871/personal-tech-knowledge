# Engine引擎实现

> 模块：容器（Container）
> 更新时间：2026-03-29

---

## 一、Engine职责

```
Engine是顶层容器：
  - 管理多个虚拟主机（Host）
  - 根据请求的Host头路由到对应Host
  - 提供默认Host
```

---

## 二、实现代码

```java
public class StandardEngine extends ContainerBase implements Engine {
    private String defaultHost;
    private Service service;
    
    public StandardEngine() {
        super();
        pipeline.setBasic(new StandardEngineValve());
    }
    
    @Override
    public String getDefaultHost() {
        return defaultHost;
    }
    
    @Override
    public void setDefaultHost(String defaultHost) {
        this.defaultHost = defaultHost;
    }
    
    @Override
    public Service getService() {
        return service;
    }
    
    @Override
    public void setService(Service service) {
        this.service = service;
    }
    
    // Engine的基础Valve
    private class StandardEngineValve extends ValveBase {
        @Override
        public void invoke(Request request, Response response) throws IOException {
            // 根据Host头找到对应的Host容器
            String hostName = request.getHeader("Host");
            if (hostName == null) {
                hostName = defaultHost;
            }
            
            Host host = (Host) findChild(hostName);
            if (host == null) {
                host = (Host) findChild(defaultHost);
            }
            
            if (host != null) {
                host.invoke(request, response);
            } else {
                response.sendError(404, "Host not found");
            }
        }
    }
}
```

---

*下一步：Host虚拟主机*
