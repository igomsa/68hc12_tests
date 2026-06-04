;***********************************************
;                  ASSIGNMENT 7
;***********************************************

#include "../../include/registers.inc"

;***********************************************
; INTERRUPT VECTOR REDIRECTION
;***********************************************
        org $3E40               ; I2C interrupt vector
        dw I2C_ISR

        org $3E4C               ; IRQ interrupt vector
        dw PTH_ISR

        org $3E70               ; RTI interrupt vector
        dw RTI_ISR

        org $3E64               ; Comparator Ch5 interrupt vector.
        dw OC5_ISR

        org $3E66               ; Comparator Ch4 interrupt vector.
        dw OC4_ISR

;***********************************************
; 	       MEMORY DECLARATION
;***********************************************

		org $1000
CONT_RTI:               ds 1
BANDERAS:               ds 1
BRILLO                  ds 1
CONT_DIG                ds 1
CONT_TICKS              ds 1
DT                      ds 1
BCD1                    ds 1
BCD2                    ds 1
DIG1                    ds 1
DIG2                    ds 1
DIG3                    ds 1
DIG4                    ds 1
LEDS                    ds 1
SEGMENT                 db $3F,$06,$5B,$4F,$66,$6D,$7D,$07,$7F,$6F,$0A
CONT_7SEG               ds 2
Cont_Delay              ds 1
D2mS                    ds 1
D260uS                  ds 1
D40uS                   ds 1
Clear_LCD               ds 1
ADD_L1                  ds 1
ADD_L2                  ds 1

;***********************************************
; 	     LCD INITIALIZATION
;***********************************************
iniDsp:                 db $04
FUNCTION_SET1:          db $28
FUNCTION_SET2:          db $28
ENTRY_MODE:             db $06
DISPLAY_ON_OFF:         db $01

;***********************************************
; 	          I2C
;***********************************************
INDEX_RTC:      ds 1
DIR_WR:         db $D0
DIR_RD:         db $D1
DIR_SEG:        db $00
ALARMA:         dw $0108

                org $1030
T_WRITE_RTC:    db $00,$00,$08,$03,$04,$12,$19

                org $1040
T_READ_RTC:     ds 6

;***********************************************
; 	     MESSAGES START
;***********************************************
        org $1050
EOM:    EQU $04
MSG0:   FCC "     RELOJ"
        db EOM
MSG1:   FCC " DESPERTADOR 623"
        db EOM

;***********************************************
; 	     HARDWARE CONFIGURATION
;***********************************************

		org $2000

	lds #$3BFF               ; Load stack pointer.

        ;; LEDS configuration
	movb #$FF,DDRB           ; Port B: write.
        bset DDRJ,#$03           ; PJ1 write.
	bclr PTJ,#$02            ; PJ1 as GND.
        movb #$FF,DDRP           ; PORTJ: Input.

        ;; PK configuration for LCD
        movb #$FF,DDRK

        ;; I2C configuration
        movb #$1F,IBFD          ; Set SCL to 1kHz and
                                ; SDA_Hold=1.375us.

        ;; Enable respectively:  ; I_Bus, I_Bus Interrupt,
        ;; Master mode and Transmission
        movb #$F0,IBCR          ; I_BEN=1, IBIE=1, MS/SL=1, Tx/Rx=1.

        ;; RTI_ISR configuration
        movb #$75,RTICTL       ; Set 50ms interrupts.
        bset CRGINT,#$80       ; To enable RTI interrupt.

        ;; PTH_ISR configuration
        movb #$09,PIEH          ; Enable PH(3,0) interrupt.
        bclr PPSH,#$0F          ; Select interrupt on
                                ; flanco decreciente.

        ;; OC4_ISR and OC5_ISR configuration
        movb #$90,TSCR1         ; Enable TCNT and TFFCA function.
        movb #$03,TSCR2         ; Prescaler of 8.
        movb #$10,TIOS          ; Enable IOS4.
        movb #$05,TCTL1         ; Channels 4 and 5 as Toggle.
        movb #$10,TIE           ; Enable TC4.




