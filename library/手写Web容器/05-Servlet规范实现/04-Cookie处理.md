# Cookie处理

> 模块：Servlet规范实现
> 更新时间：2026-03-29

---

## 一、Cookie解析

```java
public class CookieParser {
    
    public static Cookie[] parse(String cookieHeader) {
        if (cookieHeader == null || cookieHeader.isEmpty()) {
            return new Cookie[0];
        }
        
        List<Cookie> cookies = new ArrayList<>();
        String[] pairs = cookieHeader.split(";");
        
        for (String pair : pairs) {
            int eq = pair.indexOf('=');
            if (eq > 0) {
                String name = pair.substring(0, eq).trim();
                String value = pair.substring(eq + 1).trim();
                cookies.add(new Cookie(name, value));
            }
        }
        
        return cookies.toArray(new Cookie[0]);
    }
    
    public static String toString(Cookie cookie) {
        StringBuilder sb = new StringBuilder();
        sb.append(cookie.getName()).append("=").append(cookie.getValue());
        
        if (cookie.getPath() != null) {
            sb.append("; Path=").append(cookie.getPath());
        }
        
        if (cookie.getDomain() != null) {
            sb.append("; Domain=").append(cookie.getDomain());
        }
        
        if (cookie.getMaxAge() > 0) {
            sb.append("; Max-Age=").append(cookie.getMaxAge());
        }
        
        if (cookie.getSecure()) {
            sb.append("; Secure");
        }
        
        if (cookie.isHttpOnly()) {
            sb.append("; HttpOnly");
        }
        
        return sb.toString();
    }
}
```

---

## 二、Cookie类

```java
public class Cookie implements Cloneable {
    private String name;
    private String value;
    private String comment;
    private String domain;
    private int maxAge = -1;
    private String path;
    private boolean secure;
    private boolean httpOnly;
    private int version;
    
    public Cookie(String name, String value) {
        this.name = name;
        this.value = value;
    }
    
    public String getName() { return name; }
    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }
    
    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }
    
    public String getDomain() { return domain; }
    public void setDomain(String domain) { this.domain = domain; }
    
    public int getMaxAge() { return maxAge; }
    public void setMaxAge(int maxAge) { this.maxAge = maxAge; }
    
    public String getPath() { return path; }
    public void setPath(String path) { this.path = path; }
    
    public boolean getSecure() { return secure; }
    public void setSecure(boolean secure) { this.secure = secure; }
    
    public boolean isHttpOnly() { return httpOnly; }
    public void setHttpOnly(boolean httpOnly) { this.httpOnly = httpOnly; }
}
```

---

*下一步：Filter过滤器链*
