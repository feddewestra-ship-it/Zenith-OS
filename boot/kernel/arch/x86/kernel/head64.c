/* * =========================================================================
 * ZENITH OS - head64.c (x86_64 Kernel Entry Logic)
 * =========================================================================
 */

#include <stdint.h>

/* Definities voor paginering en geheugen mapping */
#define KERNEL_VIRTUAL_OFFSET 0xffffffff80000000
#define __pa(x) ((uint64_t)(x) - KERNEL_VIRTUAL_OFFSET)
#define __va(x) ((void*)((uint64_t)(x) + KERNEL_VIRTUAL_OFFSET))

/* Externe functies uit de C++ kernel en hardware setup */
extern void x86_64_init_paging();
extern void zenith_main(void);
extern void clear_bss(void);

/**
 * x86_64_start_kernel()
 * De eerste C-functie die wordt uitgevoerd na decompressie.
 * Draait op het fysieke adres, maar bereidt de overstap naar de Higher Half voor.
 */
void x86_64_start_kernel(uint64_t magic, uint64_t boot_info_ptr) {
    
    /* 1. Maak de BSS sectie leeg 
     * Belangrijk voor C++: alle niet-geïnitialiseerde globale variabelen moeten op 0 staan.
     */
    clear_bss();

    /* 2. Initialiseer de definitieve Paging 
     * Hier mappen we de kernel naar 0xffffffff80000000.
     */
    x86_64_init_paging();

    /* 3. Update de stack pointer naar het virtuele adres 
     * We draaien nu nog fysiek, maar na de sprong naar de main kernel 
     * gebruiken we alleen nog de Higher Half adressen.
     */
    asm volatile (
        "addq %0, %%rsp" 
        : 
        : "r"(KERNEL_VIRTUAL_OFFSET)
    );

    /* 4. Spring naar de platform-onafhankelijke Kernel Main 
     * We laden het adres in een register om een absolute sprong te forceren
     * naar het virtuele adresgebied.
     */
    uint64_t entry = (uint64_t)&zenith_main;
    
    asm volatile (
        "jmp *%0" 
        : 
        : "r"(entry), "D"(magic), "S"(boot_info_ptr)
    );

    /* Mocht de kernel ooit terugkeren (onmogelijk) */
    while (1) {
        asm volatile("hlt");
    }
}

/**
 * Helper om de BSS sectie op nul te zetten.
 */
void clear_bss(void) {
    extern uint8_t __bss_start[], __bss_end[];
    uint8_t *p = __bss_start;
    while (p < __bss_end) {
        *p++ = 0;
    }
}
