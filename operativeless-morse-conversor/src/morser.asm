; morser.asm - Convertidor de texto a Morse sin sistema operativo
[BITS 64]
DEFAULT REL

; Boot constants
%define SHADOW_SPACE 0x20
%define STACK_ALIGMENT 0x10
%define CONOUT_OFFSET 0x40
%define CONIN_OFFSET 0x30
%define BOOT_SERVICES_OFFSET 0x60
; r14 methods offsets
%define CLEAR_SCREEN_OFFSET 0x30
%define OUTPUT_STRING_OFFSET 0x08
; r15 methods offsets
%define READ_KEYSTROKE_OFFSET 0x08
; Character constants
%define ENTER_UC 0x0D
%define BACKSPACE_UC 0x08
%define SPACE_UC 0x20
%define OVERFLOW_CHAR 0x9F
%define MAY_A_ASCII 0x41
%define MAY_Z_ASCII 0x5A
%define MIN_A_ASCII 0x61
%define MIN_Z_ASCII 0x7A
%define ZERO_UC 0x0030
%define NINE_UC 0x0039
%define SPACE_UC 0x0020
%define SLASH_UC 0x002F
%define UPPER_MASK 0xDF
; Other constants
%define NEXT_CHARACTER 0x02
%define MAX_INPUT_LENGTH 160
%define MAX_PERMITED_INPUT_LENGTH 159
%define MAX_OUTPUT_LENGTH 2048
section .data
    ; Program messages
    welcome_msg dw __utf16__(`Bienvenido al Convertidor a Morse Sin Sistema Operativo!\r\n`), 0
    prompt_msg dw __utf16__(`\r\nIngrese el Texto a Traducir:`), 0
    morse_msg dw __utf16__(`Morsificado:`), 0x000D, 0x000A, 0
    goodbye_msg dw __utf16__(`Gracias por usar, adios!`), 0x000D, 0x000A, 0
    new_line: dw 0x000D, 0x000A, 0
    character_buffer dw 0, 0
    delete_arrow: dw 0x21A9, 0

    ALIGN 8
    LETTERS:
        dq A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z
    NUMBERS:
        dq ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE

    ALIGN 2
    A: dw '.','_',0
    B: dw '_','.', '.', '.',0
    C: dw '_','.', '_','.',0
    D: dw '_','.', '.',0
    E: dw '.',0
    F: dw '.', '.', '_','.',0
    G: dw '_','_', '.',0
    H: dw '.', '.', '.', '.',0
    I: dw '.', '.',0
    J: dw '.', '_','_','_',0
    K: dw '_','.', '_',0
    L: dw '.', '_','.', '.',0
    M: dw '_','_',0
    N: dw '_','.',0
    O: dw '_','_','_',0
    P: dw '.', '_','.', '_',0
    Q: dw '_','_','.', '_',0
    R: dw '.', '_','.',0
    S: dw '.', '.', '.',0
    T: dw '_',0
    U: dw '.', '.', '_',0
    V: dw '.', '.', '.', '_',0
    W: dw '.', '_','_',0
    X: dw '_','.', '.', '_',0
    Y: dw '_','.', '_','_',0
    Z: dw '_','_','.', '.',0

    ZERO: dw '_','_','_','_','_',0
    ONE: dw '.', '_','_','_','_',0
    TWO: dw '.', '.', '_','_','_',0
    THREE: dw '.', '.', '.', '_','_',0
    FOUR: dw '.', '.', '.', '.', '_',0
    FIVE: dw '.', '.', '.', '.', '.',0
    SIX: dw '_','.', '.', '.', '.',0
    SEVEN: dw '_','_','.', '.', '.',0
    EIGHT: dw '_','_','_','.', '.',0
    NINE: dw '_','_','_','_','.',0

    ; Unkwnown character
    UNKNOWN: dw __utf16__("?"), 0

section .bss
    ; Buffers
    input_buffer: resb MAX_INPUT_LENGTH
    output_buffer: resb MAX_OUTPUT_LENGTH
    end_of_output_buffer:
    key_buffer: resw 2
section .text
    global _start
