# HTTP请求对象封装

> 模块：HTTP解析引擎
> 更新时间：2026-03-29

---

## 一、Request接口设计

```java
public interface HttpServletRequest {
    String getMethod();
    String getRequestURI();
    String getContextPath();
    String getServletPath();
    String getQueryString();
    String getProtocol();
    
    String getHeader(String name);
    Enumeration<String> getHeaders(String name);
    Enumeration<String> getHeaderNames();
    
    String getParameter(String name);
    Enumeration<String> getParameterNames();
    String[] getParameterValues(String name);
    Map<String, String[]> getParameterMap();
    
    BufferedReader getReader() throws IOException;
    ServletInputStream getInputStream() throws IOException;
    
    String getRemoteAddr();
    String getRemoteHost();
    int getRemotePort();
    
    HttpSession getSession();
    HttpSession getSession(boolean create);
    
    Cookie[] getCookies();
    
    Object getAttribute(String name);
    void setAttribute(String name, Object value);
    void removeAttribute(String name);
}
```

---

## 二、实现类

```java
public class HttpRequest implements HttpServletRequest {
    private String method;
    private String uri;
    private String queryString;
    private String protocol;
    private Map<String, String> headers = new HashMap<>();
    private Map<String, String[]> parameters = new HashMap<>();
    private Map<String, Object> attributes = new HashMap<>();
    private Cookie[] cookies;
    private HttpSession session;
    private InputStream inputStream;
    private String remoteAddr;
    
    @Override
    public String getMethod() {
        return method;
    }
    
    @Override
    public String getRequestURI() {
        return uri;
    }
    
    @Override
    public String getParameter(String name) {
        String[] values = parameters.get(name);
        return values != null && values.length > 0 ? values[0] : null;
    }
    
    @Override
    public String[] getParameterValues(String name) {
        return parameters.get(name);
    }
    
    @Override
    public Map<String, String[]> getParameterMap() {
        return parameters;
    }
    
    @Override
    public String getHeader(String name) {
        return headers.get(name);
    }
    
    @Override
    public Cookie[] getCookies() {
        return cookies;
    }
    
    @Override
    public HttpSession getSession() {
        return getSession(true);
    }
    
    @Override
    public HttpSession getSession(boolean create) {
        if (session != null) {
            return session;
        }
        
        Cookie sessionCookie = findSessionCookie();
        if (sessionCookie != null) {
            session = SessionManager.getSession(sessionCookie.getValue());
        }
        
        if (session == null && create) {
            session = SessionManager.createSession();
        }
        
        return session;
    }
    
    private Cookie findSessionCookie() {
        if (cookies == null) return null;
        for (Cookie cookie : cookies) {
            if ("JSESSIONID".equals(cookie.getName())) {
                return cookie;
            }
        }
        return null;
    }
    
    @Override
    public Object getAttribute(String name) {
        return attributes.get(name);
    }
    
    @Override
    public void setAttribute(String name, Object value) {
        attributes.put(name, value);
    }
    
    @Override
    public String getRemoteAddr() {
        return remoteAddr;
    }
}
```

---

*下一步：HTTP响应对象封装*
