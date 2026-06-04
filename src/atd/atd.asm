;***********************************************
;                  ASSIGNMENT 6
;***********************************************

#include "../../include/registers.inc"

;***********************************************
; INTERRUPT VECTOR REDIRECTION
;***********************************************
        ;; Redirection of the interrupt vector
        ;; for the analog-to-digital converter.
        org $3E52
        dw ATD0_ISR

        ;; Redirection of the interrupt vector
        ;; for channel 5 output compare.
        org $3E64
        dw OC5_ISR
;***********************************************
; 	       MEMORY DECLARATION
;***********************************************
        ;; Memory reservation for required variables
                org $1010
Nivel_PROM:     ds 2
NIVEL:          ds 1
VOLUMEN:        ds 2
CONT_OC:        ds 1
BCD1:           ds 1
BCD2:           ds 1
BCD_L:          ds 1
BCD_H:          ds 1


        ;; Messages to load.
        ;; They are in ASCII.
CR:     EQU $0D                 ; Carriage Return.
NL:     EQU $0A                 ; Line feed.
NP:     EQU $0C                 ; New page.
EOM:    EQU $03                 ; End of Message.

MSG0:   db NP
        FCC "MEDICION DE VOLUMEN"
        db CR,NL,EOM
MSG1:   FCC "VOLUMEN ACTUAL: "
        db EOM
MSG2:   ds 1
        db EOM
MSG3:   ds 1
        db CR,NL,EOM
MSG4:   FCC "Alarma: El Nivel esta Bajo"
        db CR,NL,EOM
MSG5:   FCC "Tanque lleno, Bomba Apagada"
        db CR,NL,EOM


;***********************************************
; 	     HARDWARE CONFIGURATION
;***********************************************

               org $2000
        ;; Load the stack pointer.
        lds #$3BFF

        ;; Relay configuration.
        bset DDRE,$04           ; PORTE.2 as output.
        bclr PORTE,$04          ; PORTE.2 off at power-up.

        ;; SC1 configuration
        movw #38,SC1BDH         ; SRB=38, for Data_Rate=8400 baud.

        movb #$02,SC1CR1        ; PE=1 and PT=0, to enable parity
                                ; bit with even parity.

        movb #$08,SC1CR2        ; TE=1, enables data transmission.

        ;; ATD configuration
        movb #$C2,ATD0CTL2      ; ADPU=1 to enable the ATD and
                                ; AFFC=1 for

        ;; A wait time is allowed so the
        ;; converter can enable.
        ldab #160
DEC_B:
        dbne B,DEC_B
        movb #$30,ATD0CTL3      ; Configures 6 conversions in a single
                                ; command.

        movb #$30,ATD0CTL4      ; Configures SRES8=0 for a
                                ; 10-bit conversion, SMP=$00 for
                                ; a sample time of 2 ATD periods,
                                ; and PRS=16 for a frequency of
                                ; about 700kHz.

        movb #$87,ATD0CTL5      ; DJM=1 to right-justify the result
                                ; and CC=CB=CA=1 to set the
                                ; potentiometer as the input for
                                ; the measurements.


        ;; OC5_ISR configuration
        movb #$90,TSCR1         ; Enables TCNT and TFFCA function
        movb #$06,TSCR2         ; Prescaler of 64
        movb #$20,TIOS          ; Enables IOS5
        movb #$20,TIE           ; C5I=1 to enable interrupt
                                ; on channel 5 output compare.

        ;; Enable interrupts
	cli		; Load 0 into I in CCR

;***********************************************
; 	     MAIN PROGRAM
;***********************************************
        ;; Variable initialization.
        ;; Since there is no special case, they are initialized to 0.
        movw #$00,Nivel_PROM
        movb #$00,NIVEL
        movw #$0000,VOLUMEN
        movb #$08,CONT_OC
        movb #$00,BCD1
        movb #$00,BCD2
        movb #$00,BCD_L
        movb #$00,BCD_H

        ;; Enable the output compare interrupt.
        ldd TCNT
        addd #46875
        std TC5

