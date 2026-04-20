; ==========================================
; Zenith OS - Bootloader Stage 0 (MBR)
; ==========================================

[org 0x7c00]          ; Vertel de assembler dat de code op dit adres geladen wordt

start:
    ; Register initialisatie
    cli               ; Schakel interrupts uit tijdens de setup
    xor ax, ax        ; Maak AX leeg (0)
    mov ds, ax        ; Data Segment op 0
    mov es, ax        ; Extra Segment op 0
    mov ss, ax        ; Stack Segment op 0
    mov sp, 0x7c00    ; Stack pointer groeit naar beneden vanaf het begin van de bootloader
    sti               ; Schakel interrupts weer in

    ; --- Hier komt jouw logica voor Zenith OS ---

    ; Voorbeeld: Stop de CPU zodat we niet in willekeurige data crashen
    jmp $             

; ==========================================
; MBR Opvulling & Signature
; ==========================================

times 510-($-$$) db 0 ; Vul de rest van de 512 bytes met 0
dw 0xaa55             ; De verplichte MBR boot signature
