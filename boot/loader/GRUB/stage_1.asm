; ==========================================
; Zenith OS - Multiboot2 Header (FIXED)
; ==========================================
section .multiboot_header
align 8

header_start:
    ; Multiboot2 Header
    dd 0xE85250D6                  ; Magic
    dd 0                           ; Architecture: 0 = i386 protected mode
    dd header_end - header_start   ; Header length
    dd -(0xE85250D6 + 0 + (header_end - header_start)) ; Checksum

    ; ==========================================
    ; FRAMEBUFFER REQUEST - OPTIONAL
    ; ==========================================
align 8
framebuffer_tag:
    dw 5                           ; Type 5 = framebuffer
    dw 1                           ; Flags: 1 = OPTIONAL. Boot gaat door als dit faalt.
    dd 24                          ; Size: MOET 8-byte aligned zijn. 20 -> 24 met 4 padding.
    dd 1024                        ; Preferred width
    dd 768                         ; Preferred height
    dd 32                          ; Preferred bpp
    ; 4 bytes padding impliciet door size=24

    ; ==========================================
    ; MODULE ALIGNMENT - AANBEVOLEN
    ; ==========================================
align 8
module_align_tag:
    dw 6                           ; Type 6 = module alignment
    dw 0                           ; Flags: 0 = required is prima hier
    dd 8                           ; Size: 8 is al 8-byte aligned

    ; ==========================================
    ; ADDRESS TAG - NODIG VOOR HOGER-HALF KERNELS
    ; ==========================================
    ; Als je kernel gelinkt is op bv. 0xFFFFFFFF80100000, MOET je dit aanzetten.
    ; Anders laadt GRUB je op 1MiB en crasht je direct.
; align 8
; address_tag:
;     dw 2                         ; Type 2 = address tag
;     dw 0                         ; Flags: required
;     dd 24                        ; Size: 8 + 4*4 = 24, klopt
;     dd header_start              ; header_addr: virtueel adres van header
;     dd _load_start               ; load_addr: fysiek adres waar eerste byte komt
;     dd _load_end                 ; load_end_addr: fysiek einde van data+nobits
;     dd _bss_end                  ; bss_end_addr: fysiek einde van BSS

    ; ==========================================
    ; ENTRY POINT TAG - NODIG ALS ENTRY != LOAD_ADDR
    ; ==========================================
    ; Als je entry point niet gelijk is aan load_addr, zet dit aan.
; align 8
; entry_tag:
;     dw 3                         ; Type 3 = entry address
;     dw 0                         ; Flags: required
;     dd 16                        ; Size: 8 + 4 = 12 -> 16 met padding
;     dd kernel_entry              ; Fysiek adres van je _start label
;     dd 0                         ; Padding naar 8-byte boundary

    ; ==========================================
    ; END TAG - VERPLICHT EN MOET LAATSTE ZIJN
    ; ==========================================
align 8
end_tag:
    dw 0                           ; Type 0 = end tag
    dw 0                           ; Flags
    dd 8                           ; Size

header_end:
