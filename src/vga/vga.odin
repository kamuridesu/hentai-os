package vga

import "../hardware"
import "base:intrinsics"

Color :: enum u8 {
	Black       = 0,
	Blue        = 1,
	Green       = 2,
	Cyan        = 3,
	Red         = 4,
	Magenta     = 5,
	Brown       = 6,
	Light_Gray  = 7,
	Dark_Gray   = 8,
	Light_Blue  = 9,
	Light_Green = 10,
	Light_Cyan  = 11,
	Light_Red   = 12,
	Pink        = 13,
	Yellow      = 14,
	White       = 15,
}

// 80 x 25 = standard vga text mode dimensions
VGA_WIDTH :: 80
VGA_HEIGHT :: 25
VGA_BUFFER := cast([^]u16)uintptr(0xB8000) // Physical addr of the VGA text mode framebuffer

Writer :: struct {
	row:   int,
	col:   int,
	color: u16,
}

vga_writer: Writer

// VGA text buffer (16 bits)
// 0-7: ASCII chars
// 8-11: Foreground color (4 bits)
// 12-14: backgoround color (3 bits)
// 15: blink
build_color :: proc(fg: Color, bg: Color) -> u16 {
	return (u16(fg) << 8) | (u16(bg) << 12)
}

write_byte :: proc(w: ^Writer, b: byte) {
	if b == '\n' {
		new_line(w)
		return
	}

	if w.col >= VGA_WIDTH {
		new_line(w)
	}

	index := w.row * VGA_WIDTH + w.col

	char_data := u16(b) | w.color

	intrinsics.volatile_store(&VGA_BUFFER[index], char_data)
	w.col += 1
}

write_string :: proc(w: ^Writer, s: string) {
	for i in 0 ..< len(s) {
		b := s[i]
		// 0x20-0x7E = Printable ASCII range
		if (b >= 0x20 && b <= 0x7E) || b == '\n' {
			write_byte(w, b)
		} else {
			// Prints  █
			write_byte(w, 0xFE)
		}
	}
}

new_line :: proc(w: ^Writer) {
	w.col = 0
	w.row += 1
	if w.row >= VGA_HEIGHT {
		for r in 1 ..< VGA_HEIGHT {
			for c in 0 ..< VGA_WIDTH {
				src_idx := r * VGA_WIDTH + c
				dst_idx := (r - 1) * VGA_WIDTH + c

				char := intrinsics.volatile_load(&VGA_BUFFER[src_idx])
				intrinsics.volatile_store(&VGA_BUFFER[dst_idx], char)
			}
		}
		w.row = VGA_HEIGHT - 1
		clear_row(w.row, w.color)
	}
}

clear_row :: proc(row: int, color: u16) {
	blank := u16(' ') | color
	for c in 0 ..< VGA_WIDTH {
		index := row * VGA_WIDTH + c
		intrinsics.volatile_store(&VGA_BUFFER[index], blank)
	}
}

clear_screen :: proc() {
	for r in 0 ..< VGA_HEIGHT {
		clear_row(r, vga_writer.color)
	}

	vga_writer.row = 0
	vga_writer.col = 0
}

print_string :: proc(s: string) {
	hardware.disable_interrupts()
	defer hardware.enable_interrupts()
	write_string(&vga_writer, s)
}

println :: proc(s: string) {
	hardware.disable_interrupts()
	defer hardware.enable_interrupts()
	write_string(&vga_writer, s)
	new_line(&vga_writer)
}

print_u32 :: proc(n: u32) {
	hardware.disable_interrupts()
	defer hardware.enable_interrupts()
	if n == 0 {
		write_byte(&vga_writer, '0')
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
		write_byte(&vga_writer, buf[j])
	}
}

print_hex :: proc(n: u32) {
	hardware.disable_interrupts()
	defer hardware.enable_interrupts()
	print_string("0x")
	if n == 0 {
		write_byte(&vga_writer, '0')
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
		write_byte(&vga_writer, buf[j])
	}
}
