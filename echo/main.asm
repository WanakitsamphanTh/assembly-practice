struc sockaddr_in
    .sin_family resw 1
    .sin_port resw 1
    .sin_addr resd 1
    .sin_zero resb 8
endstruc
%define sockaddr_in_size sockaddr_in_size

%define AF_INET 2
%define SERVER_MODE 0
%define CLI_MODE 1
%define buffer_max_len 255
section .rodata
    server_mode_str db "server", 0
    client_mode_str db "client", 0

    init_cli_done db "initalized client mode", 10, 0
    init_server_done db "initialized server mode", 10, 0

    server_running_msg db "server is running on port %d...", 10, 0
    ip_convert_error_msg db "cannot convert ip address", 10, 0

    cmd_arg_error_msg db "please run the program in the following format", 10, "main client [ip] [port] | main server [port]", 10, 0
    socket_error_msg db "socket error", 10, 0
    server_bind_error_msg db "binding error", 10, 0
    server_read_error_msg db "cannot read from socket", 10, 0
    server_send_error_msg db "cannot response to the client", 10, 0
    server_listen_error_msg db "cannot listen to the ip address", 10, 0
    server_receive_error_msg db "cannot receive a message", 10, 0
    server_receive_msg db "received: %s", 10, 0
    server_close_cli_socket_msg db "connection closed", 10, 0

    cli_init_msg db "trying to connect to %s:%s", 10, 0

    cli_read_error_msg db "read failed", 10, 0
    cli_connect_error_msg db "cannot connect to server (errno=%d)", 10, 0
    cli_input_error_msg db "input error", 10, 0
    cli_send_error_msg db "cannot send to server", 10, 0
    cli_receive_error_msg db "cannot receive message from server", 10, 0
    cli_receive_msg db "received: %s", 10, 0

    print_arg_fmt db "received %s", 10, 0
    test_msg db "as client", 10, 0

    jmp_table:
        dq main.as_server
        dq main.as_cli

section .data
    sockfd dq 0
    cli_fd dq 0

section .bss
    mode resb 1
    port resq 1
    buffer resb 256

section .text
    global main
    extern printf
    extern fprintf
    extern strcmp
    extern bzero
    extern htons
    extern stderr
    extern atoi
    extern htonl
    extern inet_addr
main:
    push r12            ; 8-byte
    push r13            ; 8-byte
    push r14            ; 8-byte
    push rbx            ; 8-byte
    push rbp            ; 8-byte
    mov rbp, rsp
    mov r12, rdi        ; r12 := argc
    mov r13, rsi        ; r13 := argv

    cmp r12, 2
    jl .cmd_arg_error

    sub rsp, sockaddr_in_size   ; server_addr
    sub rsp, sockaddr_in_size   ; client_addr
    sub rsp, 8                  ; addr_len

    sub rsp, 8                  ; padding

    lea rdi, [rbp - 2 * sockaddr_in_size]
    mov rsi, sockaddr_in_size * 2
    call bzero
    
    mov rdi, qword [r13 + 8]
    lea rsi, [server_mode_str]
    call strcmp
    test rax, rax
    jz .init_server

    mov rdi, qword [r13 + 8]
    lea rsi, [client_mode_str]
    call strcmp
    test rax, rax
    jz .init_cli

    jmp .cmd_arg_error

.init_done:
    mov [rbp - sockaddr_in_size + sockaddr_in.sin_family], AF_INET  ;server_addr.sin_family = AF_INET

    mov rax, 41     ; sys_socket
    mov rdi, AF_INET; family = AF_INET (IPv4)
    mov rsi, 1      ; type = SOCK_STREAM
    xor rdx, rdx    ; protocol = NULL
    syscall
    test rax, rax
    js .socket_error
    mov qword [sockfd], rax ; create socket

    mov qword [rbp - 2 * sockaddr_in_size - 8], sockaddr_in_size

    movzx rax, byte [mode]
    jmp qword [jmp_table + 8 * rax]

