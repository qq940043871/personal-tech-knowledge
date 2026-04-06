# DOM树生成

> 模块：HTML解析器
> 更新时间：2026-03-29

---

## 一、DOM接口

```cpp
class DOMNode {
public:
    virtual ~DOMNode() = default;
    
    virtual DOMNode* firstChild() const = 0;
    virtual DOMNode* lastChild() const = 0;
    virtual DOMNode* nextSibling() const = 0;
    virtual DOMNode* previousSibling() const = 0;
    virtual DOMNode* parentNode() const = 0;
    
    virtual std::string nodeName() const = 0;
    virtual std::string textContent() const = 0;
};

class DOMElement : public DOMNode {
private:
    std::string tagName;
    std::map<std::string, std::string> attributes;
    DOMNode* firstChild_ = nullptr;
    DOMNode* lastChild_ = nullptr;
    DOMNode* nextSibling_ = nullptr;
    DOMNode* previousSibling_ = nullptr;
    DOMElement* parentElement_ = nullptr;
    
public:
    std::string nodeName() const override { return tagName; }
    
    DOMElement* querySelector(const std::string& selectors) {
        // CSS选择器实现
    }
    
    std::vector<DOMElement*> querySelectorAll(const std::string& selectors) {
        std::vector<DOMElement*> results;
        // 递归查找
        return results;
    }
    
    std::string getAttribute(const std::string& name) {
        auto it = attributes.find(name);
        return it != attributes.end() ? it->second : "";
    }
    
    void setAttribute(const std::string& name, const std::string& value) {
        attributes[name] = value;
    }
    
    // 遍历方法
    DOMNode* firstChild() const override { return firstChild_; }
    DOMNode* lastChild() const override { return lastChild_; }
    DOMNode* nextSibling() const override { return nextSibling_; }
    DOMNode* previousSibling() const override { return previousSibling_; }
    DOMElement* parentNode() const override { return parentElement_; }
};

class DOMText : public DOMNode {
private:
    std::string data;
    DOMElement* parentElement_;
    
public:
    std::string nodeName() const override { return "#text"; }
    std::string textContent() const override { return data; }
    
    DOMElement* parentNode() const override { return parentElement_; }
};
```

---

## 二、DOM操作

```cpp
class DOMOperations {
public:
    // 创建元素
    static DOMElement* createElement(const std::string& tagName) {
        return new DOMElement(tagName);
    }
    
    // 创建文本节点
    static DOMText* createTextNode(const std::string& text) {
        return new DOMText(text);
    }
    
    // 插入节点
    static void insertBefore(DOMNode* newNode, DOMNode* referenceNode) {
        if (!referenceNode->parentNode()) return;
        
        // 更新链表指针
        // ...
    }
    
    // 移除节点
    static void removeChild(DOMNode* child) {
        if (!child->parentNode()) return;
        
        // 从父节点移除
        // ...
    }
    
    // 替换节点
    static void replaceChild(DOMNode* newChild, DOM