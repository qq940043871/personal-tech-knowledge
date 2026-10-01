# HTTP响应对象封装

> 模块：HTTP解析引擎
> 更新时间：2026-03-29

---

## 一、Response接口设计

```java
public interface HttpServletResponse {
    void setStatus(int sc);
    int getStatus();
    
    void setHeader(String name, String value);
    void addHeader(String name, String value);
    void setContentType(String type);
    void setContentLength(int len);
    
    PrintWriter getWriter() throws IOException;
    ServletOutputStream getOutputStream() throws IOException;
    
    void sendRedirect(String location) throws IOException;
    void sendError(int sc) throws IOException;
    void sendError(int sc, String msg) throws IOException;
    
    void addCookie(Cookie cookie);
    
    void setCharacterEncoding(String charset);
    String getCharacterEncoding();
    
    void flushBuffer() throws IOException;
    void reset();
}
```

---

## 二、实现类

```java
public class HttpResponse implements HttpServletResponse {
    private int status = 200;
    private String message = "OK";
    private Map<String, List<String>> headers = new LinkedHashMap<>();
    private OutputStream output;
    private PrintWriter writer;
    private ServletOutputStream servletOutputStream;
    private String characterEncoding = "UTF-8";
    private String contentType = "text/html";
    private List<Cookie> cookies = new ArrayList<>();
    private boolean committed = false;
    
    public HttpResponse(OutputStream output) {
        this.output = output;
    }
    
    @Override
    public void setStatus(int status) {
        this.status = status;
        this.message = getStatusMessage(status);
    }
    
    @Override
    public int getStatus() {
        return status;
    }
    
    @Override
    public void setHeader(String name, String value) {
        List<String> values = new ArrayList<>();
        values.add(value);
        headers.put(name, values);
    }
    
    @Override
    public void addHeader(String name, String value) {
        headers.computeIfAbsent(name, k -> new ArrayList<>()).add(value);
    }
    
    @Override
    public void setContentType(String type) {
        this.contentType = type;
        setHeader("Content-Type", type);
    }
    
    @Override
    public void setContentLength(int len) {
        setHeader("Content-Length", String.valueOf(len));
    }
    
    @Override
    public PrintWriter getWriter() throws IOException {
        if (writer == null) {
            writer = new PrintWriter(new OutputStreamWriter(output, characterEncoding), true);
        }
        return writer;
    }
    
    @Override
    public void addCookie(Cookie cookie) {
        cookies.add(cookie);
    }
    
    @Override
    public void sendRedirect(String location) throws IOException {
        setStatus(302);
        setHeader("Location", location);
        flushBuffer();
    }
    
    @Override
    public void sendError(int sc) throws IOException {
        sendError(sc, getStatusMessage(sc));
    }
    
    @Override
    public void sendError(int sc, String msg) throws IOException {
        setStatus(sc);
        setContentType("text/html; charset=" + characterEncoding);
        
        String html = "<!DOCTYPE html>" +
            "<html><head><title>Error " + sc + "</title></head>" +
            "<body><h1>" + sc + " - " + msg + "</h1></body></html>";
        
        getWriter().write(html);
        flushBuffer();
    }
    
    @Override
    public void flushBuffer() throws IOException {
        if (committed) return;
        
        StringBuilder sb = new StringBuilder();
        
        // 状态行
        sb.append("HTTP/1.1 ").append(status).append(" ").append(message).append("\r\n");
        
        // 响应头
        setHeader("Date", formatDate(new Date()));
        setHeader("Server", "MyTomcat/1.0");
        
        for (Map.Entry<String, List<String>> entry : headers.entrySet()) {
            for (String value : entry.getValue()) {
                sb.append(entry.getKey()).append(": ").append(value).append("\r\n");
            }
        }
        
        // Cookie
        for (Cookie cookie : cookies) {
            sb.append("Set-Cookie: ").append(cookie.getName()).append("=").append(cookie.getValue());
            if (cookie.getPath() != null) {
                sb.append("; Path=").append(cookie.getPath());
            }
            if (cookie.getMaxAge() > 0) {
                sb.append("; Max-Age=").append(cookie.getMaxAge());
            }
            if (cookie.isHttpOnly()) {
                sb.append("; HttpOnly");
            }
            sb.append("\r\n");
        }
        
        // 空行
        sb.append("\r\n");
        
        output.write(sb.toString().getBytes(StandardCharsets.UTF_8));
        
        if (writer != null) {
            writer.flush();
        }
        
        committed = true;
    }
    
    @Override
    public void reset() {
        if (committed) {
            throw new IllegalStateException("Response already committed");
        }
        status = 200;
        message = "OK";
        headers.clear();
        cookies.clear();
    }
}
```

---

*下一步：Connector架构设计*
