/*
 * =========================================================================
 * ZENITH OS KERNEL - CORE SYSTEM
 * =========================================================================
 */

// Types definiëren voor 64-bit omgeving
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;

// Structure voor boot-informatie vanuit Stage 2/3
struct boot_info {
    uint64_t memory_map_addr;
    uint64_t framebuffer_addr;
    uint64_t total_memory;
};

// VGA-instellingen (Higher Half Mapping basis)
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define KERNEL_VIRTUAL_OFFSET 0xffffffff80000000
uint16_t* const vga_buffer = (uint16_t*)(0xB8000); // Fysiek adres voor eenvoud

// Globale status voor de console
int cursor_x = 0;
int cursor_y = 0;
uint8_t current_color = 0x07; // Grijs op zwart

/* --- CONSOLE ENGINE --- */

void console_clear() {
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga_buffer[i] = (uint16_t)' ' | (uint16_t)current_color << 8;
    }
    cursor_x = 0;
    cursor_y = 0;
}

void console_putc(char c) {
    if (c == '\n') {
        cursor_x = 0;
        cursor_y++;
    } else {
        const int index = cursor_y * VGA_WIDTH + cursor_x;
        vga_buffer[index] = (uint16_t)c | (uint16_t)current_color << 8;
        cursor_x++;
    }

    // Automatische nieuwe regel bij einde schermbreedte
    if (cursor_x >= VGA_WIDTH) {
        cursor_x = 0;
        cursor_y++;
    }
}

void console_write(const char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        console_putc(str[i]);
    }
}

/* --- SYSTEM ROUTINES --- */

void kpanic(const char* message) {
    current_color = 0x4F; // Wit op rood
    console_clear();
    console_write("!!! ZENITH OS FATAL ERROR (PANIC) !!!\n");
    console_write("REASON: ");
    console_write(message);
    console_write("\n\nSysteem bevroren.");
    
    // Stop alle CPU activiteit
    __asm__ volatile ("cli");
    while (1) { __asm__ volatile ("hlt"); }
}

/* --- KERNEL MAIN ENTRY --- */

extern "C" void kernel_entry(boot_info* info) {
    // 1. Scherm initialiseren
    console_clear();
    console_write("Zenith OS is succesvol opgestart in 64-bit Long Mode.\n");
    console_write("Bootloader info ontvangen op adres: ");
    
    // 2. Basis controle (test panic)
    if (info == nullptr) {
        kpanic("Geen boot_info ontvangen van de lader!");
    }

    console_write("Status: Kernel actief. Wachten op instructies...\n");
    console_write("--------------------------------------------------\n");

    // 3. De Main Kernel Loop
    while (1) {
        // Hier komt straks de scheduler en de browser-engine
        __asm__ volatile ("hlt"); 
    }
}
