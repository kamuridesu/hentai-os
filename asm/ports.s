.global inb
.global outb
.global out32
.global trigger_breakpoint

trigger_breakpoint:
    int $3
    ret

/* void outb(u16 port, u8 value) */
outb:
    movw 4(%esp), %dx
    movb 8(%esp), %al
    outb %al, %dx
    ret

/* void out32(u16 port, u32 value) */
out32:
    movw 4(%esp), %dx
    movl 8(%esp), %eax
    outl %eax, %dx
    ret

/* u8 inb(u16 port) */
inb:
    movw 4(%esp), %dx
    inb %dx, %al
    ret
