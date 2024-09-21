; ******************************************************************************
        ;; Tarea 2: Problema 3
; ******************************************************************************

; ******************************************************************************
        ;; Este programa busca números divisibles por 4, en un arreglo de
        ;; números de 1B con signo, de tamaño variable L, llamado DATOS. Los
        ;; números divisibles por 4 son copiados a otro arreglo llamado DIV4
        ;; La cantidad de números divisibles por 4 se almacena en la variable
        ;; CANT4.
; ******************************************************************************

; ******************************************************************************
        ;; DECLARACIÓN DE ESTRUCTURAS DE DATOS
        ;; DATOS: Arreglo con números con signo de 1B.
        ;; DIV4: Contendrá los números de DATOS  que son divisibles por 4.
        ;; L: Tamaño de DATOS.
; ******************************************************************************

        org $1000
L:      equ #10
        org $1001
CANT4:  ds 1

        org $1100
DATOS:  fcb -24, 122, -24, 118, -60, 88, 122, 67, 16, 08
            ;fd, 7a,   e8, 76,  c4,  58, 7a, 43, 10,  08

        org $1200

DIV4:   ds 1


; ******************************************************************************
        ;; INICIO DEL PROGRAMA
; ******************************************************************************

        org $1300
        lds #$3BFF              ; Carga puntero de pila.

        ;; Se cargan las direcciones de los arreglos en los índices.
        ldx #DATOS              ; X <-- DATOS
        ldy #DIV4               ; Y <-- DIV4

        ;; Limpie los registros A y B, y el contenido de la variable CANT4.
        ldaa #$00
        ldab #$00
        movb #00,CANT4
        psha                    ; El registro A se usará tanto para recorrer
                                ; DATOS como para guardar los números divisibles
                                ; por 4 en DIV4. Por ello se emplea la pila.

        ;; Si se llegó al final de DATOS, finalice el programa. Si no, cargue un
        ;; número de DATOS en A y revise si el contenido es positivo o negativo.
SIGUIENTE:
        cmpb #DATOS+L
        bhs FIN
        ldaa b,X
        tsta
        bgt POSITIVO

        ;; Si el número es negativo, relice su complemento a dos.
NEGATIVO:
        nega

        ;; Si es positivo, revise si los primeros dos LSBs del número son cero
        ;; (número divisible por 4). Si no lo son, prosiga con el siguiente
        ;; número.
POSITIVO:
        anda #$03
        tsta
        bne AVANZAR

        ;; Si los dos primeros LSBs son cero, el número es divisible por 4,
        ;; entonces desapile el offset para la posición de memoria de DIV4 y
        ;; guarde el número en dicho arreglo. Seguidamente incremente el valor
        ;; del offset para DIV4 y apile ese valor.
DIVISIBLE:
        pula
        movb b,X,a,Y
        inca
        psha
        inc CANT4

        ;; Para seguir con otro número, aumente el valor del registro B.
AVANZAR:
        incb
        bra SIGUIENTE

        ;; Fin del programa
FIN:
        bra *
