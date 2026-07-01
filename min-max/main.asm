section .data
    max_msg db "max: ", 0
    min_msg db "min: ", 0

section .bss
    buflen resq 1
    buffer resb 64
    arr    resq 32
    arr_len resq 1

section .text
    global _start

_start:
    ; scan array length
    call scan_i64
    mov [arr_len], rax

    ; scan array
    mov rcx, 0
    loop:
        cmp rcx, [arr_len]
        je done

        push rcx
        call scan_i64
        pop rcx

        mov [arr+rcx*8], rax
        inc rcx
        jmp loop

    done:

    ; print min
    mov rax, 1
    mov rdi, 1
    mov rsi, min_msg
    mov rdx, 6
    syscall

    mov rbx, arr
    mov rcx, [arr_len]
    call min_fn
    call print_i64

    mov rdi, 10
    call putchar

    ; print max
    mov rax, 1
    mov rdi, 1
    mov rsi, max_msg
    mov rdx, 6
    syscall

    mov rbx, arr
    mov rcx, [arr_len]
    call max_fn
    call print_i64

    mov rdi, 10
    call putchar

    ; return
    mov rax, 60
    xor rdi, rdi
    syscall

min_fn:             ; min_fn(i64 arr[]; rbx, i64 n: rcx)
    xor rsi, rsi    ; iterator
    mov rax, [rbx]

    min_fn_loop:
        cmp rax, [rbx + 8 * rsi]
        jb min_fn_loop_inc

        mov rax, [rbx + 8 * rsi]

        min_fn_loop_inc:
        inc rsi
        cmp rsi, rcx
        jb min_fn_loop

    ret

max_fn:             ; max_fn(i64 arr[], i64 n: rcx)
    xor rsi, rsi    ; iterator
    mov rax, [rbx]

    max_fn_loop:
        cmp rax, [rbx + 8 * rsi]
        ja max_fn_loop_inc

        mov rax, [rbx + 8 * rsi]

        max_fn_loop_inc:
        inc rsi
        cmp rsi, rcx
        jb max_fn_loop

    ret

scan_i64: 
    sub rsp, 16
    mov rax, 0      ; set return value (rax) to 0
    xor r10, r10    ; set flag whether scanning starts or not (to skip space or newline before reading a character)

    scan_loop:
        push rax

        mov rax, 0
        mov rdi, 0
        lea rsi, [rsp + 8]
        mov rdx, 1
        syscall     ; read a character

        pop rax

        ; if r10 is zero (not scanned yet), skip space and new line or terminate if have reached null
        cmp r10, 0
        jne _scan_loop
        cmp byte [rsp], ' '
        je scan_loop
        cmp byte [rsp], 10
        je scan_loop
        cmp byte [rsp], 0
        je scan_done

        _scan_loop:
        cmp byte [rsp], ' '
        je scan_done
        cmp byte [rsp], 10
        je scan_done
        cmp byte [rsp], 0
        je scan_done    ; otherwise done if scanned space, new line, or null

        mov r10, 1

        imul rax, 10
        sub byte [rsp], '0'
        movzx rcx, byte[rsp]
        add rax, rcx

        jmp scan_loop
    
    scan_done:

    add rsp, 16
    ret

print_i64:
    xor r9, r9                 ; digit counter
    cmp rax, 0
    jne print_i64_conversion_loop
    
    mov rdi, '0'
    call putchar            ; if rax = 0 print '0'
    jmp print_i64_done

    print_i64_conversion_loop:
        cmp rax, 0
        je print_i64_loop

        xor rdx, rdx
        mov rcx, 10
        div rcx

        add rdx, '0'
        push rdx

        inc r9
        jmp print_i64_conversion_loop

    print_i64_loop:
        cmp r9, 0
        je print_i64_done

        pop rdi
        call putchar

        dec r9
        jmp print_i64_loop

    print_i64_done:
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