/* * =========================================================================
 * ZENITH OS - main.c (The Kernel Core)
 * =========================================================================
 */

#include <stdint.h>
#include "console.h"   // Voor tekstuitvoer
#include "gdt.h"       // Voor segmentatie
#include "idt.h"       // Voor interrupts
#include "pmm.h"       // Physical Memory Manager
#include "vmm.h"       // Virtual Memory Manager

/**
 * start_kernel(void)
 * De architectuur-onafhankelijke start van de kernel.
 * Hier wordt de fundering gelegd voor multitasking en drivers.
 */
void start_kernel(void) {
    // 1. Initialiseer de console direct voor debug-logging
    zenith_console_init();
    zenith_console_clear();
    zenith_console_write("ZENITH OS [v0.1.0] - Kernel Booting...\n");

    // 2. Setup CPU-structuren (Global Descriptor Table)
    // Dit definieert de kernel- en user-rechten.
    zenith_gdt_install();
    zenith_console_write("[OK] GDT Geinstalleerd.\n");

    // 3. Setup Interrupts (Interrupt Descriptor Table)
    // Zorgt dat we kunnen reageren op toetsenbord, timer en crashes.
    zenith_idt_install();
    zenith_console_write("[OK] IDT Geactiveerd.\n");

    // 4. Memory Management (PMM & VMM)
    // De PMM beheert fysieke blokken, de VMM beheert de paginatabellen.
    zenith_pmm_init();
    zenith_vmm_init();
    zenith_console_write("[OK] Geheugenbeheer actief.\n");

    // 5. Toetsenbord en Timer initialisatie
    // De PIC/APIC vertelt de CPU wanneer hardware aandacht nodig heeft.
    zenith_drivers_init();
    zenith_console_write("[OK] Drivers geladen.\n");

    // 6. Multitasking inschakelen
    // Vanaf hier kan de kernel meerdere processen (zoals de browser) draaien.
    zenith_scheduler_init();

    // Final Touch: Schakel interrupts in
    asm volatile("sti");
    zenith_console_write("Zenith OS is klaar voor gebruik.\n");
    zenith_console_write("--------------------------------\n");

    // De kernel blijft hier in een systeem-idle loop
    while (1) {
        // Hier kan de scheduler taken oppakken
        asm volatile("hlt");
    }
}

/**
 * Mocht er iets fataal misgaan tijdens de start_kernel...
 */
void kernel_panic(const char* msg) {
    zenith_console_set_color(0x4F); // Wit op rood
    zenith_console_write("\n!!! KERNEL PANIC !!!\n");
    zenith_console_write(msg);
    
    asm volatile("cli"); // Stop alle interrupts
    for(;;) asm volatile("hlt");
}
