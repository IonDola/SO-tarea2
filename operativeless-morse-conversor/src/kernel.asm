bits 64
section .text
global _start
struc EFI_TABLE_HEADER
    .Signature RESQ 1
    .Revision RESD 1
    .HeaderSize RESD 1
    .CRC32 RESD 1
    .Reserved RESD 1
endstruc

struc EFI_SYSTEM_TABLE
    .Hdr                  RESB EFI_TABLE_HEADER_size
    .FirmwareVendor       RESQ 1
    .FirmwareRevision     RESD 1
    .ConsoleInHandle      RESQ 1
    .ConIn                RESQ 1
    .ConsoleOutHandle     RESQ 1
    .ConOut               RESQ 1
    .StandardErrorHandle  RESQ 1
    .StdErr               RESQ 1
    .RuntimeServices      RESQ 1
    .BootServices         RESQ 1
    .NumberOfTableEntries RESQ 1
    .ConfigurationTable   RESQ 1
endstruc

struc EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL
    .Reset             RESQ 1
    .OutputString      RESQ 1
    .TestString        RESQ 1
    .QueryMode         RESQ 1
    .SetMode           RESQ 1
    .SetAttribute      RESQ 1
    .ClearScreen       RESQ 1
    .SetCursorPosition RESQ 1
    .EnableCursor      RESQ 1
    .Mode              RESQ 1
endstruc

loopForever:
    jmp loopForever

_start:
    sub rsp, 4 * 8
    ; rdx points to the EFI_SYSTEM_TABLE structure
    ; which is the 2nd argument passed to us by the UEFI firmware
    ; adding 64 causes rcx to point to EFI_SYSTEM_TABLE.ConOut
    mov rcx, [rdx + 64]

    lea rdx, [rel strHello]

    call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]

    jmp loopForever

codesize equ $ - $$

section .reloc
; Solo para que UEFI lo encuentre

section .data
    strHello db __utf16__ `Hello World !\0`

datasize equ $ - $$
