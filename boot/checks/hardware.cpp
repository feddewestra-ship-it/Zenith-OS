/* * =========================================================================
 * ZENITH OS - HARDWARE REQUIREMENT CHECKS
 * =========================================================================
 */

#include <stdint.h>

// Helper om CPUID-informatie op te vragen via Assembly
static inline void cpuid(uint32_t code, uint32_t* a, uint32_t* d) {
    asm volatile("cpuid" : "=a"(*a), "=d"(*d) : "a"(code) : "ecx", "ebx");
}

class HardwareChecker {
public:
    // 1. Controleer of de CPU CPUID ondersteunt
    bool check_cpuid() {
        uint32_t eflags_before, eflags_after;
        asm volatile (
            "pushf\n"
            "pushf\n"
            "pop %0\n"
            "mov %0, %1\n"
            "xor $0x200000, %1\n"
            "push %1\n"
            "popf\n"
            "pushf\n"
            "pop %1\n"
            "popf\n"
            : "=r"(eflags_before), "=r"(eflags_after));
        
        return ((eflags_before ^ eflags_after) & 0x200000) != 0;
    }

    // 2. Controleer op Long Mode (64-bit) ondersteuning
    bool check_long_mode() {
        uint32_t eax, edx;
        
        // Check of extended functies beschikbaar zijn
        cpuid(0x80000000, &eax, &edx);
        if (eax < 0x80000001) return false;

        // Check voor de 'Long Mode' bit
        cpuid(0x80000001, &eax, &edx);
        return (edx & (1 << 29)) != 0;
    }

    // 3. Controleer of er genoeg RAM is (via boot_info van de PMM)
    bool check_memory(uint64_t total_ram_bytes) {
        // Minimale vereiste: 64 MB
        const uint64_t min_ram = 64 * 1024 * 1024;
        return total_ram_bytes >= min_ram;
    }

    // Voer alle tests uit
    void run_all_checks(uint64_t actual_ram) {
        if (!check_cpuid()) {
            kpanic("Zenith OS Error: CPU ondersteunt CPUID niet.");
        }
        if (!check_long_mode()) {
            kpanic("Zenith OS Error: 64-bit (Long Mode) niet ondersteund.");
        }
        if (!check_memory(actual_ram)) {
            kpanic("Zenith OS Error: Onvoldoende RAM. 64MB vereist.");
        }
        
        console.Write("Hardware Check: PASS\n");
    }
};

// Global instance
HardwareChecker hw_checker;
