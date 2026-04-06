# Container层次结构

> 模块：容器（Container）
> 更新时间：2026-03-29

---

## 一、Container四层结构

```
Engine（引擎）
  └── Host（虚拟主机）
       └── Context（Web应用）
            └── Wrapper（Servlet包装器）

职责划分：
  Engine：全局引擎，管理多个虚拟主机
  Host：虚拟主机，对应一个域名
  Context：Web应用，对应一个Context Path
  Wrapper：Servlet包装器，封装单个Servlet
```

---

## 二、接口设计

```java
public interface Container {
    String getName();
    void setName(String name);
    
    Container getParent();
    void setParent(Container parent);
    
    void addChild(Container child);
    void removeChild(Container child);
    Container findChild(String name);
    Container[] findChildren();
    
    void invoke(Request request, Response response);
    
    Pipeline getPipeline();
    void setPipeline(Pipeline pipeline);
}
```

---

## 三、基础实现

```java
public abstract class ContainerBase implements Container {
    protected String name;
    protected Container parent;
    protected Map<String, Container> children = new HashMap<>();
    protected Pipeline pipeline = new StandardPipeline();
    
    @Override
    public String getName() {
        return name;
    }
    
    @Override
    public void setName(String name) {
        this.name = name;
    }
    
    @Override
    public Container getParent() {
        return parent;
    }
    
    @Override
    public void setParent(Container parent) {
        this.parent = parent;
    }
    
    @Override
    public void addChild(Container child) {
        child.setParent(this);
        children.put(child.getName(), child);
    }
    
    @Override
    public void removeChild(Container child) {
        children.remove(child.getName());
        child.setParent(null);
    }
    
    @Override
    public Container findChild(String name) {
        return children.get(name);
    }
    
    @Override
    public Container[] findChildren() {
        return children.values().toArray(new Container[0]);
    }
    
    @Override
    public Pipeline getPipeline() {
        return pipeline;
    }
    
    @Override
    public void invoke(Request request, Response response) {
        pipeline.invoke(request, response);
    }
}
```

---

*下一步：Engine引擎实现*
