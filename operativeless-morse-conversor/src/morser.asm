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
%define UNICODE_OFFSET 0x02
%define SCAPE_SC 0x17
%define SCAPE_UC 0x1B
%define SCAPE_ASCII 0x1B
%define ENTER_UC 0x0D
%define BACKSPACE_UC 0x08
%define SPACE_UC 0x20
%define OVERFLOW_CHAR 0x9F
%define A_UC 0x0041
%define Z_UC 0x005A
%define a_UC 0x0061
%define z_UC 0x007A
%define ZERO_UC 0x0030
%define NINE_UC 0x0039
%define SLASH_UC 0x002F
; Other constants
%define HALF_SECCOND_DELAY 0x04738B80 ; Medio segundo
%define NEXT_CHARACTER 0x02

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
    A: dw __utf16__(".-"), 0
    B: dw __utf16__("-..."), 0
    C: dw __utf16__("-.-."), 0
    D: dw __utf16__("-.."), 0
    E: dw __utf16__("."), 0
    F: dw __utf16__("..-."), 0
    G: dw __utf16__("--."), 0
    H: dw __utf16__("...."), 0
    I: dw __utf16__(".."), 0
    J: dw __utf16__(".---"), 0
    K: dw __utf16__("-.-"), 0
    L: dw __utf16__(".-.."), 0
    M: dw __utf16__("--"), 0
    N: dw __utf16__("-."), 0
    O: dw __utf16__("---"), 0
    P: dw __utf16__(".--."), 0
    Q: dw __utf16__("--.-"), 0
    R: dw __utf16__(".-."), 0
    S: dw __utf16__("..."), 0
    T: dw __utf16__("-"), 0
    U: dw __utf16__("..-"), 0
    V: dw __utf16__("...-"), 0
    W: dw __utf16__(".--"), 0
    X: dw __utf16__("-..-"), 0
    Y: dw __utf16__("-.--"), 0
    Z: dw __utf16__("--.."), 0  

    ZERO:  dw __utf16__("-----"), 0
    ONE:   dw __utf16__(".----"), 0
    TWO:   dw __utf16__("..---"), 0
    THREE: dw __utf16__("...--"), 0
    FOUR:  dw __utf16__("....-"), 0
    FIVE:  dw __utf16__("....."), 0
    SIX:   dw __utf16__("-...."), 0
    SEVEN: dw __utf16__("--..."), 0
    EIGHT: dw __utf16__("---.."), 0
    NINE:  dw __utf16__("----."), 0


    ; Unkwnown character
    UNKNOWN: dw __utf16__("?"), 0

section .bss
    ; Interfaces de UEFI
    SystemTable resq 1

    ; Buffers
    align 2
    input_buffer resw 256
    output_buffer resw 2048
    end_of_output_buffer:

    align 4
    key_buffer resd 1

section .text
    global _start
_start:
    ; Alinear la pila
    mov rax, rsp
    and rsp, -STACK_ALIGMENT
    sub rsp, SHADOW_SPACE

    ; Guardar SystemTable
    mov [SystemTable], rdx
    mov r14, [rdx + CONOUT_OFFSET] ; ConOut
    mov r15, [rdx + CONIN_OFFSET]  ; ConIn

    ; Limpiar pantalla
    mov rcx, r14
    call [rcx + CLEAR_SCREEN_OFFSET]

    ; Mostrar mensaje de bienvenida
    mov rcx, r14
    lea rdx, [welcome_msg]
    call [r14 + OUTPUT_STRING_OFFSET] ; OutputString
    
    .repl:
        ; Mostrar prompt
        mov rcx, r14
        lea rdx, [prompt_msg]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        xor ebx, ebx

    ; Leer input
    .read_loop:
        ; Limpiar buffer y leer un caracter
        mov dword [key_buffer], 0
        mov rcx, r15
        lea rdx, [key_buffer]
        call [r15 + READ_KEYSTROKE_OFFSET] ; ReadKeyStroke

        ; Verificar si esta vacio
        test rax, rax
        jnz .read_loop
        mov ax, word [key_buffer]
        mov dx, word [key_buffer + UNICODE_OFFSET]

        ; Verificar si es ESC
        cmp ax, SCAPE_SC
        je .exit_program
        cmp dx, SCAPE_UC
        je .exit_program
        cmp dx, SCAPE_ASCII
        je .exit_program

        ; Procesar Unicode
        mov ax, dx
        cmp ax, ENTER_UC
        je .process_input
        cmp ax, BACKSPACE_UC
        je .handle_backspace
        cmp ax, SPACE_UC
        jb .read_loop
        cmp ebx, OVERFLOW_CHAR
        jae .read_loop

        ; Guardar caracter
    .store_char:
        movzx ax, al
        mov [input_buffer + rbx*2], ax
        inc rbx

        sub rsp, STACK_ALIGMENT
        mov word [rsp], ax
        mov word [rsp + 2], 0
        mov rcx, r14
        mov rdx, rsp
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString
        add rsp, STACK_ALIGMENT
        jmp .read_loop

    .handle_backspace:
        test ebx, ebx
        jz .read_loop

        dec ebx
        mov word [input_buffer + rbx*2], 0
        ; Mover cursor atras, imprimir espacio y mover cursor atras de nuevo
        sub rsp, STACK_ALIGMENT
        mov word [rsp], BACKSPACE_UC
        mov word [rsp + 2], SPACE_UC
        mov word [rsp + 4], BACKSPACE_UC
        mov word [rsp + 6], 0
        mov rcx, r14
        mov rdx, rsp
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString
        add rsp, STACK_ALIGMENT
        jmp .read_loop
    
    .process_input:
        mov word [input_buffer + rbx*2], 0 ; Null-terminate input
        test ebx, ebx
        jz .repl ; Si no hay input, repetir

        ; Nueva linea
        mov rcx, r14
        lea rdx, [new_line]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        ; Convertir a Morse
        call convert

        ; Mostrar resultado
        mov rcx, r14
        lea rdx, [morse_msg]
        call [rcx + OUTPUT_STRING_OFFSET]
        mov rcx, r14
        lea rdx, [output_buffer]
        call [r14 + OUTPUT_STRING_OFFSET]

        ; Nueva linea
        mov rcx, r14
        lea rdx, [new_line]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString

        call clear_buffers
        jmp .repl
    
    .exit_program:
        ; Mostrar mensaje de despedida
        mov rcx, r14
        lea rdx, [new_line]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString
        mov rcx, r14
        lea rdx, [goodbye_msg]
        call [r14 + OUTPUT_STRING_OFFSET] ; OutputString
        call short_delay
        mov rax, 0
        ret

