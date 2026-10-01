# web.xml解析

> 模块：配置与启动
> 更新时间：2026-03-29

---

## 一、web.xml结构

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app>
    <servlet>
        <servlet-name>HelloServlet</servlet-name>
        <servlet-class>com.example.HelloServlet</servlet-class>
        <init-param>
            <param-name>message</param-name>
            <param-value>Hello World</param-value>
        </init-param>
    </servlet>
    
    <servlet-mapping>
        <servlet-name>HelloServlet</servlet-name>
        <url-pattern>/hello</url-pattern>
    </servlet-mapping>
    
    <filter>
        <filter-name>LogFilter</filter-name>
        <filter-class>com.example.LogFilter</filter-class>
    </filter>
    
    <filter-mapping>
        <filter-name>LogFilter</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>
    
    <listener>
        <listener-class>com.example.AppListener</listener-class>
    </listener>
    
    <session-config>
        <timeout>30</timeout>
    </session-config>
</web-app>
```

---

## 二、WebXmlParser

```java
public class WebXmlParser {
    
    public void parse(Context context, String webXmlPath) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document doc = builder.parse(new File(webXmlPath));
        
        Element root = doc.getDocumentElement();
        
        // 解析Servlet
        parseServlets(context, root);
        
        // 解析Servlet映射
        parseServletMappings(context, root);
        
        // 解析Filter
        parseFilters(context, root);
        
        // 解析Filter映射
        parseFilterMappings(context, root);
        
        // 解析Listener
        parseListeners(context, root);
        
        // 解析Session配置
        parseSessionConfig(context, root);
    }
    
    private void parseServlets(Context context, Element root) {
        NodeList servlets = root.getElementsByTagName("servlet");
        for (int i = 0; i < servlets.getLength(); i++) {
            Element servlet = (Element) servlets.item(i);
            
            String name = servlet.getElementsByTagName("servlet-name").item(0).getTextContent();
            String className = servlet.getElementsByTagName("servlet-class").item(0).getTextContent();
            
            Wrapper wrapper = new StandardWrapper();
            wrapper.setName(name);
            wrapper.setServletClass(className);
            
            // 解析init-param
            NodeList params = servlet.getElementsByTagName("init-param");
            for (int j = 0; j < params.getLength(); j++) {
                Element param = (Element) params.item(j);
                String paramName = param.getElementsByTagName("param-name").item(0).getTextContent();
                String paramValue = param.getElementsByTagName("param-value").item(0).getTextContent();
                wrapper.addInitParameter(paramName, paramValue);
            }
            
            context.addChild(wrapper);
        }
    }
    
    private void parseServletMappings(Context context, Element root) {
        NodeList mappings = root.getElementsByTagName("servlet-mapping");
        for (int i = 0; i < mappings.getLength(); i++) {
            Element mapping = (Element) mappings.item(i);
            
            String name = mapping.getElementsByTagName("servlet-name").item(0).getTextContent();
            String pattern = mapping.getElementsByTagName("url-pattern").item(0).getTextContent();
            
            Wrapper wrapper = (Wrapper) context.findChild(name);
            if (wrapper != null) {
                wrapper.addMapping(pattern);
            }
        }
    }
    
    private void parseFilters(Context context, Element root) {
        // 类似parseServlets
    }
    
    private void parseFilterMappings(Context context, Element root) {
        // 类似parseServletMappings
    }
    
    private void parseListeners(Context context, Element root) {
        NodeList listeners = root.getElementsByTagName("listener");
        for (int i = 0; i < listeners.getLength(); i++) {
            Element listener = (Element) listeners.item(i);
            String className = listener.getElementsByTagName("listener-class").item(0).getTextContent();
            
            try {
                Class<?> clazz = Class.forName(className);
                ServletContextListener instance = (ServletContextListener) clazz.newInstance();
                context.addListener(instance);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
    
    private void parseSessionConfig(Context context, Element root) {
        NodeList configs = root.getElementsByTagName("session-config");
        if (configs.getLength() > 0) {
            Element config = (Element) configs.item(0);
            NodeList timeouts = config.getElementsByTagName("timeout");
            if (timeouts.getLength() > 0) {
                int timeout = Integer.parseInt(timeouts.item(0).getTextContent());
                context.setSessionTimeout(timeout);
            }
        }
    }
}
```

---

*下一步：启动流程设计*
