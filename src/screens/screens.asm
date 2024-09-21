;***********************************************
;                  TAREA #5
;***********************************************

#include "../../include/registers.inc"


;***********************************************
; REDIRECCIONAMIENTO DEL VECTOR DE INTERRUPCION
;***********************************************


        org $3E6A               ; Vec. interrupcón por Comparador.
        dw OC2_ISR

        org $3E70               ; Vec. interrupción RTI
        dw RTI_ISR


;***********************************************
; 	       DECLARACION DE MEMORIA
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
; 	     INICIO DE MENSAJES
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
; 	     CONFIGURACION DE HARDWARE
;***********************************************

		org $2000

	lds #$3BFF               ; Carga puntero de pila.

        ;; Configuración de LEDS
	movb #$FF,DDRB           ; Puerto B: escritura
        bset DDRJ,#$03           ; PJ1 escritura
	bclr PTJ,#$02            ; PJ1 como GND
        movb #$FF,DDRP           ; PORTJ: Entrada


	movb #$FF,PORTB         ; LEDS encendidos inicialmente

        ;; Configuración de PK para LCD
        movb #$FF,DDRK

        ;; Configuación de RTI_ISR
        movb #$25,RTICTL       ; Define interrupciones de 1ms
        bset CRGINT,#$80       ; Para habilitar interrupción RTI

        ;; Configuración de PTH_ISR
        bset PIEH,#$0D          ; Habilita interrupción de PH(3,2,0)
        bclr PPSH,#$0D          ; Selección de interrupción por
                                ; flanco decreciente

        ;; Configuración de OC2_ISR
        movb #$90,TSCR1         ; Habilita TCNT y funcion de TFFCA
        movb #$03,TSCR2         ; Prescalador de 8
        movb #$04,TIOS          ; Habilita el IOS2
        movb #$10,TCTL2         ; Canal 2 como Toggle
        movb #$04,TIE           ; Habilita TC2


;***********************************************
; 	   INICIALIZACIÓN_DE_VARIABLES
;***********************************************
        movb #$00,LOW
        movb #$00,BANDERAS      ; X:X:X:X:X:X:CARGAR_LCD:DIRECCION_LEDS
        movb #250,CONT_RTI      ; Para contar 0.25 s en RTI_ISR
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

        ;; Para generar ticks de 50 KHz.
        ldd TCNT
        addd #60
        std TC2

;***********************************************
; 	   PROGRAMA PRINCIPAL
;***********************************************

        brset PTIH,#$80,CONT_FREE_DES_ON
        brclr BANDERAS,$04,NO_PRIMER_UP_FREE
        jsr INICIALIZAR_LCD


ESPERE:
        jsr BIN_BCD             ; Se convierte siempre de BIN a BCD

        ;; Si la bandera de cargar mensaje está habilitada, actualice la LCD.
        ;; Sino, convierta a BCD.
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
        ;; Cuando han pasado 0.25s se varía LEDS y CONT_FREE
        dec CONT_RTI
        tst CONT_RTI
        bne FIN_RTI_ISR
        movb #250,CONT_RTI

        ;; Si PTIH.7 es 0, la cuenta es ascendente.
        brclr PTIH,#$80,CONT_FREE_ASC

        ;; Sino, es descendente.
CONT_FREE_DEC:
        bset BANDERAS,$02

        lda CONT_FREE
        jsr CUENTA_DECRECIENTE  ;Subrutina de manejo de cuenta decreciente
        sta CONT_FREE
        bra VARIAR_LEDS

        ;; Manejo de cuenta ascendente del FREE COUNTER.
CONT_FREE_ASC:
        bset BANDERAS,$02

        lda CONT_FREE
        jsr CUENTA_CRECIENTE    ;Subrutina de manejo de cuenta creciente
        sta CONT_FREE

VARIAR_LEDS:
        ;; Si la bandera de LEDS es 0, el movimiento es DER->IZQ
        brclr BANDERAS,$01,LEDS_DER_IZQ

        ;; Sino, es IZQ->DER
