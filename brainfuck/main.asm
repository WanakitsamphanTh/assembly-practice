section .rodata
    no_input_file_msg db "No input file", 10, 0
    open_file_error_msg db "Cannot open file", 10, 0
    error_open_bracket_msg db "Open bracket", 10, 0
    inc_error_msg db "Tape increment error", 10, 0
    tape_end equ tape + 2056
section .bss
    fname resq 1
    fd resq 1
    buffer resb 1024
    tape resb 2056
section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jb .no_input_file_error

    mov rax, [rsp + 16]
    mov rdi, rax ; = file name ptr
    
    mov rax, 2      ; sys_open
    xor rsi, rsi      ; read only
    xor rdx, rdx      ; ignore permissions
    syscall

    test rax, rax
    js .open_file_error

    mov [fd], rax

    mov rdi, [fd]   ; read source code
    mov rsi, buffer
    mov rdx, 1023
    call fread

    call interpret

    xor rdi, rdi
    jmp terminate

    .no_input_file_error:
    lea rdi, [no_input_file_msg]
    call str_print
    mov rdi, -1
    jmp terminate

    .open_file_error:
    lea rdi, [open_file_error_msg]
    call str_print
    mov rdi, -1
    jmp terminate

    terminate:
    mov rax, 60
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

interpret:
    push rbp 
    mov rbp, rsp
    push r12
    push r13
    lea r12, [buffer]
    lea r13, [tape]

    .loop:
    cmp byte [r12], 0
    je .done
    cmp byte [r12], '>'
    je .inc_ptr
    cmp byte [r12], '<'
    je .dec_ptr
    cmp byte [r12], '+'
    je .inc_data
    cmp byte [r12], '-'
    je .dec_data
    cmp byte [r12], '.'
    je .output
    cmp byte [r12], ','
    je .input
    cmp byte [r12], '['
    je .jump_forth
    cmp byte [r12], ']'
    je .jump_back
    
    jmp .latch

    .inc_ptr:
    cmp r13, tape_end
    je .inc_error
    inc r13
    jmp .latch

    .dec_ptr:
    cmp r13, tape      
    jle .latch          ; do nothing
    
    dec r13
    jmp .latch

    .inc_data:
    inc byte [r13]
    jmp .latch

    .dec_data:
    dec byte [r13]
    jmp .latch

    .input:
    mov rax, 0
    mov rdi, 0
    mov rsi, r13
    mov rdx, 1
    syscall
    jmp .latch

    .output:
    mov rax, 1
    mov rdi, 1
    mov rsi, r13
    mov rdx, 1
    syscall
    jmp .latch

    .jump_forth:
    cmp byte [r13], 0
    jne .latch              ; only jump if current data = 0

    xor r9, r9              
    inc r9                  ; start counting open brackets
    
    .jf_loop:
    cmp r9, 0
    je .latch
    cmp byte [r12], 0
    je .error_open_bracket
    inc r12
    cmp byte [r12], '['
    je .jf_open
    cmp byte [r12], ']'
    je .jf_close

    jmp .jf_loop
    
    .jf_open:
    inc r9
    jmp .jf_loop

    .jf_close:
    dec r9
    jmp .jf_loop


    .jump_back:
    cmp byte [r13], 0
    je .latch              ; only jump if current data != 0

    xor r9, r9              
    inc r9                  ; start counting open brackets

    .jb_loop:
    cmp r9, 0
    je .latch
    cmp r12, buffer
    je .error_open_bracket
    dec r12
    cmp byte [r12], '['
    je .jb_rclose
    cmp byte [r12], ']'
    je .jb_ropen            ; open and close must be reversed

    jmp .jb_loop
    
    .jb_ropen:
    inc r9
    jmp .jb_loop

    .jb_rclose:
    dec r9
    jmp .jb_loop

    jmp .latch

    .latch:
    inc r12
    jmp .loop

    .error_open_bracket:
    lea rdi, [error_open_bracket_msg]
    call str_print
    mov rdi, -1
    jmp terminate

    .inc_error:
    lea rdi, [inc_error_msg]
    call str_print
    mov rdi, -1
    jmp terminate

    .done:
    mov rax, 0
    pop r13
    pop r12
    leave
    ret