ESPERE:
        bra ESPERE
        end

;***********************************************
; 	             CALCULATION
;***********************************************
CALCULO:
        ;; Level calculation

        ;; A rule of three is used here to convert
        ;; the average level from bits to meters.
        ldd Nivel_PROM
        ldy #30
        emul                    ; Nivel_PROM * 30
        ldx #1024
        idiv                    ; (Nivel_PROM * 30)/1024
        tfr X,A
        sta NIVEL               ; NIVEL=(Nivel_PROM * 30)/1024

        ;; Volume calculation

        ;; For this step the radius and pi values are scaled
        ;; to work with decimals.
        ;; This gives 1-decimal precision.

        ldd #19375              ; (2.5^2)*100 * 3.1*10

        ldx #1000               ; Divide by 1000
                                ; to return to the
                                ; original scale

        idiv                    ; (r^2*pi)
        tfr X,Y
        lda NIVEL
        sex A,D
        emul                    ; (r^2*pi) * NIVEL
        std VOLUMEN             ; VOLUMEN = (r^2*pi) * NIVEL

        rts


;***********************************************
;          BIN_BCD
;***********************************************
        ;; Binary-to-BCD conversion subroutine seen in class.
BIN_BCD:
        ;; Push accumulators and indices used in the subroutine,
        ;; in case they were used in other subroutines.
        pshx
        psha
        pshb

        ;; Conversion of the tens and hundreds of
        ;; VOLUMEN starts here.
        ldab #$0F
        ;; R2 is pushed, since register RR1 will be used.
        pshb
        ldd 0,X
        movb #$00,BCD_L
        movb #$00,BCD_H
NEXT_BIT_BCD1:
        lsld
        rol BCD_L
        rol BCD_H
        ;; RR1 is loaded into TEMP here
        pshd
        ldaa BCD_L
        anda #$0F
        cmpa #$05
        blt NOT_5_ON_L_BCD1
        adda #$03
NOT_5_ON_L_BCD1:
        ;; R1 is loaded into LOW here
        psha
        ldaa BCD_L
        anda #$F0
        cmpa #$50
        blt NOT_5_ON_H_BCD1
        adda #$30
NOT_5_ON_H_BCD1:
        ;; LOW is added to R1 here
        adda 0,SP
        sta BCD_L
        ;; B is pulled and decremented, then tested for 0. If so,
        ;; the process ends; otherwise B is pushed again.
        ins
        leas 2,SP
        pulb
        dbeq B,FINALIZAR_BCD1
        pshb
        leas -2,SP
        ;; TEMP is loaded into RR1 here
        puld
        bra NEXT_BIT_BCD1
FINALIZAR_BCD1:
        lsla
        rol BCD_L
        rol BCD_H
        movb BCD_L,BCD1




        ;; Conversion of the most significant nibble,
        ;; the hundreds of VOLUMEN, starts here.
        ldaa BCD_H
        ldab #$07
        movb #$00,BCD_L
NEXT_BIT_BCD2:
        lsla
        rol BCD_L
        rol BCD_H
        ;; R1 is loaded into TEMP here
        psha
        ldaa BCD_L
        anda #$0F
        cmpa #$05
        blt NOT_5_ON_L_BCD2
        adda #$03
NOT_5_ON_L_BCD2:
        ;; R1 is loaded into LOW here
        psha
        ldaa BCD_L
        anda #$F0
        cmpa #$50
        blt NOT_5_ON_H_BCD2
        adda #$30
NOT_5_ON_H_BCD2:
        ;; LOW is added to R1 here
        adda 0,SP
        sta BCD_L
        ;; TEMP is loaded into R1 here
        ins
        pula
        dbeq B,FINALIZAR_BCD2
        bra NEXT_BIT_BCD2
FINALIZAR_BCD2:
        lsla
        rol BCD_L
        rol BCD_H
        movb BCD_L,BCD2


        ;; Restore accumulators and indices.
        pulb
        pula
        pulx
        rts


