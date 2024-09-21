; ******************************************************************************
        ;; Tarea 2: Problema 1
; ******************************************************************************

; ******************************************************************************
        ;; Este programa ordena el contenido de un arreglo de números con signo,
        ;; diferentes de cero, cuya dirección se llama ORDENAR. Estos números,
        ;; ordenados de menor a mayor, se copian en la dirección a un arreglo
        ;; de dirección ORDENADOS. Si dos números son iguales, se copia solo uno de
        ;; ellos. El arreglo ORDENAR puede ser borrado de ser necesario.
; ******************************************************************************

; ******************************************************************************
        ;; DECLARACIÓN DE ESTRUCTURAS DE ORDENAR

        ;; SIZE: Variable que contiene la cantidad de números no ordenados. Es
        ;; modificada en tiempo de ejecución, ya que la cantidad de números no
        ;; ordenados varía con el transcurso del programa.

        ;; CANT: Constante que contiene el tamaño de ORDENAR, es decir la cantidad
        ;; de números presentes en el arreglo al inicio del programa.
        ;; Esta constante no es modificada en tiempo de ejecución pues a lo
        ;; largo del programa el tamaño original de ORDENAR es invariante.

        ;; ORDENAR: Dirección de arreglo de números con signo, diferentes de cero, a ordenar.

        ;; ORDENADOS: Dirección de arreglo de destino de números presentes en ORDENAR, ordenados
        ;; de menor a mayor.
; ******************************************************************************

        org $1000
CANT:   ds 1

        org $1100
ORDENAR:  db -03, 122, -24, 118, 113, 88, 122, 88, 100, 15
        ;; En HEX:
            ;fd, 7a,   e8, 76,  71,  58, 7a, 58, 64,  0f

        ;; Ordenados
            ;-24, -03, 15, 88, 100, 113, 118, 122
        ;; En HEX:
            ; e8,  fd, 0f, 58, 64,  71,  76,  7a

        org $1120
ORDENADOS:  ds 200

        org $1300
SIZE:   ds 1                    ;Tamaño de arreglo sin ordenar
EOA:    ds 2                    ;End of arrange
; ******************************************************************************
        ;; INICIO DEL PROGRAMA
; ******************************************************************************
        org $1500

	;; lds #$3BFF              ; Carga puntero de pila.

        ;; Se define el valor de CANT
        movb #$0a,CANT

        ;; Se iguala el valor de SIZE al tamaño original del arreglo ORDENAR.
        movb CANT,SIZE          ; Esto se hace porque inicialmente la cantidad de
                                ; números que no se han ordenado es igual al
                                ; número elementos de la tabla.

        ;; Necesario para inicializar arreglo de resultados en cero.
        ldx #ORDENADOS
        ldaa #200

        ;; Se inicializa cada entrada del arreglo de resultados en cero.
INIC_ORDENADOS:
        movb #00,1,X+
        dbeq A,INICIO:
        bra INIC_ORDENADOS

INICIO:
        ldd #ORDENAR
        addb CANT
        std EOA
        dec EOA+1

        ;; Se cargan las direcciones de los arreglos en los índices.
        ldx #ORDENAR              ; X <-- ORDENAR
        ldy #ORDENADOS            ; Y <-- ORDENADOS


        movb 0,X,0,Y            ; El primer número de SERIE se asume como el mayor.

; ******************************************************************************
        ;; ALGORITMO

        ;; El algoritmo recorre todo el arreglo en búsqueda de un número menor
        ;; que el primer elemento de la tabla, en caso de que se encuentre un
        ;; número menor, este se cambia de posición con el primer elemento de la
        ;; tabla.

        ;; En caso de que no haya ningún número menor que el primero,
        ;; se copia el primer número a ORDENADOS y se incrementa la posición del
        ;; índice al que apuntan tanto el "nuevo número menor" de ORDENAR
        ;; (índice X) como la siguiente posición a la que se enviará dicho
        ;; nuevo número en ORDENADOS (índice Y). Seguidamente se reduce SIZE.

        ;; Si se encuentra un número repetido, se incrementa el puntero del arreglo
        ;; ()X+1) y se reduce SIZE.
; ******************************************************************************

        ;; Cuando se ha recorrido todo ORDENAR y ya no hay números menores
        ;; que el primer elemento, el registro B, que se usa como offset
        ;; (X+B) para referenciar al número a comparar con el "número menor",
        ;; vuelve a cero.
REINICIO:
        ldab #$00

CONTINUE:
        cpx EOA                 ; Si X apunta al final del vector de ORDENAR
        bge FINAL               ; finalice el programa.

        incb                    ; Si no, incremente B y si es mayor que
        cmpb SIZE               ; la cantidad de números no ordenados, reduzca
        bge REDUCE_ARRAY        ; SIZE e incremente los punteros.

        lda 0,X                 ; Carga el primer elemento del arreglo en A
                                ; y se define como pivote ("número menor").

        cmpa B,X                ; Compare el pivote con otro número de ORDENAR
        blt PIV_ES_MENOR
        beq IGUAL

        ;; Si pivote es mayor, cambie de posición el pivote con el número en
        ;; comparación.
PIV_ES_MAYOR:
        lda 0,X
        movb B,X,0,Y
        movb B,X,0,X
        staa B,X
        bra CONTINUE

        ;; Si el pivote es menor, compare con el siguiente número
PIV_ES_MENOR:
        bra CONTINUE

        ;; Si es igual, se incrementa el puntero a pivote y con esto se elimina
        ;; el número repetido.
IGUAL:
        inx
        dec SIZE
        bra CONTINUE

        ;; Cuando se haya comparado el pivote con todo el arreglo, reduzca
        ;; SIZE (tamaño de números sin ordenar) e incremente los punteros.
REDUCE_ARRAY:
        dec SIZE
        inx
        iny
        bra REINICIO

        ;; Al finalizar, copie el último elemento al final de ORDENADOS.
FINAL:
        movb 0,X,0,Y
        bra *
