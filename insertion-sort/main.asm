section .bss
    arr resq 32     ; arr
    n   resq 1      ; number of arr elements
    i   resq 1
    buffer resb 32  ; input buffer
    buflen resb 1   ; input buffer len

section .text
    global _start

_start:
    ; input n
    mov r8, buffer
    call scan_str
    call convert_str_to_int64
    mov [n], rax

    ; iterate over arr, input arr[i]
    mov [i], 0
    input_loop:
        mov rcx, [i]
        cmp rcx, [n]
        je input_done

        ; input arr[i] and iterate
        mov r8, buffer
        call scan_str
        call convert_str_to_int64
        mov rcx, [i]
        mov [arr + 8 * rcx], rax

        add rcx, 1
        mov [i], rcx
        jmp input_loop
    
    input_done:

    ; sort arr
    mov rax, arr
    mov r9, [n]
    call sort

    ; iterate over arr, output arr[i]
    mov [i], 0
    print_loop:
        mov rcx, [i]
        cmp rcx, [n]
        je print_done

        mov rcx, [i]
        mov rax, [arr + rcx * 8]
        call print_number

        mov rdi, ' '
        call putchar

        inc qword [i]
        jmp print_loop

    print_done:

    mov rdi, 10
    call putchar
    ; return
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

        ; if scanned char is '\0' or '\n' or ' ', terminate loop
        cmp byte [rsp], 0
        je scan_str_done
        cmp byte [rsp], 10
        je scan_str_done
        cmp byte [rsp], ' '
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

    cmp rax, 0
    jne _print_number_conversion_loop
    mov rdi, '0'
    call putchar
    jmp done

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

sort:      ; target array pointer in rax, length in r9
    push rbx

    sub rsp, 8          ; advance stack pointer by 8 byte [as int var]: i := rsp + 24 
    sub rsp, 8          ; advance stack pointer by 8 byte [as int var]: j := rsp + 16
    sub rsp, 8          ; advance stack pointer by 8 byte [as int var]: min_index := rsp + 8
                        ; for iteration and saving minimum index
    
    mov qword [rsp + 24], 0
    loop:
        mov rcx, qword [rsp + 24] 
        cmp rcx, r9        ; if i == n
        je sort_done

        mov qword [rsp + 16], rcx ; j = i
        mov qword [rsp + 8], rcx ; min = j
        loop_find_min:
            mov rcx, qword [rsp + 16]
            cmp rcx, r9
            je find_done

            mov rcx, qword [rsp + 16]
            mov rcx, qword [rax + rcx * 8]        ; arr[j]
            mov rbx, qword [rsp + 8]
            mov rbx, qword [rax + rbx * 8]        ; arr[min_index]
            cmp rcx, rbx
            ja increment                     ; jump to increment (skip assignment) if arr[j] > arr[min_index]

            mov rcx, qword [rsp + 16]
            mov qword [rsp + 8], rcx   ; min_index <- j

            increment:
            inc qword [rsp + 16]
            jmp loop_find_min

        find_done:
        ; swap
        mov r10, qword [rsp + 24]  
        mov r11, qword [rax + r10 * 8]  ; r11 <- arr[i]
        mov r12, qword [rsp + 8]    
        mov r13, qword [rax + r12 * 8]
        mov qword [rax + r10 * 8], r13 ; arr[i] <- arr[min_index]
        mov qword [rax + r12 * 8], r11

        add qword [rsp + 24], 1
        jmp loop

    sort_done:

    add rsp, 24
    pop rbx
    ret