package main

PAGE_SIZE :: 4096

Frame_Allocator :: struct {
	mmap_addr:           u32,
	mmap_length:         u32,
	next_frame:          u64,
	current_mmap_offset: u32,
}

frame_allocator: Frame_Allocator

init_frame_allocator :: proc(mb_info: ^Multiboot_Info, kernel_end: u32) {
	frame_allocator.mmap_addr = mb_info.mmap_addr
	frame_allocator.mmap_length = mb_info.mmap_length

	mask := cast(u64)(PAGE_SIZE - 1)
	kernel_end_aligned := (cast(u64)kernel_end + mask) & ~mask
	frame_allocator.next_frame = max(kernel_end_aligned, u64(0x400000))
}

// Bump allocator
allocate_frame :: proc() -> u64 {

	for frame_allocator.current_mmap_offset < frame_allocator.mmap_length {
		entry := cast(^Multiboot_Mmap_Entry)uintptr(
			frame_allocator.mmap_addr + frame_allocator.current_mmap_offset,
		)
		if entry.type == 1 { 	// usable RAM
			if frame_allocator.next_frame < entry.addr {
				// ensure the addr is aligned to a 4KiB boundary
				align_mask := cast(u64)(PAGE_SIZE - 1)
				frame_allocator.next_frame = (entry.addr + align_mask) & ~align_mask
			}

			if frame_allocator.next_frame + PAGE_SIZE <= entry.addr + entry.len {
				allocated_addr := frame_allocator.next_frame
				frame_allocator.next_frame += PAGE_SIZE
				return allocated_addr
			}
		}

		frame_allocator.current_mmap_offset += entry.size + 4
	}

	panic_handler("MEMORY", "Out of Physical Memory (OOM)", {})
}
