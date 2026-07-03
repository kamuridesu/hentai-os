package keyboard

import "../../hardware"
import "../../vga"

scancode_chars := [?]byte {
	0,
	27,
	'1',
	'2',
	'3',
	'4',
	'5',
	'6',
	'7',
	'8',
	'9',
	'0',
	'-',
	'=',
	'\b',
	'\t',
	'q',
	'w',
	'e',
	'r',
	't',
	'y',
	'u',
	'i',
	'o',
	'p',
	'[',
	']',
	'\n',
	0,
	'a',
	's',
	'd',
	'f',
	'g',
	'h',
	'j',
	'k',
	'l',
	';',
	'\'',
	'`',
	0,
	'\\',
	'z',
	'x',
	'c',
	'v',
	'b',
	'n',
	'm',
	',',
	'.',
	'/',
	0,
	'*',
	0,
	' ',
}

@(export, link_name = "keyboard_handler")
keyboard_handler :: proc "c" () {
	context = {}
	scancode := hardware.inb(0x60)

	if scancode < 0x80 {
		char := scancode_chars[scancode]
		if char != 0 {
			buf := [2]byte{char, 0}
			vga.print_string(string(buf[:1]))
		}
	}
	hardware.pic_send_eoi(1)
}
