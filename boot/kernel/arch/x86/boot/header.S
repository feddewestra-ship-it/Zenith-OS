# ==========================================
# ZENITH OS - KERNEL STARTUP (FIXED)
# ==========================================
.set VIRT_BASE, 0xffffffff80000000

.macro PHYS reg, sym
    mov $\sym, \reg
    sub $VIRT_BASE, \reg
.endm

.section.text
.code32
.global _start
.extern kernel_main

_start:
    # Reset EFLAGS
    pushl $0
    popf

    # Bewaar Multiboot2 info direct in.data
    movl %eax, mb_magic
    movl %ebx, mb_info

    # Early physical stack
    PHYS %esp, stack_top

    call setup_page_tables
    call enable_paging

    # BUGFIX: LGDT moet fysiek adres gebruiken zolang we nog op identity map zitten
    PHYS %eax, gdt64_ptr_phys
    lgdt (%eax)
    ljmp $0x08, $startup_64

# ==========================================
setup_page_tables:
    # BUGFIX: Zero met fysiek adres
    PHYS %edi, pml4_table
    mov $(4096*3 / 4), %ecx # PML4 + PDP + PD
    xor %eax, %eax
    rep stosl

    # PML4[0] -> PDP (lower half identity voor de transitie)
    PHYS %edi, pml4_table
    PHYS %eax, pdp_table
    or $0b11, %eax
    movl %eax, (%edi)

    # BUGFIX: PML4[511] voor 0xFFFFFFFF80000000, niet 256
    PHYS %eax, pdp_table
    or $0b11, %eax
    movl %eax, 511*8(%edi)

    # PDP[510] -> PD, want 0xFFFFFFFF80000000 >> 30 & 0x1FF = 510
    PHYS %edi, pdp_table
    PHYS %eax, pd_table
    or $0b11, %eax
    movl %eax, 510*8(%edi)

    # Map eerste 1GB met 2MB huge pages. 4GB is overdreven en traag.
    PHYS %edi, pd_table
    mov $0x83, %eax # P | RW | PS (2MB page)
    mov $512, %ecx # 512 * 2MB = 1GB

1: movl %eax, (%edi)
    add $8, %edi
    add $0x200000, %eax
    loop 1b

    ret

# ==========================================
enable_paging:
    # CR3 = PML4 (physical)
    PHYS %eax, pml4_table
    mov %eax, %cr3

    # CR4: PAE + PGE
    mov %cr4, %eax
    or $(1<<5 | 1<<7), %eax
    mov %eax, %cr4

    # EFER.LME = 1
    mov $0xC0000080, %ecx
    rdmsr
    or $(1<<8), %eax
    wrmsr

    # CR0: Paging enable
    mov %cr0, %eax
    or $(1<<31), %eax
    mov %eax, %cr0
    ret

# ==========================================
.code64
startup_64:
    # Segment registers
    mov $0x10, %ax
    mov %ax, %ss
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs

    # Higher-half stack, nu mag VMA
    mov $stack_top, %rsp

    # BUGFIX: Laad multiboot args terug uit.data
    mov mb_magic, %edi # Zero-extend naar RDI
    mov mb_info, %esi # Zero-extend naar RSI

    cmp $0x36D76289, %edi
    jne halt_loop

    call kernel_main

halt_loop:
    cli
    hlt
    jmp halt_loop

# ==========================================
.section.rodata
.align 16
gdt64:
   .quad 0x0000000000000000 # 0x00 null
   .quad 0x00AF9A000000FFFF # 0x08 code: L=1, P=1, DPL=0, S=1, Type=1010, G=1
   .quad 0x00AF92000000FFFF # 0x10 data: P=1, S=1, Type=0010, G=1
gdt64_ptr:
   .word. - gdt64 - 1
   .quad gdt64 # VMA, voor na paging

# BUGFIX: aparte fysieke pointer voor LGDT vóór paging
gdt64_ptr_phys:
   .word gdt64_ptr - gdt64 - 1
   .quad gdt64 - VIRT_BASE # LMA

# ==========================================
.section.bss
.align 4096
pml4_table:.skip 4096
pdp_table:.skip 4096
pd_table:.skip 4096

.align 16
stack_bottom:.skip 32768
stack_top:

# ==========================================
.section.data
.align 8
mb_magic:.long 0
mb_info:.long 0
