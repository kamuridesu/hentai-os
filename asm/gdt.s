.global load_gdt
.global flush_tss

/* void load_gdt(struct {u16 limit, u32 base} __attribute__((packed))* value) */
load_gdt:
    movl 4(%esp), %eax
    lgdt (%eax)
    ljmp $0x08, $reload_cs /* Force reload Code Segment */

reload_cs:
    /* Reload data segments (0x10) */
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %fs
    movw %ax, %gs
    movw %ax, %ss
    ret

flush_tss:
    movw $0x28, %ax
    ltr %ax
    ret
