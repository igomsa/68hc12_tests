;***********************************************
;                  ASSIGNMENT #5
;***********************************************

#include "../../include/registers.inc"


;***********************************************
; INTERRUPT VECTOR REDIRECTION
;***********************************************


        org $3E6A               ; Comparator interrupt vector.
        dw OC2_ISR

        org $3E70               ; RTI interrupt vector
        dw RTI_ISR


;***********************************************
; 	       MEMORY DECLARATION
;***********************************************

		org $1000
CONT_RTI:               ds 1
BANDERAS:               ds 1
CONT_MAN                ds 1
CONT_FREE               ds 1
LEDS                    ds 1
POT                  ds 1
CONT_DIG                ds 1
CONT_TICKS              ds 1
DT                      ds 1
LOW:                    ds 1
BCD1                    ds 1
BCD2                    ds 1
DIG1                    ds 1
DIG2                    ds 1
DIG3                    ds 1
DIG4                    ds 1
CONT_7SEG               ds 2
Cont_Delay              ds 1
D2mS                    ds 1
D250uS                  ds 1
D40uS                   ds 1
D60uS                   ds 1
Clear_LCD               ds 1
ADD_L1                  ds 1
ADD_L2                  ds 1
SEGMENT                 db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$0A

;***********************************************
; 	     MESSAGES START
;***********************************************
iniDsp:                 db $04
FUNCTION_SET1:          db $28
FUNCTION_SET2:          db $28
ENTRY_MODE:             db $06
DISPLAY_ON_OFF:         db $01

Inicio_de_mensajes:     ds 1
EOM:    EQU $04
Msg_L0: FCC "FREE_CONT=UP"
        db EOM
Msg_L1: FCC "FREE_CONT=DOWN"
        db EOM
Msg_L2: FCC "MAN_CONT=UP"
        db EOM
Msg_L3: FCC "MAN_CONT=DOWN"
        db EOM
;***********************************************
; 	     HARDWARE CONFIGURATION
;***********************************************

		org $2000

	lds #$3BFF               ; Load stack pointer.

        ;; LEDS configuration
	movb #$FF,DDRB           ; Port B: write
        bset DDRJ,#$03           ; PJ1 write
	bclr PTJ,#$02            ; PJ1 as GND
        movb #$FF,DDRP           ; PORTJ: Input


	movb #$FF,PORTB         ; LEDS on initially

        ;; PK configuration for LCD
        movb #$FF,DDRK

        ;; RTI_ISR configuration
        movb #$25,RTICTL       ; Set 1ms interrupts
        bset CRGINT,#$80       ; To enable RTI interrupt

        ;; PTH_ISR configuration
        bset PIEH,#$0D          ; Enable PH(3,2,0) interrupt
        bclr PPSH,#$0D          ; Select interrupt on
                                ; falling edge

        ;; OC2_ISR configuration
        movb #$90,TSCR1         ; Enable TCNT and TFFCA function
        movb #$03,TSCR2         ; Prescaler of 8
        movb #$04,TIOS          ; Enable IOS2
        movb #$10,TCTL2         ; Channel 2 as Toggle
        movb #$04,TIE           ; Enable TC2


;***********************************************
; 	   VARIABLE_INITIALIZATION
;***********************************************
        movb #$00,LOW
        movb #$00,BANDERAS      ; X:X:X:X:X:X:CARGAR_LCD:DIRECCION_LEDS
        movb #250,CONT_RTI      ; To count 0.25 s in RTI_ISR
        movb #$00,CONT_MAN
        movb #$00,CONT_FREE
        movb #$01,LEDS
        movb #$00,POT
        movb #$00,CONT_DIG
        movb #100,CONT_TICKS
        movb #$00,DT
        movb #$00,BCD1
        movb #$00,BCD2
        movb #$00,DIG1
        movb #$00,DIG2
        movb #$00,DIG3
        movb #$00,DIG4
        movw #$0000,CONT_7SEG
        movb #$00,Cont_Delay
        movb #$64,D2mS
        movb #$0D,D250uS
        movb #$02,D40uS
        movb #$03,D60uS
        movb #$00,Clear_LCD
        movb #$80,ADD_L1
        movb #$C0,ADD_L2

	cli		        ; Carga 0 en I en CCR

        ;; To generate 50 KHz ticks.
        ldd TCNT
        addd #60
        std TC2

