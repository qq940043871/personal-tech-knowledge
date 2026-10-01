# ClassFile结构详解

> 模块：字节码基础
> 更新时间：2026-03-29

---

## 一、ClassFile结构概述

Class文件是Java程序编译后的二进制文件，是JVM运行的基石。一个标准的ClassFile包含以下部分：

```
ClassFile {
    u4             magic;              // 魔数：0xCAFEBABE
    u2             minor_version;     // 次版本号
    u2             major_version;     // 主版本号
    u2             constant_pool_count; // 常量池容量
    cp_info        constant_pool[constant_pool_count-1]; // 常量池
    u2             access_flags;      // 访问标志
    u2             this_class;       // 当前类索引
    u2             super_class;      // 父类索引
    u2             interfaces_count;  // 接口数量
    u2             interfaces[interfaces_count]; // 接口索引表
    u2             fields_count;     // 字段数量
    field_info     fields[fields_count]; // 字段表
    u2             methods_count;    // 方法数量
    method_info    methods[methods_count]; // 方法表
    u2             attributes_count;  // 属性数量
    attribute_info attributes[attributes_count]; // 属性表
}
```

---

## 二、核心代码实现

### 1. 数据类型定义

```java
public class ClassFileReader {
    
    // 数据输入流
    private ByteBuffer buffer;
    
    // 读取无符号数
    public int readUnsignedByte() {
        return buffer.get() & 0xFF;
    }
    
    public int readUnsignedShort() {
        return buffer.getShort() & 0xFFFF;
    }
    
    public int readUnsignedInt() {
        return buffer.getInt();
    }
    
    // 读取有符号数
    public int readSignedByte() {
        return buffer.get();
    }
    
    public int readSignedShort() {
        return buffer.getShort();
    }
    
    public int readSignedInt() {
        return buffer.getInt();
    }
    
    // 读取长整数
    public long readLong() {
        return buffer.getLong();
    }
    
    // 读取UTF-8字符串
    public String readUTF8(int length) {
        byte[] bytes = new byte[length];
        buffer.get(bytes);
        return new String(bytes, StandardCharsets.UTF_8);
    }
}
```

### 2. ClassFile结构体

```java
public class ClassFile {
    public int magic;                    // 0xCAFEBABE
    public int minorVersion;             // 次版本号
    public int majorVersion;             // 主版本号
    public ConstantPool constantPool;    // 常量池
    public int accessFlags;             // 访问标志
    public int thisClass;              // 当前类
    public int superClass;              // 父类
    public int[] interfaces;            // 接口表
    public FieldInfo[] fields;         // 字段表
    public MethodInfo[] methods;        // 方法表
    public AttributeInfo[] attributes;  // 属性表
}

public class ClassFileReader {
    
    public ClassFile parse(byte[] classData) {
        ByteBuffer buffer = ByteBuffer.wrap(classData);
        // 设置字节序为大端序
        buffer.order(ByteOrder.BIG_ENDIAN);
        
        ClassFile cf = new ClassFile();
        
        // 1. 读取魔数
        cf.magic = buffer.getInt();
        if (cf.magic != 0xCAFEBABE) {
            throw new ClassFormatError("Invalid magic number");
        }
        
        // 2. 读取版本号
        cf.minorVersion = buffer.getShort();
        cf.majorVersion = buffer.getShort();
        
        // 3. 读取常量池
        int constantPoolCount = buffer.getShort();
        cf.constantPool = parseConstantPool(buffer, constantPoolCount);
        
        // 4. 读取访问标志
        cf.accessFlags = buffer.getShort();
        
        // 5. 读取类索引
        cf.thisClass = buffer.getShort();
        cf.superClass = buffer.getShort();
        
        // 6. 读取接口表
        int interfacesCount = buffer.getShort();
        cf.interfaces = new int[interfacesCount];
        for (int i = 0; i < interfacesCount; i++) {
            cf.interfaces[i] = buffer.getShort();
        }
        
        // 7. 读取字段表
        int fieldsCount = buffer.getShort();
        cf.fields = new FieldInfo[fieldsCount];
        for (int i = 0; i < fieldsCount; i++) {
            cf.fields[i] = parseFieldInfo(buffer);
        }
        
        // 8. 读取方法表
        int methodsCount = buffer.getShort();
        cf.methods = new MethodInfo[methodsCount];
        for (int i = 0; i < methodsCount; i++) {
            cf.methods[i] = parseMethodInfo(buffer);
        }
        
        // 9. 读取属性表
        int attributesCount = buffer.getShort();
        cf.attributes = new AttributeInfo[attributesCount];
        for (int i = 0; i < attributesCount; i++) {
            cf.attributes[i] = parseAttributeInfo(buffer);
        }
        
        return cf;
    }
}
```

