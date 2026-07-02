section .rodata
    no_input_file_msg db "No input file", 10, 0
    open_file_error_msg db "Cannot open file", 10, 0
section .bss
    fname resq 1
    fd resq 1
    buffer resb 256
section .text
    global _start

_start:
    pop rdi
    cmp rdi, 2
    jb .no_input_file

    pop rdi          ; drop program path
    pop rdi          ; argv[1]
    mov [fname], rdi ; = file name ptr

    mov rax, 2      ; sys_open
    mov rsi, 0      ; read only
    mov rdx, 0      ; ignore permissions
    syscall

    cmp rax, 0
    jl .open_file_error

    mov [fd], rax   ; file descriptor

    .loop:
    mov rdi, [fd]
    mov rsi, buffer
    mov rdx, 255
    call fread

    cmp rax, 0
    je .close_file
    jl .read_file_error

    mov rdi, buffer
    call str_print
    jmp .loop

    .close_file:
    mov rax, 3      ; sys_close
    mov rdi, [fd]
    syscall
    jmp .done

    .no_input_file:
    mov rdi, no_input_file_msg
    call str_print
    jmp .done

    .open_file_error:
    mov rdi, open_file_error_msg
    call str_print
    jmp .done

    .read_file_error:
    push rax            ; save returned error
    mov rax, 3
    mov rdi, [fd]
    syscall

    mov rax, 60
    pop rdi
    syscall

    .done:
    mov rax, 60
    xor rdi, rdi
    syscall

fread:      ; rdi = file descriptor, rsi = buffer, rdx = buffer size
    mov rax, 0  ; read file
    syscall

    cmp rax, 0
    jle .done   ; rax <= 0 : reached eof or error

    mov [rsi + rax], 0
    
    .done:
    ret

str_print:
    push rbx

    push rdi
    .count:
    cmp byte [rdi], 0
    je .done
    inc rdi
    jmp .count

    .done:
    pop rbx
    mov rdx, rdi
    sub rdx, rbx

    mov rax, 1
    mov rdi, 1
    mov rsi, rbx
    syscall

    pop rbx
    ret

putchar:
    push rdi
    mov rax, 1
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rdi
    ret