; Subrutina para convertir el texto en input_buffer a Morse en output_buffer
convert:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10

    ; Punteros
    lea rsi, [input_buffer]  ; Puntero al input
    lea rdi, [output_buffer] ; Puntero al output
    lea r9, [end_of_output_buffer]
    xor r8, r8          ; Índice de letras

.next_char:
    movzx rax, word [rsi + r8*2]
    test rax, rax
    jz .done; Fin del string
    mov dx, ax

    ; Detectar espacio
    cmp dl, ' '
    jne .not_space
    call append_space_separator
    jmp .try_next

.not_space:
    ; Detectar si es mayuscula
    cmp dx, A_UC
    jb .check_lower
    cmp dx, Z_UC
    ja .check_lower
    sub dx, A_UC ; Convertir a índice 0-25
    jmp .fetch_letter


.check_lower:
    cmp dx, a_UC
    jb .check_number
    cmp dx, z_UC
    ja .check_number
    sub dx, a_UC ; Convertir a índice 0-25
    jmp .fetch_letter

.check_number:
    cmp dx, ZERO_UC
    jb .unknown_char
    cmp dx, NINE_UC
    ja .unknown_char
    sub dx, ZERO_UC ; Convertir a índice 0-9
    jmp .fetch_number

.unknown_char:
    lea rax, [UNKNOWN]
    jmp .append_morse

.fetch_letter:
    movzx rax, dx
    lea r10, [LETTERS]
    mov rax, [r10 + rax*8]
    jmp .append_morse

.fetch_number:
    movzx rax, dx
    lea r10, [NUMBERS]
    mov rax, [r10 + rax*8]
    jmp .append_morse

.append_morse:
    ; Append Morse code to output_buffer
    cmp rdi, r9
    jae .done ; Evitar overflow
    mov cx, [rax]
    test cx, cx
    jz .copied
    mov [rdi], cx
    add rax, NEXT_CHARACTER
    add rdi, NEXT_CHARACTER
    jmp .append_morse

.copied:
    ; Verificar si requiere espacio
    lea rax, [input_buffer]
    movzx rdx, r8w
    shl rdx, 1
    add rax, rdx
    add rax, 2

    cmp word [rax], 0
    je .try_next
    cmp word [rax], SPACE_UC
    je .try_next

    cmp rdi, r9
    jae .done
    mov word [rdi], SPACE_UC ; Espacio entre letras
    add rdi, NEXT_CHARACTER
    jmp .try_next

.try_next:
    inc r8
    jmp .next_char
  
.done:
    cmp rdi, r9
    jae .no_term
    mov word [rdi], 0 ; Null-terminate output

.no_term:
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

append_space_separator:
    ; Append space for word separation
    cmp rdi, r9
    jae .done_space
    mov word [rdi], SPACE_UC ; Espacio entre palabras
    add rdi, NEXT_CHARACTER

    cmp rdi, r9
    jae .done_space
    mov word [rdi], SLASH_UC ; Diagonal para espacio entre palabras
    add rdi, NEXT_CHARACTER

    cmp rdi, r9
    jae .done_space
    mov word [rdi], SPACE_UC ; Espacio entre palabras
    add rdi, NEXT_CHARACTER

.done_space:
    ret

clear_buffers:
    push rax
    push rcx
    push rdi

    lea rdi, [input_buffer]
    mov rcx, 256
    xor rax, rax
    rep stosW

    lea rdi, [output_buffer]
    mov rcx, 2048
    xor rax, rax
    rep stosw

    pop rdi
    pop rcx
    pop rax
    ret

short_delay:
    push rcx
    mov rcx, HALF_SECCOND_DELAY
.delay_loop:
    dec rcx
    jnz .delay_loop
    pop rcx
    ret
    


section .reloc
    ; UEFI requeriment