_start:
    ; Alinear la pila
    push rbp
    mov rbp, rsp
    and rsp, -STACK_ALIGMENT
    sub rsp, SHADOW_SPACE

    ; Guardar SystemTable
    mov r14, [rdx + CONOUT_OFFSET] ; ConOut
    mov r15, [rdx + CONIN_OFFSET]  ; ConIn

    ; Limpiar pantalla
    mov rcx, r14
    call [rcx + CLEAR_SCREEN_OFFSET]

    ; Mostrar mensaje de bienvenida
    mov rcx, r14
    lea rdx, [welcome_msg]
    call [r14 + OUTPUT_STRING_OFFSET] ; OutputString
    
    xor ebx, ebx
    
    .repl:
        ; Mostrar prompt
        mov rcx, r14
        lea rdx, [prompt_msg]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString


    ; Leer input
    .read_loop:
        ; Reiniciar buffer
        mov word [key_buffer], 0
        mov word [key_buffer + NEXT_CHARACTER], 0

        mov rcx, r15
        lea rdx, [key_buffer]
        call qword [r15 + READ_KEYSTROKE_OFFSET] ; ReadKeyStroke
        test rax, rax
        jnz .read_loop

        mov dx, word [key_buffer + NEXT_CHARACTER]
        mov ax, dx
        
        cmp al, ENTER_UC
        je .process_input
        cmp al, BACKSPACE_UC
        je .handle_backspace
        cmp al, SPACE_UC
        jb .read_loop

        mov dl, al
        cmp dl, MIN_A_ASCII
        jb .store_char
        cmp dl, MIN_Z_ASCII
        ja .store_char
        and dl, UPPER_MASK ; Convertir a mayuscula
    
    ; Guardar caracter
    .store_char:
        cmp ebx, MAX_PERMITED_INPUT_LENGTH
        jae .read_loop ; Evitar overflow

        mov byte [input_buffer + rbx], dl
        inc rbx

        mov word [character_buffer], ax
        mov word [character_buffer + NEXT_CHARACTER], 0
        mov rcx, r14
        lea rdx, [character_buffer]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        jmp .read_loop

    .handle_backspace:
        cmp rbx, 0
        jz .read_loop
        dec rbx
        
        mov byte [input_buffer + rbx], 0
        mov rcx, r14
        lea rdx, [delete_arrow]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        jmp .read_loop
    
    .process_input:
        cmp rbx, 0
        je .repl

        mov rcx, r14
        lea rdx, [new_line]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        lea rdi, [output_buffer] ; output_buffer pointer
        lea r9, [end_of_output_buffer] ; end of output_buffer
        xor r8d, r8d ; input_buffer index

    .process_input_loop:
        mov eax, r8d
        cmp eax, ebx
        jae .append_completed

        mov dl, [input_buffer + r8]

        cmp dl, SPACE_UC
        jne .not_space
        call add_space
        jmp .proccess_next_character

    .not_space:
        cmp dl, MAY_A_ASCII
        jb .try_number
        cmp dl, MAY_Z_ASCII
        ja .try_number
        sub dl, MAY_A_ASCII
        movzx rax, dl
        lea r10, [LETTERS]
        mov rax, [r10 + rax*8]
        jmp .append_morse
    
    .try_number:
        cmp dl, ZERO_UC
        jb .unknown_char
        cmp dl, NINE_UC
        ja .unknown_char
        sub dl, ZERO_UC
        movzx rax, dl
        lea r10, [NUMBERS]
        mov rax, [r10 + rax*8]
        jmp .append_morse
    
    .unknown_char:
        lea rax, [UNKNOWN]
    
    .append_morse:
        mov cx, [rax]
        test cx, cx
        jz .appended

        cmp rdi, r9
        jae .append_completed
        mov [rdi], cx
        add rax, 2
        add rdi, 2
        jmp .append_morse
    
    .appended:
        mov eax, ebx
        dec eax
        cmp r8d, eax
        jae .proccess_next_character
        mov al, [input_buffer + r8 + 1]
        cmp al, SPACE_UC
        je .proccess_next_character
        cmp rdi, r9
        jae .append_completed
        mov word [rdi], SPACE_UC
        add rdi, 2
    
    .proccess_next_character:
        inc r8d
        jmp .process_input_loop

    .append_completed:
        cmp rdi, r9
        jae .print_conversion
        mov word [rdi], 0

    .print_conversion:
        mov rcx, r14
        lea rdx, [rel new_line]
        call qword [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        mov rcx, r14
        lea rdx, [rel morse_msg]
        call qword [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        mov rcx, r14
        lea rdx, [rel output_buffer]
        call qword [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        mov rcx, r14
        lea rdx, [rel new_line]
        call qword [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        call clear_input_buffer
        jmp .repl

add_space:
    push rax
    cmp rdi, r9
    jae .done_space
    mov word [rdi], SPACE_UC
    add rdi, 2
    cmp rdi, r9
    jae .done_space
    mov word [rdi], SLASH_UC
    add rdi, 2
    cmp rdi, r9
    jae .done_space
    mov word [rdi], SPACE_UC
    add rdi, 2
.done_space:
    pop rax
    ret

clear_input_buffer:
    push rax
    push rcx
    push rdi
    lea rdi, [input_buffer]
    mov rcx, 160
    xor rax, rax
    rep stosb
    pop rdi
    pop rcx
    pop rax
    ret

section .reloc
section .note.GNU-stack noalloc noexec nowrite
    ; UEFI requeriment