LEDS_IZQ_DER:
        movb LEDS,PORTB
        lsr LEDS
        brclr LEDS,#$01,FIN_RTI_ISR
        bclr BANDERAS,$01
        bra FIN_RTI_ISR

        ;; Cargar LEDS DER->IZQ
LEDS_DER_IZQ:
        movb LEDS,PORTB
        lsl LEDS
        brclr LEDS,#$80,FIN_RTI_ISR
        bset BANDERAS,$01

FIN_RTI_ISR:
        bset crgflg, #$80       ; Se limpia la interrupción
        rti

;***********************************************
; 	   PTH_ISR
;***********************************************
PTH_ISR:

        brclr PIFH,#$01,ESTADO_POT ; Identifica interrupción por brillo.

        ;; Si PTIH.6 es 0, la cuenta manual es ascendente.
        brclr PTIH,#$40,CONT_MAN_ASC

        ;; Sino, es descendente.
CONT_MAN_DEC:
        bset BANDERAS,$02

        ldaa CONT_MAN
        jsr CUENTA_DECRECIENTE
        sta CONT_MAN
        bra ESTADO_POT

        ;; Manejo de cuenta ascendente del MAN COUNTER.
CONT_MAN_ASC:
        bset BANDERAS,$02

        ldaa CONT_MAN
        jsr CUENTA_CRECIENTE
        sta CONT_MAN
        bra ESTADO_POT

        ;; Manejo de aumento o decremento de brillo.
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
        movb #$64,POT        ; Si se llega a lo mínimo y se decrementa el
                                ; brillo, va al máximo.
        bra SALIR_PTH

AUMENTAR_POT:
        ldaa POT
        adda #$05
        sta POT
        cmpa #$64
        ble SALIR_PTH
        movb #$00,POT ; Si se llega al tope, el brillo vuelve a cero.
SALIR_PTH:
        bset PIFH, $0D          ; Limpia la interrupción.
        rti

;***********************************************
;          MANEJO DE CARGA DE MENSAJE A LCD
;***********************************************
MSG_LCD:
        ;; Si PTIH.7 es 0, la cuenta free es ascendente y
        ;; por tanto se carga el mensaje respectivo.
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
;          MANEJO DE CUENTA CRECIENTE Y DECRECIENTE
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
        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        psha
        pshb

        ldaa CONT_MAN
        ldab #$07
        movb #$00,LOW
        ;; Aquí inicia conversión de CONT_FREE
NEXT_BIT_BCD1:
        lsla
        rol LOW
        ;; Aqui se carga R1 a TEMP
        psha
        ldaa LOW
        anda #$0F
        cmpa #$05
        blt NOT_5_ON_L_BCD1
        adda #$03
NOT_5_ON_L_BCD1:
        ;; Aqui se carga R1 a LOW
        psha
        ldaa LOW
        anda #$F0
        cmpa #$50
        blt NOT_5_ON_H_BCD1
        adda #$30
NOT_5_ON_H_BCD1:
        ;; Aquí se suma LOW a R1
        adda 0,SP
        sta LOW
        ;; Aquí se carga TEMP a R1
        ins
        pula
        dbeq B,FINALIZAR_BCD1
        bra NEXT_BIT_BCD1
FINALIZAR_BCD1:
        lsla
        rol LOW
        movb LOW,BCD1

        ;; Aquí inicia conversión de CONT_FREE
        ldaa CONT_FREE
        ldab #$07
        movb #$00,LOW
NEXT_BIT_BCD2:
        lsla
        rol LOW
        ;; Aqui se carga R1 a TEMP
        psha
        ldaa LOW
        anda #$0F
        cmpa #$05
        blt NOT_5_ON_L_BCD2
        adda #$03
NOT_5_ON_L_BCD2:
        ;; Aqui se carga R1 a LOW
        psha
        ldaa LOW
        anda #$F0
        cmpa #$50
        blt NOT_5_ON_H_BCD2
        adda #$30
NOT_5_ON_H_BCD2:
        ;; Aquí se suma LOW a R1
        adda 0,SP
        sta LOW
        ;; Aquí se carga TEMP a R1
        ins
        pula
        dbeq B,FINALIZAR_BCD2
        bra NEXT_BIT_BCD2
