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
%define SCAPE_UC 0x1B
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
%define SLASH_UC 0x002F
%define UPPER_MASK 0xDF
; Other constants
%define HALF_SECCOND_DELAY 0x04738B80 ; Medio segundo
%define NEXT_CHARACTER 0x02
%define MAX_INPUT_LENGTH 160
%define MAX_OUTPUT_LENGTH 2048
section .data
    ; Program messages
    welcome_msg dw __utf16__(`Bienvenido al Convertidor a Morse Sin Sistema Operativo!\r\n`), 0
    prompt_msg dw __utf16__(`\r\nIngrese el Texto a Traducir:`), 0
    morse_msg dw __utf16__(`Morsificado:`), 0x000D, 0x000A, 0
    new_line: dw 0x000D, 0x000A, 0
    goodbye_msg dw __utf16__(`Gracias por usar, adios!`), 0x000D, 0x000A, 0

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

    ; Buffers
    input_buffer: times MAX_INPUT_LENGTH dB 0
    output_buffer: times MAX_OUTPUT_LENGTH dW 0
    end_of_output_buffer:
    key_buffer: dw 0,0
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
        mov rcx, r15
        lea rdx, [key_buffer]
        call qword [r15 + READ_KEYSTROKE_OFFSET] ; ReadKeyStroke
        test rax, rax
        jnz .read_loop

        movzx eax, word [key_buffer + 2] ; Leer Unicode
        
        cmp al, SCAPE_UC
        je .exit_program
        
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
        cmp ebx, MAX_INPUT_LENGTH
        jae .read_loop ; Evitar overflow
        mov [input_buffer + rbx], dl
        inc rbx
        jmp .read_loop

    .handle_backspace:
        test ebx, ebx
        jz .read_loop
        dec rbx
        jmp .read_loop
    
    .process_input:
        lea rdi, [rel output_buffer]
        lea r9, [rel end_of_output_buffer]
        xor r8d, r8d
    
    .next_character:
        cmp r8d, ebx
        jae .append_completed ; Fin de input

        mov dl, [input_buffer + r8]

        cmp dl, SPACE_UC
        jne .not_space
        call add_space
        jmp .after_append

    .not_space:
        mov al, dl
        cmp al, MAY_A_ASCII
        jb .try_number
        cmp al, MAY_Z_ASCII
        ja .try_number
        sub al, MAY_A_ASCII
        movzx rax, al
        lea r10, [rel LETTERS]
        mov rax, [r10 + rax*8]
        jmp .append_morse
    
    .try_number:
        cmp dl, ZERO_UC
        jb .unknown_char
        cmp dl, NINE_UC
        ja .unknown_char
        sub dl, ZERO_UC
        movzx rax, dl
        lea r10, [rel NUMBERS]
        mov rax, [r10 + rax*8]
        jmp .append_morse
    
    .unknown_char:
        lea rax, [rel UNKNOWN]
    
    .append_morse:
        mov cx, [rax]
        test cx, cx
        jz .copied

        cmp rdi, r9
        jae .append_completed
        mov [rdi], cx
        add rax, 2
        add rdi, 2
        jmp .append_morse
    
    .copied:
        mov eax, ebx
        dec eax
        cmp r8d, eax
        jae .after_append
        mov al, [input_buffer + r8 + 1]
        cmp al, SPACE_UC
        je .after_append
        cmp rdi, r9
        jae .append_completed
        mov word [rdi], SPACE_UC
        add rdi, 2
    
    .after_append:
        inc r8d
        jmp .next_character

    .append_completed:
        cmp rdi, r9
        jae .print_conversion
        mov word [rdi], 0

    .print_conversion:
        mov rcx, r14
        lea rdx, [rel morse_msg]
        call qword [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        mov rcx, r14
        lea rdx, [rel output_buffer]
        call qword [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        mov rcx, r14
        lea rdx, [rel new_line]
        call qword [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        xor ebx, ebx
        jmp .repl
    
    .exit_program:
    mov rcx, r14
    lea rdx, [rel goodbye_msg]
    call qword [r14 + OUTPUT_STRING_OFFSET] ; OutputString
    ret

add_space:
    cmp rdi, r9
    jae .done
    mov word [rdi], SPACE_UC
    add rdi, 2
    cmp rdi, r9
    jae .done
    mov word [rdi], SLASH_UC
    add rdi, 2
    cmp rdi, r9
    jae .done
    mov word [rdi], SPACE_UC
    add rdi, 2
.done:
    ret

section .reloc
section .note.GNU-stack noalloc noexec nowrite
    ; UEFI requeriment

