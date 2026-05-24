package main

PIC1_COMMAND :: 0x20
PIC1_DATA :: 0x21
PIC2_COMMAND :: 0xA0
PIC2_DATA :: 0xA1

PIC_EOI :: 0x20 // End Of Interrupt

init_pic :: proc() {
	outb(PIC1_COMMAND, 0x11) // Start init sequence
	outb(PIC2_COMMAND, 0x11)

	outb(PIC1_DATA, 0x20) // Sets the primary PIC IRQ to start at 32
	outb(PIC2_DATA, 0x28) // Sets the secondary PIC IRQ to start at 40 (32 + 8)

	outb(PIC1_DATA, 0x04) // Tells the primary PIC there's a slave PIC at IRQ2 (0000 0100)
	outb(PIC2_DATA, 0x02) // Tells the secondary PIC its cascade identity

	// Sets the mode to 8086/88
	outb(PIC1_DATA, 0x01)
	outb(PIC2_DATA, 0x01)

	// Unmask all interrupts
	outb(PIC1_DATA, 0x00)
	outb(PIC2_DATA, 0x00)
}

pic_send_eoi :: proc(irq: u8) {
	if irq >= 8 {
		outb(PIC2_COMMAND, PIC_EOI)
	}
	outb(PIC1_COMMAND, PIC_EOI)
}

disable_pic :: proc() {
	outb(PIC1_DATA, 0xFF)
	outb(PIC2_DATA, 0xFF)
}
