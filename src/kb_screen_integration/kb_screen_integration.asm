;***********************************************
;                  Micros Project
;***********************************************

#include "../../include/registers.inc"

;***********************************************
; INTERRUPT VECTOR REDIRECTION
;***********************************************

	org $3E4C               ; PTH interrupt vector.
	dw CALCULAR

        org $3E52               ; ATD interrupt vector.
        dw ATD_ISR

        org $3E5E               ; TCNT overflow interrupt vector.
        dw TCNT_ISR

        org $3E66               ; Comparator Ch4 interrupt vector.
        dw OC4_ISR

        org $3E70               ; RTI interrupt vector.
        dw RTI_ISR

;***********************************************
; 	       MEMORY DECLARATION
;***********************************************
		org $1000

;*********** VARIABLES TIPO BIT ***********
BANDERAS        ds 2

;*********** MODO CONFIG ***********
V_LIM           ds 1

;*********** TECLADO MATRICIAL ***********
MAX_TCL         ds 1
TECLA           ds 1
TECLA_IN        ds 1
NUM_VUELTAS     ds 1
CONT_REB        ds 1
CONT_TCL        ds 1
PATRON          ds 1
NUM_ARRAY       ds 2

;*********** ATD_ISR ***********
BRILLO          ds 1
POT             ds 1

;*********** PANT_CTRL ***********
TICK_EN         ds 2
TICK_DIS        ds 2

;*********** CALCULAR ***********
VELOC           ds 1

;*********** TCNT_ISR ***********
TICK_VEL        ds 1

;*********** CONV_BIN_BCD ***********
BIN1            ds 1
BIN2            ds 1
BCD1            ds 1
BCD2            ds 1

;*********** BIN_BCD ***********
BCD_L           ds 1
BCD_H           ds 1

;*********** BCD_7SEG ***********
DISP1           ds 1
DISP2           ds 1
DISP3           ds 1
DISP4           ds 1

;*********** PATRON_LEDS ***********
LEDS            ds 1

;*********** OC4_ISR  ***********
CONT_DIG        ds 1
CONT_TICKS      ds 1
DT              ds 1
CONT_7SEG       ds 2
CONT_200        ds 1

;*********** CONT_DELAY  ***********
CONT_DELAY      ds 1
D2mS            ds 1
D250uS          ds 1
D40uS           ds 1
D60uS           ds 1
CLEAR_LCD       ds 1
ADD_L1          ds 1
ADD_L2          ds 1

;*********** DISPONIBLE  ***********
VAR             ds 1

;*********** TABLAS  ***********
        org $1030
TECLAS          db $01, $02, $03, $04, $05, $06, $07, $08, $09, $0B, $00, $0E
SEGMENT         db $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $6F, $0A

;*********** LCD INITIALIZATION ***********
iniDsp          db $04
FUNCTION_SET1   db $28
FUNCTION_SET2   db $28
ENTRY_MODE      db $06
DISPLAY_ON_OFF  db $01

;*********** MESSAGES START ***********
Inicio_de_mensajes:     ds 1
EOM:    EQU $04
MSG0: FCC "  RADAR  623"       ;LIBRE | COMP X2
       db EOM
MSG1: FCC "  MODO LIBRE"
       db EOM
MSG2: FCC "  MODO CONFIG"
       db EOM
MSG3: FCC " VELOC. LIMITE"
       db EOM
MSG4: FCC " MODO MEDICION"
       db EOM
MSG5: FCC "SU VEL. VEL.LIM"
       db EOM
MSG6: FCC "  CALCULANDO..."
       db EOM
MSG8: FCC "  ESPERANDO..."
       db EOM

;***********************************************
; 	     HARDWARE CONFIGURATION
;***********************************************
		org $2000

	lds #$3BFF               ; Load stack pointer.

        ;; LEDS configuration
	movb #$FF,DDRB          ; PB: write
        bset DDRJ,#$02          ; PJ1 write
	bclr PTJ,#$02           ; PJ1 as GND

        movb #$FF,DDRP         ; PP: write
        movb #$0F,PTP          ; 7 seg disabled.
	movb #$00,PORTB         ; LEDS off initially

        ;; Keypad configuration.
        movb #$01,PUCR          ; Enable PA pull-up resistors
        movb #$F0,DDRA          ; PA4-7: output
                                ; PA0-3: input

        ;; PK configuration for LCD
        movb #$FF,DDRK

        ;; ;; RTI_ISR configuration
        movb #$23,RTICTL       ; Set 1ms interrupts
        bset CRGINT,#$80       ; To enable RTI interrupt


        ;; PTH configuration.
        bclr DDRH,$C0           ; PH7,6: read
        bclr PPSH,#$09          ; Select interrupt on
                                ; falling edge
        movb #$00,PIEH          ; Disable all PH interrupts.


        ;; OC4_ISR configuration
        movb #$80,TSCR1         ; Enable TCNT and TFFCA function
        movb #$03,TSCR2         ; Prescaler of 8. TCNT ovf. disabled.
        movb #$10,TIOS          ; Enable IOS4
        movb #$01,TCTL1         ; Channel 4 as Toggle
        movb #$10,TIE           ; Enable TC4

        ;; ATD configuration
        movb #$C2,ATD0CTL2
        ldab #160
DEC_B:
        dbne B,DEC_B
        movb #$30,ATD0CTL3
        movb #$97,ATD0CTL4
        ;; movb #$87,ATD0CTL5


;***********************************************
; 	   VARIABLE_INITIALIZATION
;***********************************************

;*********** VARIABLES TIPO BIT ***********
        ;; X:X:CALC_TICKS:ALERTA:PANT_FLAG:ARRAY_OK:TCL_LEIDA:TCL_LISTA
        movw #$0000,BANDERAS
        ;; movb #$00,BANDERAS+1

;*********** MODO CONFIG ***********
        movb #$00,V_LIM

;*********** TECLADO MATRICIAL ***********
        movb #$02,MAX_TCL
        movb #$FF,TECLA
        movb #$FF,TECLA_IN
        movb #$00,NUM_VUELTAS
        movb #$00,CONT_REB
        movb #$00,CONT_TCL
        movb #$00,PATRON

        ;; Array initialization
        ldaa MAX_TCL
        ldx  #NUM_ARRAY
INIT_ARR:
        movb #$FF,1,X+
        dbne A,INIT_ARR

;*********** ATD_ISR ***********
        movb #$00,BRILLO
        movb #$00,POT

;*********** PANT_CTRL ***********
        movw #$0000,TICK_EN
        movw #$0000,TICK_DIS

;*********** CALCULAR ***********
        movb #$00,VELOC

;*********** TCNT_ISR ***********
        movb #$00,TICK_VEL

;*********** CONV_BIN_BCD ***********
        movb #$00,BIN1
        movb #$BB,BIN2
        movb #$00,BCD1
        movb #$00,BCD1

;*********** BIN_BCD ***********
        movb #$00,BCD_L
        movb #$00,BCD_H

;*********** BCD_7SEG ***********
        movb #$00,DISP1
        movb #$00,DISP2
        movb #$00,DISP3
        movb #$00,DISP4