---

## 三、常量池解析

```java
public class ConstantPool {
    public ConstantInfo[] constants;
    public int count;
}

public abstract class ConstantInfo {
    public static final int CONSTANT_Class = 7;
    public static final int CONSTANT_Fieldref = 9;
    public static final int CONSTANT_Methodref = 10;
    public static final int CONSTANT_InterfaceMethodref = 11;
    public static final int CONSTANT_String = 8;
    public static final int CONSTANT_Integer = 3;
    public static final int CONSTANT_Float = 4;
    public static final int CONSTANT_Long = 5;
    public static final int CONSTANT_Double = 6;
    public static final int CONSTANT_NameAndType = 12;
    public static final int CONSTANT_Utf8 = 1;
    public static final int CONSTANT_MethodHandle = 15;
    public static final int CONSTANT_MethodType = 16;
    public static final int CONSTANT_InvokeDynamic = 18;
}

// UTF-8常量
public class ConstantUtf8Info extends ConstantInfo {
    public String value;
}

// 类常量
public class ConstantClassInfo extends ConstantInfo {
    public int nameIndex;  // 指向CONSTANT_Utf8_info
}

// 方法/字段引用常量
public class ConstantMethodrefInfo extends ConstantInfo {
    public int classIndex;       // 指向CONSTANT_Class_info
    public int nameAndTypeIndex; // 指向CONSTANT_NameAndType_info
}

// 整数常量
public class ConstantIntegerInfo extends ConstantInfo {
    public int value;
}
```

---

## 四、访问标志

```java
public class AccessFlags {
    // 类访问标志
    public static final int ACC_PUBLIC = 0x0001;     // public
    public static final int ACC_FINAL = 0x0010;      // final
    public static final int ACC_SUPER = 0x0020;      // super
    public static final int ACC_ABSTRACT = 0x0400;   // abstract
    
    // 字段访问标志
    public static final int ACC_PRIVATE = 0x0002;    // private
    public static final int ACC_PROTECTED = 0x0004; // protected
    public static final int ACC_STATIC = 0x0008;     // static
    public static final int ACC_VOLATILE = 0x0040;   // volatile
    public static final int ACC_TRANSIENT = 0x0080; // transient
    
    // 方法访问标志
    public static final int ACC_SYNCHRONIZED = 0x0020; // synchronized
    public static final int ACC_NATIVE = 0x0100;      // native
    public static final int ACC_ABSTRACT = 0x0400;     // abstract
    
    public static String toString(int accessFlags, boolean isClass) {
        StringBuilder sb = new StringBuilder();
        if ((accessFlags & ACC_PUBLIC) != 0) sb.append("public ");
        if ((accessFlags & ACC_PRIVATE) != 0) sb.append("private ");
        if ((accessFlags & ACC_PROTECTED) != 0) sb.append("protected ");
        if ((accessFlags & ACC_STATIC) != 0) sb.append("static ");
        if ((accessFlags & ACC_FINAL) != 0) sb.append("final ");
        if ((accessFlags & ACC_VOLATILE) != 0) sb.append("volatile ");
        if ((accessFlags & ACC_SYNCHRONIZED) != 0) sb.append("synchronized ");
        return sb.toString();
    }
}
```

