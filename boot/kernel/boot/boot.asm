; ==========================================
; ZENITH OS - KERNEL STARTUP (FIXED)
; ==========================================
bits 32
section.text
global _start
extern kernel_entry

; Deze symbols komen uit je linker script
extern p4_table_phys
extern p3_table_phys
extern p2_table_phys
extern stack_top_phys
extern gdt64_phys

_start:
    ; GRUB: EAX = magic, EBX = mbi pointer. Save direct.
    mov [mb_magic], eax
    mov [mb_info], ebx

    ; ================= EARLY STACK (physical) =================
    mov esp, [stack_top_phys] ; BUGFIX: laad de waarde, niet het adres

    ; ================= ZERO PAGE TABLES =================
    ; BUGFIX: gebruik fysieke adressen, en stosd ipv stosq in 32-bit
    mov edi, [p4_table_phys]
    mov ecx, (4096*3)/4 ; 3 tables * 4096 bytes / 4 bytes per stosd
    xor eax, eax
    rep stosd

    ; ================= BASIC PAGING SETUP =================
    ; PML4[0] -> PDPT (identity voor lower half)
    mov edi, [p4_table_phys]
    mov eax, [p3_table_phys]
    or eax, 0b11 ; Present + Writable
    mov [edi], eax

    ; PML4[511] -> PDPT (higher-half op 0xFFFFFFFF80000000)
    ; 511 * 8 = 4088 = 0xFF8
    mov [edi + 511*8], eax ; BUGFIX: 511, niet 256. 256 = 0xFFFF8000... fout.

    ; PDPT[510] -> PD (map 0xFFFFFFFF80000000 - 0xFFFFFFFFC0000000)
    ; 510 * 8 = 4080 = 0xFF0
    mov edi, [p3_table_phys]
    mov eax, [p2_table_phys]
    or eax, 0b11
    mov [edi + 510*8], eax ; BUGFIX: 510, want 0xFFFFFFFF80000000 >> 30 & 0x1FF = 510

    ; 2MB pages: map 1GB vanaf 0x0 fysiek -> 0xFFFFFFFF80000000
    mov edi, [p2_table_phys]
    mov eax, 0x00000083 ; Present + Writable + Huge
    mov ecx, 512 ; 512 * 2MB = 1GB. Genoeg voor kernel.
.map_2mb:
    mov [edi], eax
    add edi, 8
    add eax, 0x200000
    loop.map_2mb

    ; ================= LOAD CR3 =================
    mov eax, [p4_table_phys]
    mov cr3, eax

    ; ================= ENABLE PAE + PGE =================
    mov eax, cr4
    or eax, (1 << 5) | (1 << 7) ; PAE + PGE
    mov cr4, eax

    ; ================= ENABLE LONG MODE =================
    mov ecx, 0xC0000080 ; EFER MSR
    rdmsr
    or eax, (1 << 8) ; LME
    wrmsr

    ; ================= ENABLE PAGING =================
    mov eax, cr0
    or eax, (1 << 31) ; PG
    mov cr0, eax

    ; ================= LOAD 64-BIT GDT =================
    ; BUGFIX: gebruik fysiek adres van GDT pointer
    lgdt [gdt64_phys_ptr]
    jmp 0x08:long_mode_start ; 0x08 = gdt64.code selector

; ==========================================
bits 64
long_mode_start:
    ; Segments: in long mode alleen SS moet geladen. DS/ES/FS/GS worden 0.
    mov ax, 0x10 ; gdt64.data selector
    mov ss, ax
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; ================= HIGHER-HALF STACK =================
    mov rsp, stack_top ; Nu mag VMA

    ; ================= ARGUMENTS TO KERNEL =================
    mov edi, [mb_magic] ; 32-bit -> rdi
    mov esi, [mb_info] ; 32-bit -> rsi

    cmp edi, 0x36D76289
    jne.bad_multiboot

    ; Check of mbi pointer canonical is voordat je hem gebruikt
    mov rax, rsi
    shr rax, 47
    cmp rax, 0
    je.mbi_ok
    cmp rax, 0x1FFFF
    jne.bad_multiboot
.mbi_ok:

    call kernel_entry

.halt:
    cli
    hlt
    jmp.halt

.bad_multiboot:
    jmp.halt

; ==========================================
section.rodata
align 16
gdt64:
    dq 0 ; Null
.code: equ $ - gdt64 ; 0x08
    dq 0x00AF9A000000FFFF ; Code: L=1, P=1, DPL=0, S=1, Type=1010
.data: equ $ - gdt64 ; 0x10
    dq 0x00AF92000000FFFF ; Data: P=1, S=1, Type=0010
.pointer:
    dw $ - gdt64 - 1
    dq gdt64 ; VMA voor na paging

; BUGFIX: fysieke pointer voor LGDT vóór paging
gdt64_phys_ptr:
    dw gdt64.pointer - gdt64 - 1
    dq gdt64_phys ; LMA, komt uit linker

; ==========================================
section.bss
align 4096
p4_table: resb 4096
p3_table: resb 4096
p2_table: resb 4096

align 16
stack_bottom:
    resb 32768
stack_top:

; ==========================================
section.data
align 8
mb_magic: dd 0
mb_info: dd 0
