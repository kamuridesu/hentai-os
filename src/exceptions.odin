package main

Page_Fault_Flag :: enum u32 {
	Present           = 0,
	Write             = 1,
	User              = 2,
	Reserved_Write    = 3,
	Instruction_Fetch = 4,
}

Page_Fault_Error_Code :: bit_set[Page_Fault_Flag;u32]

Interrupt_Stack_Frame :: struct #packed {
	eip:    u32,
	cs:     u32,
	eflags: u32,
}

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

print_page_fault_info :: proc(error_code: u32, frame: ^Interrupt_Stack_Frame) {

	error := transmute(Page_Fault_Error_Code)error_code
	serial_print("\n >>> EXCEPTION CAUGHT: PAGE FAULT (INT 14) <<<\n")

	serial_print("Accessed Address : ")
	serial_print_hex(read_cr2())
	serial_print("\n")

	serial_print("Instruction      : ")
	serial_print_hex(frame.eip)
	serial_print("\n")

	serial_print("EFLAGS           : ")
	serial_print_hex(frame.eflags)
	serial_print("\n")

	serial_print("Error Code       : ")
	serial_print_hex(error_code)
	serial_print(" [ ")
	if .Present in error {
		serial_print("protection-violation ")
	} else {
		serial_print("not-present ")
	}
	if .Write in error {
		serial_print("write ")
	}
	if .User in error {
		serial_print("user ")
	}
	if .Reserved_Write in error {
		serial_print("reserved-write ")
	}
	if .Instruction_Fetch in error {
		serial_print("instruction-fetch ")
	}
	serial_print("]\n")
}

@(export, link_name = "page_fault_handler")
page_fault_handler :: proc "c" (error_code: u32, frame: ^Interrupt_Stack_Frame) {
	context = {}
	print_page_fault_info(error_code, frame)

	// For now lets just quit as Fatal
	exit_qemu(.Failed)
	for {
		halt_cpu()
	}
}

@(export, link_name = "expected_page_fault_handler")
expected_page_fault_handler :: proc "c" (error_code: u32, frame: ^Interrupt_Stack_Frame) {
	context = {}
	print_page_fault_info(error_code, frame)

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
