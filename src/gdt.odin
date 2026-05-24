package main

foreign import "gdt.o"
@(default_calling_convention = "c")
foreign gdt {
	load_gdt :: proc(ptr: ^GDT_Pointer) ---
	flush_tss :: proc() ---
}

GDT_Entry :: struct #packed {
	limit_low:   u16,
	base_low:    u16,
	base_middle: u8,
	access:      u8,
	granularity: u8,
	base_high:   u8,
}

GDT_Pointer :: struct #packed {
	limit: u16,
	base:  u32,
}

TSS_Entry :: struct #packed {
	prev_tss, esp0, ss0, esp1, ss1, esp2, ss2:           u32,
	cr3, eip, eflags, eax, ecx, edx, esp, ebp, eso, edi: u32,
	es, cs, ss, ds, fs, gs, ldt:                         u32,
	trap:                                                u16,
	iomap_base:                                          u16,
}

KERNEL_STACK_SIZE :: 16 * 1024
Kernel_Stack :: struct #align (16) {
	data: [KERNEL_STACK_SIZE]u8,
}

kernel_stack: Kernel_Stack

DF_STACK_SIZE :: 4 * 1024
DF_Stack :: struct #align (16) {
	data: [DF_STACK_SIZE]u8,
}

gdt_table: [7]GDT_Entry
gdt_ptr: GDT_Pointer
tss: TSS_Entry
df_stack: DF_Stack
df_tss: TSS_Entry

// Access byte -> P | DPL(2) | S | Type(4), eg:
// 0x9A = 1001 1010 -> Present = 1, DPL = 0 (Ring 0), S = 1 (Code/Data), Type = 1010 (code, readable, non-conforming)
// Granularity byte -> G | D/B | L | AVL | limit[19:16], eg:
// 0xCF = 1100 1111 -> G = 1 (limit in 4KB pages, 0xFFFFF x 4KB = 4GB), D/B=1 (32 bit), upper limit = 1111
set_gdt_gate :: proc(num: int, base: u32, limit: u32, access: u8, gran: u8) {
	gdt_table[num].base_low = u16(base & 0xFFFF)
	gdt_table[num].base_middle = u8((base >> 16) & 0xFF)
	gdt_table[num].base_high = u8((base >> 24) & 0xFF)
	gdt_table[num].limit_low = u16(limit & 0xFFFF)
	gdt_table[num].granularity = u8((limit >> 16) & 0x0F) | (gran & 0xF0)
	gdt_table[num].access = access
}

init_gdt :: proc() {
	gdt_ptr.limit = size_of(gdt_table) - 1
	gdt_ptr.base = cast(u32)uintptr(&gdt_table[0])

	set_gdt_gate(0, 0, 0, 0, 0) // Null Segment
	set_gdt_gate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF) // Kernel Code (0x08)
	set_gdt_gate(2, 0, 0xFFFFFFFF, 0x92, 0xCF) // Kernel Data (0x10)
	set_gdt_gate(3, 0, 0xFFFFFFFF, 0xFA, 0xCF) // User Code
	set_gdt_gate(4, 0, 0xFFFFFFFF, 0xF2, 0xCF) // User Data

	// TSS Segment (0x28)
	tss_base := cast(u32)uintptr(&tss)
	tss_limit := cast(u32)size_of(tss)
	set_gdt_gate(5, tss_base, tss_limit, 0x89, 0x00)

	tss = {}
	tss.ss0 = 0x10
	tss.esp0 = cast(u32)uintptr(&kernel_stack.data[KERNEL_STACK_SIZE - 1])
	tss.iomap_base = size_of(tss) // Disable IO map
	load_gdt(&gdt_ptr)
	flush_tss()

	// Set Double Fault TSS
	df_tss = {}
	df_tss.esp = cast(u32)uintptr(&df_stack.data[DF_STACK_SIZE - 1])
	df_tss.ss = 0x10
	df_tss.cs = 0x08
	df_tss.ds = 0x10
	df_tss.es = 0x10
	df_tss.fs = 0x10
	df_tss.gs = 0x10
	df_tss.eip = cast(u32)uintptr(rawptr(double_fault_handler))
	df_tss.eflags = 0x2
	df_tss.cr3 = 0

	df_tss_base := cast(u32)uintptr(&df_tss)
	df_tss_limit := cast(u32)size_of(df_tss)
	set_gdt_gate(6, df_tss_base, df_tss_limit, 0x89, 0x00)
}
