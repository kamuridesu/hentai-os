ENTRY(_start)

SECTIONS {
    . = 1M;

    .text : ALIGN(4k) {
        *(.multiboot)
        *(.text .text.*)
    }

    .rodata : ALIGN(4k) {
        *(.rodata .rodata.*)
    }

    .data : ALIGN(4k) {
        *(.data .data.*)
    }

    .bss : ALIGN(4k) {
        *(COMMON)
        *(.bss .bss.*)
    }

    _kernel_end = .;
}
