org 0x7C00
bits 16

mov al, [input]
    add al, al
    mov [output], al
    cli

.hang:
    hlt

input db 07h
output db 00h

times 510-($-$$) db 0
dw 0xAA55