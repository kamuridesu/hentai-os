.global load_page_directory
.global enable_paging

/* void load_page_directory(u32* directory) */
load_page_directory:
    movl 4(%esp), %eax
    movl %eax, %cr3 /* CR3 expects the physical addr of the directory */
    ret

/* void enable_paging() */
enable_paging:
    movl %cr0, %eax
    orl $0x80000000, %eax /* Set bit 31 */
    movl %eax, %cr0
    ret