;***********************************************
; 	   MAIN PROGRAM
;***********************************************

        brset PTIH,#$80,CONT_FREE_DES_ON
        brclr BANDERAS,$04,NO_PRIMER_UP_FREE
        jsr INICIALIZAR_LCD


ESPERE:
        jsr BIN_BCD             ; Always convert from BIN to BCD

        ;; If the load-message flag is enabled, update the LCD.
        ;; Otherwise, convert to BCD.
        brclr BANDERAS,$02,ESPERE
        jsr MSG_LCD
        jsr CARGAR_LCD
        bclr BANDERAS,$02
        bra ESPERE
        end


;***********************************************
; 	   MODO_CONFIG
;***********************************************
MODO_CONFIG:
        movb #$02,LEDS
        brset BANDERDAS,#$04,ARRAY_OK
        jsr BCD_BIN
        ldaa CPROG
        cmpa #12
        ble FUERA_DE_RANGO
        cmpa #96
        bge FUERA_DE_RANGO
DENTRO_DE_RANGO:
        bclr BANDERAS,$04
        movb V_LIM,BIN1
        bra FIN_MODO_CONFIG

FUERA_DE_RANGO:
        bclr BANDERAS,$04
        movb #00,CPROG
        bra FIN_MODO_CONFIG

ARRAY_OK:
        jsr TAREA_TECLADO

FIN_MODO_CONFIG:
        rts

;***********************************************
; 	   BCD_BIN
;***********************************************
BCD_BIN:
        ldx #NUM_ARRAY
        ldaa 0,X
        ldab #10
        lsra
        lsra
        lsra
        lsra

        ldaa 1,X
        aba
        staa CPROG
        rts


;***********************************************
; 	   MODO_RUN
;***********************************************
MODO_RUN:
        movb #$01
        ldaa CUENTA
        cmpa CPROG
        beq INC_ACUMUL

        tst TIMER_CUENTA
        beq FIN_MODO_RUN

        inc CUENTA
        movb VMAX, TIMER_CUENTA
        bra FIN_MODO_RUN
INC_ACUMUL:
        inc ACUMUL
FIN_MODO_RUN:
        movb CUENTA,BIN1
        movb ACUMUL,BIN2
        rts


;***********************************************
; 	   RTI_ISR
;***********************************************
RTI_ISR:
        ;; After 0.25s have elapsed, LEDS and CONT_FREE are varied
        dec CONT_RTI
        tst CONT_RTI
        bne FIN_RTI_ISR
        movb #250,CONT_RTI

        ;; If PTIH.7 is 0, the count is ascending.
        brclr PTIH,#$80,CONT_FREE_ASC

        ;; Otherwise, it is descending.
CONT_FREE_DEC:
        bset BANDERAS,$02

        lda CONT_FREE
        jsr CUENTA_DECRECIENTE  ;Down-count handling subroutine
        sta CONT_FREE
        bra VARIAR_LEDS

        ;; Ascending count handling for the FREE COUNTER.
CONT_FREE_ASC:
        bset BANDERAS,$02

        lda CONT_FREE
        jsr CUENTA_CRECIENTE    ;Up-count handling subroutine
        sta CONT_FREE

VARIAR_LEDS:
        ;; If the LEDS flag is 0, the motion is RIGHT->LEFT
        brclr BANDERAS,$01,LEDS_DER_IZQ

        ;; Otherwise, it is LEFT->RIGHT
LEDS_IZQ_DER:
        movb LEDS,PORTB
        lsr LEDS
        brclr LEDS,#$01,FIN_RTI_ISR
        bclr BANDERAS,$01
        bra FIN_RTI_ISR

        ;; Load LEDS RIGHT->LEFT
