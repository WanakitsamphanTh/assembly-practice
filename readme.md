# Sys V x86 assembly
- [X] scan and print number (scan-and-read, multiply)
- [X] function call (fibonucci)
- [X] array (insertion-sort, min-max)
- [X] cmd arguments (calc)
- [ ] simple printf

## System V x86 64 summary

### Arguments
| registers | description |
| - | - |
| rdi, rsi, rdx, rcx, r8, r9 | passing arguments |
| xmm0 - xmm7 | floating point parameters |

1. Any parameters not fit in these registers are passed via stack in reverse order
2. Function calls are done by `call` instruction, which pushes address of the next instruction onto the stack and jumps to the function
3. The stack is 16-byte aligned just before the call instruction is executed.
4. Functions preserve the registers *rbx, rsp, rbp, r12, r13, r14, and r15* (callee-saved)
5. *rax, rdi, rsi, rdx, rcx, r8, r9, r10, r11* are scratch registers (caller-saved).

### Return value
| registers | description |
| - | - |
| rax | stores return value 1 - 64 bits |
| rdx:rax | stores return value 64 - 128 bits |
| rdi | stores pointer to return value larger than 128 bits |
1. If the return value does not fit in rdx:rax, the function allocates a storage space and return the pointer in rdi, as well as in rax