;***********************************************
; 	     VARIABLE_INITIALIZATION
;***********************************************

;***************** RTI  ***************************
        movb  #20,CONT_RTI       ; To count 1s.

;***************** PANTALLAS ***************************
        ;; The display variables are initialized
        ;; X:X:X:X:X:PTH1_PRS:RD_FLG:RW_RTC
        movb #$00,BANDERAS
        movb #$0A,BRILLO        ; For 7SEG on at startup.
        movb #$00,CONT_DIG
        movb #100,CONT_TICKS    ; To count 1s.
        movb #$00,DT
        movb #$00,BCD1
        movb #$00,BCD2
        movb #$00,DIG1
        movb #$00,DIG2
        movb #$00,DIG3
        movb #$00,DIG4
        movb #$00,LEDS
        movw #$0000,CONT_7SEG
        movb #$00,Cont_Delay
        movb #$64,D2mS          ; To count 2ms.
        movb #$0D,D260uS        ; To count 260uS.
        movb #$02,D40uS         ; To count 40us.
        movb #$00,Clear_LCD
        movb #$80,ADD_L1        ; To address L1 of LCD.
        movb #$C0,ADD_L2        ; To address L2 of LCD.

;***************** I2C ***************************
        ;; The I2C variable and array are initialized.
        movb #$00,INDEX_RTC
        ldx #T_READ_RTC-1
        ldaa #7
INICIALIZAR_T_READ_RTC:
        movb #$00,A,X
        dbne A,INICIALIZAR_T_READ_RTC

;************ INTERRUPCIONES ********************
        cli		        ; Load 0 into I in CCR

        ;; To generate 50 KHz ticks.
        ldd TCNT
        addd #60
        std TC4

;***********************************************
; 	     PRINCIPAL
;***********************************************
        ;; Load message into LCD:
        ;;      RELOJ
        ;;  DESPERTADOR 623
        jsr INICIALIZAR_LCD     ; Clear the LCD.
        ldx #MSG0               ; Load MSG0 into line.
        ldy #MSG1               ; Load MSG1 into line.
        jsr CARGAR_LCD          ; Load message into LCD.

RETORNAR:

        ;; If the alarm is on, it must stay
        ;; on until PTH1 disables it.
        brset TIE,#$20,RETORNAR

        ;; If the alarm is not on, check whether the RTC hour
        ;; and minutes already match those set in the
        ;; alarm.
        ldx #T_READ_RTC         ; Read the contents of the RTC
        ldd 1,X                 ; read array.
        cpd ALARMA              ; If it matches the preset hour
        beq ACTIVAR_ALARMA      ; and minutes, the alarm is activated.


        bclr BANDERAS,$04       ; Clear the PTH1_PRS flag.

        bra RETORNAR

ACTIVAR_ALARMA:
        ;; If the alarm was recently turned off by the PH1
        ;; interrupt, it is not turned on.
        brset BANDERAS,$04,RETORNAR

        bset TIOS,$20           ; Enable IOS5.

        bset TIE,$20            ; Enable TC5 (Alarm).

        ;; To generate a 440 KHz frequency.
        ldd TCNT
        addd #13636
        std TC5

        bra RETORNAR

        end

;***********************************************
; 	             PTH_ISR
;***********************************************
PTH_ISR:
        ;; If PTH2 was pressed, the brightness is reduced.
        brset PIFH,#$04,REDUCIR_BRILLO

        ;; If PTH3 was pressed, the brightness is increased.
        brset PIFH,#$08,AUMENTAR_BRILLO

        ;; If PTH1 was pressed, the OC5 interrupt is disabled,
        ;; which implements the alarm buzzer.
        brset PIFH,#$02,DESHABILITAR_ALARMA

        ;; If none of the above was pressed, by elimination,
        ;; PH0 was pressed. So the START byte and CALLING
        ;; ADDRESS are written to begin the write
        ;; to the DS1307 RTC registers.
