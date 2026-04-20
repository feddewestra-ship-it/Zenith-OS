; ==========================================
; Zenith OS - Bootloader Stage 1 (Real Mode Loader)
; ==========================================

[org 0x7c00]

jmp short start       ; Spring over eventuele dataheaders
nop

start:
    ; --- Setup Registers & Stack ---
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    ; --- Stage 1: De Lader ---
    ; We gebruiken BIOS Interrupt 0x13, AH=0x02 om sectoren te lezen
    mov [BOOT_DRIVE], dl    ; Het BIOS slaat het opstartstation op in DL

    mov bx, 0x8000          ; Adres in het geheugen waar we de volgende sectoren laden
    mov al, 2               ; Aantal sectoren dat we willen lezen
    mov ch, 0x00            ; Cylinder 0
    mov dh, 0x00            ; Head 0
    mov cl, 0x02            ; Sector 2 (Sector 1 was de MBR)
    
    mov ah, 0x02            ; BIOS read sector functie
    int 0x13                ; Roep de BIOS aan

    jc disk_error           ; Spring als de 'Carry Flag' gezet is (fout bij lezen)

    ; Spring naar het geladen gedeelte (Stage 2 / Kernel start)
    jmp 0x0000:0x8000

disk_error:
    ; Foutafhandeling (Zenith OS kon niet verder laden)
    mov ah, 0x0e
    mov al, 'E'
    int 0x10
    jmp $

; Variabelen
BOOT_DRIVE db 0

; MBR Vulsel
times 510-($-$$) db 0
dw 0xaa55

; ==========================================
; BEGIN VAN GELADEN SECTOREN (0x8000)
; Dit is wat de lader hierboven van de schijf leest
; ==========================================
[org 0x8000]
    ; Hier begint de echte "Zenith OS" lader logica
    mov ah, 0x0e
    mov al, 'L'             ; Laat zien dat we in de 'Loader' zijn
    int 0x10
    
    jmp $                   ; Voor nu even stoppen
