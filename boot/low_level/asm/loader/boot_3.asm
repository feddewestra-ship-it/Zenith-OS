; ==========================================
; Zenith OS - Stage 3 (Kernel Entry Jump)
; ==========================================

[bits 64]
[extern kmain]        ; Dit is de naam van de functie in onze C++/C kernel

stage_3_entry:
    ; --- 1. Scherm opschonen of status sturen ---
    ; We schrijven direct naar het VGA-geheugen (0xB8000)
    mov rax, 0x2f532f4b2f4f2f4c ; "LOK " in groen/grijs (voor 'Link OK')
    mov qword [0xb8000], rax

    ; --- 2. Stack voor de kernel opzetten ---
    ; De kernel heeft een eigen stabiele stack nodig
    mov rsp, kernel_stack_top

    ; --- 3. De sprong naar de Grote Baas ---
    ; We roepen de C/C++ entry point aan
    call kmain

    ; --- 4. Fallback ---
    ; Als de kernel ooit 'returned' (wat niet zou mogen), vangen we de CPU hier op
    cli
.halt:
    hlt
    jmp .halt

section .bss
align 16
kernel_stack_bottom:
    resb 16384          ; 16 KB gereserveerd voor de kernel stack
kernel_stack_top:
