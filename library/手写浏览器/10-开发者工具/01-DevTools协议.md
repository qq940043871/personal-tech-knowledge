# DevTools协议

> 模块：开发者工具
> 更新时间：2026-03-29

---

## 一、CDP协议

```
Chrome DevTools Protocol（CDP）：
  - 基于WebSocket
  - JSON-RPC 2.0
  - 双向通信
  
领域（Domains）：
  - Debugger
  - Console
  - Network
  - Page
  - Runtime
  - DOM
  - CSS
```

---

## 二、C++实现

```cpp
class DevToolsProtocol {
public:
    void handleCommand(const std::string& method, 
                     const Json::Value& params) {
        if (method == "Page.enable") {
            enablePage();
        } else if (method == "Page.disable") {
            disablePage();
        } else if (method == "Runtime.evaluate") {
            evaluate(params);
        } else if (method == "DOM.getDocument") {
            getDocument();
        } else if (method == "CSS.getComputedStyleForNode") {
            getComputedStyle(params);
        } else if (method == "Debugger.enable") {
            enableDebugger();
        } else if (method == "Debugger.setBreakpoint") {
            setBreakpoint(params);
        }
    }
    
    void sendEvent(const std::string& name, const Json::Value& params) {
        Json::Value message;
        message["method"] = name;
        message["params"] = params;
        message["sessionId"] = sessionId_;
        
        websocket->send(message.toStyledString());
    }
};
```

---

*下一步：调试功能*
