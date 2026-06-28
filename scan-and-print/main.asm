section .data
    msg db "You entered: ", 0
    len equ $ - msg

section .bss
    c resb 1
    buffer resb 32      ; input buffer of 32 bytes
    buflen resb 1       ; length of buffer

section .text
    global  _start

_start:
    mov byte [buflen], 0

_input_loop:

    mov rax, 0          ; sys_read
    mov rdi, 0          ; file descriptor stdin
    mov rsi, c          ; store input in c
    mov rdx, 1
    syscall

    cmp byte [c], 0            ; if c is '\0'
    je done

    cmp byte [c], 10            ; if c is '\n'
    je done

    movzx rcx, byte [buflen]
    mov al, [c]
    mov [buffer + rcx], al ;  buffer[buflen] =  c

    inc byte [buflen]

    jmp _input_loop

done:
    ; print
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, [buflen]
    syscall

    ; print new line
    mov rdi, 10
    call putchar

    ; program ends
    mov rax, 60
    xor rdi, rdi
    syscall

putchar: 
    push rdi    ; store character to print in register rdi and push into stack

    mov rax, 1
    mov rdi, 1      ; file descriptor to stdout
    mov rsi, rsp    ; stack pointer
    mov rdx, 1      ; 1-character length
    syscall

    pop rdi         ; pop stack and clean up rdi
    ret