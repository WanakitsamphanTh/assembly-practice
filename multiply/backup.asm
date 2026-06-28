section .data
    msg db "You entered: ", 0
    len equ $ - msg

section .bss
    c resb 1
    buffer resb 32      ; input buffer of 32 bytes
    buflen resb 1       ; length of buffer
    number resd 1       ; target number

section .text
    global  _start

_start:
    call scan_string

    call str_to_number

    ; print
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, len
    syscall

    ; print
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, [buflen]
    syscall
    
    ; print new line
    mov rdi, 10
    call putchar

    ; program ends
    mov rax, 60
    xor rdi, rdi
    syscall

scan_string:
    sub rsp, 1              ; increment stack pointer by 1 byte
    mov byte [buflen], 0

    _scan_string_input_loop:
        mov rax, 0          ; sys_read
        mov rdi, 0          ; file descriptor stdin
        mov rsi, rsp        ; store input in c
        mov rdx, 1
        syscall

        cmp byte [rsp], 0            ; if c is '\0'
        je scan_string_done

        cmp byte [rsp], 10           ; if c is '\n'
        je scan_string_done

        movzx rcx, byte [buflen]
        mov al, [rsp]
        mov [buffer + rcx], al      ;  buffer[buflen] =  c

        inc byte [buflen]

        jmp _scan_string_input_loop

    scan_string_done:

        add rsp, 1      ; retract stack pointer by 1 byte
        ret


str_to_number:          ; eax for digit value, top stack for pointer to a character
    mov [number], 0
    mov eax, [buflen]   ; move buflen to eax
    push msg + eax       ; push pointer to the last char in msg into stack
    mov eax, 0          ; set eax to 0 to store digit value
    
    conversion_loop:
        movzx al, byte [rsp]
        sub al, '0'
        mov rdi, al    ; current digit
        call power_of_10

        mov rax, rdi
        mov rbx, dword [num]
        add rbx, rax
        add dword [num], rbx  ; add rdi to num

        dec [rsp]         ; decrement value (pointer) in stack pointer
        inc eax         ; increment buflen by one 

        mov al, rsp
        sub al, msg
        cmp al, 0
        je conversion_done ; if rsp and msg point to the same location (beginning of msg)
                            ; then jump to conversion_done

    conversion_done:

    pop eax        ; pop msg pointer from stack
    xor eax, eax
    ret

power_of_10:    ; use eax for power, rdi for digit (and return value)
    push eax
    power_loop:
        cmp byte [rsp], 0
        je power_loop_done
        mul rdi, 10
        dec byte [rsp]
    power_loop_done:
    pop eax
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

