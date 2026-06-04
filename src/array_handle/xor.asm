; ******************************************************************************
        ;; Assignment 2: Problem 2
; ******************************************************************************

; ******************************************************************************
        ;; This program XORs the contents of two tables,
        ;; one at position DATOS, which holds
        ;; numbers, and the other at position MASCARAS, which holds masks.

        ;; The last DATOS number is XORed with the first mask,
        ;; until one of them runs out.

        ;; The XOR result is stored at memory location NEGAT,
        ;; provided the operation result is negative.

        ;; The last element of DATOS is $$FF,
        ;; while the last element of MASCARAS is $$FE.
; ******************************************************************************

; ******************************************************************************
        ;; DATA STRUCTURE DECLARATION
        ;; DATOS: Memory location holding a table of signed numbers.
        ;; MASCARAS: Memory location holding a table of masks.
        ;; NEGAT: Memory location holding a table of the XOR results
        ;; of the DATOS numbers with MASCARAS that are negative.
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
        ;; PROGRAM START
; ******************************************************************************
        org $2000

        lds #$3BFF              ; Load stack pointer.

        ;; Load the table addresses into the index registers.
        ldx #DATOS              ; X <-- DATOS
        ldy #NEGAT             ; Y <-- NEGAT
        pshy                    ; Since Y is used both to scan the tables
                                ; and to generate NEGAT, the "context"
                                ; switch is handled with the stack.
        ldy #MASCARAS               ; Y <-- MASCARAS


        ;; Since the size of DATOS is unknown, an $FF is searched in the table
        ;; to mark its end.
BUSCAR_$FF:
        ldaa 0,X                ; Register A holds the contents of the
                                ; position pointed to by X.
        cmpa #$FF
        beq SI_$FF

        ;; If A is not $$FF, X is incremented by one and the search
        ;; continues.
NO_$FF:
        inx
        bra BUSCAR_$FF

        ;; If the end of the table is reached, the program ends if the only
        ;; DATOS element is $$FF, or if the only MASCARAS element is $$FE.
SI_$FF:
        cpx #DATOS
        beq FINAL
        ldaa 0,Y
        cmpa #$FE
        beq FINAL

        ;; If DATOS and MASCARAS are not empty, X is reduced by one and the
        ;; DATOS values are XORed with the MASCARAS values in reverse order.
SIGUIENTE:
        dex
        ldaa 0,X
        eora 0,Y
        tsta
        blt NEGATIVO

        ;; If the XOR result is positive, proceed with the next
        ;; mask.
CONTINUE:
        iny
        bra SI_$FF

        ;; If the XOR result is negative, it is stored in NEGAT.
        ;; Since index Y had been used to scan MASCARAS,
        ;; the "context" is switched by pushing the current Y and pulling
        ;; the previous value (NEGAT position).
NEGATIVO:
        pshy
        leas 2,SP
        puly
        staa 1,Y+               ; This operation increments the NEGAT pointer.
        pshy
        leas -2,SP
        puly
        bra CONTINUE

        ;; End of program
FINAL:
        bra *
