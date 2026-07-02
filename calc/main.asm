section .rodata
    invalid_op_msg db "invalid operation", 0
    div_zero_msg db "division by zero", 0
section .bss
    buffer resb 256
section .text
    global _start

_start:

    pop rdi
    cmp rdi, 2
    jl .done

    pop rdi             ; pop the first argument (the string to check)
    pop rdi

    call scan_char_str
    push rax

    push rdi
    mov rdi, rax
    call putchar
    mov rdi, ' '
    call putchar
    pop rdi

    call scan_int_str
    push rax

    push rdi
    call print_int
    mov rdi, ' '
    call putchar
    pop rdi

    call scan_int_str
    push rax

    push rdi
    call print_int
    mov rdi, ' '
    call putchar
    mov rdi, '='
    call putchar
    mov rdi, ' '
    call putchar
    pop rdi

    pop rcx
    pop rbx

    pop rax
    cmp rax, '+'
    je .add
    cmp rax, '-'
    je .sub
    cmp rax, '*'
    je .mul
    cmp rax, '/'
    je .div

    mov rdi, invalid_op_msg
    call str_print
    jmp .done

    .add:
    add rbx, rcx
    jmp .print_result

    .sub:
    sub rbx, rcx
    jmp .print_result

    .mul:
    imul rbx, rcx
    jmp .print_result

    .div:
    cmp rcx, 0
    je .div_zero
    xor rdx, rdx
    mov rax, rbx
    div rcx
    mov rbx, rax

    jmp .print_result

    .div_zero:
    mov rdi, div_zero_msg
    call str_print
    jmp .done
    
    .print_result:
    mov rax, rbx
    call print_int

    .done:
    mov rdi, 10
    call putchar
    mov rax, 60
    xor rdi, rdi
    syscall

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

str_scan:
    xor r8, r8

    push rbx
    mov rbx, rdi
    mov r9, rsi
    dec r9

    mov rax, 0
    mov rdi, 0
    mov rsi, rbx
    mov rdx, r9
    syscall

    test rax, rax
    je .done
    mov rcx, rax

    .loop:
    cmp byte [rbx], 10
    je .done
    cmp r8, rcx
    je .done

    inc r8
    inc rbx
    jmp .loop

    .done:
    mov byte [rbx], 0
    mov rax, r8
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

scan_char_str:
    call consume_whitespace
    movzx rax, byte [rdi] 
    inc rdi
    ret

scan_int_str:
    call consume_whitespace

    push rbx
    xor rax, rax

    .loop:
    cmp byte [rdi], 0
    je .done

    movzx rbx, byte [rdi]
    sub rbx, '0'
    cmp rbx, 9
    ja .error

    imul rax, 10
    add rax, rbx

    inc rdi
    jmp .loop

    .error:
    stc

    .done:
    pop rbx
    ret

consume_whitespace:
    .loop:
    cmp byte [rdi], 0
    je .done

    cmp byte [rdi], ' '
    jne .done

    inc rdi
    jmp .loop

    .done:
    ret

print_int:
    push rbp
    mov rbp, rsp
    cmp rax, 0
    je .zero

    .loop:
    xor rdx, rdx
    mov rdi, 10
    div rdi
    add rdx, '0'

    push rdx
    cmp rax, 0
    jne .loop

    .print:
    pop rdi
    call putchar
    cmp rsp, rbp
    jne .print
    jmp .done

    .zero:
    mov rdi, '0'
    call putchar

    .done:
    pop rbp
    ret

is_open:
    push rbx
    xor rax, rax
    mov rbx, rdi

    .loop:
    cmp byte [rbx], 0
    je .done

    cmp byte [rbx], '('
    je .inc_c
    cmp byte [rbx], ')'
    jne .inc
    cmp rax, 0
    je .error
    dec rax
    jmp .inc

    .inc_c:
    inc rax

    .inc:
    inc rbx
    jmp .loop

    .error:
    mov rax, -1

    .done:
    pop rbx
    ret