;*********** PATRON_LEDS ***********
        movb #$00,LEDS

;*********** OC4_ISR  ***********
        movb #$00,CONT_DIG
        movb #100,CONT_TICKS
        movb #$00,DT
        movb #$00,CONT_7SEG
        movb #$02,CONT_200

;*********** CONT_DELAY  ***********
        movb #$00,CONT_DELAY
        movb #$64,D2mS
        movb #$0D,D250uS
        movb #$02,D40uS
        movb #$03,D60uS
        movb #$00,CLEAR_LCD
        movb #$80,ADD_L1
        movb #$C0,ADD_L2

;*********** DISPONIBLE  ***********
        movb #$5C,VAR


	cli		        ; Carga 0 en I en CCR

        ;; To generate 50 KHz ticks.
        ldd TCNT
        addd #60
        std TC4


;***********************************************
; 	   MAIN PROGRAM
;***********************************************
        ;; jsr INICIALIZAR_LCD
        bra M_CONF

ESPERAR:
        brset PTIH,$C0,M_MED
        movb #$00,VELOC
        bclr BANDERAS+1,$10       ; Clear the ALERTA flag.
        bclr TSCR2,$80
        bclr PIEH,$09           ; Disable PH(3,0) interrupt.
        brclr PTIH,$C0,M_CONF
M_LIB:
        ;; bclr BANDERAS+1,$04
        jsr MODO_LIBRE
        bra ESPERAR
M_MED:
        bset TSCR2,$80          ; Enable TCNT interrupt.
        bset PIEH,$09          ; Enable PH(3,0) interrupt
        jsr MODO_MEDICION
        bra ESPERAR
M_CONF:
        jsr MODO_CONFIG
        bra ESPERAR
        end

;***********************************************
;          MODO LIBRE
;***********************************************
MODO_LIBRE:

        pshy
        pshx
        pshb
        psha

        ;; If the message was already printed, do not print it.
        ldaa BANDERAS+1
        anda #$C0
        cmpa #$00
        beq FIN_MODO_LIBRE

        ;; ;; If the message was already printed, do not print it.
        ;; brclr BANDERAS+1,$C0,SOLICITAR_VLIM

        movb #$04,LEDS          ; Load the respective LEDS pattern.

        movb #$BB,BIN1
        movb #$BB,BIN2

        ;; Load message
        jsr INICIALIZAR_LCD
        ldx #MSG0
        ldy #MSG1
        jsr CARGAR_LCD

        ;; ;; Indicate message already printed.
        bclr BANDERAS+1,$C0
FIN_MODO_LIBRE:

        pula
        pulb
        pulx
        puly

        rts


;***********************************************
; 	   MODO CONFIG
;***********************************************
        ;; Description:
        ;; This subroutine implements MODO CONFIG.
        ;; In this mode the maximum allowed speed is configured.
        ;; This subroutine verifies that the maximum speed
        ;; entered by the user is between 45 and 90 km/h.
        ;; It is the first subroutine on board power-up, and until
        ;; a value is entered

        ;; Inputs:
        ;; ARRAY_OK flag via memory
        ;; V_LIM variable via memory, from BIN_BCD

        ;; Outputs:
        ;; LEDS variable via memory
        ;; BIN1 variable via memory
        ;; ARRAY_OK variable via memory

MODO_CONFIG:

        pshy
        pshx
        pshb
        psha

        ;; If the message was already printed, do not print it.
        ldaa BANDERAS+1
        anda #$C0
        cmpa #$40
        beq SOLICITAR_VLIM


        movb V_LIM,BIN1

        ;; ;; If the message was already printed, do not print it.
        ;; brset BANDERAS+1,$40,SOLICITAR_VLIM

        movb #$01,LEDS          ; Load the respective LEDS pattern.

        ;; Load message
        jsr INICIALIZAR_LCD
        ldx #MSG2
        ldy #MSG3
        jsr CARGAR_LCD

        ;; Indicate message already printed.
        ldaa BANDERAS+1
        anda #$3F
        adda #$40
        staa BANDERAS+1

SOLICITAR_VLIM:

        jsr TAREA_TECLADO

        ;; Check whether ARRAY_OK is enabled.
        brclr BANDERAS+1,#$04,NO_ARRAY_OK

        ;; If ARRAY_OK=1, the speed limit is converted to BIN and
        ;; verified to be in the accepted range.

        bclr BANDERAS+1,$04     ; Since, whether or not the entered value
                                ; is in the acceptable range,
                                ; the ARRAY_OK flag is always cleared,
                                ; it is cleared here.

        jsr BCD_BIN             ; The value is converted to BIN here.

        ;; Here it is checked whether 45km/h =< V_LIM =< 90km/h.
        ldaa V_LIM
        cmpa #45
        blt FUERA_DE_RANGO
        cmpa #90
        bgt FUERA_DE_RANGO


        ;; If the value is within the acceptable range, it is stored
        ;; to BIN1.
DENTRO_DE_RANGO:
        movb V_LIM,BIN1
        ;; bclr BANDERAS+1,$04
        bra FIN_MODO_CONFIG

        ;; If the value is not in the accepted range, that value
        ;; keeps waiting for a valid value to be entered.
FUERA_DE_RANGO:
        movb #$00,V_LIM
        movb #$00,BIN1
        movb #$BB,BIN2
        bra FIN_MODO_CONFIG

        ;; This is entered when a valid amount has not yet been
        ;; entered on the keypad.
NO_ARRAY_OK:
        tst V_LIM
        bne FIN_MODO_CONFIG

        bra SOLICITAR_VLIM

        ;; The subroutine ends here.
FIN_MODO_CONFIG:

        pula
        pulb
        pulx
        puly

        rts

;***********************************************
;          MODO_MEDICION
;***********************************************
        ;; Description:
        ;; This subroutine implements MODO COMPETENCIA.
        ;; In this mode the PANT_CTRL subroutine is called if
        ;; VELOC != 0. On entering, BIN1 and BIN2 are ensured
        ;; to be $BB, so that the 7SEG initially stay
        ;; off. When this mode is exited, the VELOC and ALERTA
        ;; variables are cleared.

        ;; Inputs:
        ;; VELOC variable via memory

        ;; Outputs:
        ;; BIN1 variable via memory
        ;; BIN2 variable via memory
        ;; VELOC variable via memory
        ;; ALERTA variable via memory

MODO_MEDICION:
        pshy
        pshx
        pshb
        psha

        ;; If the message was already printed, do not print it.
        ldaa BANDERAS+1
        anda #$C0
        cmpa #$80
        beq MEDICION_RET

        movb #$BB,BIN1
        movb #$BB,BIN2


        movb #$02,LEDS          ; Load the respective LEDS pattern.

        ;;--------------- Load message ---------------
        ;; The messages loaded are:
        ;; X: MODO MEDICION
        ;; Y:   ESPERANDO
        jsr INICIALIZAR_LCD
        ldx #MSG4
        ldy #MSG8
        jsr CARGAR_LCD


        ;; Indicate message already printed.
        ldaa BANDERAS+1
        anda #$3F
        adda #$80
        staa BANDERAS+1

