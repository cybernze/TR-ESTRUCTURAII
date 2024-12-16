section .data
    prompt:     db "Ingrese números separados por espacios (finalice con ENTER): ", 0
    prompt_len: equ $ - prompt

    newline:    db 10, 0
    error:      db "Error al leer entrada.", 10, 0
    error_len:  equ $ - error

section .bss
    input_buf resb 4000000      ; Buffer para leer la entrada (suficiente para 10,000 números)
    A        resd 1000000       ; Espacio para almacenar hasta 10,000 números (32 bits por número)
    num_count resd 1         ; Variable para almacenar el número total de números leídos
    num_str  resb 12         ; Buffer para convertir un número a cadena

section .text
global _start

_start:
    ; Mostrar el mensaje para ingresar los números
    mov eax, 4
    mov ebx, 1
    mov ecx, prompt
    mov edx, prompt_len
    int 0x80

    ; Leer la entrada del usuario
    mov eax, 3              ; Número de la llamada al sistema (read)
    mov ebx, 0              ; Descriptor de archivo (0 = entrada estándar)
    mov ecx, input_buf      ; Dirección del buffer de entrada
    mov edx, 4000000          ; Leemos hasta 40,000 bytes (suficiente para 10,000 números)
    int 0x80                ; Llamada al sistema
    cmp eax, 0              ; Comprobar si la lectura fue exitosa
    jle error_exit          ; Si no, mostrar error

    ; Convertir la entrada en números enteros
    xor edi, edi                ; Índice para el buffer A (números leídos)
    mov esi, input_buf          ; Apuntador al comienzo del buffer de entrada

convert_loop:
    mov al, byte [esi]
    cmp al, 0                   ; Fin de la cadena (terminador null)
    je done_parsing
    cmp al, 10                  ; Fin de línea (ENTER)
    je done_parsing
    cmp al, ' '                 ; Saltar espacios
    jne parse_number
    inc esi
    jmp convert_loop

parse_number:
    xor eax, eax                ; Preparar el acumulador
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
    mov [A + edi*4], ebx        ; Guardar el número en A[edi]
    inc edi                     ; Incrementar el índice
    cmp edi, 1000000              ; Verificar límite máximo de 10,000 números
    je done_parsing
    jmp convert_loop

done_parsing:
    mov [num_count], edi        ; Guardar el número total de números leídos

    ; Ordenamiento de burbuja
    xor ecx, ecx                ; ecx = número de pasos
    mov ecx, [num_count]
    dec ecx                     ; Pasos = num_count - 1
bubble_sort_outer_loop:
    xor eax, eax
bubble_sort_inner_loop:
    mov edx, [A + eax*4]        ; A[a]
    mov esi, [A + (eax+1)*4]    ; A[a+1]
    cmp edx, esi
    jle no_swap
    mov [A + eax*4], esi        ; Intercambio
    mov [A + (eax+1)*4], edx
no_swap:
    inc eax
    cmp eax, ecx
    jl bubble_sort_inner_loop
    dec ecx
    cmp ecx, 0
    jg bubble_sort_outer_loop

    ; Imprimir el resultado ordenado sin pausa
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