;***********************************************
; 	             OC5_ISR
;***********************************************
OC5_ISR:
        ;; Check whether the transmission counter has reached
        ;; zero, to know whether a datum must be transmitted.
        ;; Data is transmitted every 1s.
        tst CONT_OC
        bne DEC_CONT

        ;; Load header: "MEDICION DE VOLUMEN"
        ldx #MSG0
        jsr ESCRIBIR

        ;; Load message: "VOLUMEN ACTUAL"
        ldx #MSG1
        jsr ESCRIBIR

        ;; Convert volume to BCD.
        ldx #VOLUMEN
        jsr BIN_BCD

        ;; The most significant nibble of VOLUMEN is received via
        ;; memory in BCD2 and converted to ASCII.
        ldaa BCD2
        adda #$30

        ;; Load the most significant nibble to be sent via
        ;; SCI.
        sta MSG2
        ldx #MSG2
        jsr ESCRIBIR

        ;; The tens nibble and the units nibble of VOLUMEN
        ;; are received via memory in BCD1.

        ;; First the tens nibble is extracted and converted to
        ;; ASCII.
        ldaa BCD1
        lsra
        lsra
        lsra
        lsra
        adda #$30

        ;; Load the tens nibble to be sent via SCI.
        sta MSG2
        ldx #MSG2
        jsr ESCRIBIR

        ;; Extract the units nibble and convert it to ASCII.
        ldaa BCD1
        anda #$0F
        adda #$30


        ;; Load the units nibble to be sent via SCI.
        sta MSG3
        ldx #MSG3
        jsr ESCRIBIR

        ;; Check whether VOLUMEN =< 15%
        ldaa NIVEL
        cmpa #5
        bgt PREGUNTAR_30        ; If NIVEL>15%, ask
                                ; whether NIVEL>30%

        bset PORTE,$04          ; If NIVEL=<15%, activate
                                ; relay

        ;; Check whether VOLUMEN =< 30%
PREGUNTAR_30:

        ;; If VOLUMEN =< 30% && RELE = ON,
        ;; the alarm message is printed.
        brclr PORTE,$04,RECARGAR_OC
        cmpa #9
        bgt PREGUNTAR_90
        ldx #MSG4
        jsr ESCRIBIR
        bra RECARGAR_OC

        ;; Check whether VOLUMEN =< 90%
PREGUNTAR_90:
        cmpa #27
        blt RECARGAR_OC

        ;; VOLUMEN > 90%, the tank-full message is printed.
        ldx #MSG5
        jsr ESCRIBIR
        bclr PORTE,$04          ; If VOLUMEN > 90%, RELE = OFF.

RECARGAR_OC:
        movb #$08,CONT_OC       ; Reload CONT_OC.
        bra FIN_OC5

DEC_CONT:
        dec CONT_OC             ; Reduce CONT_OC.

FIN_OC5:
        ;; Clear the interrupt flags and load the next
        ;; value to compare in TC5.
        ldd TCNT
        addd #46875
        std TC5
        rti

        ;; Data-write subroutine
ESCRIBIR:
        ldaa SC1SR1             ; Read status register.
        ldab #$00
RETORNO:
        ldaa B,X                ; Load datum into R1.
        cmpa #EOM
        beq FIN_ESCRIBIR        ; If DATO=EOM, finish.
L1:     brclr SC1SR1,$80,L1     ; Wait for transmission complete.
        sta SC1DRL              ; Load datum to transmit.
L2:     brclr SC1SR1 #$40 L2
        incb                    ; Increment register offset.
        bra RETORNO
FIN_ESCRIBIR:
        rts


;***********************************************
; 	             ATD0_ISR
;***********************************************
ATD0_ISR:
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
        stx Nivel_PROM          ; The average is stored in Nivel_PROM.

        ;; Call CALCULO to compute NIVEL and VOLUMEN.
        jsr CALCULO

        ;; Re-enable the ATD interrupt.
        movb #$87,ATD0CTL5
        rti