LEDS_DER_IZQ:
        movb LEDS,PORTB
        lsl LEDS
        brclr LEDS,#$80,FIN_RTI_ISR
        bset BANDERAS,$01

FIN_RTI_ISR:
        bset crgflg, #$80       ; Clear the interrupt
        rti

;***********************************************
; 	   PTH_ISR
;***********************************************
PTH_ISR:

        brclr PIFH,#$01,ESTADO_POT ; Identify the brightness interrupt.

        ;; If PTIH.6 is 0, the manual count is ascending.
        brclr PTIH,#$40,CONT_MAN_ASC

        ;; Otherwise, it is descending.
CONT_MAN_DEC:
        bset BANDERAS,$02

        ldaa CONT_MAN
        jsr CUENTA_DECRECIENTE
        sta CONT_MAN
        bra ESTADO_POT

        ;; Ascending count handling for the MAN COUNTER.
CONT_MAN_ASC:
        bset BANDERAS,$02

        ldaa CONT_MAN
        jsr CUENTA_CRECIENTE
        sta CONT_MAN
        bra ESTADO_POT

        ;; Brightness increase/decrease handling.
ESTADO_POT:
        brset PIFH,#$04,REDUCIR_POT
        brset PIFH,#$08,AUMENTAR_POT
        bra SALIR_PTH

REDUCIR_POT:
        ldaa POT
        suba #$05
        sta POT
        tsta
        bge SALIR_PTH
        movb #$64,POT        ; If minimum is reached and brightness
                                ; is decremented, it goes to maximum.
        bra SALIR_PTH

AUMENTAR_POT:
        ldaa POT
        adda #$05
        sta POT
        cmpa #$64
        ble SALIR_PTH
        movb #$00,POT ; If the top is reached, brightness returns to zero.
SALIR_PTH:
        bset PIFH, $0D          ; Clear the interrupt.
        rti

;***********************************************
;          LCD MESSAGE LOAD HANDLING
;***********************************************
MSG_LCD:
        ;; If PTIH.7 is 0, the free count is ascending and
        ;; therefore the respective message is loaded.
        brset PTIH,#$80,CONT_FREE_DES_ON
        brclr BANDERAS,$04,NO_PRIMER_UP_FREE
        jsr INICIALIZAR_LCD
NO_PRIMER_UP_FREE:
        ldx #Msg_L0
        bclr BANDERAS,$04
        bra CONT_MAN_MSG
CONT_FREE_DES_ON:
        ldx #Msg_L1
        bset BANDERAS,$04
CONT_MAN_MSG:
        brset PTIH,#$40,CONT_MAN_DES_ON
        brclr BANDERAS,$08,NO_PRIMER_UP_MAN
        jsr INICIALIZAR_LCD
NO_PRIMER_UP_MAN:
        ldy #Msg_L2
        bclr BANDERAS,$08
        bra CARGAR_MSG
CONT_MAN_DES_ON:
        ldy #Msg_L3
        bset BANDERAS,$08
CARGAR_MSG:
        rts


;***********************************************
;          UP/DOWN COUNT HANDLING
;***********************************************
CUENTA_DECRECIENTE:
        deca
        tsta
        bge RET_CUENTA_DEC
        ldaa #$63
RET_CUENTA_DEC:
        rts

CUENTA_CRECIENTE:
        inca
        cmpa #$64
        bne RET_CUENTA_CREC
        lda #$00
RET_CUENTA_CREC:
        rts


;***********************************************
;          BIN_BCD
;***********************************************
BIN_BCD:
        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        psha
        pshb

        ldaa CONT_MAN
        ldab #$07
        movb #$00,LOW
        ;; Conversion of CONT_FREE starts here
NEXT_BIT_BCD1:
        lsla
        rol LOW
        ;; R1 is loaded into TEMP here
        psha
        ldaa LOW
        anda #$0F
        cmpa #$05
        blt NOT_5_ON_L_BCD1
        adda #$03
NOT_5_ON_L_BCD1:
        ;; R1 is loaded into LOW here
        psha
        ldaa LOW
        anda #$F0
        cmpa #$50
        blt NOT_5_ON_H_BCD1
        adda #$30
