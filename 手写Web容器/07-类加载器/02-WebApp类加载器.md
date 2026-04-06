# WebApp类加载器

> 模块：类加载器
> 更新时间：2026-03-29

---

## 一、Tomcat类加载器层次

```
Bootstrap
    │
    ▼
System
    │
    ▼
Common
    │
    ├──► WebApp ClassLoader (应用1)
    │         │
    │         ▼
    │      WebApp/WEB-INF/classes
    │      WebApp/WEB-INF/lib/*.jar
    │
    └──► WebApp ClassLoader (应用2)
              │
              ▼
           WebApp/WEB-INF/classes
           WebApp/WEB-INF/lib/*.jar

特点：
  - 每个WebApp有独立的ClassLoader
  - WebApp优先加载自己的类
  - 实现应用隔离
```

---

## 二、WebAppClassLoader实现

```java
public class WebAppClassLoader extends URLClassLoader {
    private File classesDir;
    private File libDir;
    private Map<String, Class<?>> cache = new ConcurrentHashMap<>();
    
    public WebAppClassLoader(ClassLoader parent, Context context) {
        super(new URL[0], parent);
        
        String docBase = context.getDocBase();
        this.classesDir = new File(docBase, "WEB-INF/classes");
        this.libDir = new File(docBase, "WEB-INF/lib");
        
        // 添加classes目录
        if (classesDir.exists()) {
            addURL(classesDir.toURI());
        }
        
        // 添加lib目录下的jar包
        if (libDir.exists()) {
            File[] jars = libDir.listFiles((dir, name) -> name.endsWith(".jar"));
            if (jars != null) {
                for (File jar : jars) {
                    addURL(jar.toURI());
                }
            }
        }
    }
    
    @Override
    protected Class<?> loadClass(String name, boolean resolve) 
        throws ClassNotFoundException {
        
        // 1. 检查缓存
        Class<?> clazz = cache.get(name);
        if (clazz != null) {
            return clazz;
        }
        
        // 2. 检查是否已加载
        clazz = findLoadedClass(name);
        if (clazz != null) {
            return clazz;
        }
        
        // 3. 核心类委托给父加载器
        if (name.startsWith("java.") || name.startsWith("javax.servlet")) {
            return super.loadClass(name, resolve);
        }
        
        // 4. 尝试自己加载
        try {
            clazz = findClass(name);
            cache.put(name, clazz);
            return clazz;
        } catch (ClassNotFoundException e) {
            // 5. 委托给父加载器
            return super.loadClass(name, resolve);
        }
    }
    
    @Override
    public URL findResource(String name) {
        // 优先从自己找
        URL url = findResource(name);
        if (url != null) {
            return url;
        }
        return super.findResource(name);
    }
}
```

---

*下一步：类隔离与热部署*
