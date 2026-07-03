package main

import "base:intrinsics"
import "base:runtime"
import "hardware"
import "memory"
import "vga"

TEST_NORMAL :: #config(TEST_NORMAL, false)
TEST_PANIC :: #config(TEST_PANIC, false)
TEST_DOUBLE_FAULT :: #config(TEST_DOUBLE_FAULT, false)
TEST_PAGE_FAULT :: #config(TEST_PAGE_FAULT, false)

expected_panic_handler :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	hardware.serial_print("[OK]\n")
	hardware.exit_qemu(.Success)
	for {}
}

test_vga_bounds :: proc() {
	hardware.serial_print("Testing VGA bounds...")
	assert(vga.VGA_WIDTH == 80)
	assert(vga.VGA_HEIGHT == 25)
	hardware.serial_print("[OK]\n")
}

test_math :: proc() {
	hardware.serial_print("Testing basic math...")
	assert(1 + 1 == 2)
	hardware.serial_print("[OK]\n")
}

test_println_simple :: proc() {
	hardware.serial_print("Testing simple println...")
	vga.println("test_println")
	hardware.serial_print("[OK]\n")
}

test_println_many :: proc() {
	hardware.serial_print("Testing many print...")
	for _ in 0 ..< 200 {
		vga.println("test_print_many")
	}
	hardware.serial_print("[OK]\n")
}

test_println_output :: proc() {
	hardware.serial_print("Testing println output...")

	s := "Some test string that fits on a single line"
	vga.println(s)

	target_row := vga.vga_writer.row - 1
	for i in 0 ..< len(s) {
		index := target_row * vga.VGA_WIDTH + i
		char_data := intrinsics.volatile_load(&vga.VGA_BUFFER[index])
		char_byte := byte(char_data & 0xFF)

		assert(char_byte == s[i])
	}

	hardware.serial_print("[OK]\n")
}

test_should_fail :: proc() {
	hardware.serial_print("Test should panic...")

	context.assertion_failure_proc = expected_panic_handler
	assert(1 == 0)
}

test_shouldtrigger_breakpoint_and_recover :: proc() {
	hardware.serial_print("Triggering a breakpoint exception...\n")
	hardware.trigger_breakpoint()
	hardware.serial_print("[OK]\n")
}

test_should_throw_exception :: proc() {
	hardware.serial_print("Triggering a Devide By Zero to cause a Double Fault...\n")
	hardware.set_idt_gate(8, cast(u32)uintptr(rawptr(hardware.isr8_expected_stub)), 0x08, 0x8E)
	hardware.trigger_divide_by_zero()
	hardware.serial_print("[OK]\n")
}

test_should_trigger_page_fault :: proc() {
	hardware.serial_print("Triggering a Page fault exception...\n")
	hardware.set_idt_gate(14, cast(u32)uintptr(rawptr(hardware.isr14_expected_stub)), 0x08, 0x8E)
	bad_ptr := cast(^u32)uintptr(0xDEADBEEF)
	bad_ptr^ = 42
	hardware.serial_print("[OK]\n")
}

test_should_allocate_3_physical_frames :: proc() {
	defer hardware.serial_print("[OK]\n")
	hardware.serial_print("Allocating 3 Physical Frames... ")

	frame1 := memory.allocate_frame()
	assert(cast(u32)frame1 == 0x400000)

	frame2 := memory.allocate_frame()
	assert(cast(u32)frame2 == 0x401000)

	frame3 := memory.allocate_frame()
	assert(cast(u32)frame3 == 0x402000)
}

test_should_trigger_OOM :: proc() {
	hardware.serial_print("Allocating Physical Frames to trigger OOM...")
	context.assertion_failure_proc = expected_panic_handler
	for {
		memory.allocate_frame()
	}
	hardware.serial_print("[FAIL] Could not trigger OOM...")
	hardware.exit_qemu(.Failed)
}

run_tests :: proc() {
	defer hardware.exit_qemu(.Success)
	hardware.serial_print("=== RUNNING KERNEL TESTS ===\n")

	when TEST_NORMAL {
		test_vga_bounds()
		test_math()
		test_println_simple()
		test_println_many()
		test_println_output()
		test_shouldtrigger_breakpoint_and_recover()
		test_should_allocate_3_physical_frames()
		test_should_trigger_OOM()
	} else when TEST_PANIC {
		test_should_fail()
	} else when TEST_DOUBLE_FAULT {
		test_should_throw_exception()
	} else when TEST_PAGE_FAULT {
		test_should_trigger_page_fault()
	}
}
