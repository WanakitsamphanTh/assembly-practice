section .bss
    tape resq 1
    tape_break resq 1
    tape_end resq 1
    size resq 1
section .text
    global init_allocator
    global allocate
    global free_allocator

init_allocator: ; requires rdi as size in kb
    shl rdi, 10
    mov qword [size], rdi
    push rdi

    mov rax, 9 ; mmap
    mov rsi, rdi ; size
    xor rdi, rdi ; addr = NULL
    mov rdx, 0x3 ; PROT_READ (0x1) | PROT_WRITE (0x2)
    mov r10, 0x22 ;  MAP_PRIVATE (0x02) | MAP_ANONYMOUS (0x20)
    mov r8, -1 ; fd (not backed by a file)
    xor r9, r9 ; offset
    syscall

    test rax, rax
    js .init_failed

    pop rdi     ; size
    mov qword [tape], rax ; allocated region
    mov qword [tape_break], rax
    lea rcx, [rax + rdi]
    mov qword [tape_end], rcx
    ret

.init_failed:
    pop rdi
    xor rax, rax
    ret


allocate: ; requires rdi as size
    ; checking
    add rdi, 7
    and rdi, -8
    mov rcx, rdi
    add rcx, qword [tape_break]
    cmp rcx, qword [tape_end]
    ja .overflow_error

    mov rax, qword [tape_break]
    mov qword [tape_break], rcx

    ret

.overflow_error:
    xor rax, rax
    ret


free_allocator:
    mov rax, 11
    mov rdi, qword [tape]
    mov rsi, qword [size]
    syscall

    test rax, rax
    js .free_failed

    mov qword [tape], 0
    mov qword [tape_break], 0
    mov qword [tape_end], 0
    mov qword [size], 0
    
    xor rax, rax
    ret

.free_failed:
    mov rax, -1
    ret