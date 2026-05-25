.global _start
.extern kernel_main

_start:
    /* Setup the initial stack from 4MiB */
    movl $0x400000, %esp
    pushl $_kernel_end
    pushl %ebx /* Pointer to the multiboot info struct */
    pushl %eax /* Multiboot magic number (0x2BADB002) */
    call kernel_main
    cli

1:  hlt
    jmp 1b