MEDICION_RET:
        ;; If PH0_PRES=1, print "CALCULANDO".
        brclr BANDERAS,$02,CONTINUAR_MED

        ;; Load "CALCULANDO" message
        jsr INICIALIZAR_LCD
        ldx #MSG4
        ldy #MSG6
        jsr CARGAR_LCD


        bclr BANDERAS,$02

        ;;------- General subroutine functions ------
CONTINUAR_MED:
        ;; $BB is loaded into BIN1 and BIN2 to ensure they
        ;; are in this state at the start of the subroutine.
        ;; movb #$BB,BIN1
        ;; movb #$BB,BIN2

        ;; Test whether VELOC=0. If so, the subroutine ends.
        tst VELOC
        beq FIN_MEDICION
        jsr PANT_CTRL           ; If VELOC != 0, call PANT_CTRL.
        ;; movb #$00,VELOC         ; Clear VELOC at the end of the subroutine.
        ;; bset BANDERAS+1,$10     ; Clear the ALERTA flag.


FIN_MEDICION:

        pula
        pulb
        pulx
        puly

        rts

;***********************************************
; 	             RTI_ISR
;***********************************************
        ;; Description:
        ;; This subroutine reduces the debounce counter every 1 ms.

        ;; Inputs:
        ;; CONT_REB variable via memory

        ;; Outputs:
        ;; CONT_REB variable via memory

RTI_ISR:
        ;; Reduce CONT_REB if it is nonzero.
        tst CONT_REB
        beq RETORNAR
        dec CONT_REB

RETORNAR:
        bset crgflg, #$80       ; Re-enable the interrupt
        rti

;***********************************************
;          TCNT_ISR
;***********************************************
        ;; Description:
        ;; This subroutine performs two tasks:
        ;; 1. Increment TICK_VEL for the VELOC calculation.
        ;; 2. Control of message-change delay times on the
        ;; displays. For that, TICK_EN and TICK_DIS are decremented if
        ;; not zero. When TICK_EN=0, PANT_FLAG=1 is set. When
        ;; TICK_DIS=0, PANT_FLAG=0 is set.

        ;; Inputs:
        ;; TICK_EN variable via memory
        ;; TICK_DIS variable via memory

        ;; Outputs:
        ;; TICK_EN variable via memory
        ;; TICK_DIS variable via memory
        ;; PANT_FLAG flag via memory

TCNT_ISR:
;;         dec VAR
;;         tst VAR
;;         bne CCCC
;;         movb #$5D,VAR
;; LEDSSS:
;;         tst LEDS
;;         bne REFILL
;;         movb #$01,LEDS
;; REFILL:
;;         lsl LEDS
;; CCCC:
        ;; The speed ticks are incremented.
        ldaa TICK_VEL
        cmpa #$FF
        bhs NO_INC
        inc TICK_VEL
NO_INC:

        brclr BANDERAS+1,$20,TCNT_ISR_FIN

        ;; ;; If PANT_FLAG=1, check whether TICKS_DIS=0.
        ;; brset BANDERAS+1,$08,ASK_PANT_FLG_TCNT

        ;; Check whether TICK_EN=0, in which case PANT_FLG=1 is set
        ldd TICK_EN
        cpd #$0000
        bls HAB_PANT_FLG

        ;; Decrement TICK_EN if nonzero.
        ldx TICK_EN
        dex
        stx TICK_EN
        ;; com LEDS

        bra TCNT_ISR_FIN

;; ASK_PANT_FLG_TCNT:
HAB_PANT_FLG:
        ;; Check whether TICK_EN=0, in which case PANT_FLG=1 is set
        ldd TICK_DIS
        cpd #$0000
        bls DESHAB_PANT_FLG

        ;; Enable PANT_FLG.
        bset BANDERAS+1,$08
        ;; Decrement TICK_DIS if nonzero.
        ldx TICK_DIS
        dex
        stx TICK_DIS

        bra TCNT_ISR_FIN

DESHAB_PANT_FLG:
        ;; Disable PANT_FLG and ALERTA.
        bclr BANDERAS+1,$18
TCNT_ISR_FIN:
        ;; Clear the overflow interrupt flag.
        bset TFLG2,$80
        rti

;***********************************************
;          ATD_ISR
;***********************************************
;; Description:
        ;; This subroutine implements MODO CONFIG.
        ;; In this mode the maximum allowed speed is configured.
        ;; This subroutine verifies that the maximum speed
        ;; entered by the user is between 45 and 90 km/h.
        ;; It is the first subroutine on board power-up, and until
        ;; a value is entered

        ;; Inputs:
        ;; CONT_7SEG variable via memory
        ;; CONT_TICKS variable via memory
        ;; CONT_200 variable via memory
        ;; DISP1 variable via memory
        ;; DISP2 variable via memory
        ;; DISP3 variable via memory
        ;; DISP4 variable via memory

        ;; Outputs:
        ;; CONT_7SEG variable via memory
        ;; CONT_TICKS variable via memory
        ;; CONT_200 variable via memory
        ;; PTP variable via memory
        ;; PORTB variable via memory
        ;; PTJ variable via memory

ATD_ISR:
        ;; The 6 conversions are read and all summed into RR1 to
        ;; then determine their average.
        ldd ADR00H
        addd ADR01H
        addd ADR02H
        addd ADR03H
        addd ADR04H
        addd ADR05H

        ;; Determine the average of the measurement.
        ldx #6
        idiv

        ;; The measured value is stored in POT.
        tfr X,Y
        ;; staa POT         ; The average is stored in Nivel_PROM.

        ;; Brightness is computed as: [BRILLO = (20 X POT)/255].
        ldd #20
        ldx #255
        emul                    ; Compute (20 X POT)
        idiv                    ; Compute (20 X POT)/255
        tfr X,A
        staa BRILLO

        ;; Re-enable the ATD interrupt.
        ;; movb #$87,ATD0CTL5
        rti

;***********************************************
;          OC4_ISR
;***********************************************
;; Description:
        ;; This subroutine implements MODO CONFIG.
        ;; In this mode the maximum allowed speed is configured.
        ;; This subroutine verifies that the maximum speed
        ;; entered by the user is between 45 and 90 km/h.
        ;; It is the first subroutine on board power-up, and until
        ;; a value is entered

        ;; Inputs:
        ;; CONT_7SEG variable via memory
        ;; CONT_TICKS variable via memory
        ;; CONT_200 variable via memory
        ;; DISP1 variable via memory
        ;; DISP2 variable via memory
        ;; DISP3 variable via memory
        ;; DISP4 variable via memory

        ;; Outputs:
        ;; CONT_7SEG variable via memory
        ;; CONT_TICKS variable via memory
        ;; CONT_200 variable via memory
        ;; PTP variable via memory
        ;; PORTB variable via memory
        ;; PTJ variable via memory

