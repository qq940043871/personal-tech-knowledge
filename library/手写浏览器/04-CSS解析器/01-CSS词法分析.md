# CSS词法分析

> 模块：CSS解析器
> 更新时间：2026-03-29

---

## 一、CSS语法基础

```
选择器：
  标签选择器：div
  类选择器：.container
  ID选择器：#header
  属性选择器：[type="text"]
  伪类：:hover、:first-child
  伪元素：::before、::after
  组合：div.container、ul > li
  后代：div p
  兄弟：h1 + p、h1 ~ p

属性：
  selector {
    property: value;
  }

@media查询：
  @media screen and (max-width: 768px) {
    .container { width: 100%; }
  }
```

---

## 二、CSS词法规则

```cpp
enum class CSSTokenType {
    SELECTOR,
    PROPERTY,
    VALUE,
    COLON,
    SEMICOLON,
    LBRACE,
    RBRACE,
    COMMA,
    AT_RULE,      // @media, @keyframes
    IMPORTANT,     // !important
    STRING,
    EOF
};

struct CSSToken {
    CSSTokenType type;
    std::string value;
    int line;
};

class CSSTokenizer {
public:
    std::vector<CSSToken> tokenize(const std::string& css) {
        std::vector<CSSToken> tokens;
        size_t pos = 0;
        
        while (pos < css.size()) {
            skipWhitespace(css, pos);
            if (pos >= css.size()) break;
            
            char c = css[pos];
            
            if (c == '{') {
                tokens.push_back({CSSTokenType::LBRACE, "{"});
                pos++;
            } else if (c == '}') {
                tokens.push_back({CSSTokenType::RBRACE, "}"});
                pos++;
            } else if (c == ':') {
                tokens.push_back({CSSTokenType::COLON, ":"});
                pos++;
            } else if (c == ';') {
                tokens.push_back({CSSTokenType::SEMICOLON, ";"});
                pos++;
            } else if (c == ',') {
                tokens.push_back({CSSTokenType::COMMA, ","});
                pos++;
            } else if (c == '@') {
                tokens.push_back(parseAtRule(css, pos));
            } else if (c == '!') {
                tokens.push_back(parseImportant(css, pos));
            } else if (c == '"' || c == '\'') {
                tokens.push_back(parseString(css, pos));
            } else if (isAlphaNumeric(c)) {
                tokens.push_back(parseIdentifier(css, pos));
            } else {
                pos++;
            }
        }
        
        tokens.push_back({CSSTokenType::EOF, ""});
        return tokens;
    }
    
private:
    CSSToken parseIdentifier(const std::string& css, size_t& pos) {
        size_t start = pos;
        while (pos < css.size() && 
               (isAlphaNumeric(css[pos]) || css[pos] == '-' || css[pos] == '_')) {
            pos++;
        }
        return {CSSTokenType::SELECTOR, css.substr(start, pos - start)};
    }
    
    CSSToken parseString(const std::string& css, size_t& pos) {
        char quote = css[pos++];
        size_t start = pos;
        while (pos < css.size() && css[pos] != quote) {
            if (css[pos] == '\\') pos++;
            pos++;
        }
        std::string value = css.substr(start, pos - start);
        pos++; // skip closing quote
        return {CSSTokenType::STRING, value};
    }
};
```

---

*下一步：样式规则解析*
