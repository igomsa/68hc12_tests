; ******************************************************************************
        ;; Assignment 2: Problem 1
; ******************************************************************************

; ******************************************************************************
        ;; This program sorts the contents of an array of nonzero signed
        ;; numbers, whose address is named ORDENAR. These numbers,
        ;; sorted from smallest to largest, are copied to an array
        ;; at address ORDENADOS. If two numbers are equal, only one of
        ;; them is copied. The ORDENAR array may be erased if needed.
; ******************************************************************************

; ******************************************************************************
        ;; ORDENAR DATA STRUCTURE DECLARATION

        ;; SIZE: Variable holding the count of unsorted numbers. It is
        ;; modified at runtime, since the count of unsorted numbers
        ;; varies as the program runs.

        ;; CANT: Constant holding the size of ORDENAR, i.e. the count
        ;; of numbers in the array at program start.
        ;; This constant is not modified at runtime since
        ;; the original size of ORDENAR stays invariant throughout.

        ;; ORDENAR: Address of the array of nonzero signed numbers to sort.

        ;; ORDENADOS: Destination array address for the ORDENAR numbers, sorted
        ;; from smallest to largest.
; ******************************************************************************

        org $1000
CANT:   ds 1

        org $1100
ORDENAR:  db -03, 122, -24, 118, 113, 88, 122, 88, 100, 15
        ;; In HEX:
            ;fd, 7a,   e8, 76,  71,  58, 7a, 58, 64,  0f

        ;; Sorted
            ;-24, -03, 15, 88, 100, 113, 118, 122
        ;; In HEX:
            ; e8,  fd, 0f, 58, 64,  71,  76,  7a

        org $1120
ORDENADOS:  ds 200

        org $1300
SIZE:   ds 1                    ;Size of unsorted array
EOA:    ds 2                    ;End of arrange
; ******************************************************************************
        ;; PROGRAM START
; ******************************************************************************
        org $1500

	;; lds #$3BFF              ; Load stack pointer.

        ;; Set the value of CANT
        movb #$0a,CANT

        ;; Set SIZE equal to the original size of the ORDENAR array.
        movb CANT,SIZE          ; This is done because initially the count of
                                ; unsorted numbers equals the
                                ; number of table elements.

        ;; Needed to initialize the result array to zero.
        ldx #ORDENADOS
        ldaa #200

        ;; Each entry of the result array is initialized to zero.
INIC_ORDENADOS:
        movb #00,1,X+
        dbeq A,INICIO:
        bra INIC_ORDENADOS

INICIO:
        ldd #ORDENAR
        addb CANT
        std EOA
        dec EOA+1

        ;; Load the array addresses into the index registers.
        ldx #ORDENAR              ; X <-- ORDENAR
        ldy #ORDENADOS            ; Y <-- ORDENADOS


        movb 0,X,0,Y            ; The first number of the series is assumed the largest.

; ******************************************************************************
        ;; ALGORITMO

        ;; The algorithm scans the whole array for a number smaller
        ;; than the first element of the table; if a smaller
        ;; number is found, it is swapped with the first element of the
        ;; table.

        ;; If there is no number smaller than the first,
        ;; the first number is copied to ORDENADOS and the position of the
        ;; index pointing to the "new smallest number" of ORDENAR
        ;; (index X) and the next position where that number will be sent
        ;; in ORDENADOS (index Y) are both incremented. Then SIZE is reduced.

        ;; If a repeated number is found, the array pointer is incremented
        ;; (X+1) and SIZE is reduced.
; ******************************************************************************

        ;; When all of ORDENAR has been scanned and there are no numbers smaller
        ;; than the first element, register B, used as offset
        ;; (X+B) to reference the number compared with the "smallest number",
        ;; returns to zero.
REINICIO:
        ldab #$00

CONTINUE:
        cpx EOA                 ; If X points to the end of the ORDENAR vector
        bge FINAL               ; finish the program.

        incb                    ; Otherwise, increment B and if greater than
        cmpb SIZE               ; the count of unsorted numbers, reduce
        bge REDUCE_ARRAY        ; SIZE and increment the pointers.

        lda 0,X                 ; Load the first array element into A
                                ; and define it as pivot ("smallest number").

        cmpa B,X                ; Compare the pivot with another ORDENAR number
        blt PIV_ES_MENOR
        beq IGUAL

        ;; If the pivot is greater, swap the pivot with the number being
        ;; compared.
PIV_ES_MAYOR:
        lda 0,X
        movb B,X,0,Y
        movb B,X,0,X
        staa B,X
        bra CONTINUE

        ;; If the pivot is smaller, compare with the next number
PIV_ES_MENOR:
        bra CONTINUE

        ;; If equal, the pivot pointer is incremented, removing
        ;; the repeated number.
IGUAL:
        inx
        dec SIZE
        bra CONTINUE

        ;; Once the pivot has been compared with the whole array, reduce
        ;; SIZE (count of unsorted numbers) and increment the pointers.
REDUCE_ARRAY:
        dec SIZE
        inx
        iny
        bra REINICIO

        ;; At the end, copy the last element to the end of ORDENADOS.
FINAL:
        movb 0,X,0,Y
        bra *
