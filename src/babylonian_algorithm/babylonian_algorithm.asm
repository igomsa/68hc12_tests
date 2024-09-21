;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             Definición de  Constantes y Variables
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                org $1000
LONG:           EQU $0a  ;Longitud de DATOS.

                org $1001
CANT:           ds 1  ;Cantidad de valores a buscar en DATOS que
                      ;se encuentren en CUAD.

                org $1002
CONT:           ds 1       ;Número de coincidencias entre DATOS y CUAD.

                org $1020
DATOS:          db  4, 9, 18, 4, 27, 63, 12, 32, 36, 15 ;Tabla con datos.
;; DATOS:          db  4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 4  ;Tabla con datos.

                org $1040
               ;;Números con raiz entera en posibles valores de DATOS.
CUAD:           db 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225


                org $1100
ENTERO:         ds  LONG       ;Raíz entera determinada a partir del algoritmo
                               ;babilónico.

        ;; Variables para cáculo de Babilónico.
                org $1300
R:              ds 2
T:              ds 2
V:              ds 2


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             Definición de etiquetas
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_char:               EQU $EE84 ;Definimos las direcciones de las subrutinas
put_char:               EQU $EE86 ;get_char y put_char.
CR:                     EQU $0D  ;Caracter de control, retorna el cursor al
                                 ;principio de la línea.
BS:                     EQU $08  ;Caracter de espacio.
LF:                     EQU $0A  ;Salto de línea, línea en blanco.
FIN:                    EQU $00  ;Para indicar que termino la linea o caracter.

MSG1:           db CR,LF
                fcc "INGRESE EL VALOR DE CANT (ENTRE 1 Y 99): "
                db BS,FIN

MSG2:           fcc " %d"
                db FIN

MSG3:           fcc "%d"
                db CR,LF,FIN

MSG4:           db CR,LF,CR,LF
                fcc "CANTIDAD DE NUMEROS ENCONTRADOS: %d"
                db CR,LF,FIN

MSG5:           db CR,LF,CR,LF
                fcc "ENTERO: "
                db FIN

MSG6:           fcc " %d,"
                db FIN

MSG7:           fcc " %d."
                db FIN

PRINTF:         EQU $EE88       ;Dirección de subrutina PRINTF.


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             Subrutina principal
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         org $2000
	lds #$3BFF              ; Carga puntero de pila.

        ;; Inicializa todas las variables en cero.
        movb #$00,CANT
        movb #$00,CONT
        movw #$0000,R
        movw #$0000,T
        movw #$0000,V
        ;; ldab D,X

PRINCIPAL:
        jsr LEER_CANT   ;Se solicita el valor de CANT del usuario.
        jsr BUSCAR      ;Se buscan CANT de datos en DATOS con
                        ;raíz entera.
        jsr Print_RESULT   ;Se imprimen los datos en ENTERO.
FINAL:
        bra *
	end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             LEER CANT
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

LEER_CANT:
        ;;Se solicita CANT del usuario.
        ldx #$0000
        ldd #MSG1
        jsr [PRINTF,x]

PRIMER_DIG:
        ;;Se toma CANT del teclado.
        ldx #$00
        jsr [get_char,x]
        ;; ldd #$31     ;Para depuración con simulador.

        ;; Se convierte el valor caputatado de ACII a entero.
        subd #$30
        tfr D,B

        ;; Se verifica que el valor esté entre 0 y 9.
        cmpb #9
        bhi LEER_CANT
        tstb
        blo LEER_CANT

        ;; Se almacena el caracter en CANT y se imprime lo ingresado.
        pshd
        ldaa #$10
        mul
        stab CANT

        ldx #$00
        ldd #MSG2
        jsr [PRINTF,x]  ;Se imprime el primer dígito.
        leas 2,SP

SEGUNDO_DIG:
        ldx #$00
        jsr [get_char,x]
        ;; ldd #$39     ;Para depuración con simulador.

        ;; Se convierte el valor caputatado de ACII a entero.
        subd #$30
        tfr D,B

        ;; Se verifica que el valor esté entre 1 y 9.
        cmpb #9
        bhi LEER_CANT
        cmpb #1
        blo LEER_CANT

        ;; Se almacena el caracter en CANT y se imprime lo ingresado.
        pshd
        ldaa CANT
        aba
        staa CANT
        ldx #$00
        ldd #MSG3
        jsr [PRINTF,x]  ;Se imprime el primer dígito.
        leas 2,SP
        rts

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;              BUSCAR
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BUSCAR:

        ;;Se inicializan los índices con las posiciones de los arreglos y la
        ;;tabla.
        ldx #DATOS             ;Posición de DATOS en X.
        ldy #ENTERO            ;Posición de ENTERO en Y.
        pshy                   ;Se apila el valor de Y para hacer cambio de
        ldy #CUAD              ;contexto e indexar con Y también a CUAD.

