;***********************************************
;                  ASSIGNMENT #4
;***********************************************

#include "../../include/registers.inc"

;***********************************************
; INTERRUPT VECTOR REDIRECTION
;***********************************************

	org $3E4C               ; IRQ interrupt vector
	dw PTH_ISR

        org $3E70               ; RTI interrupt vector
        dw RTI_ISR

;***********************************************
; 	       MEMORY DECLARATION
;***********************************************
                org $1000
MAX_TCL         ds 1
TECLA           ds 1
TECLA_IN        ds 1
CONT_REB        ds 1
CONT_TCL        ds 1
PATRON          ds 1
BANDERAS        ds 1
NUM_ARRAY       ds 6
TECLAS          db $01, $02, $03, $04, $05, $06, $07, $08, $09, $0B, $00, $0E

;***********************************************
; 	     HARDWARE CONFIGURATION
;***********************************************
		org $1100

	lds #$3BFF              ; Load stack pointer.

        ;; Port A configuration for keypad
	movb #$01,PUCR          ; Enable pull-up resistor
                                ; for port A.

        movb #$F0,DDRA          ; PA4-7: output
                                ; PA0-3: input

        ;; RTI_ISR configuration
        movb #$14, RTICTL       ; Set 1ms interrupts
        bset CRGINT, #$80       ; Enable RTI interrupt

        ;; PTH_ISR configuration
        bset DDRJ,#$03           ; PJ1 write
	bclr PTJ,#$02            ; PJ1 as GND
        bset PIEH,#$01          ; Enable PH0 interrupt
        bclr PPSH,#$01          ; Select interrupt on
                                ; falling edge

;***********************************************
; 	   MAIN PROGRAM
;***********************************************

        ;; Initialize the variables to zero
        movb #$06,MAX_TCL
        movb #$FF,TECLA
        movb #$FF,TECLA_IN
        movb #$00,CONT_REB
        movb #$00,CONT_TCL
        movb #$00,PATRON
        movb #$00,BANDERAS

        ;; Array initialization
        ldaa MAX_TCL
        ldx  #NUM_ARRAY
INIT_ARR:
        movb #$FF,1,X+
        dbne A,INIT_ARR

        ;; Enable interrupts
	cli		        ; Load 0 into I in CCR

        ;ldab #$00               ; To use in accumulator-offset
                                ; indexed addressing
ESPERE:
        ;; If Array_OK, proceed to build the sequences of keys
        ;; read. Otherwise, keep waiting for TECLA_LISTA.
        brclr BANDERAS,$04,TAREA_TECLADO
        bra ESPERE
        end

;***********************************************
; 	             TAREA_TECLADO
;***********************************************
TAREA_TECLADO:

        tst CONT_REB                ; If the debounce process is not
        bne FIN_TAREA_TECLADO       ; done, count down one bounce.

        movb #$FF,TECLA

        jsr MUX_TECLADO

        brset TECLA,$FF,COMPROBAR_LISTA
COMPROBAR_LEIDA:
        brset BANDERAS,$02,COMPROBAR_VALIDA

        movb TECLA,TECLA_IN
        bset BANDERAS,$02
        movb #10,CONT_REB
        bra FIN_TAREA_TECLADO

COMPROBAR_VALIDA:
        ldaa TECLA
        cmpa TECLA_IN
        beq VALIDA

NO_VALIDA:
        movb #$FF,TECLA
        movb #$FF,TECLA_IN
        bra FIN_TAREA_TECLADO

VALIDA:
        bset BANDERAS,$01
        bra FIN_TAREA_TECLADO

COMPROBAR_LISTA:
        brclr BANDERAS,$01,FIN_TAREA_TECLADO

        bclr BANDERAS,$03
        jsr FORMAR_ARRAY

FIN_TAREA_TECLADO:
        lbra ESPERE



;***********************************************
; 	             FORMAR_ARRAY
;***********************************************
FORMAR_ARRAY:
        ldx #NUM_ARRAY               ; To access NUM_ARRAY by accumulator-offset
        ldab CONT_TCL                ; indexed addressing.

        ;; If the key is $0B jump to the delete sequence
        ldaa TECLA_IN
        cmpa #$0B
        beq BORRAR

        ;; If the key is $0E load the values to the LEDS.
        cmpa #$0E
        beq ENTER

