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

serial_print_u32 :: proc(n: u32) {
	if n == 0 {
		serial_write_byte('0')
		return
	}

	buf: [16]byte
	i := 15
	num := n

	for num > 0 {
		buf[i] = '0' + byte(num % 10)
		num /= 10
		i -= 1
	}

	for j in i + 1 ..= 15 {
		serial_write_byte(buf[j])
	}
}

serial_print_hex :: proc(n: u32) {
	serial_print("0x")
	if n == 0 {
		serial_write_byte('0')
		return
	}

	hex_chars := "0123456789ABCDEF"
	buf: [8]byte
	i := 7
	num := n

	for num > 0 {
		buf[i] = hex_chars[num % 16]
		num /= 16
		i -= 1
	}

	for j in i + 1 ..= 7 {
		serial_write_byte(buf[j])
	}
}
