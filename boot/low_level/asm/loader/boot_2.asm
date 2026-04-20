; ==========================================
; Zenith OS - Stage 2 (64-bit Switch & Loader)
; Locatie: 0x8000
; ==========================================

[bits 16]
stage_2_start:
    ; 1. Schakel de A20-line in (toegang tot geheugen boven 1MB)
    in al, 0x92
    or al, 2
    out 0x92, al

    ; 2. Laad de tijdelijke 32-bit GDT
    lgdt [gdt_descriptor]

    ; 3. Switch naar Protected Mode (CR0 bit 0 instellen)
    mov eax, cr4
    or eax, 1 << 5          ; Schakel PAE (Physical Address Extension) in voor 64-bit
    mov cr4, eax

    ; --- Paging opzetten (Minimaal 2MB identiteit-mapping voor de kernel) ---
    ; [Hier bouwen we de Page Tables op 0x1000, 0x2000, etc.]
    ; Voor de beknoptheid gaan we ervan uit dat de tabellen klaarstaan:
    mov eax, 0x1000         ; PML4 tabel adres
    mov cr3, eax

    ; 4. Schakel Long Mode in via EFER MSR
    mov ecx, 0xC0000080     ; EFER MSR register
    rdmsr
    or eax, 1 << 8          ; LME (Long Mode Enable) bit
    wrmsr

    ; 5. Activeer paging en 64-bit mode tegelijk
    mov eax, cr0
    or eax, 1 << 31         ; PG (Paging) bit
    or eax, 1 << 0          ; PE (Protection Enable) bit
    mov cr0, eax

    ; 6. Verre sprong naar de 64-bit Code Segment
    jmp gdt_code:init_64bit

[bits 64]
init_64bit:
    ; Zenith OS is nu officieel in 64-bit mode!
    mov ax, gdt_data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; --- Kernel Loader ---
    ; Hier roepen we de functie aan die de rest van de kernel inlaadt
    call kernel_main_loader
    jmp $

; --- GDT Structure voor de switch ---
gdt_start:
    dq 0x0000000000000000    ; Null descriptor
gdt_code: equ $ - gdt_start
    dq 0x00af9a000000ffff    ; 64-bit code segment
gdt_data: equ $ - gdt_start
    dq 0x00af92000000ffff    ; 64-bit data segment
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dq gdt_start

kernel_main_loader:
    ; Placeholder voor het laden van de C++ kernel van schijf naar RAM
    ret
