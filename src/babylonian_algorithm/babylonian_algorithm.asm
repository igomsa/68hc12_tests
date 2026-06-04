;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             Definition of Constants and Variables
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                org $1000
LONG:           EQU $0a  ;Length of DATOS.

                org $1001
CANT:           ds 1  ;Count of values to search for in DATOS that
                      ;are present in CUAD.

                org $1002
CONT:           ds 1       ;Number of matches between DATOS and CUAD.

                org $1020
DATOS:          db  4, 9, 18, 4, 27, 63, 12, 32, 36, 15 ;Table of data.
;; DATOS:          db  4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 4  ;Table of data.

                org $1040
               ;;Numbers with integer root among possible DATOS values.
CUAD:           db 4, 9, 16, 25, 36, 49, 64, 81, 100, 121, 144, 169, 196, 225


                org $1100
ENTERO:         ds  LONG       ;Integer root determined by the
                               ;Babylonian algorithm.

        ;; Variables for Babylonian calculation.
                org $1300
R:              ds 2
T:              ds 2
V:              ds 2


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             Label definitions
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_char:               EQU $EE84 ;Define the addresses of the get_char
put_char:               EQU $EE86 ;and put_char subroutines.
CR:                     EQU $0D  ;Control character, returns the cursor to
                                 ;the start of the line.
BS:                     EQU $08  ;Backspace character.
LF:                     EQU $0A  ;Line feed, blank line.
FIN:                    EQU $00  ;To indicate end of line or character.

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

PRINTF:         EQU $EE88       ;Address of PRINTF subroutine.


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             Main subroutine
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         org $2000
	lds #$3BFF              ; Load stack pointer.

        ;; Initialize all variables to zero.
        movb #$00,CANT
        movb #$00,CONT
        movw #$0000,R
        movw #$0000,T
        movw #$0000,V
        ;; ldab D,X

PRINCIPAL:
        jsr LEER_CANT   ;Request the value of CANT from the user.
        jsr BUSCAR      ;Search for CANT data items in DATOS with
                        ;an integer root.
        jsr Print_RESULT   ;Print the data in ENTERO.
FINAL:
        bra *
	end

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             LEER CANT
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

LEER_CANT:
        ;;Request CANT from the user.
        ldx #$0000
        ldd #MSG1
        jsr [PRINTF,x]

PRIMER_DIG:
        ;;Read CANT from the keyboard.
        ldx #$00
        jsr [get_char,x]
        ;; ldd #$31     ;For debugging with the simulator.

        ;; Convert the captured value from ASCII to integer.
        subd #$30
        tfr D,B

        ;; Verify that the value is between 0 and 9.
        cmpb #9
        bhi LEER_CANT
        tstb
        blo LEER_CANT

        ;; Store the character in CANT and print what was entered.
        pshd
        ldaa #$10
        mul
        stab CANT

        ldx #$00
        ldd #MSG2
        jsr [PRINTF,x]  ;Print the first digit.
        leas 2,SP

SEGUNDO_DIG:
        ldx #$00
        jsr [get_char,x]
        ;; ldd #$39     ;For debugging with the simulator.

        ;; Convert the captured value from ASCII to integer.
        subd #$30
        tfr D,B

        ;; Verify that the value is between 1 and 9.
        cmpb #9
        bhi LEER_CANT
        cmpb #1
        blo LEER_CANT

        ;; Store the character in CANT and print what was entered.
        pshd
        ldaa CANT
        aba
        staa CANT
        ldx #$00
        ldd #MSG3
        jsr [PRINTF,x]  ;Print the first digit.
        leas 2,SP
        rts

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;              BUSCAR
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BUSCAR:

        ;;Initialize the indices with the positions of the arrays and the
        ;;table.
        ldx #DATOS             ;Position of DATOS in X.
        ldy #ENTERO            ;Position of ENTERO in Y.
        pshy                   ;Push Y to switch context and also
        ldy #CUAD              ;index CUAD with Y.

SECUENCIA:
        ;; If CONT has not reached CANT, and the end of DATOS has not been reached,
        ;; keep comparing.
        ldaa CONT
        cmpa CANT
        bhs RETORNO1
        cpx #DATOS+LONG
        bhs RETORNO1

        ;; If the DATOS number is not in CUAD, proceed with the next
        ;; number.
        cpy #CUAD+13
        bhs AUMENTAR_INDICE

        ;; Search for matches between CUAD and DATOS.
COMPARAR:
        ldaa 0,X
        cmpa 1,Y+
        bne SECUENCIA

COINCIDENCIA:
        ;;Save the indices.
        pshy
        pshx
        psha
        jsr  RAIZ          ;Compute the square root of the match.

        ;;Reload the indices
        pula
        pulx

        ;;Before reloading Y, switch context to store the matching
        ;;datum on the stack.
        leas 2,SP
        puly
        staa 1,Y+
        pshy                    ;Save the index to the next value in ENTERO.
        leas -2,SP

        puly                 ;Reload Y.
        inc  CONT            ;Increment the match counter.

AUMENTAR_INDICE:
        inx                    ;Increment the DATOS index.
        ldy  #CUAD             ;Reload the CUAD index to restart the search.
        bra  SECUENCIA         ;Continue the search.

RETORNO1:
        leas 2,SP        ;Move the stack pointer so it points to the
                         ;return address.
        rts              ;Continue with the main program sequence.

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             SQUARE ROOT WITH INTEGER ALGORITHM
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RAIZ:

        leas 2,SP
        pula                    ;Load the match into A.
        sex A,D
        std V                  ;Define variable V as "x".
        movw V,R                ;Load "x" into "r".
        movw #$00,T             ;Load 0 into "t".

ALGORITMO:
        ldd T
        cmpd R                  ;If(r!=t): compute root
        bne  CALCULO

        ;;Return the root value via the stack.
        ldd R
        tfr D,A
        psha
        leas -2,SP
        rts

CALCULO:
        movw R,T                ;Save the value of "r" into "t".

        ;;The division is D/X, so "x" is loaded into D and "r" into X
        ldd  V
        ldx  R

        idiv                    ;X = "x"/"r", D:remainder
        ldd R                  ;B = "r"
        tfr D,B
        abx                     ;("x"/"r") + r
        tfr X,B
        lsrb                    ;1/2 * {("x"/"r") + r}
        sex B,D
        std R                   ;r = 1/2 * {("x"/"r") + r}
        bra  ALGORITMO



;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;             RESULT PRINTOUT
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Print_RESULT:
        ;;Print CONT and the respective message on screen.
        ldb  CONT
        sex B,D
        pshd
        ldx  #$00
        ldd  #MSG4
        jsr [PRINTF,X]
        leas 2,SP

        ;;Print the last message with all the roots found.
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


        ;;The last printout is handled as a special case.
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
