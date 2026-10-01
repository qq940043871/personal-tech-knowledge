# Token识别实现

> 模块：词法分析器
> 更新时间：2026-03-29

---

## 一、词法分析器实现

```java
public class Lexer {
    private String input;
    private int position = 0;
    private int line = 1;
    private int column = 1;
    private List<Token> tokens = new ArrayList<>();
    
    public Lexer(String input) {
        this.input = input;
    }
    
    public List<Token> tokenize() {
        while (position < input.length()) {
            skipWhitespace();
            if (position >= input.length()) break;
            
            char c = peek();
            
            if (Character.isLetter(c) || c == '_') {
                tokens.add(scanIdentifier());
            } else if (Character.isDigit(c)) {
                tokens.add(scanNumber());
            } else if (c == '\'' || c == '"') {
                tokens.add(scanString());
            } else if (c == '-') {
                tokens.add(scanComment());
            } else {
                tokens.add(scanOperator());
            }
        }
        
        tokens.add(new Token(Token.Type.EOF, "", position, line, column));
        return tokens;
    }
    
    private Token scanIdentifier() {
        int start = position;
        int startLine = line;
        int startColumn = column;
        
        StringBuilder sb = new StringBuilder();
        while (position < input.length()) {
            char c = peek();
            if (Character.isLetterOrDigit(c) || c == '_') {
                sb.append(c);
                advance();
            } else {
                break;
            }
        }
        
        String word = sb.toString();
        Token.Type type = getKeywordType(word);
        
        return new Token(type, word, start, startLine, startColumn);
    }
    
    private Token scanNumber() {
        int start = position;
        StringBuilder sb = new StringBuilder();
        
        while (position < input.length()) {
            char c = peek();
            if (Character.isDigit(c) || c == '.') {
                sb.append(c);
                advance();
            } else {
                break;
            }
        }
        
        String num = sb.toString();
        Token.Type type = num.contains(".") ? Token.Type.FLOAT : Token.Type.INTEGER;
        
        return new Token(type, num, start, line, column);
    }
    
    private Token scanString() {
        int start = position;
        char quote = peek();
        advance();
        
        StringBuilder sb = new StringBuilder();
        while (position < input.length() && peek() != quote) {
            if (peek() == '\\') {
                advance();
                char escaped = peek();
                switch (escaped) {
                    case 'n': sb.append('\n'); break;
                    case 't': sb.append('\t'); break;
                    case 'r': sb.append('\r'); break;
                    case '\\': sb.append('\\'); break;
                    case '\'': sb.append('\''); break;
                    case '"': sb.append('"'); break;
                    default: sb.append(escaped); break;
                }
            } else {
                sb.append(peek());
            }
            advance();
        }
        
        advance(); // 跳过结束引号
        
        return new Token(Token.Type.STRING, sb.toString(), start, line, column);
    }
    
    private Token scanComment() {
        int start = position;
        advance(); // 跳过 -
        
        if (peek() == '-') {
            advance();
            while (position < input.length() && peek() != '\n') {
                advance();
            }
            return new Token(Token.Type.EOF, "", start, line, column);
        }
        
        return new Token(Token.Type.MINUS, "-", start, line, column);
    }
    
    private Token scanOperator() {
        int start = position;
        char c = peek();
        advance();
        
        switch (c) {
            case '+': return new Token(Token.Type.PLUS, "+", start, line, column);
            case '-': return new Token(Token.Type.MINUS, "-", start, line, column);
            case '*': return new Token(Token.Type.STAR, "*", start, line, column);
            case '/': return new Token(Token.Type.SLASH, "/", start, line, column);
            case '%': return new Token(Token.Type.PERCENT, "%", start, line, column);
            case '(': return new Token(Token.Type.LPAREN, "(", start, line, column);
            case ')': return new Token(Token.Type.RPAREN, ")", start, line, column);
            case ',': return new Token(Token.Type.COMMA, ",", start, line, column);
            case '.': return new Token(Token.Type.DOT, ".", start, line, column);
            case ';': return new Token(Token.Type.SEMICOLON, ";", start, line, column);
            case '=': return new Token(Token.Type.EQ, "=", start, line, column);
            
            case '<':
                if (peek() == '=') { advance(); return new Token(Token.Type.LE, "<=", start, line, column); }
                if (peek() == '>') { advance(); return new Token(Token.Type.NE, "<>", start, line, column); }
                return new Token(Token.Type.LT, "<", start, line, column);
                
            case '>':
                if (peek() == '=') { advance(); return new Token(Token.Type.GE, ">=", start, line, column); }
                return new Token(Token.Type.GT, ">", start, line, column);
                
            case '!':
                if (peek() == '=') { advance(); return new Token(Token.Type.NE, "!=", start, line, column); }
                return new Token(Token.Type.ERROR, "!", start, line, column);
                
            default:
                return new Token(Token.Type.ERROR, String.valueOf(c), start, line, column);
        }
    }
    
    private char peek() {
        return position < input.length() ? input.charAt(position) : '\0';
    }
    
    private void advance() {
        if (position < input.length()) {
            if (input.charAt(position) == '\n') {
                line++;
                column = 1;
            } else {
                column++;
            }
            position++;
        }
    }
    
    private void skipWhitespace() {
        while (position < input.length() && Character.isWhitespace(peek())) {
            advance();
        }
    }
}
```

---

*下一步：词法分析器编写*