SECUENCIA:
        ;; Si CONT no ha alcanzado a CANT, y no se ha alcanzado el fin del DATOS,
        ;; siga comparando.
        ldaa CONT
        cmpa CANT
        bhs RETORNO1
        cpx #DATOS+LONG
        bhs RETORNO1

        ;; Si el número en DATOS no está en CUAD, proceda con el siguiente
        ;; número.
        cpy #CUAD+13
        bhs AUMENTAR_INDICE

        ;; Búsqueda de coincidencias entre CUAD y DATOS.
COMPARAR:
        ldaa 0,X
        cmpa 1,Y+
        bne SECUENCIA

COINCIDENCIA:
        ;;Se guardan los índices.
        pshy
        pshx
        psha
        jsr  RAIZ          ;Calcula la raíz cuadrada de la coincidencia.

        ;;Se recargan los índices
        pula
        pulx

        ;;Antes de recargar Y, se cambia de contexto para guardar el dato
        ;;coincidente en pila.
        leas 2,SP
        puly
        staa 1,Y+
        pshy                    ;Se guarda el índica al siguiente valor en ENTERO.
        leas -2,SP

        puly                 ;Se recarga Y.
        inc  CONT            ;Se incrementa el contador de coincidencias.

AUMENTAR_INDICE:
        inx                    ;Se incrementan el indice de DATOS.
        ldy  #CUAD             ;Se recarga el índice a CUAD para reinciar búsqueda.
        bra  SECUENCIA         ;Se continúa con la búsqueda.

RETORNO1:
        leas 2,SP        ;Se mueve el puntero de Pila para que apunte a la
                         ;dirección de retorno.
        rts              ;Seguir con secuencia del programa principal.

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             RAIZ CUADRADA CON ALG. ENTERO
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RAIZ:

        leas 2,SP
        pula                    ;Carga la coincidencia en A.
        sex A,D
        std V                  ;Se define la variable V como "x".
        movw V,R                ;Carga "x" a "r".
        movw #$00,T             ;Carga 0 a "t".

ALGORITMO:
        ldd T
        cmpd R                  ;Si(r!=t): calcular raíz
        bne  CALCULO

        ;;Se devuelve el valor de la raíz por la pila.
        ldd R
        tfr D,A
        psha
        leas -2,SP
        rts

CALCULO:
        movw R,T                ;Guardar valor de "r" en "t".

        ;;La división es D/X, por tanto se carga "x" en D y "r" en X
        ldd  V
        ldx  R

        idiv                    ;X = "x"/"r", D:resto
        ldd R                  ;B = "r"
        tfr D,B
        abx                     ;("x"/"r") + r
        tfr X,B
        lsrb                    ;1/2 * {("x"/"r") + r}
        sex B,D
        std R                   ;r = 1/2 * {("x"/"r") + r}
        bra  ALGORITMO



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             IMPRESIÓN DE RESULTADO
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Print_RESULT:
        ;;Se imprime CONT y el respectivo mensaje en pantalla.
        ldb  CONT
        sex B,D
        pshd
        ldx  #$00
        ldd  #MSG4
        jsr [PRINTF,X]
        leas 2,SP

        ;;Impresión del último mensaje con todas las raices encontradas.
        ldx  #$00
        ldd  #MSG5
        jsr [PRINTF,X]
        ldaa #$00
        dec CONT
PRINT_OTHERS:
        ldy #ENTERO
        cmpa CONT
        bhs  LAST_ONE
        psha
        ldab A,Y
        sex B,D
        pshd
        ldx  #$00
        ldd  #MSG6
        jsr [PRINTF,X]
        leas 2,SP
        pula
        inca
        bra PRINT_OTHERS


        ;;La última impresión se toma como un caso especial.
LAST_ONE:
        ldab A,Y
        sex B,D
        pshd
        ldx  #$00
        ldd  #MSG7
        jsr [PRINTF,X]
        leas 2,SP
RETURN2:
        rts
