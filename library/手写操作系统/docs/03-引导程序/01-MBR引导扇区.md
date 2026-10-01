# 第六章：MBR引导扇区

## 6.1 MBR的结构

### 512字节布局

```
┌─────────────────────────────────────┐
│  引导代码（446字节）                │  0x0000-0x01BD
├─────────────────────────────────────┤
│  分区表项1（16字节）                │  0x01BE-0x01CD
├─────────────────────────────────────┤
│  分区表项2（16字节）                │  0x01CE-0x01DD
├─────────────────────────────────────┤
│  分区表项3（16字节）                │  0x01DE-0x01ED
├─────────────────────────────────────┤
│  分区表项4（16字节）                │  0x01EE-0x01FD
├─────────────────────────────────────┤
│  启动签名（2字节）：0x55AA          │  0x01FE-0x01FF
└─────────────────────────────────────┘
```

---

## 6.2 简单的MBR实现

### boot.asm

```asm
[bits 16]
org 0x7c00

start:
    ; 初始化段寄存器
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    
    ; 清屏
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    ; 打印欢迎信息
    mov si, msg
    call print_string
    
    ; 无限循环
    jmp $

print_string:
    lodsb
    cmp al, 0
    je .done
    
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07
    int 0x10
    
    jmp print_string
    
.done:
    ret

msg db "Welcome to My OS!", 0

; 填充到510字节
times 510 - ($ - $$) db 0

; 启动签名
dw 0xaa55
```

---

## 6.3 加载内核

### 完整的引导程序

```asm
[bits 16]
org 0x7c00

start:
    ; 初始化
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    
    ; 清屏
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    ; 打印信息
    mov si, msg_boot
    call print_string
    
    ; 读取内核
    mov ax, 0x1000
    mov es, ax
    mov bx, 0
    
    mov ah, 0x02        ; 读磁盘
    mov al, 10          ; 读10个扇区
    mov ch, 0           ; 柱面
    mov cl, 2           ; 扇区
    mov dh, 0           ; 磁头
    mov dl, 0x80        ; 硬盘
    int 0x13
    
    jc .read_error
    
    ; 打印成功信息
    mov si, msg_success
    call print_string
    
    ; 跳转到内核
    jmp 0x1000:0
    
.read_error:
    mov si, msg_error
    call print_string
    jmp $

print_string:
    lodsb
    cmp al, 0
    je .done
    
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07
    int 0x10
    
    jmp print_string
    
.done:
    ret

msg_boot db "Booting...", 0x0D, 0x0A, 0
msg_success db "Kernel loaded!", 0x0D, 0x0A, 0
msg_error db "Read error!", 0x0D, 0x0A, 0

times 510 - ($ - $$) db 0
dw 0xaa55
```

---

## 6.4 编译和测试

### Makefile

```makefile
AS = nasm
ASFLAGS = -f bin

boot.img: boot.asm
	$(AS) $(ASFLAGS) $< -o $@

run: boot.img
	qemu-system-i386 -fda $<

clean:
	rm -f boot.img

.PHONY: run clean
```

### 编译和运行

```bash
# 编译
make

# 运行
make run

# 清理
make clean
```

---

## 6.5 总结

本章介绍了MBR引导扇区的实现：

1. **MBR结构**：512字节布局
2. **简单的MBR**：基本的引导程序
3. **加载内核**：从磁盘读取内核
4. **编译和测试**：使用QEMU测试

MBR是操作系统启动的第一步。