NOT_5_ON_H_BCD1:
        ;; LOW is added to R1 here
        adda 0,SP
        sta LOW
        ;; TEMP is loaded into R1 here
        ins
        pula
        dbeq B,FINALIZAR_BCD1
        bra NEXT_BIT_BCD1
FINALIZAR_BCD1:
        lsla
        rol LOW
        movb LOW,BCD1

        ;; Conversion of CONT_FREE starts here
        ldaa CONT_FREE
        ldab #$07
        movb #$00,LOW
NEXT_BIT_BCD2:
        lsla
        rol LOW
        ;; R1 is loaded into TEMP here
        psha
        ldaa LOW
        anda #$0F
        cmpa #$05
        blt NOT_5_ON_L_BCD2
        adda #$03
NOT_5_ON_L_BCD2:
        ;; R1 is loaded into LOW here
        psha
        ldaa LOW
        anda #$F0
        cmpa #$50
        blt NOT_5_ON_H_BCD2
        adda #$30
NOT_5_ON_H_BCD2:
        ;; LOW is added to R1 here
        adda 0,SP
        sta LOW
        ;; TEMP is loaded into R1 here
        ins
        pula
        dbeq B,FINALIZAR_BCD2
        bra NEXT_BIT_BCD2
FINALIZAR_BCD2:
        lsla
        rol LOW
        movb LOW,BCD2

        ;; Restore accumulators and indices.
        pulb
        pula
        pulx
        rts

;***********************************************
;          BCD_7SEG
;***********************************************
BCD_7SEG:
        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        psha

        ldx #SEGMENT
        ;; Prepare DIG3
        ldaa BCD2
        anda #$0F
        psha
        ;; Prepare DIG4
        ldaa BCD1
        anda #$0F
        psha
        ;; Prepare DIG2
        ldaa BCD2
        lsra
        lsra
        lsra
        lsra
        psha
        ;; Prepare DIG4
        ldaa BCD1
        lsra
        lsra
        lsra
        lsra
        psha

        ;; Load the digit values
        pula
        movb A,X,DIG2
        pula
        movb A,X,DIG4
        pula
        movb A,X,DIG1
        pula
        movb A,X,DIG3

        ;; Restore accumulators and indices.
        pula
        pulx
        rts

;***********************************************
;          OC2_ISR
;***********************************************
OC2_ISR:
        ;; Counter to refresh the digit value.
        ldd CONT_7SEG
        addd #$01
        std CONT_7SEG

        ;; Counter for duty-cycle control.
        dec CONT_TICKS
        tst CONT_TICKS
        ble CERO
        ldaa CONT_TICKS

        ;; Determine the LED enable pulse width.
        ldab #100
        subb POT
        stb DT
        cmpa DT
        ble HAB_LED
        ldd CONT_7SEG
        cpd #5000
        lbne FIN_OC2_ISR
        movw #$0000,CONT_7SEG
        jsr BCD_7SEG            ;Convert BCD variables to 7 segments.
        bra FIN_OC2_ISR

        ;; LEDS enable handling.
HAB_LED:
        movb #$FF,PTP
        bclr PTJ,#$03
        movb LEDS,PORTB
        bra FIN_OC2_ISR

        ;; DIGIT enable handling.
CERO:
        movb #100,CONT_TICKS
        inc CONT_DIG
        bset PTJ,#$03
        brset CONT_DIG,#$03,HAB_DIG4
        brset CONT_DIG,#$02,HAB_DIG3
        brset CONT_DIG,#$01,HAB_DIG2

        ;; Enable digit 1
HAB_DIG1:
        tst CONT_DIG
        beq LOAD_DIG1
        movb #$00,CONT_DIG
LOAD_DIG1:
        movb #$07,PTP
        movb DIG1,PORTB
        bra FIN_OC2_ISR

        ;; Enable digit 2
HAB_DIG2:
        ldaa DIG2
        cmpa #$3F
        beq FIN_OC2_ISR
        movb #$0B,PTP
