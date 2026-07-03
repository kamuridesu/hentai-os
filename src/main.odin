package main

import "base:runtime"
@(require) import "math"
_ :: math
@(require) import "hardware/io"
_ :: io

import "boot"
import "hardware"
import "memory"
import "vga"

panic_handler :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	vga.vga_writer.color = vga.build_color(.Light_Red, .Black)

	vga.print_string("\nKERNEL PANIC: ")
	vga.print_string(message)

	hardware.serial_print("\n[FAILED] Kernel Panic at")
	hardware.serial_print(loc.file_path)
	hardware.serial_print("\nMessage: ")
	hardware.serial_print(message)
	hardware.serial_print("\n")

	hardware.exit_qemu(.Failed)

	for {}
}

_init :: proc() {
	hardware.init_serial()
	hardware.serial_print("Serial OK!\nStarting GDT... ")
	hardware.init_gdt()
	hardware.serial_print("OK!\nStarting IDT... ")
	hardware.init_idt()
	hardware.serial_print("OK!\nStarting PIC... ")
	hardware.init_pic()
	hardware.serial_print("OK!\nStarting paging... ")
	memory.init_paging()
}

_vga_init :: proc() {
	vga.vga_writer.row = 0
	vga.vga_writer.col = 0
	vga.vga_writer.color = vga.build_color(.Light_Green, .Black)
	vga.clear_screen()
}

@(export, link_name = "kernel_main")
kernel_main :: proc "c" (magic: u32, mb_info: ^boot.Multiboot_Info, kernel_end: u32) -> ! {
	context = {}
	context.assertion_failure_proc = panic_handler

	if magic != boot.MULTIBOOT_BOOTLOADER_MAGIC {
		for {}
	}

	_init()
	_vga_init()

	// Checks if mem_upper is valid
	// GRUB almost aways sets it but the spec doesnt guarantee it
	if mb_info.flags & (1 << 0) == 0 {
		panic("Memory info not provided")
	}

	total_memory_mb := (mb_info.mem_lower + mb_info.mem_upper) / 1024

	vga.print_string("System RAM detected: ")
	vga.print_u32(total_memory_mb)
	vga.print_string("MiB\n")

	memory.init_frame_allocator(mb_info, kernel_end)
	hardware.serial_print("Frame allocator initialized\n")

	hardware.serial_print("OK!\nEnabling interrupts... ")
	hardware.enable_interrupts()
	hardware.serial_print("OK!\n")


	run_tests()

	for {
		hardware.halt_cpu()
	}
}
