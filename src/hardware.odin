package main

foreign import "ports.o"

@(default_calling_convention = "c")
foreign ports {
	outb :: proc(port: u16, value: u8) ---
	out32 :: proc(port: u16, value: u32) ---
	trigger_breakpoint :: proc() ---
	inb :: proc(port: u16) -> u8 ---

}

Qemu_Exit_Code :: enum u32 {
	Success = 0x10,
	Failed  = 0x11,
}

exit_qemu :: proc(code: Qemu_Exit_Code) {
	// 0xF4 = isa-debug-exit
	out32(0xF4, u32(code))
}

// COM1
SERIAL_PORT :: 0x3F8

init_serial :: proc() {
	// +0 -> data register
	// +1 -> interrupt enable
	// +2 -> FIFO control
	// +3 -> line control
	// +4 -> modem control

	outb(SERIAL_PORT + 1, 0x00) // Disable UART interrupts
	outb(SERIAL_PORT + 3, 0x80) // set DLAB (dividor latch access bit) to +0 and +1 access the baud rate instead of data
	outb(SERIAL_PORT + 0, 0x03) // set baud rate divisor to 3
	outb(SERIAL_PORT + 1, 0x00) // (baud rate is 115200 bps for serial, we set it to 38400)
	outb(SERIAL_PORT + 3, 0x03) // Configure line to 8 bits no parity 1 stop bit (8N1)
	outb(SERIAL_PORT + 2, 0xC7) // Enable FIFO and set it to 14-byte threshold
	outb(SERIAL_PORT + 4, 0x0B) // Enable IRQs, sets RTS/DSR on modem (ready to send/receive)
}

serial_write_byte :: proc(b: byte) {
	outb(SERIAL_PORT, b)
}

serial_print :: proc(s: string) {
	for i in 0 ..< len(s) {
		serial_write_byte(s[i])
	}
}