OC4_ISR:
        ;; Counter to refresh the digit value.
        ldd CONT_7SEG           ; Increment the 7SEG counter
        addd #$01               ; to keep track of the 100ms
        std CONT_7SEG           ; at which BCD_7SEG must be called.

        ;; Check whether CONT_7SEG has reached its maximum.
        ;; ldd CONT_7SEG
        cpd #5000
        lbne ASK_TICKS        ; If it reached the maximum,
        movw #$0000,CONT_7SEG   ; reload CONT_7SEG to zero.
        jsr CONV_BIN_BCD        ; Convert BIN1 and BIN2 to BCD,
        jsr BCD_7SEG            ; and convert BCD variables to 7SEG.

        ;; Check whether CONT_200 reached its maximum.
        dec CONT_200
        tst CONT_200
        lbhi ASK_TICKS         ; If maximum not reached, finish.
        movb #$02,CONT_200      ; If reached, reload the counter.
        movb #$87,ATD0CTL5      ; Re-enable
        jsr PATRON_LEDS

        ;; ;; Counter to enable the ATD conversion.
        ;; ldd CONT_200            ; Increment the ATD counter
        ;; addd #$01               ; to enable the conversion every
        ;; std CONT_200            ; 200ms from the potentiometer.

ASK_TICKS:
        ;; Counter for duty-cycle control.
        dec CONT_TICKS          ; Count down the tick counter,
        tst CONT_TICKS          ; which acts as N in the display
        bls CERO                ; multiplexing handling.

        ;; Determine the enable pulse width for the LEDs.
        ldaa CONT_TICKS         ; Taking N=100 and K=POT,
        ldab #100               ; DT is determined by
        subb BRILLO                ; computing DT = N-K.
        stb DT
        cmpa DT                 ; If DT >= CONT_TICKS, enable
        bls HAB_LED             ; the 7SEG and disable the LEDs.

        lbra FIN_OC4_ISR

        ;; LEDS enable handling.
HAB_LED:
        movb #$FF,PTP           ; Load $FF, since it enables
                                ; no special value on the 7SEG.
        bclr PTJ,#$02           ; Enable the LEDs.
        movb LEDS,PORTB         ; Load the LEDS value to PORTB.
        bra FIN_OC4_ISR

        ;; DIGIT enable handling.
CERO:
        movb #100,CONT_TICKS    ; When CONT_TICKS has reached zero,
                                ; reload CONT_TICKS to 100.

        inc CONT_DIG            ; Also, CONT_DIG is incremented here
        bset PTJ,#$02           ; and the LEDs are disabled.

        ;; Check which digit to write, according to
        ;; the contents of CONT_DIG.
        brset CONT_DIG,#$03,HAB_DISP4
        brset CONT_DIG,#$02,HAB_DISP3
        brset CONT_DIG,#$01,HAB_DISP2

        ;; Enable digit 1
HAB_DISP1:
        ;; DISP1 enabling is special, it enables in two
        ;; cases, when CONT_DIG is 00 and when the count exceeded the value

        tst CONT_DIG            ; DISP1 enabling is special,
        beq LOAD_DISP1           ; since it enables when the count
        movb #$00,CONT_DIG      ; is zero or when it overflowed. In the
                                ; latter case the digit must be enabled
                                ; and the counter reset.

LOAD_DISP1:
        movb #$07,PTP           ; Enable DISP1 on PP
        movb DISP1,PORTB         ; and load its value to PORTB.
        bra FIN_OC4_ISR

        ;; Enable digit 2
        ;; Digit 2 has a peculiarity: when the tens are not
        ;; printed, it stays disabled.
HAB_DISP2:
        ldaa DISP2
        cmpa #$3F               ; If the digit is 0,
        beq FIN_OC4_ISR         ; it is not printed.

        ;; If not 0, enable DISP2 and load the corresponding
        ;; value into PORTB.
        movb #$0B,PTP           ; Enable DISP2.
LOAD_DISP2:
        movb DISP2,PORTB         ; Load digit to PORTB.
        bra FIN_OC4_ISR

        ;; Enable digit 3
HAB_DISP3:
        movb #$0D,PTP           ; Enable DISP3
LOAD_DISP3:
        movb DISP3,PORTB         ; Load digit to PORTB.
        bra FIN_OC4_ISR

        ;; Enable digit 4
        ;; Digit 4 has a peculiarity: when the tens are not
        ;; printed, it stays disabled.
HAB_DISP4:
        ldaa DISP4
        cmpa #$3F               ; If the digit is 0,
        beq FIN_OC4_ISR         ; it is not printed.
        movb #$0E,PTP           ; Enable DISP4
LOAD_DISP4:
        movb DISP4,PORTB         ; Load digit to PORTB.
        bra FIN_OC4_ISR

FIN_OC4_ISR:
        ;; Cont_Delay handling for LCD
        tst CONT_DELAY
        beq CARGAR_TC4          ; If CONT_DELAY != 0,
        dec CONT_DELAY          ; decrement its value.
CARGAR_TC4:
        ;; Read TCNT and reload the next value to compare in
        ;; TC4.
        ldd TCNT
        addd #60
        std TC4
        movb #$10,TFLG1
        rti

;***********************************************
;          PANT_CTRL
;***********************************************
        ;; Description:
        ;; This subroutine computes the time delay,
        ;; based on VELOC, to change the message on the
        ;; display when the vehicle is 100m from the goal and then
        ;; once the vehicle has passed it. For this it computes
        ;; the tick counters needed to show the
        ;; first message and to change it after the vehicle
        ;; passes the display. Since the tick calculation is done
        ;; only the first time in the subroutine, a flag called
        ;; CALC_TICKS is used. The ticks are decremented
        ;; by the TCNT_ISR subroutine. On a new call to the
        ;; subroutine, PANT_FLAG=1 is awaited to change the message
        ;; on the display and show the speed value and the
        ;; speed limit on the 7SEG display.

        ;; Also, this subroutine sets the ALERTA flag if the
        ;; speed is outside the accepted range.

        ;; Inputs:
        ;; VELOC variable via memory
        ;; V_LIM variable via memory
        ;; TICK_EN flag via memory

        ;; Outputs:
        ;; BIN1 variable via memory
        ;; BIN2 variable via memory
        ;; ALERTA flag via memory

PANT_CTRL:

        pshy
        pshx
        pshb
        psha

        ;; movb #$FF,LEDS
        bclr PIEH,$09           ; Disable PH(3,0) interrupt.

        ;; Check whether 30km/h <= VELOC <= V_LIM
        ldaa VELOC
        cmpa #30
        lbls FUERA_RANG
        cmpa #99
        lbhs FUERA_RANG
        cmpa V_LIM
        lbhi ALERTA
        bra ASK_CALC_TICKS


FUERA_RANG:
        ldaa VELOC
        cmpa #$AA
        beq ASK_PANT_FLG

        movw #$0001,TICK_EN       ; Load 1 to turn the display on
                                ; quickly, holding the alert
                                ; message.

        movw #$005C,TICK_DIS      ; Load the respective value to
                                ; keep the display on
                                ; for 2s.
;; CARGAR_AA_VELOC:
        ;; Sequence run when the measured speed exceeds the
        ;; limits.
        movb #$AA,VELOC         ; Load "--" into the speed 7SEG.

        bset BANDERAS+1,$20     ; Set CALC_TICKS=1.

        bra ASK_PANT_FLG

