package main

import "base:intrinsics"
import "base:runtime"

TEST_NORMAL :: #config(TEST_NORMAL, false)
TEST_PANIC :: #config(TEST_PANIC, false)
TEST_DOUBLE_FAULT :: #config(TEST_DOUBLE_FAULT, false)
TEST_PAGE_FAULT :: #config(TEST_PAGE_FAULT, false)

expected_panic_handler :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	serial_print("[OK]\n")
	exit_qemu(.Success)
	for {}
}

test_vga_bounds :: proc() {
	serial_print("Testing VGA bounds...")
	assert(VGA_WIDTH == 80)
	assert(VGA_HEIGHT == 25)
	serial_print("[OK]\n")
}

test_math :: proc() {
	serial_print("Testing basic math...")
	assert(1 + 1 == 2)
	serial_print("[OK]\n")
}

test_println_simple :: proc() {
	serial_print("Testing simple println...")
	println("test_println")
	serial_print("[OK]\n")
}

test_println_many :: proc() {
	serial_print("Testing many print...")
	for _ in 0 ..< 200 {
		println("test_print_many")
	}
	serial_print("[OK]\n")
}

test_println_output :: proc() {
	serial_print("Testing println output...")

	s := "Some test string that fits on a single line"
	println(s)

	target_row := vga_writer.row - 1
	for i in 0 ..< len(s) {
		index := target_row * VGA_WIDTH + i
		char_data := intrinsics.volatile_load(&VGA_BUFFER[index])
		char_byte := byte(char_data & 0xFF)

		assert(char_byte == s[i])
	}

	serial_print("[OK]\n")
}

test_should_fail :: proc() {
	serial_print("Test should panic...")

	context.assertion_failure_proc = expected_panic_handler
	assert(1 == 0)
}

test_shouldtrigger_breakpoint_and_recover :: proc() {
	serial_print("Triggering a breakpoint exception...\n")
	trigger_breakpoint()
	serial_print("[OK]\n")
}

test_should_throw_exception :: proc() {
	serial_print("Triggering a Devide By Zero to cause a Double Fault...\n")
	set_idt_gate(8, cast(u32)uintptr(rawptr(isr8_expected_stub)), 0x08, 0x8E)
	trigger_divide_by_zero()
	serial_print("[OK]\n")
}

test_should_trigger_page_fault :: proc() {
	serial_print("Triggering a Page fault exception...\n")
	set_idt_gate(14, cast(u32)uintptr(rawptr(isr14_expected_stub)), 0x08, 0x8E)
	bad_ptr := cast(^u32)uintptr(0xDEADBEEF)
	bad_ptr^ = 42
	serial_print("[OK]\n")
}

run_tests :: proc() {
	defer exit_qemu(.Success)
	defer serial_print("=== ALL TESTS PASSED ===\n")

	serial_print("=== RUNNING KERNEL TESTS ===\n")

	when TEST_NORMAL {
		test_vga_bounds()
		test_math()
		test_println_simple()
		test_println_many()
		test_println_output()
		test_shouldtrigger_breakpoint_and_recover()
	} else when TEST_PANIC {
		test_should_fail()
	} else when TEST_DOUBLE_FAULT {
		test_should_throw_exception()
	} else when TEST_PAGE_FAULT {
		test_should_trigger_page_fault()
	}
}
