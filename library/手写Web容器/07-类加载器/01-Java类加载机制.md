# Java类加载机制

> 模块：类加载器
> 更新时间：2026-03-29

---

## 一、双亲委派模型

```
Bootstrap ClassLoader (启动类加载器)
        │
        ▼
Extension ClassLoader (扩展类加载器)
        │
        ▼
Application ClassLoader (应用类加载器)
        │
        ▼
Custom ClassLoader (自定义类加载器)

双亲委派：
  1. 收到加载请求，先委托父加载器
  2. 父加载器无法加载，才自己加载
  3. 保证核心类唯一性
```

---

## 二、ClassLoader实现

```java
public abstract class ClassLoader {
    private ClassLoader parent;
    
    public Class<?> loadClass(String name) throws ClassNotFoundException {
        return loadClass(name, false);
    }
    
    protected Class<?> loadClass(String name, boolean resolve) 
        throws ClassNotFoundException {
        
        synchronized (getClassLoadingLock(name)) {
            // 1. 检查是否已加载
            Class<?> c = findLoadedClass(name);
            
            if (c == null) {
                try {
                    // 2. 委托父加载器
                    if (parent != null) {
                        c = parent.loadClass(name, false);
                    } else {
                        c = findBootstrapClassOrNull(name);
                    }
                } catch (ClassNotFoundException e) {
                    // 父加载器无法加载
                }
                
                if (c == null) {
                    // 3. 自己加载
                    c = findClass(name);
                }
            }
            
            if (resolve) {
                resolveClass(c);
            }
            
            return c;
        }
    }
    
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        throw new ClassNotFoundException(name);
    }
}
```

---

*下一步：WebApp类加载器*
