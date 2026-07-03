package hardware

foreign import "interrupts.o"
@(default_calling_convention = "c")
foreign interrupts {
	enable_interrupts :: proc() ---
	disable_interrupts :: proc() ---
	halt_cpu :: proc() ---
	load_idt :: proc(ptr: ^IDT_Pointer) ---
	read_cr2 :: proc() -> u32 ---
	trigger_divide_by_zero :: proc() ---
	isr3_stub :: proc() ---
	isr8_expected_stub :: proc() ---
	isr14_stub :: proc() ---
	isr14_expected_stub :: proc() ---
	isr32_stub :: proc() ---
	isr33_stub :: proc() ---
}

IDT_Entry :: struct #packed {
	offset_low:  u16, // bits 0.15 of handler addr
	selector:    u16, // code segment selector in GDT, usually 0x08
	zero:        u8, // must be 0
	type_attr:   u8, // flags: gate type, privilege level, present bit
	offset_high: u16, // bits 16-31 of handler addr
}

IDT_Pointer :: struct #packed {
	limit: u16, // size of IDT - 1
	base:  u32, // addr of IDT
}

// First 32 are reserved for cpu exceptions
IDT_ENTRIES :: 256

idt: [IDT_ENTRIES]IDT_Entry
idt_ptr: IDT_Pointer

// flags: P | DPL(2) | 0 | Type(4), eg:
// 0x8E = 1000 1110 -> Present=1, DPL=0 (ring 0 only), Type = 1110 (32 bit Interrupt Gate)
set_idt_gate :: proc(num: int, base: u32, sel: u16, flags: u8) {
	idt[num].offset_low = u16(base & 0xFFFF)
	idt[num].selector = sel
	idt[num].zero = 0
	idt[num].type_attr = flags
	idt[num].offset_high = u16((base >> 16) & 0xFFFF)
}

init_idt :: proc() {
	idt_ptr.limit = size_of(idt) - 1
	idt_ptr.base = cast(u32)uintptr(&idt[0])

	// Exceptions
	set_idt_gate(3, cast(u32)uintptr(rawptr(isr3_stub)), 0x08, 0x8E) // Breakpoint
	set_idt_gate(8, 0, 0x30, 0x85) // Double Fault
	set_idt_gate(14, cast(u32)uintptr(rawptr(isr14_stub)), 0x08, 0x8E) // Page Fault

	// Hardware interrupts
	set_idt_gate(32, cast(u32)uintptr(rawptr(isr32_stub)), 0x08, 0x8E) // Timer (IRQ 0, PIC remapped to start at 32)
	set_idt_gate(33, cast(u32)uintptr(rawptr(isr33_stub)), 0x08, 0x8E) // Keyboard (IRQ 1 = 32 + 1)

	load_idt(&idt_ptr)
}
