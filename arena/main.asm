section .rodata
    no_args_error_msg db "Run the program in the specified format: [Program name] [n1] [n2] ...", 10, 0
    allocate_failed_msg db "Cannot allocate array", 10, 0
    conversion_failed_msg_fmt db "Conversion failed at %ld-th element", 10, 0
    print_fmt db "array[%ld] = %ld", 10, 0
section .data
section .bss
    length resq 1
    arr resq 1
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
    push r15
    push rbx

    mov rbx, rsi    ; argv
    mov r15, rdi    ; argc

    mov rdi, 1
    call init_allocator

    cmp rax, 0
    je .allocate_failed
    
    cmp r15, 2
    jb .no_args_error

    sub r15, 1          ; argc--
    mov qword [length], r15 ; length = r15
    imul r15, 8      
    mov rdi, r15
    call allocate       ; allocate(r15*8)

    cmp rax, 0
    je .allocate_failed

    mov qword [arr], rax ; arr  =rax

    xor r12, r12
    add rbx, 8      ; argv += 8
    mov r13, rbx    ; r13 = argv
    mov r14, rax    ; r14 = arr
.assign_loop:

    mov rdi, qword [r13]
    call strtoi                 ; strtoi(*argv)
    jc .conversion_failed      ; why error here

    mov qword [r14], rax        ; rax  = *arr

    inc r12             ; r12++
    add r13, 8          ; increase iterator by 8 bytes
    add r14, 8         ; increase array iterator by 8 bytes

    cmp r12, qword [length]
    jne .assign_loop

    mov r14, qword [arr]
    xor r12, r12
.print_loop:
    lea rdi, [rel print_fmt]
    mov rsi, r12
    mov rdx, qword [r14]
    xor eax,  eax
    call printf

    add r14, 8
    inc r12
    cmp r12, qword [length]
    jne .print_loop

    mov rax, 0
.terminate:
    call free_allocator
    ; ignore failure anyway
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    ret

.conversion_failed:
    lea rdi, [rel conversion_failed_msg_fmt]
    xor eax,  eax
    mov rsi, r12
    call printf
    mov rax, 1
    jmp .terminate

.no_args_error:
    lea rdi, [rel no_args_error_msg]
    xor eax,  eax
    call printf
    mov rax, 1
    jmp .terminate

.allocate_failed:
    lea rdi, [rel allocate_failed_msg]
    xor eax,  eax
    call printf
    mov rax, 1
    jmp .terminate

strtoi:
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
    clc
    ret

.invalid_error:
    stc             ; set carry flag to 1
    ret

.neg:
    neg rax
    clc
    ret