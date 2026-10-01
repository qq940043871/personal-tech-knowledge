# Filter过滤器链

> 模块：Servlet规范实现
> 更新时间：2026-03-29

---

## 一、Filter接口

```java
public interface Filter {
    void init(FilterConfig filterConfig) throws ServletException;
    
    void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) 
        throws IOException, ServletException;
    
    void destroy();
}
```

---

## 二、FilterChain实现

```java
public class ApplicationFilterChain implements FilterChain {
    private List<Filter> filters = new ArrayList<>();
    private Servlet servlet;
    private int pos = 0;
    
    public ApplicationFilterChain(Servlet servlet) {
        this.servlet = servlet;
    }
    
    public void addFilter(Filter filter) {
        filters.add(filter);
    }
    
    @Override
    public void doFilter(ServletRequest request, ServletResponse response) 
        throws IOException, ServletException {
        
        if (pos < filters.size()) {
            Filter filter = filters.get(pos++);
            filter.doFilter(request, response, this);
        } else {
            servlet.service(request, response);
        }
    }
}
```

---

## 三、FilterConfig

```java
public class ApplicationFilterConfig implements FilterConfig {
    private Context context;
    private FilterDef filterDef;
    private Filter filter;
    
    public ApplicationFilterConfig(Context context, FilterDef filterDef) {
        this.context = context;
        this.filterDef = filterDef;
    }
    
    @Override
    public String getFilterName() {
        return filterDef.getName();
    }
    
    @Override
    public ServletContext getServletContext() {
        return context.getServletContext();
    }
    
    @Override
    public String getInitParameter(String name) {
        return filterDef.getInitParameter(name);
    }
    
    @Override
    public Enumeration<String> getInitParameterNames() {
        return Collections.enumeration(filterDef.getInitParameterNames());
    }
    
    public Filter getFilter() throws ServletException {
        if (filter == null) {
            try {
                Class<?> clazz = Class.forName(filterDef.getFilterClass());
                filter = (Filter) clazz.newInstance();
                filter.init(this);
            } catch (Exception e) {
                throw new ServletException("Failed to create filter", e);
            }
        }
        return filter;
    }
}
```

---

*下一步：Pipeline-Valve管道阀门*
