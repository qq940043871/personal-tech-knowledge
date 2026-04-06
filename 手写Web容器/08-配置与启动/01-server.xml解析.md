# server.xml解析

> 模块：配置与启动
> 更新时间：2026-03-29

---

## 一、server.xml结构

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Server port="8005" shutdown="SHUTDOWN">
    <Service name="Catalina">
        <Connector port="8080" protocol="HTTP/1.1" />
        <Connector port="8443" protocol="HTTPS" />
        
        <Engine name="Catalina" defaultHost="localhost">
            <Host name="localhost" appBase="webapps">
                <Context path="" docBase="ROOT" />
                <Context path="/app1" docBase="app1" />
            </Host>
        </Engine>
    </Service>
</Server>
```

---

## 二、XML解析器

```java
public class ServerXmlParser {
    
    public Server parse(String configFile) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        DocumentBuilder builder = factory.newDocumentBuilder();
        Document doc = builder.parse(new File(configFile));
        
        Element root = doc.getDocumentElement();
        return parseServer(root);
    }
    
    private Server parseServer(Element element) {
        Server server = new Server();
        server.setPort(Integer.parseInt(element.getAttribute("port")));
        server.setShutdown(element.getAttribute("shutdown"));
        
        NodeList services = element.getElementsByTagName("Service");
        for (int i = 0; i < services.getLength(); i++) {
            Service service = parseService((Element) services.item(i));
            server.addService(service);
        }
        
        return server;
    }
    
    private Service parseService(Element element) {
        Service service = new Service();
        service.setName(element.getAttribute("name"));
        
        // 解析Connector
        NodeList connectors = element.getElementsByTagName("Connector");
        for (int i = 0; i < connectors.getLength(); i++) {
            Connector connector = parseConnector((Element) connectors.item(i));
            service.addConnector(connector);
        }
        
        // 解析Engine
        NodeList engines = element.getElementsByTagName("Engine");
        if (engines.getLength() > 0) {
            Engine engine = parseEngine((Element) engines.item(0));
            service.setEngine(engine);
        }
        
        return service;
    }
    
    private Connector parseConnector(Element element) {
        Connector connector = new Connector();
        connector.setPort(Integer.parseInt(element.getAttribute("port")));
        connector.setProtocol(element.getAttribute("protocol"));
        
        return connector;
    }
    
    private Engine parseEngine(Element element) {
        Engine engine = new StandardEngine();
        engine.setName(element.getAttribute("name"));
        engine.setDefaultHost(element.getAttribute("defaultHost"));
        
        NodeList hosts = element.getElementsByTagName("Host");
        for (int i = 0; i < hosts.getLength(); i++) {
            Host host = parseHost((Element) hosts.item(i));
            engine.addChild(host);
        }
        
        return engine;
    }
    
    private Host parseHost(Element element) {
        Host host = new StandardHost();
        host.setName(element.getAttribute("name"));
        host.setAppBase(element.getAttribute("appBase"));
        
        NodeList contexts = element.getElementsByTagName("Context");
        for (int i = 0; i < contexts.getLength(); i++) {
            Context context = parseContext((Element) contexts.item(i));
            host.addChild(context);
        }
        
        return host;
    }
    
    private Context parseContext(Element element) {
        Context context = new StandardContext();
        context.setPath(element.getAttribute("path"));
        context.setDocBase(element.getAttribute("docBase"));
        
        return context;
    }
}
```

---

*下一步：web.xml解析*