FINALIZAR_BCD2:
        lsla
        rol LOW
        movb LOW,BCD2

        ;; Se retornan acumuladores e índices.
        pulb
        pula
        pulx
        rts

;***********************************************
;          BCD_7SEG
;***********************************************
BCD_7SEG:
        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        psha

        ldx #SEGMENT
        ;; Prepara DIG3
        ldaa BCD2
        anda #$0F
        psha
        ;; Prepara DIG4
        ldaa BCD1
        anda #$0F
        psha
        ;; Prepara DIG2
        ldaa BCD2
        lsra
        lsra
        lsra
        lsra
        psha
        ;; Prepara DIG4
        ldaa BCD1
        lsra
        lsra
        lsra
        lsra
        psha

        ;; Carga los valores de los dígitos
        pula
        movb A,X,DIG2
        pula
        movb A,X,DIG4
        pula
        movb A,X,DIG1
        pula
        movb A,X,DIG3

        ;; Se retornan acumuladores e índices.
        pula
        pulx
        rts

;***********************************************
;          OC2_ISR
;***********************************************
OC2_ISR:
        ;; Cuenta para refrescar valor de dígitos.
        ldd CONT_7SEG
        addd #$01
        std CONT_7SEG

        ;; Cuenta para control por ciclo de trabajo.
        dec CONT_TICKS
        tst CONT_TICKS
        ble CERO
        ldaa CONT_TICKS

        ;; Determina el ancho de pulso habilitación de leds.
        ldab #100
        subb POT
        stb DT
        cmpa DT
        ble HAB_LED
        ldd CONT_7SEG
        cpd #5000
        lbne FIN_OC2_ISR
        movw #$0000,CONT_7SEG
        jsr BCD_7SEG            ;Convierte variables BCD a 7 segmentos.
        bra FIN_OC2_ISR

        ;; Manejo de habilitación de LEDS.
HAB_LED:
        movb #$FF,PTP
        bclr PTJ,#$03
        movb LEDS,PORTB
        bra FIN_OC2_ISR

        ;; Manejo de habilitación de DIGITOS.
CERO:
        movb #100,CONT_TICKS
        inc CONT_DIG
        bset PTJ,#$03
        brset CONT_DIG,#$03,HAB_DIG4
        brset CONT_DIG,#$02,HAB_DIG3
        brset CONT_DIG,#$01,HAB_DIG2

        ;; Habilita dígito 1
HAB_DIG1:
        tst CONT_DIG
        beq LOAD_DIG1
        movb #$00,CONT_DIG
LOAD_DIG1:
        movb #$07,PTP
        movb DIG1,PORTB
        bra FIN_OC2_ISR

        ;; Habilita dígito 2
HAB_DIG2:
        ldaa DIG2
        cmpa #$3F
        beq FIN_OC2_ISR
        movb #$0B,PTP
LOAD_DIG2:
        movb DIG2,PORTB
        bra FIN_OC2_ISR

        ;; Habilita dígito 3
HAB_DIG3:
        movb #$0D,PTP
LOAD_DIG3:
        movb DIG3,PORTB
        bra FIN_OC2_ISR

        ;; Habilita dígito 4
HAB_DIG4:
        ldaa DIG4
        cmpa #$3F
        beq FIN_OC2_ISR
        movb #$0E,PTP
LOAD_DIG4:
        movb DIG4,PORTB
        bra FIN_OC2_ISR

FIN_OC2_ISR:
        ;; Manejor de Cont_Delay para LCD
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
        jsr SEND_COMMAND        ;De iniDsp
        movb D40uS,Cont_Delay
        jsr Delay               ;40us
        inx
        ;; inca
        cpx #iniDsp+4
        bne SEGUIR_IniDSP
        ldaa #$01
        jsr SEND_COMMAND        ;De Clear Display
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
        jsr SEND_DATA        ;Char de Msg_L1
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
        jsr SEND_DATA        ;Char de Msg_L2
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