CALL_W:
        bclr BANDERAS,$02       ;Disable the per-second read
                                ;of the RTC.

        bset BANDERAS,$01       ; W_FLAG=1.

        bset IBCR,#$30          ; Assert START signal.

        movb DIR_WR,IBDR        ; Write WRITE CALL ADDR on the bus.

        bra SALIR_PTH           ; Return to the end of the subroutine.

        ;; This subroutine reduces the brightness.
REDUCIR_BRILLO:
        ldaa BRILLO
        suba #$05               ; Brightness decreases by 5.

        tsta                    ; If BRILLO reaches minimum,
        blt SALIR_PTH           ; the subroutine ends.

        sta BRILLO              ; Otherwise, store the new value
                                ; in BRILLO.

        bra SALIR_PTH           ; Return to the end of the subroutine.

        ;; This subroutine increases the brightness.
AUMENTAR_BRILLO:
        ldaa BRILLO
        adda #$05               ; Brightness increases by 5.

        cmpa #$64               ; If BRILLO reaches maximum,
        bgt SALIR_PTH           ; the subroutine ends.

        sta BRILLO              ; Otherwise, store the new value
                                ; in BRILLO.

        bra SALIR_PTH           ; Return to the end of the subroutine.

        ;; This subroutine disables the alarm.
DESHABILITAR_ALARMA:
        bset BANDERAS,$04       ; Set the PTH1_PRS flag.

        bclr TIOS,#$20          ; Disable IOS5.

        bclr TIE,#$20           ; Disable TC5

        ;; End of subroutine.
SALIR_PTH:
        bset PIFH, $0F          ; Clear the interrupt.
        rti

;***********************************************
;                   RTI_ISR
;***********************************************
RTI_ISR:
        dec CONT_RTI            ; Decrement CONT_RTI.

        tst CONT_RTI            ; If 1s has not been reached,
        bne FIN_RTI             ; the subroutine ends.

        ;; When 1s is reached, the subroutine's own
        ;; sequence is carried out.
CONT_RTI_CERO:
        movb #20,CONT_RTI       ; Reload the 1s counter.

        ;; If RD_FLG=1, a value has already been written to the
        ;; DS1307 registers and a read must be performed
        ;; every second. For that, the START bit is written
        ;; and the read CALLING ADDRESS is sent.
        brset BANDERAS,$02,CALL_R

        ;; If RD_FLG=0, nothing has been written to the DS1307
        ;; register, so it must not be read.
        bra FIN_RTI

CALL_R:
        brset IBSR,$20,*        ; Wait for the I2C bus to be free.

        bclr BANDERAS,$01       ; W_FLAG=0.

        bset IBCR,$30           ; Assert START signal.

        movb DIR_WR,IBDR        ; Write CALL ADDR on the bus.

FIN_RTI:
        bset CRGFLG,#$80        ; Clear interrupt flag.
        rti

;***********************************************
;                   I2C_ISR
;***********************************************
I2C_ISR:
        ;; Check whether a read or write is in progress
        ;; (WR_FLG flag).
        brset BANDERAS,$01,WRITE_RTC ; If WR_FLG=1, go to write.

        jsr READ_RTC                 ; Otherwise, go to read.

RETORNAR_I2C_ISR:
        bset IBSR,$02           ;Clear the interrupt flag.
        rti

;***********************************************
;                  WRITE_RTC
;***********************************************
WRITE_RTC:
        ;; Check whether this is the first interrupt
        tst INDEX_RTC
        bne W_BYTE

        ;; If this is the first interrupt, the pointer-register
        ;; address is transmitted.
        brset IBSR,$01,*        ; Verify ACK received.

        inc INDEX_RTC           ; Increment the index.

        movb DIR_SEG,IBDR       ; Write the register pointer.


        bra RETORNAR_I2C_ISR    ; Return to I2C_ISR.

        ;; The corresponding DS1307 register values are written
        ;; byte by byte.