ALERTA:
        bset BANDERAS+1,$10       ; Set the ALERTA flag.

ASK_CALC_TICKS:
        ;; If CALC_TICKS=0, the number of ticks is computed.
        brclr BANDERAS+1,$20,CALC_TICKS

        ;; movb #$00,LEDS
ASK_PANT_FLG:
        ;; If PANT_FLAG=1, check whether it is on.
        brset BANDERAS+1,$08,PANT_FLAG_EN

        ;; If PANT_FLAG=0, the speed message is loaded.
PANT_FLAG_DIS:
        ldaa BIN1
        cmpa #$BB
        beq FIN_PANT_CTRL

        ;; Load ESPERANDO... message
        jsr INICIALIZAR_LCD
        ldx #MSG4
        ldy #MSG8
        jsr CARGAR_LCD

        ;; $BB is loaded into BIN1 and BIN2 to ensure they
        ;; are in this state at the start of the subroutine.
        movb #$BB,BIN1
        movb #$BB,BIN2
        movb #$00,VELOC
        bset PIEH,$09           ; Enable PH(3,0) interrupt.
        bclr BANDERAS+1,$20     ; Set CALC_TICKS=0.
        bra FIN_PANT_CTRL

PANT_FLAG_EN:
        ldaa BIN1
        cmpa #$BB
        bne FIN_PANT_CTRL

        ;; If within the display-on time and printing
        ;; the value for 100m from the goal, the respective
        ;; message is loaded.
        jsr INICIALIZAR_LCD
        ldx #MSG4
        ldy #MSG5
        jsr CARGAR_LCD

        ;; The speed-limit and measured-speed values are loaded
        ;; to be shown on the 7SEG.
        movb V_LIM,BIN1
        movb VELOC,BIN2
        bra FIN_PANT_CTRL

CALC_TICKS:
        ;; The ticks for the display on and off states
        ;; are computed.
        ldaa VELOC              ; tick time from the
        tfr A,X                 ; speed.
        ldd #36000                ; Convert km/h to m/s and determine the
        idiv
        tfr X,D

        ;; The tick value is computed from the estimated
        ;; time to travel 100m, relative to the computed
        ;; average speed.
        ;; The following formula is used:
        ;; Tiempo = (8*(2^16)*Ticks)/(24x10^6)
        ;;        => Ticks = ((24x10^6)*Time)/(8*(2^16))
        ;;        => Ticks = 46*Time
        ldy #46
        emul
        ldx #100
        idiv
        tfr X,D

        std TICK_EN             ; Load ticks for enable.
        ;; lsld                    ; TICK_DES=TICK_EN*2, multiply by 2.
        std TICK_DIS            ; Load ticks for disable, and since
        bset BANDERAS+1,$20     ; Set CALC_TICKS=1.

        ;; movb #$0F,LEDS


FIN_PANT_CTRL:

        pula
        pulb
        pulx
        puly

        rts
        ;; jsr INICIALIZAR_LCD

;***********************************************
;          CALCULAR
;***********************************************
        ;; Description:
        ;; This is the interrupt service subroutine for
        ;; port H. It is enabled in MODO_MEDICION. It computes
        ;; the vehicle speed in KM/H. There are two
        ;; different interrupts:
        ;; * PH3: Sets TICK_VEL to zero.
        ;; * PH0: TICK_VEL is read and the vehicle speed is computed
        ;; from that value. Also, TICK_VEL is reset and the
        ;; "CACULANDO..." message is printed.

        ;; Inputs:
        ;; TICK_VEL variable via memory

        ;; Outputs:
        ;; VELOC variable via memory

CALCULAR:

        tst CONT_REB
        bne SALIR_CALCULAR

        brset PIFH,#$01,PH0_PULSADO
        brset PIFH,#$08,PH3_PULSADO
        bra SALIR_CALCULAR

        ;; Start tick counting to compute speed.
PH3_PULSADO:
        bset BANDERAS,$02
        movb #$00,TICK_VEL
        movb #$0A,CONT_REB
        bra SALIR_CALCULAR

PH0_PULSADO:
        ;; The speed is computed from TICK_VEL.
        ;; We have:
        ;;  VELOC = (40m/(TICK_VEL*20)) * (3600/1000) [km/h]
        ;;  VELOC = 144/(TICK_VEL*T_int_overflow) [km/h]
        ;; However, since T_int_overflow = 0.021845333.. it is
        ;; required to scale that value. So T_int_overflow is
        ;; multiplied by 10000 to get 4 significant figures of
        ;; accuracy. To get the value in the desired
        ;; scale, these values are then divided by 10000^2 and
        ;; multiplied by the km/h conversion value: 144.

        ;; Compute TICK_VEL*T_int_overflow*10000
        ldaa #218
        ldab TICK_VEL
        mul
        tfr D,X                 ; Free RR1 for later use.

        ;; Compute (144*10000)
        ldd #144
        ldy #10000
        emul

        ;; Compute (144*10000)/(TICK_VEL*T_int_overflow*10000)
        ;;      = (144)/(TICK_VEL*T_int_overflow)
        ;;      = VELOC
        ediv

        tfr Y,A

        staa VELOC
        movb #$00,TICK_VEL
        movb #$0A,CONT_REB
        bclr BANDERAS,$02

SALIR_CALCULAR:
        bset PIFH,$FF          ; Clear the interrupt.
        rti

;***********************************************
; 	   BCD_BIN
;***********************************************
        ;; Description:
        ;; This subroutine converts the values entered on the
        ;; matrix keypad in BCD format to binary
        ;; format.

        ;; Inputs:
        ;; Num_Array array via memory

        ;; Outputs:
        ;; V_LIM variable via memory

BCD_BIN:

        pshy
        pshx
        pshb
        psha

        ;; NUM_ARRAY is accessed by constant-offset indexed
        ;; addressing with J.
        ldx #NUM_ARRAY

        ;; First the MSNibble of BCD is loaded and then converted
        ;; to BIN.
        ldaa 1,X+
        ldab #10
        mul

        ;; Then the LSNibble of BCD is loaded and the already-converted
        ;; MSNibble is added to it.
        ldaa 0,X
        aba

        ;; The resulting value is loaded into V_LIM
        staa V_LIM

        pula
        pulb
        pulx
        puly

        rts

;***********************************************
; 	             TAREA_TECLADO
;***********************************************
        ;; Description:
        ;; This is a management subroutine in charge of
        ;; calling MUX_TECLADOS to capture a
        ;; pressed key. It also handles the actions related
        ;; to debouncing and the held-key concept,
        ;; reading the key until it is released.

        ;; Inputs:
        ;; CONT_REB variable via memory
        ;; TECLA variable via memory, from MUX_TECLADO
        ;; TCL_LISTA flag via memory
        ;; TCL_LEIDA flag via memory

        ;; Outputs:
        ;; TECLA_IN variable via memory
        ;; ARRAY_OK flag via memory

