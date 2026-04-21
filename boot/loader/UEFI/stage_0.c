/* =========================================================================
 * ZENITH OS - UEFI BOOTLOADER STAGE 0 (FIXED)
 * =========================================================================
 */
#include <efi.h>
#include <efilib.h>

typedef struct {
    EFI_MEMORY_DESCRIPTOR *map;
    UINTN map_size;
    UINTN desc_size;
    UINT32 desc_ver;
} bootinfo_t;

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    InitializeLib(ImageHandle, SystemTable);

    EFI_BOOT_SERVICES* BS = SystemTable->BootServices;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL* ConOut = SystemTable->ConOut;
    EFI_SIMPLE_TEXT_INPUT_PROTOCOL* ConIn = SystemTable->ConIn;

    uefi_call_wrapper(ConOut->ClearScreen, 1, ConOut);
    Print(L"Zenith OS UEFI Loader Stage 0\n");
    Print(L"----------------------------------------\n");

    // ===================== 1. WATCHDOG UIT =====================
    uefi_call_wrapper(BS->SetWatchdogTimer, 4, 0, 0, 0, NULL);

    // ===================== 2. MEMORY MAP LOOP =====================
    EFI_MEMORY_DESCRIPTOR* MemoryMap = NULL;
    UINTN MapSize = 0;
    UINTN AllocSize = 0;
    UINTN MapKey = 0;
    UINTN DescSize = 0;
    UINT32 DescVer = 0;
    EFI_STATUS status;

    // Eerste call: vraag required size
    status = uefi_call_wrapper(BS->GetMemoryMap, 5, &MapSize, NULL, &MapKey, &DescSize, &DescVer);
    if (status != EFI_BUFFER_TOO_SMALL) {
        Print(L"ERROR: GetMemoryMap unexpected status: 0x%x\n", status);
        return status;
    }

    // BUGFIX: AllocSize apart houden, MapSize wordt overschreven door GetMemoryMap
    while (1) {
        // Extra ruimte omdat alloc zelf de map kan laten groeien
        AllocSize = MapSize + (DescSize * 8); 

        status = uefi_call_wrapper(BS->AllocatePool, 3, EfiLoaderData, AllocSize, (void**)&MemoryMap);
        if (EFI_ERROR(status)) {
            Print(L"ERROR: AllocatePool failed: 0x%x\n", status);
            return status;
        }

        // Let op: MapSize wordt hier gezet op de echte benodigde grootte
        status = uefi_call_wrapper(BS->GetMemoryMap, 5, &MapSize, MemoryMap, &MapKey, &DescSize, &DescVer);
        if (status == EFI_BUFFER_TOO_SMALL) {
            uefi_call_wrapper(BS->FreePool, 1, MemoryMap);
            // MapSize is nu de nieuwe required size. Loop opnieuw met grotere AllocSize.
            continue;
        }
        if (EFI_ERROR(status)) {
            Print(L"ERROR: GetMemoryMap failed: 0x%x\n", status);
            uefi_call_wrapper(BS->FreePool, 1, MemoryMap);
            return status;
        }
        break; // gelukt
    }

    Print(L"Memory map OK: %u entries, DescSize=%u\n", MapSize / DescSize, DescSize);

    // ===================== 3. PAUSE VOOR DEBUG =====================
    EFI_INPUT_KEY Key;
    Print(L"\nDruk op een toets om ExitBootServices te doen...\n");
    uefi_call_wrapper(ConIn->Reset, 2, ConIn, FALSE);
    while (uefi_call_wrapper(ConIn->ReadKeyStroke, 2, ConIn, &Key) == EFI_NOT_READY);

    // ===================== 4. EXIT BOOT SERVICES =====================
    // Na deze call mag je GEEN enkele Boot Service meer aanroepen.
    // Dus ook geen Print, geen FreePool, geen GetMemoryMap.
    status = uefi_call_wrapper(BS->ExitBootServices, 2, ImageHandle, MapKey);
    
    if (EFI_ERROR(status)) {
        // Retry 1x met verse map. Dit is het standaard patroon.
        // Let op: MemoryMap buffer moet nog groot genoeg zijn. We alloceerden al met *8.
        status = uefi_call_wrapper(BS->GetMemoryMap, 5, &MapSize, MemoryMap, &MapKey, &DescSize, &DescVer);
        if (EFI_ERROR(status)) {
            Print(L"ERROR: GetMemoryMap retry failed: 0x%x\n", status);
            return status; // laatste Print die je mag doen
        }
        
        status = uefi_call_wrapper(BS->ExitBootServices, 2, ImageHandle, MapKey);
        if (EFI_ERROR(status)) {
            Print(L"FATAL: ExitBootServices failed twice: 0x%x\n", status);
            return status; // game over
        }
    }

    // ===================== 5. POST-EBS ZONE =====================
    // BUGFIX: Vanaf hier GEEN UEFI calls meer. Alles hieronder is pure C/asm.
    
    // Stap 1: Vul bootinfo struct voor je kernel
    bootinfo_t bootinfo;
    bootinfo.map = MemoryMap;      // nog steeds valid: EfiLoaderData -> EfiConventionalMemory
    bootinfo.map_size = MapSize;
    bootinfo.desc_size = DescSize;
    bootinfo.desc_ver = DescVer;

    // Stap 2: TODO - Laad kernel ELF, setup paging, map higher-half
    // Stap 3: TODO - Maak stack voor kernel
    
    // Stap 4: Jump naar kernel met bootinfo pointer
    // void (*kernel_main)(bootinfo_t*) = (void*)KERNEL_ENTRY;
    // kernel_main(&bootinfo);
    
    // Placeholder: als je hier komt zonder kernel handoff = hang
    while (1) {
        asm volatile("cli; hlt");
    }

    return EFI_SUCCESS; // kom je nooit
}