W_BYTE:

        ldaa INDEX_RTC          ; Load into R1 the contents of
                                ; the interrupt index.

        ;; Check whether the last byte was already transmitted.
        cmpa #8
        beq INDEX_RTC_W_I9

        ldx #T_WRITE_RTC        ; T_WRITE_RTC is accessed by
        tfr A,B                 ; accumulator-offset indexed
        subb #1                 ; addressing with R2. R2 references
                                ; the interrupt index.

        brset IBSR,$01,*        ; Verify ACK received.

        movb B,X,IBDR           ; Write the respective byte to
                                ; configure the RTC.

        ;; If the last interrupt was not reached, the interrupt
        ;; index is incremented and control returns to I2C_ISR.
        inc INDEX_RTC
        bra RETORNAR_I2C_ISR

        ;; If the last byte was already transmitted, send the STOP signal.
INDEX_RTC_W_I9:
        brset IBSR,$01,*        ; Verify ACK received.

        bset BANDERAS,$02       ; Enable the per-second read
                                ; of the RTC.

        movb #$00,INDEX_RTC     ; Reset the interrupt index.

        bclr IBCR,#$20          ; Send STOP signal.

        bra RETORNAR_I2C_ISR    ; Return to I2C_ISR.

;***********************************************
;                  READ_RTC
;***********************************************
READ_RTC:
        ldaa INDEX_RTC          ; Load into R1 the contents of
                                ; the interrupt index.

        ldx #T_READ_RTC         ; T_READ_RTC is accessed by
        tfr A,B                 ; accumulator-offset indexed
        subb #3                 ; accumulator-offset indexed
                                ; the interrupt index.
        ;; Check whether it is the first interrupt.
        tsta
        beq INDEX_RTC_R_I1

        ;; Check whether it is the second interrupt.
        cmpa #01
        beq INDEX_RTC_R_I2

        ;; Check whether it is the third interrupt.
        cmpa #02
        beq INDEX_RTC_R_I3

        ;; Check whether it is the last interrupt.
        cmpa #10
        beq INDEX_RTC_R_I11

        ;; Check whether it is the second-to-last interrupt.
        cmpa #09
        beq INDEX_RTC_R_I9

LEER_IBDR:

        movb IBDR,B,X           ; Read the RTC register and store it
                                ; in the table in S12 memory.

FINALIZANDO_READ_RTC:
        inc INDEX_RTC           ; Increment the interrupt index.

FIN_READ_RTC:
        rts                     ; End of subroutine.

        ;; Sequence for the first interrupt.
INDEX_RTC_R_I1:
        ;; If this is the first interrupt, the pointer-register
        ;; address is transmitted.
        brset IBSR,$01,*        ; Wait for an ACK.

        movb DIR_SEG,IBDR       ; Write the register pointer.

        bra FINALIZANDO_READ_RTC ; Increment index and return.

        ;; Sequence for the second interrupt.
INDEX_RTC_R_I2:
        brset IBSR,$01,*        ; Wait for an ACK.

        bset IBCR,$04           ; Send REPEAT START signal.

        movb DIR_RD,IBDR        ; Write READ CALL ADDR on the bus.

        bra FINALIZANDO_READ_RTC ; Increment index and return.

        ;; Sequence for the third interrupt.
INDEX_RTC_R_I3:
        brset IBSR,$01,*        ; Wait for an ACK.

        bclr IBCR,$18           ; Enable TXACK and set Master
                                ; as RX.

        ldaa IBDR                ; Dummy read.

        bra FINALIZANDO_READ_RTC ; Increment index and return.

        ;; Sequence for the last interrupt.
