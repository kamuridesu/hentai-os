package main

import "base:runtime"


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

_init :: proc() {
	init_serial()
	serial_print("Serial OK!\nStarting GDT... ")
	init_gdt()
	serial_print("OK!\nStarting IDT... ")
	init_idt()
	serial_print("OK!\nStarting PIC... ")
	init_pic()
	serial_print("OK!\nStarting paging... ")
	init_paging()
	serial_print("OK!\nEnabling interrupts... ")
	enable_interrupts()
	serial_print("OK!\n")
}

_vga_init :: proc() {
	vga_writer.row = 0
	vga_writer.col = 0
	vga_writer.color = build_color(.Light_Green, .Black)
	clear_screen()
}

@(export, link_name = "kernel_main")
kernel_main :: proc "c" (magic: u32, mb_info: ^Multiboot_Info, kernel_end: u32) -> ! {
	context = {}
	context.assertion_failure_proc = panic_handler

	if magic != MULTIBOOT_BOOTLOADER_MAGIC {
		for {}
	}

	_init()
	_vga_init()

	// Checks if mem_upper is valid
	// GRUB almost aways sets it but the spec doesnt guarantee it
	if mb_info.flags & (1 << 0) == 0 {
		panic_handler("MULTIBOOT", "Memory info not provided", {})
	}

	total_memory_mb := (mb_info.mem_lower + mb_info.mem_upper) / 1024

	print_string("System RAM detected: ")
	print_u32(total_memory_mb)
	print_string("MiB\n")

	init_frame_allocator(mb_info, kernel_end)
	serial_print("Frame allocator initialized\n")


	run_tests()

	for {
		halt_cpu()
	}
}
