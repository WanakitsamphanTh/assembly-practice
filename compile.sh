for af in $1/*.asm; do
    [ -e "$af" ] || continue
    name=$(basename "$af" .asm)
    nasm -f elf64 "$af" -o "$1/$name.o"
done

obj_files=($1/*.o)
gcc "${obj_files[@]}" -o ./programs/$1 -no-pie -lc