INDEX_RTC_R_I11:
        ;; bset IBCR,#$10          ; Set Master as TX.

        movb #$00,INDEX_RTC     ; Reset the interrupt index.

        bclr IBCR,#$38          ; Send STOP signal.

        movb 1,X,BCD2           ; Read the contents of the RTC read
        movb 2,X,BCD1           ; array and put it on the 7SEG
                                ; display.

        ;; bclr IBCR,#$08           ; Put NACK in the frame.

        bra FIN_READ_RTC

        ;; Sequence for the second-to-last interrupt.
INDEX_RTC_R_I9:
        bset IBCR,#$08           ; Put NACK in the frame.

        movb IBDR,B,X           ; Read the RTC register and store it
                                ; in the table in S12 memory.

        bra FINALIZANDO_READ_RTC ; Increment index and return.


;***********************************************
;                  OC5_ISR
;***********************************************
OC5_ISR:
        ;; To generate an audible 440 KHz frequency.
        ldd TCNT
        addd #13636
        std TC5

        rti


;***********************************************
;          OC4_ISR
;***********************************************
OC4_ISR:
        ;; Counter to refresh the digit value.
        ldd CONT_7SEG           ; Increment the 7SEG counter
        addd #$01               ; to keep track of the 100ms
        std CONT_7SEG           ; at which BCD_7SEG must be called.

        ;; Counter for duty-cycle control.
        dec CONT_TICKS          ; Count down the tick counter,
        tst CONT_TICKS          ; which acts as N in the display
        ble CERO                ; multiplexing handling.

        ;; Determine the enable pulse width for the LEDs.
        ldaa CONT_TICKS         ; Taking N=100 and K=BRILLO,
        ldab #100               ; DT is determined by
        subb BRILLO             ; computing DT = N-K.
        stb DT
        cmpa DT                 ; If DT >= CONT_TICKS, enable
        ble HAB_LED             ; the 7SEG and disable the LEDs.

        ;; Check whether CONT_7SEG has reached its maximum.
        ldd CONT_7SEG
        cpd #5000
        lblt FIN_OC2_ISR        ; If it reached the maximum,
        movw #$0000,CONT_7SEG   ; reload CONT_7SEG to zero,
        jsr BCD_7SEG            ; and convert BCD variables to 7SEG.
        bra FIN_OC2_ISR

        ;; LEDS enable handling.
HAB_LED:
        movb #$FF,PTP           ; Load $FF, since it enables
                                ; no special value on the 7SEG.

        bclr PTJ,#$02           ; Disable the LEDs.

        movb LEDS,PORTB         ; Load the LEDS value to PORTB.
        bra FIN_OC2_ISR

        ;; DIGIT enable handling.
CERO:
        movb #100,CONT_TICKS    ; When CONT_TICKS has reached zero,
                                ; reload CONT_TICKS to 100.

        inc CONT_DIG            ; Also, CONT_DIG is incremented here
        bset PTJ,#$02           ; and the LEDs are enabled.

        ;; Check which digit to write, according to
        ;; the contents of CONT_DIG.
        brset CONT_DIG,#$03,HAB_DIG4
        brset CONT_DIG,#$02,HAB_DIG3
        brset CONT_DIG,#$01,HAB_DIG2

        ;; Enable digit 1
HAB_DIG1:
        ;; DIG1 enabling is special, it enables in two
        ;; cases, when CONT_DIG is 00 and when the count exceeded the value

        tst CONT_DIG            ; DIG1 enabling is special,
        beq LOAD_DIG1           ; since it enables when the count
        movb #$00,CONT_DIG      ; is zero or when it overflowed. In the
                                ; latter case the digit must be enabled
                                ; and the counter reset.

LOAD_DIG1:
        movb #$07,PTP           ; Enable DIG1 on PP
        movb DIG1,PORTB         ; and load its value to PORTB.
        bra FIN_OC2_ISR

        ;; Enable digit 2
HAB_DIG2:
        movb #$0B,PTP           ; Enable DIG2.
