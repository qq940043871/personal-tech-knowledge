# CSSOM树构建

> 模块：CSS解析器
> 更新时间：2026-03-29

---

## 一、CSSOM结构

```cpp
class CSSStyleSheet {
public:
    std::vector<CSSRule*> rules;
    
    void addRule(CSSRule* rule) {
        rules.push_back(rule);
    }
};

class CSSStyleDeclaration {
private:
    std::map<std::string, std::string> properties;
    
public:
    std::string getPropertyValue(const std::string& property) {
        auto it = properties.find(property);
        return it != properties.end() ? it->second : "";
    }
    
    void setProperty(const std::string& property, const std::string& value) {
        properties[property] = value;
    }
    
    void removeProperty(const std::string& property) {
        properties.erase(property);
    }
};

class CSSComputedStyle {
public:
    // 包含所有计算后的样式
    std::map<std::string, std::string> values;
    
    std::string getProperty(const std::string& name) {
        return values.count(name) ? values[name] : "";
    }
};
```

---

## 二、样式计算

```cpp
class StyleComputer {
private:
    std::vector<CSSStyleSheet*> sheets;
    
public:
    CSSComputedStyle computeStyle(DOMElement* element) {
        CSSComputedStyle style;
        
        // 1. 继承
        inheritStyles(element, style);
        
        // 2. 级联
        cascadeStyles(element, style);
        
        // 3. 计算值
        computeValues(style);
        
        return style;
    }
    
private:
    void cascadeStyles(DOMElement* element, CSSComputedStyle& style) {
        std::vector<CSSRule*> matchingRules;
        
        for (CSSStyleSheet* sheet : sheets) {
            for (CSSRule* rule : sheet->rules) {
                if (matchesSelector(element, rule->selectors)) {
                    matchingRules.push_back(rule);
                }
            }
        }
        
        // 按特异性排序
        sortBySpecificity(matchingRules);
        
        // 应用规则
        for (CSSRule* rule : matchingRules) {
            for (auto& decl : rule->declarations) {
                style.values[decl.first] = decl.second;
            }
        }
    }
    
    bool matchesSelector(DOMElement* element, 
                         const std::vector<std::string>& selectors) {
        for (const std::string& selector : selectors) {
            if (matchSingleSelector(element, selector)) {
                return true;
            }
        }
        return false;
    }
    
    void computeValues(CSSComputedStyle& style) {
        // 计算百分比值
        // 计算em/rem值
        // 计算颜色值
        // 计算url()值
        // ...
    }
};
```

---

*下一步：盒模型原理*
