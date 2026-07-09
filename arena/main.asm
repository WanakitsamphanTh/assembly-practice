section .rodata
    no_args_error_msg db "Run the program in the specified format: [Program name] [n1] [n2] ...", 10, 0
    allocate_failed_msg db "Cannot allocate array", 10, 0
    conversion_failed_msg_fmt db "Conversion failed at %d-th element", 10, 0
    print_fmt db "array[%d] = %d", 10, 0
section .data
section .bss
    length resq
    arr resq
section .text
    global main
    extern printf
    extern init_allocator
    extern allocate
    extern free_allocator

main:
    push r12
    push r13
    push r14

    push rsi
    push rdi

    mov rdi, 1
    call init_allocator

    pop rdi
    pop rsi

    cmp rax, 0
    je .allocate_failed
    
    cmp rdi, 2
    jb .no_args_error

    sub rdi, 1
    mov qword [length], rdi
    imul rdi, 8
    call allocate

    cmp rax, 0
    je .allocate_failed

    mov qword [arr], rax

    add rsi, 8      ; start with argv[1]
    xor r12, r12
    mov r13, rsi
    mov r14, rax
.assign_loop:
    mov rdi, r13          ; nptr
    call atoi
    jc .conversion_failed

    mov qword [r14], rax

    inc r12
    add r13, 8          ; increase iterator by 8 bytes
    add r14, 8         ; increase array iterator by 8 bytes

    cmp r12, qword [length]
    jne .assign_loop

    mov r14, qword [arr]
    xor r12, r12
.print_loop:
    sub rsp, 8
    lea rdi, [rel print_fmt]
    mov rsi, r12
    mov rdx, qword [r14]
    xor eax,  eax
    call printf
    add rsp, 8

    add r14, 8
    inc r12
    cmp r12, qword [length]
    jne .print_loop

    mov rax, 0
.terminate:
    call free_allocator
    ; ignore failure anyway
    pop r14
    pop r13
    pop r12
    ret

.conversion_failed:
    lea rdi, [rel conversion_failed_msg_fmt]
    sub rsp, 8
    xor eax,  eax
    mov rsi, r12
    call printf
    add rsp, 8
    mov rax, 1
    jmp .terminate

.no_args_error:
    lea rdi, [rel no_args_error_msg]
    sub rsp, 8
    xor eax,  eax
    call printf
    add rsp, 8
    mov rax, 1
    jmp .terminate

.allocate_failed:
    lea rdi, [rel allocate_failed_msg]
    sub rsp, 8
    xor eax,  eax
    call printf
    add rsp, 8
    mov rax, 1
    jmp .terminate

atoi:
    xor rax, rax
    xor r9, r9
    clc             ; clear CF
    
    cmp byte [rdi], '-'
    jne .loop
    mov r9, 1
    inc rdi
    jmp .loop

.loop:
    imul rax, 10

    movzx rcx, byte [rdi]
    cmp rcx, '0'
    jb .invalid_error
    cmp rcx, '9'
    ja .invalid_error

    sub rcx,  '0'
    add rax, rcx
    inc rdi
    cmp byte [rdi], 0
    jne .loop
    
.done:
    cmp r9, 1
    je .neg
    ret

.invalid_error:
    stc             ; set carry flag to 1
    ret

.neg:
    neg rax
    ret