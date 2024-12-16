section .data
    prompt:     db "Ingrese números separados por espacios (finalice con ENTER): ", 0
    prompt_len: equ $ - prompt

    newline:    db 10, 0
    error:      db "Error al leer entrada.", 10, 0
    error_len:  equ $ - error

section .bss
    input_buf resb 400000       ; Espai per llegir la entrada (més gran per permetre més números)
    A        resd 100000        ; Espai per un màxim de 128 números (32 bytes per número)
    num_count resd 1         ; Variable per emmagatzemar el nombre total de números llegits
    num_str  resb 12         ; Buffer per convertir un número a cadena
    sleep_req resq 1         ; Estructura `timespec` (1 segon de pausa)

section .text
global _start

_start:
    ; Mostrar el missatge per introduir els números
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt
    mov edx, prompt_len
    int 0x80

    ; Llegir l'entrada de l'usuari
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buf
    mov edx, 512
    int 0x80
    cmp eax, 0
    jle error_exit

    ; Convertir l'entrada a números enters
    xor edi, edi                ; índex per al buffer A (números llegits)
    mov esi, input_buf          ; apuntador al començament del buffer d'entrada

convert_loop:
    mov al, byte [esi]
    cmp al, 0                   ; final de la cadena (null terminator)
    je done_parsing
    cmp al, 10                  ; final de línia (ENTER)
    je done_parsing
    cmp al, ' '                 ; saltar espais
    jne parse_number
    inc esi
    jmp convert_loop

parse_number:
    xor eax, eax                ; preparar acumulador
    xor ebx, ebx
parse_digit:
    mov al, byte [esi]
    cmp al, '0'
    jl store_number
    cmp al, '9'
    jg store_number
    sub al, '0'
    imul ebx, ebx, 10
    add ebx, eax
    inc esi
    jmp parse_digit

store_number:
    mov [A + edi*4], ebx        ; guardar el número a A[edi]
    inc edi                     ; incrementar índex
    cmp edi, 100000                ; verificar límit màxim
    je done_parsing
    jmp convert_loop

done_parsing:
    mov [num_count], edi        ; guardar el nombre de números llegits

    ; Bubble Sort
    xor ecx, ecx                ; ecx = nombre de passes
    mov ecx, [num_count]
    dec ecx                     ; nombre de passes = num_count - 1
bubble_sort_outer_loop:
    xor eax, eax
bubble_sort_inner_loop:
    mov edx, [A + eax*4]        ; A[a]
    mov esi, [A + (eax+1)*4]    ; A[a+1]
    cmp edx, esi
    jle no_swap
    mov [A + eax*4], esi        ; intercanvi
    mov [A + (eax+1)*4], edx
no_swap:
    inc eax
    cmp eax, ecx
    jl bubble_sort_inner_loop
    dec ecx
    cmp ecx, 0
    jg bubble_sort_outer_loop

    ; Imprimir el resultat ordenat amb espera d'1 segon
    xor edi, edi
print_loop:
    cmp edi, [num_count]
    jge exit
    mov eax, [A + edi*4]
    mov ecx, num_str
    call int_to_ascii
    mov eax, 4
    mov ebx, 1
    lea ecx, [num_str]
    mov edx, 12
    int 0x80
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    ; Pausar 1 segon després de mostrar cada número
    mov dword [sleep_req], 1    ; 1 segon
    mov dword [sleep_req + 4], 0 ; 0 nanosegons
    mov eax, 162                ; syscall: nanosleep
    lea ebx, [sleep_req]        ; direcció de la pausa
    xor ecx, ecx                ; sense interrupcions
    int 0x80

    inc edi
    jmp print_loop

error_exit:
    mov eax, 4
    mov ebx, 1
    mov ecx, error
    mov edx, error_len
    int 0x80

exit:
    mov eax, 1
    xor ebx, ebx
    int 0x80

int_to_ascii:
    xor edx, edx
    mov ebx, 10
    mov esi, ecx
    add esi, 11
    mov byte [esi], 0
convert_loop_ascii:
    dec esi
    xor edx, edx
    div ebx
    add dl, '0'
    mov [esi], dl
    test eax, eax
    jnz convert_loop_ascii
    ret
