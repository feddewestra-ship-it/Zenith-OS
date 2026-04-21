/* ==========================================
   Zenith OS - Linker Script (Higher-Half, Multiboot2)
   ========================================== */

ENTRY(kernel_entry)

PHYS_BASE = 0x00100000;              /* 1 MiB - GRUB load address */
VIRT_BASE = 0xFFFFFFFF80000000;      /* Higher-half base */

/* ========================================== */
SECTIONS
{
    /* Multiboot header MOET in de eerste 32KiB van de file en op VMA=LMA */
    . = PHYS_BASE;
    .multiboot : AT(ADDR(.multiboot))
    {
        KEEP(*(.multiboot_header))
    }

    /* BUGFIX 1: VMA springt naar VIRT_BASE, niet VIRT_BASE+PHYS_BASE */
    . = VIRT_BASE;

    _kernel_vma_start = .;                       /* Virtueel begin van kernel */
    _kernel_lma_start = LOADADDR(.multiboot);    /* Fysiek begin van kernel */

    /* ================= TEXT ================= */
    .text ALIGN(4K) : AT(ADDR(.text) - VIRT_BASE + PHYS_BASE)
    {
        _text_start = .;
        *(.text .text.*)
        _text_end = .;
    }

    /* ================= RODATA ================= */
    .rodata ALIGN(4K) : AT(ADDR(.rodata) - VIRT_BASE + PHYS_BASE)
    {
        _rodata_start = .;
        *(.rodata .rodata.*)
        _rodata_end = .;
    }

    /* ================= DATA ================= */
    .data ALIGN(4K) : AT(ADDR(.data) - VIRT_BASE + PHYS_BASE)
    {
        _data_start = .;
        *(.data .data.*)
        _data_end = .;
    }

    /* ================= BSS ================= */
    .bss ALIGN(4K) : AT(ADDR(.bss) - VIRT_BASE + PHYS_BASE)
    {
        _bss_start = .;
        *(COMMON)
        *(.bss .bss.*)
        _bss_end = .;
    }

    /* ================= KERNEL END ================= */
    _kernel_vma_end = .;   /* Virtueel einde */

    /* BUGFIX 2: Correcte fysieke eindberekening */
    _kernel_lma_end = LOADADDR(.bss) + SIZEOF(.bss);

    /* Symbols voor je kernel en voor de address tag */
    PROVIDE(_kernel_vma_size = _kernel_vma_end - _kernel_vma_start);
    PROVIDE(_kernel_lma_size = _kernel_lma_end - _kernel_lma_start);

    /* Deze 4 gebruik je in je multiboot2 address tag */
    PROVIDE(_load_start = _kernel_lma_start);
    PROVIDE(_load_end = _kernel_lma_end);
    PROVIDE(_bss_end = _kernel_lma_end);
    PROVIDE(kernel_entry = _kernel_vma_start); /* entry = VMA van .text */

    /* Build ID netjes in .rodata dumpen */
    .note.gnu.build-id ALIGN(4) : AT(LOADADDR(.rodata) + SIZEOF(.rodata)) 
    { 
        *(.note.gnu.build-id) 
    }

    /DISCARD/ :
    {
        *(.eh_frame)
        *(.comment)
        *(.note.GNU-stack)
        *(.gnu_debuglink)
    }
}