TAREA_TECLADO:

        pshy
        pshx
        pshb
        psha

        tst CONT_REB                ; If the debounce process is not
        bne FIN_TAREA_TECLADO       ; done, count down one bounce.

        ;; This guarantees that each time a key is to be read,
        ;; if the key was not read, it will be $FF.
        movb #$FF,TECLA

        ;; A key is read and it is checked whether a valid
        ;; key value was read.
        jsr MUX_TECLADO
        brset TECLA,$FF,COMPROBAR_LISTA

        ;; If the read key seems to have a valid value,
        ;; the TECLA_LEIDA flag is then checked to see if it was
        ;; enabled.

COMPROBAR_LEIDA:
        ;; Check whether TECLA_LEIDA=1. This indicates that this
        ;; is the first key read.
        brset BANDERAS+1,$02,COMPROBAR_VALIDA

        ;; If TECLA_LEIDA=0, TECLA is loaded into TECLA_IN, TECLA_LEIDA
        ;; is enabled, and the debounce counter CONT_REB is
        ;; reloaded.
        movb TECLA,TECLA_IN
        bset BANDERAS+1,$02
        movb #10,CONT_REB
        bra FIN_TAREA_TECLADO

        ;; If the key seems to have a valid element, and the
        ;; TECLA_LEIDA flag=1 (first key already read),
        ;; it is checked whether after 10ms the key is the
        ;; same.
COMPROBAR_VALIDA:
        ldaa TECLA
        cmpa TECLA_IN
        beq VALIDA

        ;; If the key read after 10ms does not have the
        ;; previously measured value (a bounce or a signal
        ;; different from the expected patterns was measured), TECLA and
        ;; TECLA_IN are reloaded with $FF.
NO_VALIDA:
        movb #$FF,TECLA
        movb #$FF,TECLA_IN
        bclr BANDERAS+1,$03
        bra FIN_TAREA_TECLADO

        ;; If the key read after the debounce counter is the
        ;; same as the one previously read, then the
        ;; TECLA_LISTA flag is set.
VALIDA:
        bset BANDERAS+1,$01
        bra FIN_TAREA_TECLADO

        ;; If the read key does not seem to have a valid value,
        ;; the TECLA_LISTA flag is then checked to see if it was
        ;; enabled.
COMPROBAR_LISTA:
        brclr BANDERAS+1,$01,FIN_TAREA_TECLADO

        ;; If TECLA_LISTA=1 (the key was read and validated),
        ;; the TCL_LISTA and TCL_LEIDA flags are cleared and
        ;; FORMAR_ARRAY is called to store the read key.
        bclr BANDERAS+1,$03
        jsr FORMAR_ARRAY

        ;; If TECLA_LISTA=0 (the key was $FF and is not valid),
        ;; return to the main subroutine.
FIN_TAREA_TECLADO:

        pula
        pulb
        pulx
        puly

        rts



;***********************************************
; 	             FORMAR_ARRAY
;***********************************************
FORMAR_ARRAY:
        pshy
        pshx
        pshb
        psha

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
        cmpb MAX_TCL            ; If the key to load is the third
        bhs FIN_FORM_ARRY       ; and not B or E, do not load it.

        movb TECLA_IN,B,X       ; Otherwise, load it.
        incb                    ; When loading the next key, the index is added.

        ;; cmpb MAX_TCL               ; If the index exceeds the range
        ;; beq REINICIAR_TCL       ; it is reset.

        bra FIN_FORM_ARRY       ; Otherwise, end the sequence.

REINICIAR_TCL:
        ;; Reset VALOR to accept new values.
        ldb #$00

FIN_FORM_ARRY:
        stab CONT_TCL
        movb #$FF,TECLA_IN      ; Set TECLA=$FF

        pula
        pulb
        pulx
        puly

        rts

BORRAR:
        ;; If $0B is loaded to TMP1, ignore and load next datum.
        tstb
        beq FIN_FORM_ARRY

        ;;  If the previous conditions are not met, reduce the index to
        ;; load the datum.
        decb
        movb #$FF,B,X
        bra FIN_FORM_ARRY
ENTER:
        ;; If $0E is loaded to TMP1, ignore and load next datum.
        cmpb MAX_TCL
        blo FIN_FORM_ARRY
        bset BANDERAS+1,$04
        bra REINICIAR_TCL

;***********************************************
; 	             MUX_TECLADO
;***********************************************
MUX_TECLADO:
        pshy
        pshx
        pshb
        psha

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

        pula
        pulb
        pulx
        puly

        rts



;***********************************************
;          PATRON_LEDS
;***********************************************
        ;; Description:
        ;; This subroutine is in charge of updating the LEDS value
        ;; with the PB7-PB3 sweep pattern, whenever the
        ;; ALERTA flag=1. If ALERTA=0, it turns off PB7 and PB3.

        ;; Inputs:
        ;; ALERTA flag via memory

        ;; Outputs:
        ;; LEDS variable via memory

PATRON_LEDS:
        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        pshy
        psha
        pshb


        ;; Since the mode bits are independent of the alert bits, they
        ;; must be saved and restored once the alert bits have
        ;; been modified.
        ldab LEDS
        andb #$07               ; Extract the mode bits.
        pshb                    ; Push the mode LEDS.

        ;; Check whether ALERTA=1.
        brclr BANDERAS+1,$10,LEDS_APAGADOS

        ;; If ALERTA=1, start the sequence.
        ldaa LEDS
        anda #$F8               ; Load the alert bits into R1.

        lsra                    ; If maximum has not been reached,
                                ; shift the register.

        ;; Check whether the alert bits have reached
        ;; their maximum value.
        cmpa #$04               ; If maximum is reached, reset the
        ble REINICIAR_CUENTA    ; pattern.


        bra RECUPERAR_BITS_MODO ; Restore the mode bits.

        ;; If ALERTA=0, turn off the alert bits.
REINICIAR_CUENTA:
        ldaa #$80               ; Place a 1 in the MSB.

        bra RECUPERAR_BITS_MODO ; Restore the mode bits.

        ;; If ALERTA=0, turn off the LEDs.
LEDS_APAGADOS:
        lda #$00                ; Turn off the LEDs.

        ;; The mode bits are restored here.
RECUPERAR_BITS_MODO:
        pulb                    ; Pull the mode LEDS.

        aba                     ; Combine the mode and alert bits,
        staa LEDS                ; and store the value in LEDS.

FIN_PATRON_LEDS:
        ;; Restore accumulators and indices.

        pulb
        pula
        puly
        pulx

        rts


;***********************************************
;          CONV_BIN_BCD
;***********************************************
        ;; Description:
        ;; This subroutine handles the binary-to-BCD
        ;; conversion. It is in charge of calling the
        ;; BIN_BCD conversion subroutine, for which the
        ;; BIN1 BIN2 addresses are passed via index X. Also, it
        ;; is in charge of writing a $B in the digits that must
        ;; stay off.

        ;; Inputs:
        ;; BIN1 variable via memory
        ;; BIN2 variable via memory
        ;; BCD_L variable via memory

        ;; Outputs:
        ;; BIN1 variable address via index X
        ;; BIN2 variable address via index X
        ;; BCD1 variable via memory
        ;; BCD2 variable via memory