CRG_TECLA:
        cmpb #$06               ; If the key to load is the third
        bge FIN_FORM_ARRY       ; and not B or E, do not load it.

        movb TECLA_IN,B,X       ; Otherwise, load it.
        incb                    ; When loading the next key, the index is added.

        cmpb #$07               ; If the index exceeds the range
        beq REINICIAR_TCL       ; it is reset.

        bra FIN_FORM_ARRY       ; Otherwise, end the sequence.

REINICIAR_TCL:
        ;; Reset VALOR and BANDERAS to accept new values.
        ldb #$00

FIN_FORM_ARRY:
        stab CONT_TCL
        movb #$FF,TECLA_IN      ; Set TECLA=$FF

        rts

BORRAR:
        ;; If $0B is loaded to TMP1, ignore and load next datum.
        tstb
        beq FIN_FORM_ARRY
        ;; cmpb #$06
        ;; beq BORRADO_ESPECIAL

        ;;  If the previous conditions are not met, reduce the index to
        ;; load the datum.
        decb
        movb #$FF,B,X

;;         bra FINALIZAR_BORRADO

;; BORRADO_ESPECIAL:
;;         decb
;;         movb #$FF,B,X

;; FINALIZAR_BORRADO
        bra FIN_FORM_ARRY
ENTER:
        ;; If $0E is loaded to TMP1, ignore and load next datum.
        tstb
        beq FIN_FORM_ARRY
        bset BANDERAS,$04
        bra FIN_FORM_ARRY

;***********************************************
; 	             MUX_TECLADO
;***********************************************
MUX_TECLADO:

        ldx #TECLAS
        movb #$EF,PORTA         ; Load the first pattern into PORTA to read the
                                ; key.

        ;movb AUX_PA,PORTA      ; An auxiliary variable is used since it is unknown
                                ; what PORTA will hold inside.

        movb #$00,PATRON        ; A variable is used to count the
                                ; number of patterns written to PORTA.

SIG_PATRN:
        ldab #$03               ; Accumulator B is used to index the
                                ; array.

        ldaa PATRON             ; If $EF, $DF, $BF, $7F were already written to PORTA,
        cmpa #$04               ; end the subroutine.
        beq FIN_MUX_TECLADO
        mul                     ; Otherwise, do D <- A*B to index the array
                                ; of values to load.

        brclr PORTA,$01,LEER    ; If a button in the first column was pressed,
                                ; add nothing to the offset.

        brclr PORTA,$02,A_1     ; If a button in the second column was pressed,
                                ; add 1 to the offset.

        brclr PORTA,$04,A_2     ; If a button in the third column was pressed,
                                ; add 2 to the offset.
CRGR_SGNT_PATRN:

        ;; If the previous pattern produced no key press, increment PATRON
        ;; and rotate the value loaded in port A.
        inc PATRON
        sec                     ; Since port A will be rotated, C is required
                                ; to be 1.
        rol PORTA
        ;movb AUX_PA, PORTA
        bra SIG_PATRN

        ;; Case of button in first column.
A_1:
        incb
        bra LEER

        ;; Case of button in second column.
A_2:
        addb #$02

LEER:
        ;; Move the corresponding value into TECLA.
        movb B,X,TECLA

FIN_MUX_TECLADO:
        rts


;***********************************************
; 	   PTH_ISR
;***********************************************
PTH_ISR:
        bclr BANDERAS,$04

        ;; Array initialization
        ldaa MAX_TCL
        ldx  #NUM_ARRAY
INIT_ARR1:
        movb #$FF,1,X+
        dbne A,INIT_ARR1
        bset PIFH, $01          ; Clear the interrupt.
        rti

;***********************************************
; 	             RTI_ISR
;***********************************************
RTI_ISR:
        ;; Reduce CONT_REB if it is nonzero.
        tst CONT_REB
        beq RETORNAR
        dec CONT_REB
RETORNAR:
        bset crgflg, #$80       ; Re-enable the interrupt
        rti
