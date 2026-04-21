/* * =========================================================================
 * ZENITH OS - misc.c (Kernel Decompressor & Support)
 * =========================================================================
 */

typedef unsigned long size_t;
typedef unsigned char uint8_t;
typedef unsigned long long uint64_t;

/* De externe symbolen die door de linker worden aangemaakt */
extern uint8_t _compressed_kernel_start[];
extern uint8_t _compressed_kernel_end[];

/* De locatie waar de kernel moet landen (bijv. 1MB of Higher Half) */
#define KERNEL_DESTINATION 0x1000000 

/* Een simpele memory copy functie omdat we geen standaard string.h hebben */
void* zenith_memcpy(void* dest, const void* src, size_t n) {
    uint8_t* d = (uint8_t*)dest;
    const uint8_t* s = (const uint8_t*)src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}

/* * De hoofdfunctie aangeroepen vanuit head_64.S
 * Retourneert het adres van het entrypoint van de uitgepakte kernel.
 */
uint64_t zenith_decompress_kernel(void) {
    size_t compressed_size = (size_t)(_compressed_kernel_end - _compressed_kernel_start);
    
    /* * Hier zou normaal een algoritme zoals LZ4_decompress_safe staan.
     * Voor deze stap doen we een 'store' (onverpakt) of simpele kopie
     * om de architectuur van Zenith OS werkend te krijgen.
     */
    
    // Stel we gebruiken een placeholder voor het decompressie algoritme:
    // decompress(_compressed_kernel_start, (void*)KERNEL_DESTINATION, compressed_size);
    
    zenity_memcpy((void*)KERNEL_DESTINATION, _compressed_kernel_start, compressed_size);

    /* * Na de decompressie geven we het entrypoint terug aan de assembly stub.
     * Dit is meestal het begin van de uitgepakte buffer.
     */
    return (uint64_t)KERNEL_DESTINATION;
}

/* Foutafhandeling tijdens het uitpakken */
void error(char *x) {
    /* * In deze fase hebben we nog geen geavanceerde console.
     * We zouden hier direct naar het VGA geheugen kunnen schrijven
     * om een 'Decompression Error' aan de gebruiker te tonen.
     */
    volatile char *vga = (volatile char *)0xb8000;
    char *err = "ZENITH DECOMPRESS ERROR: ";
    
    while(*err) {
        *vga++ = *err++;
        *vga++ = 0x4F; // Wit op rood
    }
    while(*x) {
        *vga++ = *x++;
        *vga++ = 0x4F;
    }
    
    while(1); // Halt
}
