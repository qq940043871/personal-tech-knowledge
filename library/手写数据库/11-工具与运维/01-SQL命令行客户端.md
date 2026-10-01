# SQL命令行客户端

> 模块：工具与运维
> 更新时间：2026-03-29

---

## 一、客户端实现

```java
public class SqlClient {
    private Socket socket;
    private BufferedReader reader;
    private PrintWriter writer;
    
    public static void main(String[] args) throws Exception {
        SqlClient client = new SqlClient("localhost", 3306);
        client.connect();
        client.runInteractive();
    }
    
    public void runInteractive() {
        Scanner scanner = new Scanner(System.in);
        System.out.println("MyDB Client - Type 'exit' to quit");
        System.out.println("mysql> ");
        
        while (true) {
            String line = scanner.nextLine();
            
            if ("exit".equalsIgnoreCase(line) || "quit".equalsIgnoreCase(line)) {
                break;
            }
            
            if ("\\c".equals(line)) {
                System.out.println("Cleared");
                continue;
            }
            
            try {
                String result = executeQuery(line);
                System.out.println(result);
            } catch (Exception e) {
                System.out.println("ERROR: " + e.getMessage());
            }
            
            System.out.print("mysql> ");
        }
    }
    
    public String executeQuery(String sql) {
        // 发送SQL到服务器
        writer.println(sql);
        writer.flush();
        
        // 读取结果
        StringBuilder result = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null && !line.equals("END")) {
            result.append(line).append("\n");
        }
        
        return result.toString();
    }
}
```

---

## 二、结果显示

```java
public class ResultFormatter {
    
    public static String format(ResultSet rs) {
        StringBuilder sb = new StringBuilder();
        
        // 列头
        List<String> columns = rs.getColumns();
        List<int[]> widths = new ArrayList<>();
        
        for (int i = 0; i < columns.size(); i++) {
            widths.add(new int[]{columns.get(i).length(), i});
        }
        
        // 计算每列宽度
        for (Row row : rs.getRows()) {
            for (int i = 0; i < row.getColumnCount(); i++) {
                String value = row.getValue(i) != null ? row.getValue(i).toString() : "NULL";
                widths.get(i)[0] = Math.max(widths.get(i)[0], value.length());
            }
        }
        
        // 打印表头
        for (int[] w : widths) {
            System.out.printf("%-" + (w[0] + 2) + "s", columns.get(w[1]));
        }
        System.out.println();
        
        // 分隔线
        for (int[] w : widths) {
            System.out.print(String.join("", Collections.nCopies(w[0] + 2, "-")));
        }
        System.out.println();
        
        // 打印数据
        for (Row row : rs.getRows()) {
            for (int i = 0; i < row.getColumnCount(); i++) {
                String value = row.getValue(i) != null ? row.getValue(i).toString() : "NULL";
                System.out.printf("%-" + (widths.get(i)[0] + 2) + "s", value);
            }
            System.out.println();
        }
        
        sb.append(rs.getRowCount()).append(" rows in set");
        
        return sb.toString();
    }
}
```

---

*下一步：数据库备份*