LOAD_DIG2:
        movb DIG2,PORTB         ; Load digit to PORTB.
        bra FIN_OC2_ISR

        ;; Enable digit 3
HAB_DIG3:
        movb #$0D,PTP           ; Enable DIG3
LOAD_DIG3:
        movb DIG3,PORTB         ; Load digit to PORTB.
        bra FIN_OC2_ISR

        ;; Enable digit 4
HAB_DIG4:
        movb #$0E,PTP           ; Enable DIG4
LOAD_DIG4:
        movb DIG4,PORTB         ; Load digit to PORTB.
        bra FIN_OC2_ISR

FIN_OC2_ISR:
        ;; Cont_Delay handling for LCD
        tst CONT_DELAY
        beq CARGAR_TC4          ; If CONT_DELAY != 0,
        dec CONT_DELAY          ; decrement its value.
CARGAR_TC4:
        ;; Read TCNT and reload the next value to compare in
        ;; TC2.
        ldd TCNT
        addd #60
        std TC4
        rti

;***********************************************
;          BCD_7SEG
;***********************************************
BCD_7SEG:
        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        psha
        pshb

        ldx #SEGMENT            ; Load the SEGMENT address into
                                ; X to access it with
                                ; accumulator-offset indexed
                                ; addressing.

        ;; Prepare DIG3
        ldaa BCD1
        anda #$0F               ; Extract the least significant
        psha                    ; nibble of BCD1 and push it.

        ;; Prepare DIG1
        ldaa BCD2
        anda #$0F               ; Extract the least significant
        psha                    ; nibble of BCD2 and push it.

        ;; Prepare DIG4
        ldaa BCD1               ; Extract the most significant nibble
        lsra                    ; of BCD1. To do so, the digit is
        lsra                    ; divided by 16.
        lsra
        lsra
        psha                    ; Once divided, it is pushed.

        ;; Prepare DIG2
        ldaa BCD2               ; Extract the most significant nibble
        lsra                    ; of BCD2. To do so, the digit is
        lsra                    ; divided by 16.
        lsra
        lsra
        psha                    ; Once divided, it is pushed.

        ;; Load the digit values
        pula
        movb A,X,DIG2           ; Load DIG2.
        pula
        movb A,X,DIG4           ; Load DIG4.
        pula
        movb A,X,DIG1           ; Load DIG1.
        pula
        movb A,X,DIG3           ; Load DIG3.

        ldaa T_READ_RTC         ; Extract the most significant nibble
        lsla                    ; of BCD2. To do so, the digit is
        lsla                    ; divided by 16.
        lsla
        lsla
        lsla
        lsla
        lsla

        tfr A,B
        adda DIG3
        staa DIG3
        addb DIG2
        stab DIG2




        ;; Restore accumulators and indices.
        pulb
        pula
        pulx
        rts

;***********************************************
;          INICIALIZAR_LCD
;***********************************************
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
CARGAR_LCD:

        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        pshy
        psha
        pshb

        ldaa ADD_L1             ;Send the ADD_L1 command to put
        jsr SEND_COMMAND        ;the cursor on line 1.
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
        movb D260uS,Cont_Delay
        jsr Delay               ; Wait 260uS.
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
        movb D260uS,Cont_Delay
        jsr Delay               ; Wait 260uS.
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
        movb D260uS,Cont_Delay
        jsr Delay               ; Wait 260uS.
        bclr PORTK,#$01         ; Set EN=0.

        ;; Load the least significant nibble into R1.
        pula
        anda #$0F
        lsla
        lsla

        ;; Load the least significant nibble into PORTK.
        sta PORTK               ;
        bset PORTK,#$03         ; Set RS=0 (command) and EN=1.
        movb D260uS,Cont_Delay
        jsr Delay               ; Wait 260uS.
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
DELAY:
        ;; Wait until CONT_DELAY reaches zero.
        tst CONT_DELAY
        bne DELAY
        ;; When it reaches zero, return.
        rts