CONV_BIN_BCD:
        pshx
        pshy
        psha
        pshb

        ;; Check whether BIN1 contains $BB
        brset BIN1,$BB,CONV_BIN2

        ;; If it does not contain $BB, convert the variable to BCD.
        ldx #BIN1               ; The address of the variable to convert
                                ; is passed via index X.

        jsr BIN_BCD             ; Call BIN_BCD subroutine.

        movb BCD_L,BCD2         ; The BCD2 value is received through
                                ; the BCD_L variable.


        ;; ldaa BCD_L
        ;; anda $0F
        ;; tbne A,BCD

        ;; If it contains $BB, BIN1 stays intact and the
        ;; respective BIN2 value is loaded.
CONV_BIN2:

        ;; Check whether BIN1 contains $BB
        brset BIN2,$BB,FIN_CONV_BIN_BCD

        ;; If it does not contain $BB, convert the variable to BCD.
        ldx #BIN2               ; The address of the variable to convert
                                ; is passed via index X.

        jsr BIN_BCD             ; Call BIN_BCD subroutine.

        movb BCD_L,BCD1         ; The BCD1 value is received through
                                ; the BCD_L variable.

FIN_CONV_BIN_BCD:
        pulb
        pula
        puly
        pulx
        rts

;***********************************************
;          BIN_BCD
;***********************************************
        ;; Description:
        ;; This subroutine implements binary-to-BCD conversion.
        ;; It uses the algorithm seen in class, which
        ;; mainly consists of 4 steps:

        ;; 1) Load the binary number into BIN.
        ;; 2) Shift the BIN number left successively.
        ;;
        ;; 3) Analyze the nibbles resulting from the shift.
        ;; 4) If any nibble is greater than or equal to 5, before the
        ;; last shift, 4 must be added to that nibble.

        ;-------- SP
        ;
        ;-------- SP-1
        ; TEMP
        ;-------- SP-2
        ; LOW
        ;--------

        ;; Inputs:
        ;; BIN1 variable address via index X
        ;; BIN2 variable address via index X

        ;; Outputs:
        ;; BCD1 variable via memory
        ;; BCD2 variable via memory
        ;; BCD_L variable via memory
        ;; BCD_H variable via memory

BIN_BCD:
        ;; The stack context is saved to avoid problems if
        ;; the registers were in use before the subroutine.
        psha
        pshb
        pshx

        ldaa 0,X                ; Load the value to convert into R1.
        ldab #$07               ; Counter of shifted bits.
        movb #$00,BCD_L         ; Initialize BCD_L to zero.
        movb #$00,BCD_H         ; Initialize BCD_H to zero.

        ;; Conversion of CONT_FREE starts here
NEXT_BIT_BCD:
        lsla                    ; Shift one bit of R1.
        rol BCD_L               ; C is loaded into BCD_L.
        rol BCD_H               ; C is loaded into BCD_H.

        ;; R1 is loaded into TEMP here
        psha                    ; SP-1 is used as the TEMP variable.
        ldaa BCD_L
        anda #$0F               ; Check whether the least significant
        cmpa #$05               ; nibble of BCD_L has a 5.

        blt NOT_5_ON_L_BCD      ; If not, check the most
                                ; significant nibble.

        adda #$03               ; If it does, add 3 to the least
                                ; significant nibble.
NOT_5_ON_L_BCD:
        ;; R1 is loaded into LOW here
        psha                    ; SP-1 is used as the TEMP variable.
        ldaa BCD_L
        anda #$F0               ; Check whether the most significant
        cmpa #$50               ; nibble of BCD_L has a 5.

        blt NOT_5_ON_H_BCD      ; If not, continue with the
                                ; algorithm.

        adda #$30               ; If it does, add 3 to the most
                                ; significant nibble.

NOT_5_ON_H_BCD:

        adda 0,SP               ; LOW is added to R1 here.
        sta BCD_L               ; and the result is loaded into BCD_L.

        ins                     ; Adjust the stack to point to TEMP.
        pula                    ; Load TEMP into R1.

        dbeq B,FINALIZAR_BCD    ; If all bits were shifted, go
                                ; to the end.

        bra NEXT_BIT_BCD        ; Otherwise, continue with the algorithm.
FINALIZAR_BCD:
        ;; Shift the last bit in binary.
        lsla
        rol BCD_L
        rol BCD_H

        ;; Restore the stack context.
        pulx
        pulb
        pula

        rts

;***********************************************
;          BCD_7SEG
;***********************************************
        ;; Description:
        ;; This subroutine handles the BCD-to-7SEG
        ;; conversion. It identifies the contents of the
        ;; values to load in BCD and from them
        ;; determines an offset to index a table that
        ;; holds the valid values to load into the 7SEG
        ;; according to the BCD value.

        ;; Inputs:
        ;; BIN1 variable via memory
        ;; BIN2 variable via memory

        ;; Outputs:
        ;; DISP1 variable via memory
        ;; DISP2 variable via memory
        ;; DISP3 variable via memory
        ;; DISP4 variable via memory

BCD_7SEG:
        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        psha

        ldx #SEGMENT            ; Load the SEGMENT address into
                                ; X to access it with
                                ; accumulator-offset indexed
                                ; addressing.


        ;; Prepare DISP3
        ldaa BCD1
        anda #$0F               ; Extract the least significant
        psha                    ; nibble of BCD1 and push it.

        ;; Prepare DISP1
        ldaa BCD2
        anda #$0F               ; Extract the least significant
        psha                    ; nibble of BCD2 and push it.

        ;; Prepare DISP4
        ldaa BCD1               ; Extract the most significant nibble
        lsra                    ; of BCD1. To do so, the digit is
        lsra                    ; divided by 16.
        lsra
        lsra
        psha                    ; Once divided, it is pushed.

        ;; Prepare DISP2
        ldaa BCD2               ; Extract the most significant nibble
        lsra                    ; of BCD2. To do so, the digit is
        lsra                    ; divided by 16.
        lsra
        lsra
        psha                    ; Once divided, it is pushed.

        ;; Load the digit values
        pula
        movb A,X,DISP2           ; Load DISP2.
        pula
        movb A,X,DISP4           ; Load DISP4.
        pula
        movb A,X,DISP1           ; Load DISP1.
        pula
        movb A,X,DISP3           ; Load DISP3.


        ldaa BIN1
        cmpa #$BB
        bne ASK_AA_BIN1
        movb #$00,DISP1
        movb #$00,DISP2

ASK_AA_BIN1:
        cmpa #$AA
        bne ASK_BB_BIN2
        movb #$40,DISP1
        movb #$40,DISP2

ASK_BB_BIN2:
        ldaa BIN2
        cmpa #$BB
        bne ASK_AA_BIN2
        movb #$00,DISP3
        movb #$00,DISP4

ASK_AA_BIN2:
        cmpa #$AA
        bne CONVERTIR
        movb #$40,DISP3
        movb #$40,DISP4

CONVERTIR:
        ;; Restore accumulators and indices.
        pula
        pulx
        rts

;***********************************************
;          INICIALIZAR_LCD
;***********************************************
        ;; Description:
        ;; This subroutine initializes the LCD
        ;; display. It sends a series of commands required
        ;; for this purpose.

        ;; Inputs:
        ;; iniDsp array via memory
        ;; BIN2 variable via memory

        ;; Outputs:

