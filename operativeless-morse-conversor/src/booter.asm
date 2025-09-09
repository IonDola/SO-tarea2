bits 64
default rel

section .data
    ; cadenas UTF-16 terminadas en 0
    strInp db __utf16__ 'Escribe algo (ENTER para terminar):',0
    strEnd dw 'T','e','r','m','i','n','a','m','o','s',0
datasize equ $ - $$
section .bss
    inp    resw 24        ; buffer de 24 caracteres UTF-16
    keyBuf resw 2         ; EFI_INPUT_KEY (ScanCode + UnicodeChar)

section .text
global _start

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

struc EFI_SIMPLE_TEXT_INPUT_PROTOCOL
    .Reset         RESQ 1
    .ReadKeyStroke RESQ 1
    .WaitForKey    RESQ 1
endstruc

_start:
    ; alinear y reservar shadow space
    mov rax, rsp
    and rsp, -16
    sub rsp, 32

    ; --------------------------
    ; mostrar mensaje inicial
    ; rdx = EFI_SYSTEM_TABLE
    mov rdi, rdx

    mov rcx, [rdi + 0x40]         ; ConOut (offset 0x40)
    lea rdx, [strInp]             ; puntero a cadena UTF-16
    call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]

    ; --------------------------
    ; leer teclado
    mov rcx, [rdi + 0x30]            ; ConIn (offset 0x30)
    lea rsi, [inp]                ; buffer de entrada
    xor rbx, rbx                  ; índice

.read_loop:
    lea rdx, [keyBuf]
    call [rcx + EFI_SIMPLE_TEXT_INPUT_PROTOCOL.ReadKeyStroke]

    mov ax, [keyBuf + 2]          ; UnicodeChar (UTF-16)
    cmp ax, 0x0D                  ; Enter?
    je .done

    mov [rsi + rbx*2], ax         ; almacenar en inp
    inc rbx
    cmp rbx, 23
    jb .read_loop
    jmp .done

.done:
    mov word [rsi + rbx*2], 0     ; terminador UTF-16

    ; --------------------------
    ; mostrar "Terminamos"
    mov rcx, [rdi + 0x40]            ; ConOut (offset 0x40)
    lea rdx, [strEnd]
    call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]

    ; mostrar lo escrito por el usuario
    lea rdx, [inp]
    call [rcx + EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString]

    jmp .loopforever

.loopforever:
    hlt
    jmp .loopforever
codesize equ $ - $$

section .reloc
; Solo para que UEFI lo encuentre
