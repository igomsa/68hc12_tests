; ******************************************************************************
        ;; Tarea 2: Problema 2
; ******************************************************************************

; ******************************************************************************
        ;; Este programa realiza una XOR con el contenido de dos tablas,
        ;; una que se encuentra en la posición DATOS, la cual contiene
        ;; números, y la otra en la posición MASCARAS, la cual contiene máscaras.

        ;; Se realiza la XOR del último número en DATOS con la primera máscara,
        ;; hasta que una de ella se acabe.

        ;; El resultado de las XOR se guarda en la posción de memoria NEGAT,
        ;; siempre y cuando el resultado de la operación sea negativo.

        ;; El último elemento de DATOS es $$FF,
        ;; mientras que el último elemento en MASCARAS es $$FE.
; ******************************************************************************

; ******************************************************************************
        ;; DECLARACIÓN DE ESTRUCTURAS DE DATOS
        ;; DATOS: Posición de memoria que contiene una tabla con números son signo.
        ;; MASCARAS: Posición de memoria que contiene una tabla con máscaras.
        ;; NEGAT: Posición de memoria que contiene una tabla con el resultado
        ;; XOR de los números de DATOS con MASCARAS y que son negativos.
; ******************************************************************************

        org $1050
DATOS:    fcb  100, 67, 122, 88, -45, 99, 24, 122, 03, 255
            ;  64, 43, 7a, 58,  d3,  63, 18, 7a, 03,  ff

        org $1150
MASCARAS:   fcb -03, -122, -21, -118, -113, -88, -43, -25, -101, 254
            ;    fe, 85,   e8, 76,  71,  58, 7a, 43, 64,  fe

        org $1300
NEGAT: ds 1

; ******************************************************************************
        ;; INICIO DEL PROGRAMA
; ******************************************************************************
        org $2000

        lds #$3BFF              ; Carga puntero de pila.

        ;; Se cargan las direcciones de las tablas en los índices.
        ldx #DATOS              ; X <-- DATOS
        ldy #NEGAT             ; Y <-- NEGAT
        pshy                    ; Ya que Y se usa tanto para barrer las tablas
                                ; como para generar NEGAT, la variación
                                ; "entorno" se maneja con la pila.
        ldy #MASCARAS               ; Y <-- MASCARAS


        ;; Ya que no se sabe el tamaño de DATOS, se busca un $FF en la tabla
        ;; para delimitar su final.
BUSCAR_$FF:
        ldaa 0,X                ; El registro A tiene el contenido de la
                                ; posición apuntada por X.
        cmpa #$FF
        beq SI_$FF

        ;; Si el valor de A no es $$FF, se incrementa X en uno y se sigue
        ;; buscando.
NO_$FF:
        inx
        bra BUSCAR_$FF

        ;; Si se llegó al final de la tabla, se termina el programa si el único
        ;; elemento de DATOS es $$FF, o si el único elemento de MASCARAS es $$FE.
SI_$FF:
        cpx #DATOS
        beq FINAL
        ldaa 0,Y
        cmpa #$FE
        beq FINAL

        ;; Si DATOS y MASCARAS no están vacíos, se reduce X en uno y se hace
        ;; la XOR de los valores de DATOS con los de MASCARAS en orden inverso.
SIGUIENTE:
        dex
        ldaa 0,X
        eora 0,Y
        tsta
        blt NEGATIVO

        ;; Si el resultado de la XOR es positivo, se procede con la siguiente
        ;; máscara.
CONTINUE:
        iny
        bra SI_$FF

        ;; Si el resultado de la XOR es negativo, se guarda en NEGAT.
        ;; Ya que el índice Y se había estado usando para recorrer MASCARAS,
        ;; se cambia de "entorno" apilando el actual valor de Y, y desapilando
        ;; el valor pasado (posición de NEGAT).
NEGATIVO:
        pshy
        leas 2,SP
        puly
        staa 1,Y+               ; Esta operación incrementa el puntero a NEGAT.
        pshy
        leas -2,SP
        puly
        bra CONTINUE

        ;; Fin del programa
FINAL:
        bra *
