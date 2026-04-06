# HttpSession实现

> 模块：Servlet规范实现
> 更新时间：2026-03-29

---

## 一、Session管理

```java
public class StandardSessionManager implements SessionManager {
    private ConcurrentHashMap<String, HttpSession> sessions = new ConcurrentHashMap<>();
    private int sessionTimeout = 1800;  // 30分钟
    
    public HttpSession createSession() {
        String sessionId = generateSessionId();
        StandardSession session = new StandardSession(sessionId);
        session.setMaxInactiveInterval(sessionTimeout);
        sessions.put(sessionId, session);
        return session;
    }
    
    public HttpSession getSession(String sessionId) {
        HttpSession session = sessions.get(sessionId);
        if (session != null) {
            if (session.getMaxInactiveInterval() > 0) {
                long inactiveTime = System.currentTimeMillis() - session.getLastAccessedTime();
                if (inactiveTime > session.getMaxInactiveInterval() * 1000L) {
                    sessions.remove(sessionId);
                    session.invalidate();
                    return null;
                }
            }
            ((StandardSession) session).setLastAccessedTime(System.currentTimeMillis());
        }
        return session;
    }
    
    private String generateSessionId() {
        return UUID.randomUUID().toString().replace("-", "");
    }
    
    // 后台线程清理过期Session
    public void startBackgroundProcessor() {
        Thread cleaner = new Thread(() -> {
            while (true) {
                try {
                    Thread.sleep(60000);  // 每分钟检查一次
                    cleanExpiredSessions();
                } catch (InterruptedException e) {
                    break;
                }
            }
        }, "SessionCleaner");
        cleaner.setDaemon(true);
        cleaner.start();
    }
    
    private void cleanExpiredSessions() {
        sessions.forEach((id, session) -> {
            if (session.getMaxInactiveInterval() > 0) {
                long inactiveTime = System.currentTimeMillis() - session.getLastAccessedTime();
                if (inactiveTime > session.getMaxInactiveInterval() * 1000L) {
                    sessions.remove(id);
                    session.invalidate();
                }
            }
        });
    }
}
```

---

## 二、Session实现

```java
public class StandardSession implements HttpSession {
    private String id;
    private long creationTime;
    private long lastAccessedTime;
    private int maxInactiveInterval;
    private Map<String, Object> attributes = new ConcurrentHashMap<>();
    private boolean valid = true;
    
    public StandardSession(String id) {
        this.id = id;
        this.creationTime = System.currentTimeMillis();
        this.lastAccessedTime = creationTime;
    }
    
    @Override
    public String getId() {
        return id;
    }
    
    @Override
    public long getCreationTime() {
        return creationTime;
    }
    
    @Override
    public long getLastAccessedTime() {
        return lastAccessedTime;
    }
    
    public void setLastAccessedTime(long time) {
        this.lastAccessedTime = time;
    }
    
    @Override
    public int getMaxInactiveInterval() {
        return maxInactiveInterval;
    }
    
    @Override
    public void setMaxInactiveInterval(int interval) {
        this.maxInactiveInterval = interval;
    }
    
    @Override
    public Object getAttribute(String name) {
        checkValid();
        return attributes.get(name);
    }
    
    @Override
    public void setAttribute(String name, Object value) {
        checkValid();
        attributes.put(name, value);
    }
    
    @Override
    public void invalidate() {
        checkValid();
        attributes.clear();
        valid = false;
    }
    
    private void checkValid() {
        if (!valid) {
            throw new IllegalStateException("Session already invalidated");
        }
    }
}
```

---

*下一步：Cookie处理*
