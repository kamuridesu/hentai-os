package main

@(export, link_name = "expected_double_fault_handler")
expected_double_fault_handler :: proc "c" () {
	context = {}
	serial_print("[OK]\n")
	exit_qemu(.Success)
	for {
		halt_cpu()
	}
}

@(export, link_name = "double_fault_handler")
double_fault_handler :: proc "c" () {
	context = {}
	serial_print("\n >>> EXCEPTION CAUGHT: DOUBLE FAULT (INT 8) <<<\n")
	exit_qemu(.Failed)
	for {
		halt_cpu()
	}
}

@(export, link_name = "breakpoint_handler")
breakpoint_handler :: proc "c" () {
	context = {}
	serial_print("\n>>> EXCEPTION CAUGHT: BREAKPOINT (INT 3) <<<\n")
}

@(export, link_name = "page_fault_handler")
page_fault_handler :: proc "c" (error_code: u32) {
	context = {}
	serial_print("\n >>> EXCEPTION CAUGHT: PAGE FAULT (INT 14) <<<\n")
	// For now lets just quit as Fatal
	exit_qemu(.Failed)
	for {
		halt_cpu()
	}
}

@(export, link_name = "expected_page_fault_handler")
expected_page_fault_handler :: proc "c" (error_code: u32) {
	context = {}
	serial_print("[OK]\n")
	exit_qemu(.Success)
	for {
		halt_cpu()
	}
}

@(export, link_name = "time_handler")
time_handler :: proc "c" () {
	context = {}
	pic_send_eoi(0)
}
