package main

foreign import "paging.o"
@(default_calling_convention = "c")
foreign paging {
	load_page_directory :: proc(dir_ptr: ^u32) ---
	enable_paging :: proc() ---
}

PAGE_PRESENT :: 0x01 // Marks the page as present in the physical frame
PAGE_RW :: 0x02

Page_Table :: struct #align (4096) {
	entries: [1024]u32,
}

page_directory: Page_Table
page_table_1: Page_Table

init_paging :: proc() {
	// Maps the first 4MB of mem
	for i in 0 ..< 1024 {
		physical_addr := cast(u32)(i * 4096) // each page is 4096 bytes
		page_table_1.entries[i] = physical_addr | PAGE_PRESENT | PAGE_RW
	}

	// Init page dir, 1024 entries per table = 1024 * 4 KiB page * 1024 = 4GiB addr space
	for i in 0 ..< 1024 {
		page_directory.entries[i] = 0
	}

	// insert the populate page table into the first page dir slot
	dir_entry := cast(u32)uintptr(&page_table_1.entries[0])
	page_directory.entries[0] = dir_entry | PAGE_PRESENT | PAGE_RW

	// load into the CR3 register
	load_page_directory(&page_directory.entries[0])
	enable_paging()

	df_tss.cr3 = cast(u32)uintptr(&page_directory.entries[0])
}
