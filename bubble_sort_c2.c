#include <stdio.h>
#include <stdlib.h>

//Función para realizar el Bubble Sort
void ordenar_bombolla(int array[], int n) {
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - i - 1; j++) {
            if (array[j] > array[j + 1]) {
                // Intercambiar elementos
                int temp = array[j];
                array[j] = array[j + 1];
                array[j + 1] = temp;
            }
        }
    }
}

int main() {
    int *array = NULL; // Array dinámico
    int TAMANY = 0;    // Número de elementos leídos

    // Leer los números de la entrada estándar
    printf("Introduïu els números separats per espais: ");
    
    // Aquí leemos hasta el final de la entrada estándar
    int num;
    while (scanf("%d", &num) == 1) {
        TAMANY++;
        array = (int*) realloc(array, TAMANY * sizeof(int)); // Redimensionar el array
        if (array == NULL) {
            fprintf(stderr, "Error al reservar memòria.\n");
            return 1;
        }
        array[TAMANY - 1] = num; // Guardar el número leído
    }

    if (TAMANY == 0) {
        printf("No s'han introduït números.\n");
        return 1;
    }

    // Ordenar el array
    ordenar_bombolla(array, TAMANY);

    // Imprimir el array ordenado
    printf("Numeros ordenats:\n");
    for (int i = 0; i < TAMANY; i++) {
        printf("%d\n", array[i]);
    }

    // Liberar la memoria
    free(array);

    return 0;
}
