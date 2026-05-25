.global enable_interrupts
.global disable_interrupts
.global halt_cpu
.global load_idt
.global read_cr2
.global trigger_divide_by_zero

.global isr3_stub
.global isr8_expected_stub
.global isr14_stub
.global isr14_expected_stub
.global isr32_stub
.global isr33_stub

.extern breakpoint_handler
.extern double_fault_handler
.extern expected_double_fault_handler
.extern page_fault_handler
.extern expected_page_fault_handler
.extern time_handler
.extern keyboard_handler

enable_interrupts:
    sti
    ret

disable_interrupts:
    cli
    ret

halt_cpu:
    hlt
    ret

/* void load_idt(IDT_Pointer* idt_ptr) */
load_idt:
    movl 4(%esp), %eax
    lidt (%eax)
    ret

/* u32 read_cr2() */
read_cr2:
    movl %cr2, %eax
    ret

trigger_divide_by_zero:
    xor %eax, %eax
    div %eax
    ret

isr3_stub:
    pushal
    cld /* clear direction flag */
    movl %esp, %ebp /* save current unaligned stack ptr */
    andl $0xFFFFFFF0, %esp /* Align stack to 16 bytes */
    call breakpoint_handler
    movl %ebp, %esp /* Restore original stack ptr */
    popal
    iret

isr8_expected_stub:
    pushal
    cld /* clear direction flag */
    movl %esp, %ebp /* save current unaligned stack ptr */
    andl $0xFFFFFFF0, %esp /* Align stack to 16 bytes */
    call expected_double_fault_handler
    movl %ebp, %esp /* Restore original stack ptr */
    popal
    iret

isr14_stub:
    pushal
    cld
    movl %esp, %ebp
    andl $0xFFFFFFF0, %esp
    subl $8, %esp
    leal 36(%ebp), %eax
    pushl %eax /* pass the pointer to the interrupt stack frame */
    pushl 32(%ebp) /* Pass the error to the Odin handler, the error code is located at EBP + 32 */
    call page_fault_handler
    movl %ebp, %esp
    popal
    addl $4, %esp /* Discard error code */
    iret

isr14_expected_stub:
    pushal
    cld
    movl %esp, %ebp
    andl $0xFFFFFFF0, %esp
    subl $8, %esp
    leal 36(%ebp), %eax
    pushl %eax /* pass the pointer to the interrupt stack frame */
    pushl 32(%ebp) /* Pass the error to the Odin handler, the error code is located at EBP + 32 */
    call expected_page_fault_handler 
    movl %ebp, %esp
    popal
    addl $4, %esp /* Discard error code */
    iret 

isr32_stub:
    pushal
    cld /* clear direction flag */
    movl %esp, %ebp /* save current unaligned stack ptr */
    andl $0xFFFFFFF0, %esp /* Align stack to 16 bytes */
    call time_handler
    movl %ebp, %esp /* Restore original stack ptr */
    popal
    iret

isr33_stub:
    pushal
    cld /* clear direction flag */
    movl %esp, %ebp /* save current unaligned stack ptr */
    andl $0xFFFFFFF0, %esp /* Align stack to 16 bytes */
    call keyboard_handler
    movl %ebp, %esp /* Restore original stack ptr */
    popal
    iret

