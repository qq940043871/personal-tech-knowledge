# Pipeline-Valve管道阀门

> 模块：请求处理管道
> 更新时间：2026-03-29

---

## 一、Pipeline-Valve模式

```
请求 ──► Valve1 ──► Valve2 ──► Valve3 ──► BasicValve ──► Servlet

特点：
  - 责任链模式
  - 可插拔的阀门
  - 每个容器有自己的Pipeline
  - 最后一个是BasicValve
```

---

## 二、接口定义

```java
public interface Pipeline {
    Valve getBasic();
    void setBasic(Valve valve);
    
    void addValve(Valve valve);
    void removeValve(Valve valve);
    
    Valve[] getValves();
    
    void invoke(Request request, Response response) throws IOException;
}

public interface Valve {
    String getInfo();
    
    void invoke(Request request, Response response, ValveContext context) 
        throws IOException;
}
```

---

## 三、StandardPipeline实现

```java
public class StandardPipeline implements Pipeline {
    protected Valve basic;
    protected List<Valve> valves = new ArrayList<>();
    
    @Override
    public Valve getBasic() {
        return basic;
    }
    
    @Override
    public void setBasic(Valve valve) {
        this.basic = valve;
    }
    
    @Override
    public void addValve(Valve valve) {
        valves.add(valve);
    }
    
    @Override
    public void removeValve(Valve valve) {
        valves.remove(valve);
    }
    
    @Override
    public void invoke(Request request, Response response) throws IOException {
        StandardValveContext context = new StandardValveContext();
        context.invokeNext(request, response);
    }
    
    private class StandardValveContext implements ValveContext {
        private int stage = 0;
        
        @Override
        public void invokeNext(Request request, Response response) throws IOException {
            Valve valve;
            
            if (stage < valves.size()) {
                valve = valves.get(stage);
            } else if (stage == valves.size()) {
                valve = basic;
            } else {
                return;
            }
            
            stage++;
            valve.invoke(request, response, this);
        }
    }
}
```

---

## 四、常用Valve

```java
// 访问日志Valve
public class AccessLogValve extends ValveBase {
    @Override
    public void invoke(Request request, Response response, ValveContext context) 
        throws IOException {
        long start = System.currentTimeMillis();
        
        context.invokeNext(request, response);
        
        long duration = System.currentTimeMillis() - start;
        logAccess(request, response, duration);
    }
    
    private void logAccess(Request request, Response response, long duration) {
        System.out.printf("%s %s %d %dms%n",
            request.getMethod(),
            request.getRequestURI(),
            response.getStatus(),
            duration
        );
    }
}

// 错误处理Valve
public class ErrorReportValve extends ValveBase {
    @Override
    public void invoke(Request request, Response response, ValveContext context) 
        throws IOException {
        try {
            context.invokeNext(request, response);
        } catch (Exception e) {
            response.setStatus(500);
            response.setContentType("text/html");
            response.getWriter().println(
                "<h1>500 Internal Server Error</h1><pre>" + 
                e.getMessage() + "</pre>"
            );
        }
    }
}
```

---

*下一步：请求分发机制*