INICIALIZAR_LCD:

        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        pshy
        psha
        pshb

        ldx #iniDsp             ; To access iniDsp by
                                ; constant-offset indexed
                                ; addressing.

SEGUIR_IniDSP:
        ldaa 0,X
        jsr SEND_COMMAND        ; Send iniDsp command.
        movb D40uS,Cont_Delay
        jsr Delay               ; Wait 40us.
        inx
        cpx #iniDsp+4           ; If not all of iniDsp has been sent,
        bne SEGUIR_IniDSP       ; keep sending.

        ldaa #$01
        jsr SEND_COMMAND        ;Send Clear Display command.
        movb D2mS,Cont_Delay
        jsr Delay               ;Wait 2ms.

        ;; Restore accumulators and indices.
        pulb
        pula
        puly
        pulx

        rts

;***********************************************
;          CARGAR_LCD
;***********************************************
        ;; Description:
        ;; This subroutine handles loading messages to the LCD
        ;; display. It manages the sequence of
        ;; loading messages and data, needed for correct
        ;; writing of the sent message to the LCD.

        ;; Inputs:
        ;; ADD_L1 constant via memory
        ;; ADD_L2 constant via memory
        ;; MSG1 array via accumulator X
        ;; MSG2 array via accumulator X

        ;; Outputs:

CARGAR_LCD:

        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        pshy
        psha
        pshb

        ldaa ADD_L1             ; Send the ADD_L1 command to put
        jsr SEND_COMMAND        ; the cursor on line 1.
        movb D40uS,Cont_Delay
        jsr Delay               ; Wait 40us
LOAD_MSG1:
        ;; The message for line 1 is awaited via
        ;; index X. The message is loaded byte by byte. When the
        ;; end-of-message character EOM is received, the
        ;; communication ends.
        ldaa 1,X+
        cmpa #EOM               ; If EOM is received, start the
        beq IS_EOM_MSG1         ; L2 configuration sequence.

        jsr SEND_DATA           ; Otherwise, send MSGL1 char.
        movb D40uS,Cont_Delay
        jsr Delay               ;Wait 40us
        bra LOAD_MSG1
IS_EOM_MSG1:
        ldaa ADD_L2             ; Send the ADD_L2 command to put
        jsr SEND_COMMAND        ; the cursor on line 2.
        movb D40uS,Cont_Delay
        jsr Delay               ; Wait 40us
LOAD_MSG2:
        ;; The message for line 2 is awaited via
        ;; index Y. The message is loaded byte by byte. When the
        ;; end-of-message character EOM is received, the
        ;; communication ends.
        ldaa 1,Y+
        cmpa #EOM               ; If EOM is received, end the
        beq IS_EOM_MSG2         ; subroutine.

        jsr SEND_DATA           ; Otherwise, send MSG2 char.
        movb D40uS,Cont_Delay
        jsr Delay               ; Wait 40us
        bra LOAD_MSG2

IS_EOM_MSG2:
        ;; Restore accumulators and indices.
        pulb
        pula
        puly
        pulx

        rts

;***********************************************
;          SEND_COMMAND
;***********************************************
        ;; Description:
        ;; This subroutine sends a command to the LCD display. The
        ;; command to send is received in accumulator A. The
        ;; subroutine sends the high part of the byte first, then the
        ;; low part. Those nibbles are received by the LCD on
        ;; PORTK.5-PORTK.2. The subroutine controls the
        ;; timing. Sending each nibble generates a
        ;; 250us pulse on PORTK.1 (EN). This subroutine sets PORTK.0=1 (RS).

        ;; Inputs:
        ;; Command via accumulator A
        ;; BIN2 variable via memory

        ;; Outputs:
        ;; PORTK.5-PORTK.0

SEND_COMMAND:

        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        pshy
        psha
        pshb

        ;; Load the most significant nibble into R1.
        psha
        anda #$F0
        lsra
        lsra

        ;; Load the most significant nibble into PORTK.
        sta PORTK

        bclr PORTK,#$01         ; Set RS=0 (command).
        bset PORTK,#$02         ; Set EN=1.
        movb D250uS,Cont_Delay
        jsr Delay               ; Wait 250us.
        bclr PORTK,#$01         ; Set EN=0.

        ;; Load the least significant nibble into R1.
        pula
        anda #$0F
        lsla
        lsla

        ;; Load the least significant nibble into PORTK.
        sta PORTK

        bclr PORTK,#$01         ; Set RS=0 (command).
        bset PORTK,#$02         ; Set EN=1.
        movb D250uS,Cont_Delay
        jsr Delay               ; Wait 250us.
        bclr PORTK,#$02         ; Set EN=0.

        ;; Restore accumulators and indices.
        pulb
        pula
        puly
        pulx

        rts


;***********************************************
;          SEND_DATA
;***********************************************
        ;; Description:
        ;; This subroutine sends a command to the LCD display. The
        ;; command to send is received in accumulator A. The
        ;; subroutine sends the high part of the byte first, then the
        ;; low part. Those nibbles are received by the LCD on
        ;; PORTK.5-PORTK.2. The subroutine controls the
        ;; timing. Sending each nibble generates a
        ;; 250us pulse on PORTK.1 (EN). This subroutine sets PORTK.0=1 (RS).

        ;; Inputs:
        ;; Command via accumulator A
        ;; BIN2 variable via memory

        ;; Outputs:
        ;; PORTK.5-PORTK.0

SEND_DATA:

        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        pshy
        psha
        pshb

        ;; Load the most significant nibble into R1.
        psha
        anda #$F0
        lsra
        lsra

        ;; Load the most significant nibble into PORTK.
        sta PORTK

        bset PORTK,#$03         ; Set RS=0 (command) and EN=1.
        movb D250uS,Cont_Delay
        jsr Delay               ; Wait 250us.
        bclr PORTK,#$01         ; Set EN=0.

        ;; Load the least significant nibble into R1.
        pula
        anda #$0F
        lsla
        lsla

        ;; Load the least significant nibble into PORTK.
        sta PORTK               ;
        bset PORTK,#$03         ; Set RS=0 (command) and EN=1.
        movb D250uS,Cont_Delay
        jsr Delay               ; Wait 250us.
        bclr PORTK,#$02         ; Set EN=0.


        ;; Restore accumulators and indices.
        pulb
        pula
        puly
        pulx

        rts


;***********************************************
;          DELAY
;***********************************************
        ;; Description:
        ;; This subroutine waits for OC4_ISR to decrement
        ;; CONT_DELAY to zero. That CONT_DELAY is loaded by the subroutine
        ;; that calls DELAY, so the subroutine works for any
        ;; delay that fits in a byte.

        ;; Inputs:
        ;; CONT_DELAY variable via memory

        ;; Outputs:

DELAY:
        pshx
        pshy
        psha
        pshb

DELAY_RET:
        ;; Wait until CONT_DELAY reaches zero.
        tst CONT_DELAY
        bne DELAY_RET

        ;; When it reaches zero, return.

        pulb
        pula
        puly
        pulx

        rts
