section .bss
section .data
section .text
    global _start

_start:

    mov rdi, 10
    call putchar

    mov rax, 60
    xor rdi, rdi
    syscall

putchar:
    push rdi

    mov rax, 1
    mov rdx, rsp
    mov rdi, 1
    syscall

    pop rdi
    ret