.main_done:
    call close_socket
    xor eax, eax
.main_return:
    mov rsp, rbp
    pop rbp
    pop rbx
    pop r14
    pop r13
    pop r12
    ret

.init_server:
    mov r14, qword [r13 + 16]      ; port

    mov rdi, r14
    call atoi
    mov qword [port], rax
    mov rdi, rax
    call htons
    mov r14, rax
    mov word [rbp - sockaddr_in_size + sockaddr_in.sin_port], r14w  ; server_addr.sin_port = r14

    xor rdi, rdi
    call htonl
    mov dword [rbp - sockaddr_in_size + sockaddr_in.sin_addr], eax  ; server_addr.sin_port = INADDR_ANY

    mov byte [mode], SERVER_MODE

    lea rdi, [init_server_done]
    call printf

    jmp .init_done

.init_cli:
    mov r14, qword [r13 + 24]      ; port
    mov rbx, qword [r13 + 16]     ; ip

    lea rdi, [cli_init_msg]
    mov rsi, rbx
    mov rdx, r14
    call printf

    mov rdi, r14
    call atoi
    mov qword [port], rax
    mov rdi, rax
    call htons
    mov r14, rax
    mov word [rbp - sockaddr_in_size + sockaddr_in.sin_port], r14w  ; server_addr.sin_port = r9

    mov rdi, rbx
    call inet_addr
    test rax, rax
    jz .ip_convert_error

    mov dword [rbp - sockaddr_in_size + sockaddr_in.sin_addr], eax

    mov byte [mode], CLI_MODE

    lea rdi, [init_cli_done]
    call printf

    jmp .init_done

.as_server:
    ; bind
    mov rax, 49     ; sys_bind
    mov rdi, qword [sockfd]       ; sockfd
    lea rsi, [rbp - sockaddr_in_size]
    mov rdx, sockaddr_in_size
    syscall
    test rax, rax
    js .server_bind_error

    ; listen
    mov rax, 50     ; sys_listen
    mov rdi, qword [sockfd]
    mov rsi, 10     ; backlog
    syscall
    test rax, rax
    js .server_listen_error

    lea rdi, [server_running_msg]
    mov rsi, qword [port]
    call printf

    ; recieves
.accept_loop:
    mov rax, 43                              ; sys_accept
    mov rdi, qword [sockfd]
    lea rsi, [rbp - 2 * sockaddr_in_size]   ; &client_addr
    lea rdx, [rbp - 2 * sockaddr_in_size - 8]   ; &addr_len
    syscall
    test rax, rax
    js .server_receive_error
    mov qword [cli_fd], rax

.receive_loop:
    lea rdi, [buffer]
    mov rsi, 256
    call bzero

    mov rax, 0              ; sys_read
    mov rdi, qword [cli_fd]
    lea rsi, [buffer]
    mov rdx, buffer_max_len
    syscall
    test rax, rax
    js .server_read_error
    mov r14, rax            ; size

    cmp r14, 0
    je .continue_accept

    mov byte [buffer + r14], 0

    lea rdi, [server_receive_msg]
    lea rsi, [buffer]
    call printf

    ; response back
    mov rax, 1              ; sys_write
    mov rdi, qword [cli_fd]
    lea rsi, [buffer]
    mov rdx, r14
    syscall
    ;test rax, rax
    cmp rax, r14
    jne .server_send_error

    jmp .receive_loop

.continue_accept:
    mov rax, 3      ; sys_close
    mov rdi, qword [cli_fd]
    syscall

    lea rdi, [server_close_cli_socket_msg]
    call printf
    jmp .accept_loop

.receiving_loop_done:
    jmp .main_done

.as_cli:
    mov rdi, test_msg
    call printf
    ; connect
    mov rax, 42         ; sys_connect
    mov rdi, qword [sockfd]
    lea rsi, [rbp - sockaddr_in_size]
    mov rdx, qword [rbp - sockaddr_in_size * 2 - 8]
    syscall
    test rax, rax
    js .cli_connect_error

