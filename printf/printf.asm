section .bss
section .data
section .text
    global printf

    ; calling convention
    ;   push arg_n
    ;   push arg_n-1
    ;   ...
    ;   push arg_1
    ;   lea r9, [rel msg]
    ;   call printf
    ; return number printed in rax
    
printf:
    ; fmt string pointer in r9
    ; r10 as arg pointer; point to the first arg
    ; push all parameters on stack
    ; return stack -> arg[N-1] -> ... -> arg[0]
    push r10
    mov r10, [rsp + 8]  ; points to the first arg

    printf_loop:
    cmp [r9], 0
    je printf_done

    cmp [r9], '%'
    je _print_fmt

    mov rdi, [r9]
    call putchar
    jmp _printf_loop_inc
    
    _print_fmt:
    inc r9
    cmp [r9], 'c'
    je _print_char

    cmp [r9], 'd'
    je _print_i64
    
    cmp [r9], '%'
    je _print_percent

    mov rdi, '%'
    call putchar
    jmp printf_loop

    jmp _printf_loop_inc

        _print_percent:
        mov rdi, '%'
        call putchar
        jmp _printf_loop_inc

        _print_char:
        add r10, 1
        mov rdi, [r10]
        call putchar
        jmp _printf_loop_inc

        _print_i64:

        add r10, 8
        jmp _printf_loop_inc

    _printf_loop_inc:
    inc r9
    jmp printf_loop

    printf_done:
    pop rax
    ret