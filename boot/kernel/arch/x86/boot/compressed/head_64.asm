.code64
.section ".text"
.global startup_64
.extern zenith_decompress_kernel
.extern kernel_entry

startup_64:
    cli
    cld

    # ================= STACK SETUP =================
    leaq boot_stack_end(%rip), %rsp
    andq $~0xF, %rsp          # 16-byte alignment. Red zone zit onder RSP, niet ervoor.
                              # BUGFIX: geen `sub $32`. Red zone is voor callee.

    # ================= BEWAAR MULTIBOOT INFO =================
    # RDI = magic, RSI = mb_info pointer, gezet door je 32-bit _start
    movq %rdi, mb_magic(%rip)
    movq %rsi, mb_info(%rip)

    # ================= DECOMPRESSIE =================
    # BUGFIX: Alles RIP-relative. Werkt zowel op VIRT_BASE als op PHYS_BASE
    # zolang je stub zelf volledig PIC is en binnen 2GB van zichzelf zit.
    leaq _compressed_start(%rip), %rdi
    leaq _decomp_buffer(%rip), %rsi
    movq $_decomp_buffer_size, %rdx      # Geef lengte mee, veiliger

    call zenith_decompress_kernel

    # ================= CHECK RESULT =================
    testq %rax, %rax
    jz .decompress_failed

    # RAX bevat nu entry point van decompressed kernel
    movq %rax, %r12 # bewaar, want RAX is caller-saved

    # ================= MEMORY BARRIERS =================
    mfence # Alle decompress writes globaal zichtbaar maken

    # ================= RESTORE MULTIBOOT ARGS =================
    movq mb_magic(%rip), %rdi
    movq mb_info(%rip), %rsi

    # BUGFIX: Sanity check mb_info voordat je hem doorgeeft
    testq %rsi, %rsi
    jz .bad_mbi
    movq %rsi, %rax
    shrq $47, %rax
    cmp $0, %rax
    je .mbi_ok
    cmp $0x1FFFF, %rax
    jne .bad_mbi
.mbi_ok:

    # ================= JUMP NAAR DECOMPRESSED KERNEL =================
    # R12 = entry, RDI = magic, RSI = mbi
    jmp *%r12

.decompress_failed:
.bad_mbi:
    # TODO: port 0xE9 debug of VGA text
    cli
    hlt
    jmp .decompress_failed

# ==========================================
.section ".data"
.align 8
mb_magic: .quad 0
mb_info:  .quad 0

# ==========================================
.section ".rodata"
.align 16
_compressed_start:
    # .incbin "kernel.bin.lz4"
    # Zorg dat dit bestand bestaat bij het linken. Leeg = triple fault.
_compressed_end:

# ==========================================
.section ".bss"
.balign 4096
boot_stack:
    .skip 16384 # 16 KiB is zat voor een decompressor
boot_stack_end:

.balign 4096
_decomp_buffer:
    .skip 0x200000 # 2 MiB
_decomp_buffer_end:
.set _decomp_buffer_size, _decomp_buffer_end - _decomp_buffer