.cli_loop:
    ; input from terminal
    mov rax, 0      ; sys_read
    mov rdi, 0      ; stdin
    lea rsi, [buffer]
    mov rdx, buffer_max_len
    syscall
    cmp rax, 0
    je .cli_loop_end
    jl .cli_input_error
    mov r14, rax    ; size

    mov byte [buffer + r14], 0

    cmp byte [buffer], 10
    je .cli_loop_end

    ; remove newline
    lea rdi, [buffer]
    mov sil, 10
    call scan_msg
    mov r14, rax    ; size

    ; send to server
    mov rax, 1      ; sys_write
    mov rdi, qword [sockfd]
    lea rsi, [buffer]
    mov rdx, r14
    syscall
    test rax, rax
    js .cli_send_error

    ; receive
    mov rax, 0      ; sys_read
    mov rdi, qword [sockfd]
    lea rsi, [buffer]
    mov rdx, buffer_max_len
    syscall
    test rax, rax
    js .cli_receive_error
    mov r14, rax

    mov byte [buffer + r14], 0

    ; write on terminal
    lea rdi, [cli_receive_msg]
    lea rsi, [buffer]
    call printf

    jmp .cli_loop
    
.cli_loop_end:
    jmp .main_done

.cmd_arg_error:
    mov rdi, qword [stderr]
    lea rsi, [cmd_arg_error_msg]
    call fprintf
    jmp .exit
.socket_error:
    mov rdi, qword [stderr]
    lea rsi, [socket_error_msg]
    call fprintf
    jmp .exit
.ip_convert_error:
    mov rdi, qword [stderr]
    lea rsi, [ip_convert_error_msg]
    call fprintf
    jmp .exit
.server_bind_error:
    mov rdi, qword [stderr]
    lea rsi, [server_bind_error_msg]
    call fprintf
    jmp .exit
.server_listen_error:
    mov rdi, qword [stderr]
    lea rsi, [server_listen_error_msg]
    call fprintf
    jmp .exit
.server_receive_error:
    mov rdi, qword [stderr]
    lea rsi, [server_receive_error_msg]
    call fprintf
    jmp .exit
.server_read_error:
    mov rdi, qword [stderr]
    lea rsi, [server_read_error_msg]
    call fprintf
    jmp .exit
.server_send_error:
    mov rdi, qword [stderr]
    lea rsi, [server_send_error_msg]
    call fprintf
    jmp .exit
.cli_connect_error:
    lea rdi, [cli_connect_error_msg]
    mov rsi, rax
    call printf
    ;mov rdi, qword [stderr]
    ;lea rsi, [cli_connect_error_msg]
    ;call fprintf
    jmp .exit
.cli_input_error:
    lea rdi, [cli_input_error_msg]
    call printf
    ;mov rdi, qword [stderr]
    ;lea rsi, [cli_input_error_msg]
    ;call fprintf
    jmp .exit
.cli_send_error:
    lea rdi, [cli_send_error_msg]
    call printf
    ;mov rdi, qword [stderr]
    ;lea rsi, [cli_send_error_msg]
    ;call fprintf
    jmp .exit
.cli_receive_error:
    mov rdi, qword [stderr]
    lea rsi, [cli_receive_error_msg]
    call fprintf
    jmp .exit
.exit:
    call close_socket
    mov rax, 60
    mov rdi, -1
    syscall

close_socket:
    mov rdi, qword [sockfd]
    cmp rdi, 0
    je .close_cli
    mov rax, 3
    syscall
.close_cli:
    mov rdi, qword [cli_fd]
    cmp rdi, 0
    je .return
    mov rax, 3
    syscall
.return:
    ret

scan_msg:
    ; rdi as buffer
    ; rsi (sil) as delimeter
    xor rax, rax      ; size
.loop:
    cmp byte [rdi], sil
    je .done
    cmp byte [rdi], 0
    je .done
    inc rdi
    inc rax
    jmp .loop
.done:
    mov byte [rdi], 0
    ret