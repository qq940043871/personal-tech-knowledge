# DOM操作

> 模块：JavaScript引擎
> 更新时间：2026-03-29

---

## 一、DOM绑定

```cpp
class DOMBinding {
private:
    JSEngine* engine;
    std::map<DOMElement*, JSObject*> elementBindings;
    std::map<DOMElement*, JSObject*> prototypeMap;
    
public:
    void initialize() {
        // 注册document对象
        JSObject* doc = new JSObject();
        doc->set("getElementById", 
            new JSFunction(getElementById));
        doc->set("querySelector", 
            new JSFunction(querySelector));
        doc->set("querySelectorAll", 
            new JSFunction(querySelectorAll));
        doc->set("createElement", 
            new JSFunction(createElement));
        doc->set("createTextNode", 
            new JSFunction(createTextNode));
        
        engine->setGlobal("document", doc);
        
        // 注册window对象
        JSObject* win = new JSObject();
        win->set("setTimeout", new JSFunction(setTimeout));
        win->set("setInterval", new JSFunction(setInterval));
        win->set("fetch", new JSFunction(fetch));
        win->set("alert", new JSFunction(alert));
        
        engine->setGlobal("window", win);
    }
    
    static JSValue* getElementById(std::vector<JSValue*> args) {
        std::string id = args[0]->toString();
        DOMElement* element = document->getElementById(id);
        return wrapElement(element);
    }
    
    static JSValue* querySelector(std::vector<JSValue*> args) {
        std::string selector = args[0]->toString();
        DOMElement* element = document->querySelector(selector);
        return wrapElement(element);
    }
    
    static JSValue* wrapElement(DOMElement* element) {
        if (!element) return JSNull::instance();
        
        if (elementBindings.count(element)) {
            return elementBindings[element];
        }
        
        JSObject* wrapper = new JSObject();
        wrapper->set("id", new JSString(element->getAttribute("id")));
        wrapper->set("className", new JSString(element->getAttribute("class")));
        wrapper->set("innerHTML", new JSString(element->innerHTML()));
        
        // 方法
        wrapper