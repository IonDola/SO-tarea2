# bootloader.asm - Primera parte del proyecto
# Bootloader EFI que carga la segunda parte

.code64

# Definiciones EFI
.equ EFI_SUCCESS, 0
.equ EFI_LOAD_ERROR, 1
.equ EFI_INVALID_PARAMETER, 2

# Estructura básica para EFI
.section .text
.global _start

_start:
    # RDX = Handle de imagen EFI
    # RCX = Tabla del sistema EFI
    
    # Guardar parámetros EFI
    mov %rdx, %r15  # Handle de imagen
    mov %rcx, %r14  # System Table
    
    # Limpiar pantalla
    call clear_screen
    
    # Mostrar mensaje inicial
    call show_welcome_message
    
    # Cargar segunda parte del programa
    call load_second_stage
    
    # Saltar a la segunda parte
    jmp second_stage_entry

clear_screen:
    push %rax
    push %rcx
    push %rdx
    
    # Obtener protocolo de salida de texto
    mov %r14, %rcx              # System Table
    mov 64(%rcx), %rcx          # ConOut
    
    # Llamar ClearScreen
    mov %rcx, %rdx
    mov (%rcx), %rax            # Tabla de funciones
    call *32(%rax)              # ClearScreen función
    
    pop %rdx
    pop %rcx
    pop %rax
    ret

show_welcome_message:
    push %rax
    push %rcx
    push %rdx
    
    # Obtener protocolo de salida de texto
    mov %r14, %rcx              # System Table
    mov 64(%rcx), %rcx          # ConOut
    
    # Mostrar mensaje
    mov %rcx, %rdx
    lea welcome_msg(%rip), %r8
    mov (%rcx), %rax
    call *8(%rax)               # OutputString función
    
    pop %rdx
    pop %rcx
    pop %rax
    ret

load_second_stage:
    # Aquí se cargaría la segunda parte desde memoria o archivo
    # Por simplicidad, asumimos que está en memoria contigua
    ret

# Datos
.section .data
welcome_msg:
    .word 'I', 'n', 'i', 'c', 'i', 'a', 'n', 'd', 'o', ' '
    .word 'p', 'r', 'o', 'g', 'r', 'a', 'm', 'a', ' ', 'd', 'e', ' '
    .word 's', 'o', 'n', 'i', 'd', 'o', 's', '.', '.', '.', 0x0D, 0x0A, 0

# Segunda parte del programa (integrada en el mismo archivo)
second_stage_entry:
    call init_sound_system
    call show_instructions
    call input_loop

init_sound_system:
    # Inicializar el sistema de sonidos (PC Speaker)
    ret

show_instructions:
    push %rax
    push %rcx
    push %rdx
    
    # Mostrar instrucciones
    mov %r14, %rcx              # System Table
    mov 64(%rcx), %rcx          # ConOut
    
    mov %rcx, %rdx
    lea instructions_msg(%rip), %r8
    mov (%rcx), %rax
    call *8(%rax)               # OutputString
    
    pop %rdx
    pop %rcx
    pop %rax
    ret

input_loop:
    push %rax
    push %rbx
    push %rcx
    push %rdx
    
input_wait:
    # Leer entrada del teclado
    call read_key
    
    # Comparar entrada
    cmp $'0', %al
    je play_sound_0
    
    cmp $'1', %al
    je play_sound_1
    
    cmp $0x0D, %al              # Enter
    je input_wait
    
    cmp $0x1B, %al              # ESC para salir
    je exit_program
    
    jmp input_wait

play_sound_0:
    call wait_for_enter
    call sound_low_tone
    jmp input_wait

play_sound_1:
    call wait_for_enter
    call sound_high_tone
    jmp input_wait

read_key:
    push %rcx
    push %rdx
    
    # Obtener protocolo de entrada
    mov %r14, %rcx              # System Table
    mov 56(%rcx), %rcx          # ConIn
    
    # Leer tecla
    mov %rcx, %rdx
    lea key_buffer(%rip), %r8
    mov (%rcx), %rax
    call *16(%rax)              # ReadKeyStroke
    
    # Cargar carácter leído
    mov key_buffer(%rip), %ax
    mov key_buffer+2(%rip), %al # UnicodeChar
    
    pop %rdx
    pop %rcx
    ret

wait_for_enter:
    push %rax
wait_enter_loop:
    call read_key
    cmp $0x0D, %al              # Enter
    jne wait_enter_loop
    pop %rax
    ret

# Funciones de sonido usando PC Speaker
sound_low_tone:
    push %rax
    push %rdx
    
    # Configurar PIT para tono bajo (500 Hz aproximadamente)
    mov $0x43, %dx              # Puerto de comando PIT
    mov $0xB6, %al              # Configuración: canal 2, modo 3
    out %al, %dx
    
    mov $0x42, %dx              # Puerto de datos canal 2
    mov $2394, %ax              # Divisor para ~500Hz (1193180/500)
    out %al, %dx                # Byte bajo
    mov %ah, %al
    out %al, %dx                # Byte alto
    
    # Activar speaker
    in $0x61, %al
    or $3, %al
    out %al, $0x61
    
    # Mantener sonido por un tiempo
    call delay
    
    # Desactivar speaker
    in $0x61, %al
    and $0xFC, %al
    out %al, $0x61
    
    pop %rdx
    pop %rax
    ret

sound_high_tone:
    push %rax
    push %rdx
    
    # Configurar PIT para tono alto (1000 Hz aproximadamente)
    mov $0x43, %dx
    mov $0xB6, %al
    out %al, %dx
    
    mov $0x42, %dx
    mov $1193, %ax              # Divisor para ~1000Hz
    out %al, %dx
    mov %ah, %al
    out %al, %dx
    
    # Activar speaker
    in $0x61, %al
    or $3, %al
    out %al, $0x61
    
    call delay
    
    # Desactivar speaker
    in $0x61, %al
    and $0xFC, %al
    out %al, $0x61
    
    pop %rdx
    pop %rax
    ret

delay:
    push %rcx
    mov $0x100000, %rcx         # Contador para delay
delay_loop:
    dec %rcx
    jnz delay_loop
    pop %rcx
    ret

exit_program:
    # Terminar programa
    mov %r14, %rcx              # System Table
    mov 216(%rcx), %rcx         # BootServices
    mov (%rcx), %rax            # Tabla de funciones
    call *232(%rax)             # Exit función
    
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax

# Datos adicionales
.section .data
instructions_msg:
    .word 'P', 'r', 'e', 's', 'i', 'o', 'n', 'a', ':', 0x0D, 0x0A
    .word '0', ' ', '+', ' ', 'E', 'n', 't', 'e', 'r', ' ', '=', ' '
    .word 'T', 'o', 'n', 'o', ' ', 'g', 'r', 'a', 'v', 'e', 0x0D, 0x0A
    .word '1', ' ', '+', ' ', 'E', 'n', 't', 'e', 'r', ' ', '=', ' '
    .word 'T', 'o', 'n', 'o', ' ', 'a', 'g', 'u', 'd', 'o', 0x0D, 0x0A
    .word 'E', 'S', 'C', ' ', '=', ' ', 'S', 'a', 'l', 'i', 'r', 0x0D, 0x0A, 0

key_buffer:
    .quad 0                     # Buffer para almacenar tecla leída

.section .note
# Información de sección para EFI
.align 8