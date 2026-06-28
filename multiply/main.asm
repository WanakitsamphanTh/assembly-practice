section .data
section .bss
    buflen resq 1       ; buflen: 1 quarter word (8 bytes)
    buffer resb 256
    i      resq 1
    j      resq 1

section .text
    global  _start

_start:
    ;scan interger i
    mov r8, buffer       ; move buffer to pointer to r8
    call scan_str 
    mov [buflen], r9     ; store length (r9) in buflen

    ; conversion
    lea r8, [rel buffer]
    mov r9, [buflen]
    call convert_str_to_int64
    mov [i], rax

    ;scan interger j
    mov r8, buffer       ; move buffer to pointer to r8
    call scan_str 
    mov [buflen], r9     ; store length (r9) in buflen

    ; conversion
    lea r8, [rel buffer]
    mov r9, [buflen]
    call convert_str_to_int64
    mov [j], rax

    ; i <- i * j
    mov rax, [i]
    imul rax, [j]           
    mov [i], rax

    ; lea r8, [rel buffer]
    mov rax, [i]
    call print_number

    ; print new line
    mov rdi, 10
    call putchar

    ; program ends ; return the converted value
    mov rax, 60
    xor rdi, rdi
    syscall

scan_str: ; requires r8 = ptr to msg_str
    push rax
    push rdi
    push rsi
    push rdx

    xor r9, r9      ; r9 stores length, set to 0
    
    sub rsp, 1      ; the top of stack stores read char

    scan_str_loop:
        mov rax, 0  ; sys_read
        mov rdi, 0  ; stdin
        mov rsi, rsp ; write to rsp
        mov rdx, 1
        syscall 

        ; if scanned char is '\0' or '\n', terminate loop
        cmp byte [rsp], 0
        je scan_str_done
        cmp byte [rsp], 10
        je scan_str_done

        mov al, byte [rsp]    
        mov [r8 + r9], al  ; buffer[rcx] = al

        inc r9 ; increment buffer length

        jmp scan_str_loop

    scan_str_done:     
    mov byte [r8 + r9], 0

    inc rsp
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

convert_str_to_int64:
    ; buffer pointer in r8, number of digits in r9, return in rax
    push r10
    push rcx

    xor rax, rax
    xor rcx, rcx

    conversion_loop:
        cmp rcx, r9
        je conversion_done

        imul rax, 10                ; multiply r10 by 10

        movzx r10, byte [r8 + rcx]   ; read the current dgit
        sub r10, '0'                ; remove by ascii of '0'
        add rax, r10                ; add it to r10

        inc rcx

        jmp conversion_loop

    conversion_done:
    pop rcx
    pop r10
    ret

print_number:               ; rax as print target value
    push r9                ; 9 as counter
    xor r9, r9

    _print_number_conversion_loop:
        cmp rax, 0              ; terminate if the number becomes 0
        je _print_number

        xor rdx, rdx
        mov rcx, 10            ; move 10 to rcx
        div rcx                 ; div rax by rcx [rdx:rax] = [remainder:quotient]

        add rdx, '0'
        push rdx                ; push rdx (remainder) into stack

        inc r9
        jmp _print_number_conversion_loop

    _print_number:
        cmp r9, 0
        je done

        pop rdi
        call putchar

        dec r9
        jmp _print_number

    done:
    pop r9
    ret

putchar: 
    push rdi    ; store character to print in register rdi and push into stack

    mov rax, 1
    mov rdi, 1      ; file descriptor to stdout
    mov rsi, rsp    ; stack pointer
    mov rdx, 1      ; 1-character length
    syscall

    pop rdi         ; pop stack and clean up rdi
    ret