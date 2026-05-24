package main

import "base:runtime"

// Multiboot
MAGIC :: 0x1BADB002
FLAGS :: 0x00
CHECKSUM :: ~(u32(MAGIC) + u32(FLAGS)) + 1

@(export, link_section = ".multiboot")
multiboot_header := [3]u32{MAGIC, FLAGS, CHECKSUM}


panic_handler :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	vga_writer.color = build_color(.Light_Red, .Black)

	print_string("\nKERNEL PANIC: ")
	print_string(message)

	serial_print("\n[FAILED] Kernel Panic at")
	serial_print(loc.file_path)
	serial_print("\nMessage: ")
	serial_print(message)
	serial_print("\n")

	exit_qemu(.Failed)

	for {}
}

@(export, link_name = "_start")
_start :: proc "c" () -> ! {
	context = {}
	context.assertion_failure_proc = panic_handler

	init_serial()
	init_gdt()
	init_idt()
	serial_print("IDT loaded successfully\n")
	init_pic()
	init_paging()
	enable_interrupts()

	vga_writer.row = 0
	vga_writer.col = 0
	vga_writer.color = build_color(.Light_Green, .Black)
	clear_screen()

	print_string("Hello World!\n")
	print_string("https://www.youtube.com/watch?v=dQw4w9WgXcQ")

	// serial_print("Writing to unmapped mem...\n")
	// bad_ptr := cast(^u32)uintptr(0xDEADBEEF)
	// bad_ptr^ = 42

	run_tests()


	for {
		halt_cpu()
	}
}

int3 :: proc() {
	context.assertion_failure_proc("INT3", "Manual Breakpoint", {})
}
