; ******************************************************************************
        ;; Assignment 2: Problem 3
; ******************************************************************************

; ******************************************************************************
        ;; This program finds numbers divisible by 4 in an array of
        ;; signed 1B numbers, of variable size L, called DATOS. The
        ;; numbers divisible by 4 are copied to another array called DIV4.
        ;; The count of numbers divisible by 4 is stored in the variable
        ;; CANT4.
; ******************************************************************************

; ******************************************************************************
        ;; DATA STRUCTURE DECLARATION
        ;; DATOS: Array of signed 1B numbers.
        ;; DIV4: Holds the DATOS numbers that are divisible by 4.
        ;; L: Size of DATOS.
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
        ;; PROGRAM START
; ******************************************************************************

        org $1300
        lds #$3BFF              ; Load stack pointer.

        ;; Load the array addresses into the index registers.
        ldx #DATOS              ; X <-- DATOS
        ldy #DIV4               ; Y <-- DIV4

        ;; Clear registers A and B, and the contents of CANT4.
        ldaa #$00
        ldab #$00
        movb #00,CANT4
        psha                    ; Register A is used both to walk DATOS
                                ; and to store the numbers divisible
                                ; by 4 in DIV4. Hence the stack is used.

        ;; If the end of DATOS is reached, finish. Otherwise, load a
        ;; DATOS number into A and check whether it is positive or negative.
SIGUIENTE:
        cmpb #DATOS+L
        bhs FIN
        ldaa b,X
        tsta
        bgt POSITIVO

        ;; If the number is negative, take its two's complement.
NEGATIVO:
        nega

        ;; If positive, check whether the two LSBs of the number are zero
        ;; (number divisible by 4). If not, continue with the next
        ;; number.
POSITIVO:
        anda #$03
        tsta
        bne AVANZAR

        ;; If the two LSBs are zero, the number is divisible by 4,
        ;; so pull the offset for the DIV4 memory position and
        ;; store the number in that array. Then increment the
        ;; DIV4 offset and push that value.
DIVISIBLE:
        pula
        movb b,X,a,Y
        inca
        psha
        inc CANT4

        ;; To move to another number, increase register B.
AVANZAR:
        incb
        bra SIGUIENTE

        ;; End of program
FIN:
        bra *
