nasm -f elf64 $1/main.asm -o $1/main.o
ld $1/main.o -o programs/$1