LOAD_DIG2:
        movb DIG2,PORTB
        bra FIN_OC2_ISR

        ;; Enable digit 3
HAB_DIG3:
        movb #$0D,PTP
LOAD_DIG3:
        movb DIG3,PORTB
        bra FIN_OC2_ISR

        ;; Enable digit 4
HAB_DIG4:
        ldaa DIG4
        cmpa #$3F
        beq FIN_OC2_ISR
        movb #$0E,PTP
LOAD_DIG4:
        movb DIG4,PORTB
        bra FIN_OC2_ISR

FIN_OC2_ISR:
        ;; Cont_Delay handling for LCD
        tst Cont_Delay
        beq CARGAR_TC2
        dec Cont_Delay
CARGAR_TC2:
        ldd TCNT
        addd #60
        std TC2
        rti

;***********************************************
;          INICIALIZAR_LCD
;***********************************************
INICIALIZAR_LCD:

        pshx
        pshy
        psha
        pshb

        ldx #iniDsp
SEGUIR_IniDSP:
        ldaa 0,X
        jsr SEND_COMMAND        ;From iniDsp
        movb D40uS,Cont_Delay
        jsr Delay               ;40us
        inx
        ;; inca
        cpx #iniDsp+4
        bne SEGUIR_IniDSP
        ldaa #$01
        jsr SEND_COMMAND        ;From Clear Display
        movb D2mS,Cont_Delay
        jsr Delay               ;2ms

        pulb
        pula
        puly
        pulx

        rts



;***********************************************
;          CARGAR_LCD
;***********************************************
CARGAR_LCD:

        pshx
        pshy
        psha
        pshb

        ldaa ADD_L1
        jsr SEND_COMMAND        ;ADD_L1
        movb D40uS,Cont_Delay
        jsr Delay               ;40us
LOAD_MSG1:
        ldaa 1,X+
        cmpa #EOM
        beq IS_EOM_MSG1
        jsr SEND_DATA        ;Msg_L1 char
        movb D40uS,Cont_Delay
        jsr Delay               ;40us
        bra LOAD_MSG1
IS_EOM_MSG1:
        ldaa ADD_L2
        jsr SEND_COMMAND        ;ADD_L2
        movb D40uS,Cont_Delay
        jsr Delay               ;40us
LOAD_MSG2:
        ldaa 1,Y+
        cmpa #EOM
        beq IS_EOM_MSG2
        jsr SEND_DATA        ;Msg_L2 char
        movb D40uS,Cont_Delay
        jsr Delay               ;40us
        bra LOAD_MSG2
IS_EOM_MSG2:

        pulb
        pula
        puly
        pulx

        rts

;***********************************************
;          SEND_COMMAND
;***********************************************
SEND_COMMAND:

        pshx
        pshy
        psha
        pshb

        psha
        anda #$F0
        lsra
        lsra
        sta PORTK
        bclr PORTK,#$01
        bset PORTK,#$02
        movb D250uS,Cont_Delay
        jsr Delay               ;250us
        bclr PORTK,#$01
        pula
        anda #$0F
        lsla
        lsla
        sta PORTK
        bclr PORTK,#$01
        bset PORTK,#$02
        movb D250uS,Cont_Delay
        jsr Delay               ;250us
        bclr PORTK,#$02

        pulb
        pula
        puly
        pulx

        rts


;***********************************************
;          SEND_DATA
;***********************************************
SEND_DATA:

        pshx
        pshy
        psha
        pshb

        psha
        anda #$F0
        lsra
        lsra
        sta PORTK
        bset PORTK,#$03
        movb D250uS,Cont_Delay
        jsr Delay               ;250us
        bclr PORTK,#$01
        pula
        anda #$0F
        lsla
        lsla
        sta PORTK
        bset PORTK,#$03
        movb D250uS,Cont_Delay
        jsr Delay               ;250us
        bclr PORTK,#$02


        pulb
        pula
        puly
        pulx

        rts


;***********************************************
;          Delay
;***********************************************
DELAY:
        tst Cont_Delay
        bne DELAY
        rts