---

## 五、方法表解析

```java
public class MethodInfo {
    public int accessFlags;      // 访问标志
    public int nameIndex;        // 方法名索引
    public int descriptorIndex;  // 方法描述符索引
    public AttributeInfo[] attributes; // 属性表
}

// 方法描述符解析
public class MethodDescriptor {
    public String rawDescriptor; // 原始描述符
    
    public List<String> getParameterTypes() {
        // 解析参数类型列表
    }
    
    public String getReturnType() {
        // 解析返回类型
    }
}

// 示例
// (ILjava/lang/String;)V
// 表示：参数列表[int, String]，返回类型void
// (Ljava/lang/String;)Ljava/lang/Object;
// 表示：参数列表[String]，返回类型Object
```

---

## 六、属性表

```java
public abstract class AttributeInfo {
    public int attributeNameIndex;
    public int length;
    public byte[] info;
}

// Code属性 - 存储字节码
public class CodeAttribute extends AttributeInfo {
    public int maxStack;       // 操作数栈最大深度
    public int maxLocals;       // 局部变量表大小
    public int codeLength;     // 字节码长度
    public byte[] code;         // 字节码指令
    public ExceptionTableEntry[] exceptionTable; // 异常处理表
    public AttributeInfo[] attributes;
}

public class ExceptionTableEntry {
    public int startPc;    // 起始pc
    public int endPc;      // 结束pc
    public int handlerPc;  // 处理器pc
    public int catchType;  // 捕获类型
}

// LineNumberTable属性 - 行号表
public class LineNumberTableAttribute extends AttributeInfo {
    public LineNumberEntry[] entries;
}

public class LineNumberEntry {
    public int startPc;
    public int lineNumber;
}

// SourceFile属性 - 源文件名
public class SourceFileAttribute extends AttributeInfo {
    public int sourceFileIndex;
}
```

---

## 七、实际应用

### 1. 打印Class文件信息

```java
public class ClassFilePrinter {
    
    public static void print(ClassFile cf) {
        System.out.println("=== Class File Info ===");
        System.out.println("Major Version: " + cf.majorVersion);
        System.out.println("Minor Version: " + cf.minorVersion);
        System.out.println("Access Flags: " + Integer.toHexString(cf.accessFlags));
        
        // 打印类名
        String className = cf.constantPool.getClassName(cf.thisClass);
        System.out.println("Class: " + className);
        
        // 打印父类
        if (cf.superClass > 0) {
            String superClass = cf.constantPool.getClassName(cf.superClass);
            System.out.println("Super Class: " + superClass);
        }
        
        // 打印方法
        System.out.println("\nMethods:");
        for (MethodInfo method : cf.methods) {
            String name = cf.constantPool.getUTF8(method.nameIndex);
            String desc = cf.constantPool.getUTF8(method.descriptorIndex);
            System.out.println("  " + name + desc);
        }
    }
}
```

### 2. 验证Class文件

```java
public class ClassFileValidator {
    
    public static boolean validate(ClassFile cf) {
        // 验证魔数
        if (cf.magic != 0xCAFEBABE) {
            return false;
        }
        
        // 验证版本号
        if (cf.majorVersion < 45 || cf.majorVersion > 52) {
            return false;
        }
        
        // 验证常量池
        if (!validateConstantPool(cf.constantPool)) {
            return false;
        }
        
        // 验证方法
        for (MethodInfo method : cf.methods) {
            if (!validateMethod(method)) {
                return false;
            }
        }
        
        return true;
    }
}
```

---

## 八、总结

理解ClassFile结构是手写JVM的第一步。每个Java程序编译后都生成Class文件，掌握其结构对于理解JVM运行机制至关重要。

**学习要点**：
1. 理解ClassFile各个部分的作用
2. 掌握常量池的各种类型
3. 理解访问标志的含义
4. 掌握方法描述符的解析

---

*下一步：字节码指令集*
