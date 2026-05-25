package main

MULTIBOOT_BOOTLOADER_MAGIC :: 0x2BADB002
MAGIC :: 0x1BADB002
FLAGS :: 0x00
CHECKSUM :: ~(u32(MAGIC) + u32(FLAGS)) + 1

@(export, link_section = ".multiboot")
multiboot_header := [3]u32{MAGIC, FLAGS, CHECKSUM}

Multiboot_Info :: struct #packed {
	// flags field can tell which fields are valid for us to use (from the bootloader)
	// 0 -> mem_lower/mem_upper is valid
	// 1 -> boot_device is valid
	// 2 -> cmdline is valid
	// 3 -> mods_count/mods_addr are valid
	// 4 -> syms (a.out symble table) is valid
	// 5 -> sums (ELF section headers) is valid
	// 6 -> mmap_length/mmap_addr are valid
	// 7 -> drives_length/drives_addr are valid
	// 8 -> config_table is valid
	// 9 -> boot_loader_name is valid
	flags:            u32,
	// mem_lower is memory below 1MiB
	mem_lower:        u32,
	// mem_upper is memory above 1MiB, mmap is more accurate
	mem_upper:        u32,
	// which BIOS disk the kernel was loaded from
	// it has 4 bytes: [drive, partition1, partition2, partition3]
	boot_device:      u32,
	// physical addr of a null-terminated string of kernel command line arguments
	cmdline:          u32,
	// the number of boot modules loaded alongside the kernel
	mods_count:       u32,
	// the physical addr of the firstr module struct
	mods_addr:        u32,
	// 4 raw u32 that hold either an a.out symbol table or ELF section header depending on the flag
	syms:             [4]u32,
	// total size of the array (not counting the entry) stored as a pointer in the mmap_addr
	mmap_length:      u32,
	// points to an array of mem regions (Multiboot_Mmap_Entry)
	mmap_addr:        u32,
	drives_length:    u32,
	drives_addr:      u32,
	// physical addr of the BIOS ROM config table
	config_table:     u32,
	// physical addr of a null-terminated string
	boot_loader_name: u32,
	// pointer to APM BIOS info, superseded by ACPI
	apm_table:        u32,
}

// The `size` field does not includes itself
// To walk it we must have to advance by entry.size + 4 instead of calling size_of(Multiboot_Mmap_Entry) directly
Multiboot_Mmap_Entry :: struct #packed {
	// bytes size of this entry not including size itself
	size: u32,
	// physical start addr of the region
	addr: u64,
	// byte length of the region
	len:  u64,
	// what kind of mem is this?
	// 1 -> available, safe to use
	// 2 -> reserved, BIOS, hardware
	// 3 -> ACPI reclaimable
	// 4 -> ACPI NVS
	// 5 -> bad memory
	type: u32,
}
