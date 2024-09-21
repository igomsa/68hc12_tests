;***********************************************
;                  Proyecto Micros
;***********************************************

#include "../../include/registers.inc"

;***********************************************
; REDIRECCIONAMIENTO DEL VECTOR DE INTERRUPCION
;***********************************************

	org $3E4C               ; Vec. interrupción PTH.
	dw CALCULAR

        org $3E52               ; Vec. interrupción ATD.
        dw ATD_ISR

        org $3E5E               ; Vec. interrupción TCNT overflow.
        dw TCNT_ISR

        org $3E66               ; Vec. interrupcón Comparador Ch4.
        dw OC4_ISR

        org $3E70               ; Vec. interrupción RTI.
        dw RTI_ISR

;***********************************************
; 	       DECLARACION DE MEMORIA
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

;*********** INICIALIZACIÓN DE LCD ***********
iniDsp          db $04
FUNCTION_SET1   db $28
FUNCTION_SET2   db $28
ENTRY_MODE      db $06
DISPLAY_ON_OFF  db $01

;*********** INICIO DE MENSAJES ***********
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
; 	     CONFIGURACION DE HARDWARE
;***********************************************
		org $2000

	lds #$3BFF               ; Carga puntero de pila.

        ;; Configuración de LEDS
	movb #$FF,DDRB          ; PB: escritura
        bset DDRJ,#$02          ; PJ1 escritura
	bclr PTJ,#$02           ; PJ1 como GND

        movb #$FF,DDRP         ; PP: escritura
        movb #$0F,PTP          ; 7 seg desab.
	movb #$00,PORTB         ; LEDS apagados inicialmente

        ;; Configuración Teclado.
        movb #$01,PUCR          ; Habilita resistencias pull-up de PA
        movb #$F0,DDRA          ; PA4-7: salida
                                ; PA0-3: entrada

        ;; Configuración de PK para LCD
        movb #$FF,DDRK

        ;; ;; Configuación de RTI_ISR
        movb #$23,RTICTL       ; Define interrupciones de 1ms
        bset CRGINT,#$80       ; Para habilitar interrupción RTI


        ;; Configuración PTH.
        bclr DDRH,$C0           ; PH7,6: lectura
        bclr PPSH,#$09          ; Selección de interrupción por
                                ; flanco decreciente
        movb #$00,PIEH          ; Deshabilita todas interrupciones PH.


        ;; Configuración de OC4_ISR
        movb #$80,TSCR1         ; Habilita TCNT y funcion de TFFCA
        movb #$03,TSCR2         ; Prescalador de 8. TCNT ovef. deshab.
        movb #$10,TIOS          ; Habilita el IOS4
        movb #$01,TCTL1         ; Canal 4 como Toggle
        movb #$10,TIE           ; Habilita TC4

        ;; Configuración del ATD
        movb #$C2,ATD0CTL2
        ldab #160
DEC_B:
        dbne B,DEC_B
        movb #$30,ATD0CTL3
        movb #$97,ATD0CTL4
        ;; movb #$87,ATD0CTL5


;***********************************************
; 	   INICIALIZACIÓN_DE_VARIABLES
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

        ;; Inicialización de Arreglo
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

        ;; Para generar ticks de 50 KHz.
        ldd TCNT
        addd #60
        std TC4


;***********************************************
; 	   PROGRAMA PRINCIPAL
;***********************************************
        ;; jsr INICIALIZAR_LCD
        bra M_CONF

ESPERAR:
        brset PTIH,$C0,M_MED
        movb #$00,VELOC
        bclr BANDERAS+1,$10       ; Se desactiva bandera de ALERTA.
        bclr TSCR2,$80
        bclr PIEH,$09           ; Deshabilita interrupción de PH(3,0).
        brclr PTIH,$C0,M_CONF
M_LIB:
        ;; bclr BANDERAS+1,$04
        jsr MODO_LIBRE
        bra ESPERAR
M_MED:
        bset TSCR2,$80          ; Habilita interrupción TCNT.
        bset PIEH,$09          ; Habilita interrupción de PH(3,0)
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

        ;; Si ya se imprimió el mensaje, no lo imprima.
        ldaa BANDERAS+1
        anda #$C0
        cmpa #$00
        beq FIN_MODO_LIBRE

        ;; ;; Si ya se imprimió el mensaje, no lo imprima.
        ;; brclr BANDERAS+1,$C0,SOLICITAR_VLIM

        movb #$04,LEDS          ; Carga patrón de LEDS respectivo.

        movb #$BB,BIN1
        movb #$BB,BIN2

        ;; Carga de mensaje
        jsr INICIALIZAR_LCD
        ldx #MSG0
        ldy #MSG1
        jsr CARGAR_LCD

        ;; ;; Indica mensaje ya impreso.
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
        ;; Descripción:
        ;; Esta subrutina implementa el MODO CONFIG.
        ;; En este modo se configura la velocidad máxima permitida.
        ;; En esta subrutina se verifica que la velocidad máxima
        ;; ingresada por el usuario esté entre 45 y 90 km/h.
        ;; Es la primera subrutina al encender la tarjeta, y hasta
        ;; que no se ingrese un valor

        ;; Entradas:
        ;; Bandera ARRAY_OK por memoria
        ;; Variable V_LIM por memoria, desde BIN_BCD

        ;; Salidas:
        ;; Variable LEDS por memoria
        ;; Variable BIN1 por memoria
        ;; Variable ARRAY_OK por memoria

MODO_CONFIG:

        pshy
        pshx
        pshb
        psha

        ;; Si ya se imprimió el mensaje, no lo imprima.
        ldaa BANDERAS+1
        anda #$C0
        cmpa #$40
        beq SOLICITAR_VLIM


        movb V_LIM,BIN1

        ;; ;; Si ya se imprimió el mensaje, no lo imprima.
        ;; brset BANDERAS+1,$40,SOLICITAR_VLIM

        movb #$01,LEDS          ; Carga patrón de LEDS respectivo.

        ;; Carga de mensaje
        jsr INICIALIZAR_LCD
        ldx #MSG2
        ldy #MSG3
        jsr CARGAR_LCD

        ;; Indica mensaje ya impreso.
        ldaa BANDERAS+1
        anda #$3F
        adda #$40
        staa BANDERAS+1

SOLICITAR_VLIM:

        jsr TAREA_TECLADO

        ;; Se consulta si ARRAY_OK está habilitado.
        brclr BANDERAS+1,#$04,NO_ARRAY_OK

        ;; Si ARRAY_OK=1, se convierte la velocidad límite a BIN y se
        ;; verifica que esté en el rango aceptado.

        bclr BANDERAS+1,$04     ; Ya que, sea que el valor ingresado
                                ; esté o no en el rango aceptable,
                                ; siempre se borra la bandera de
                                ; ARRAY_OK, la misma se borra aquí.

        jsr BCD_BIN             ; Aquí se convierte el valor a BIN.

        ;; Aquí se comprueba si 45km/h =< V_LIM =< 90km/h.
        ldaa V_LIM
        cmpa #45
        blt FUERA_DE_RANGO
        cmpa #90
        bgt FUERA_DE_RANGO


        ;; Si el valor está dentro del rango aceptable, este se guarda
        ;; a BIN1.
DENTRO_DE_RANGO:
        movb V_LIM,BIN1
        ;; bclr BANDERAS+1,$04
        bra FIN_MODO_CONFIG

        ;; Si el valor no está en el rango aceptado, dicho valor se
        ;; sigue esperando por un valor válido introducido.
FUERA_DE_RANGO:
        movb #$00,V_LIM
        movb #$00,BIN1
        movb #$BB,BIN2
        bra FIN_MODO_CONFIG

        ;; Aquí se ingresa cuando aún no se ha ingresado una cantidad
        ;; válida en el teclado.
NO_ARRAY_OK:
        tst V_LIM
        bne FIN_MODO_CONFIG

        bra SOLICITAR_VLIM

        ;; Aquí se termina la subrutina.
FIN_MODO_CONFIG:

        pula
        pulb
        pulx
        puly

        rts

;***********************************************
;          MODO_MEDICION
;***********************************************
        ;; Descripción:
        ;; Esta subrutina implementa el MODO COMPENTECIA.
        ;; En este modo se llama a la subrutina PANT_CTRL si la
        ;; VELOC != 0. Al entrar en la subrutina, se asegura que BIN1
        ;; y BIN2 estén en $BB, para que inicialmente se mantenga los
        ;; 7SEG apagados. Cuando se sale de este modo, se borra las
        ;; variables VELOC y ALERTA.

        ;; Entradas:
        ;; Variable VELOC por memoria

        ;; Salidas:
        ;; Variable BIN1 por memoria
        ;; Variable BIN2 por memoria
        ;; Variable VELOC por memoria
        ;; Variable ALERTA por memoria

MODO_MEDICION:
        pshy
        pshx
        pshb
        psha

        ;; Si ya se imprimió el mensaje, no lo imprima.
        ldaa BANDERAS+1
        anda #$C0
        cmpa #$80
        beq MEDICION_RET

        movb #$BB,BIN1
        movb #$BB,BIN2


        movb #$02,LEDS          ; Carga patrón de LEDS respectivo.

        ;;--------------- Carga de mensaje ---------------
        ;; Se cargan los mensajes de:
        ;; X: MODO MEDICION
        ;; Y:   ESPERANDO
        jsr INICIALIZAR_LCD
        ldx #MSG4
        ldy #MSG8
        jsr CARGAR_LCD


        ;; Indica mensaje ya impreso.
        ldaa BANDERAS+1
        anda #$3F
        adda #$80
        staa BANDERAS+1

MEDICION_RET:
        ;; Si PH0_PRES=1, imprime "CALCULANDO".
        brclr BANDERAS,$02,CONTINUAR_MED

        ;; Carga mensaje de "CALCULANDO"
        jsr INICIALIZAR_LCD
        ldx #MSG4
        ldy #MSG6
        jsr CARGAR_LCD


        bclr BANDERAS,$02

        ;;------- Funciones generales de la subrutina ------
CONTINUAR_MED:
        ;; Se carga $BB en BIN1 y BIN2 para asegurar que se
        ;; encuentran en este estado al inicio de la subrutina.
        ;; movb #$BB,BIN1
        ;; movb #$BB,BIN2

        ;; Se prueba si VELOC=0. Si lo es, se termina la subrutina.
        tst VELOC
        beq FIN_MEDICION
        jsr PANT_CTRL           ; Si VELOC != 0, se llama a PANT_CTRL.
        ;; movb #$00,VELOC         ; Limpia VELOC al final de subruntina.
        ;; bset BANDERAS+1,$10     ; Se limpia bandera de ALERTA.


FIN_MEDICION:

        pula
        pulb
        pulx
        puly

        rts

;***********************************************
; 	             RTI_ISR
;***********************************************
        ;; Descripción:
        ;; Esta subrutina reduce el contador de rebotes cada 1 ms.

        ;; Entradas:
        ;; Variable CONT_REB por memoria

        ;; Salidas:
        ;; Variable CONT_REB por memoria

RTI_ISR:
        ;; Reduce el valor de CONT_REB si este es diferente de cero.
        tst CONT_REB
        beq RETORNAR
        dec CONT_REB

RETORNAR:
        bset crgflg, #$80       ; Se rehabilita la interrupción
        rti

;***********************************************
;          TCNT_ISR
;***********************************************
        ;; Descripción:
        ;; Esta subrutina realiza dos tareas:
        ;; 1. Incrementar TICK_VEL para el cálculo de VELOC.
        ;; 2. Control de tiempos de retardo de cambio de mensaje en las
        ;; pantallas. Para ello se decrementa TICK_EN y TICK_DIS si no
        ;; están en cero. Cuando TICK_EN=0, se hace PANT_FLAG=1. Cuando
        ;; TICK_DIS=0, se hace PANT_FLAG=0.

        ;; Entradas:
        ;; Variable TICK_EN por memoria
        ;; Variable TICK_DIS por memoria

        ;; Salidas:
        ;; Variable TICK_EN por memoria
        ;; Variable TICK_DIS por memoria
        ;; Bandera PANT_FLAG por memoria

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
        ;; Se increcmenta los ticks de velocidad.
        ldaa TICK_VEL
        cmpa #$FF
        bhs NO_INC
        inc TICK_VEL
NO_INC:

        brclr BANDERAS+1,$20,TCNT_ISR_FIN

        ;; ;; Si PANT_FLAG=1, se pregunta si TICKS_DIS=0.
        ;; brset BANDERAS+1,$08,ASK_PANT_FLG_TCNT

        ;; Se consulta si TICK_EN=0, en cuyo caso, se hace PANT_FLG=1
        ldd TICK_EN
        cpd #$0000
        bls HAB_PANT_FLG

        ;; Se decrementa el valor de TICK_EN si diferente de cero.
        ldx TICK_EN
        dex
        stx TICK_EN
        ;; com LEDS

        bra TCNT_ISR_FIN

;; ASK_PANT_FLG_TCNT:
HAB_PANT_FLG:
        ;; Se consulta si TICK_EN=0, en cuyo caso, se hace PANT_FLG=1
        ldd TICK_DIS
        cpd #$0000
        bls DESHAB_PANT_FLG

        ;; Se habilita PANT_FLG.
        bset BANDERAS+1,$08
        ;; Se decrementa el valor de TICK_DIS si diferente de cero.
        ldx TICK_DIS
        dex
        stx TICK_DIS

        bra TCNT_ISR_FIN

DESHAB_PANT_FLG:
        ;; Se deshabilita PANT_FLG y ALERTA.
        bclr BANDERAS+1,$18
TCNT_ISR_FIN:
        ;; Se limpia la bandera de interrupción por overflow.
        bset TFLG2,$80
        rti

;***********************************************
;          ATD_ISR
;***********************************************
;; Descripción:
        ;; Esta subrutina implementa el MODO CONFIG.
        ;; En este modo se configura la velocidad máxima permitida.
        ;; En esta subrutina se verifica que la velocidad máxima
        ;; ingresada por el usuario esté entre 45 y 90 km/h.
        ;; Es la primera subrutina al encender la tarjeta, y hasta
        ;; que no se ingrese un valor

        ;; Entradas:
        ;; Variable CONT_7SEG por memoria
        ;; Variable CONT_TICKS por memoria
        ;; Variable CONT_200 por memoria
        ;; Variable DISP1 por memoria
        ;; Variable DISP2 por memoria
        ;; Variable DISP3 por memoria
        ;; Variable DISP4 por memoria

        ;; Salidas:
        ;; Variable CONT_7SEG por memoria
        ;; Variable CONT_TICKS por memoria
        ;; Variable CONT_200 por memoria
        ;; Variable PTP por memoria
        ;; Variable PORTB por memoria
        ;; Variable PTJ por memoria

ATD_ISR:
        ;; Se leen las 6 conversiones y se suman todas en RR1 para
        ;; luego determinar su promedio.
        ldd ADR00H
        addd ADR01H
        addd ADR02H
        addd ADR03H
        addd ADR04H
        addd ADR05H

        ;; Se determina el promedio de la medición.
        ldx #6
        idiv

        ;; Se guarda el valor medido en POT.
        tfr X,Y
        ;; staa POT         ; El promedio se guarda en Nivel_PROM.

        ;; Se calcula brillo como: [BRILLO = (20 X POT)/255].
        ldd #20
        ldx #255
        emul                    ; Calcula (20 X POT)
        idiv                    ; Calcula (20 X POT)/255
        tfr X,A
        staa BRILLO

        ;; Se rehabilita la interrupción por ATD.
        ;; movb #$87,ATD0CTL5
        rti

;***********************************************
;          OC4_ISR
;***********************************************
;; Descripción:
        ;; Esta subrutina implementa el MODO CONFIG.
        ;; En este modo se configura la velocidad máxima permitida.
        ;; En esta subrutina se verifica que la velocidad máxima
        ;; ingresada por el usuario esté entre 45 y 90 km/h.
        ;; Es la primera subrutina al encender la tarjeta, y hasta
        ;; que no se ingrese un valor

        ;; Entradas:
        ;; Variable CONT_7SEG por memoria
        ;; Variable CONT_TICKS por memoria
        ;; Variable CONT_200 por memoria
        ;; Variable DISP1 por memoria
        ;; Variable DISP2 por memoria
        ;; Variable DISP3 por memoria
        ;; Variable DISP4 por memoria

        ;; Salidas:
        ;; Variable CONT_7SEG por memoria
        ;; Variable CONT_TICKS por memoria
        ;; Variable CONT_200 por memoria
        ;; Variable PTP por memoria
        ;; Variable PORTB por memoria
        ;; Variable PTJ por memoria

OC4_ISR:
        ;; Cuenta para refrescar valor de dígitos.
        ldd CONT_7SEG           ; Se incrementa el contador de 7SEG
        addd #$01               ; para llevar la cuenta de los 100ms
        std CONT_7SEG           ; en que se debe llamar a BCD_7SEG.

        ;; Se consulta si el valor de CONT_7SEG ya llegó a su máxumo.
        ;; ldd CONT_7SEG
        cpd #5000
        lbne ASK_TICKS        ; Si alcanzó el máximo,
        movw #$0000,CONT_7SEG   ; se recarga CONT_7SEG en cero.
        jsr CONV_BIN_BCD        ; Se convierte BIN1 y BIN2 a BCD,
        jsr BCD_7SEG            ; y se convierte variables BCD a 7SEG.

        ;; Se consulta si el valor CONT_200 llegó a su máximo.
        dec CONT_200
        tst CONT_200
        lbhi ASK_TICKS         ; Si no llegó máximo, finalizar.
        movb #$02,CONT_200      ; Si llegó, recargar contador.
        movb #$87,ATD0CTL5      ; Se rehabilita
        jsr PATRON_LEDS

        ;; ;; Cuenta para habilitar la conversión en el ATD.
        ;; ldd CONT_200            ; Se incrementa el contador de ATD
        ;; addd #$01               ; para habilitar la conversión cada
        ;; std CONT_200            ; 200ms del potenciómetro.

ASK_TICKS:
        ;; Cuenta para control por ciclo de trabajo.
        dec CONT_TICKS          ; Se descuenta el contador de ticks
        tst CONT_TICKS          ; que funciona como el N en el manejo
        bls CERO                ; de multiplexación de pantallas.

        ;; Determina el ancho de pulso de habilitación de LEDs.
        ldaa CONT_TICKS         ; Tomando a N=100  y a K=POT,
        ldab #100               ; se determina el valor de DT al
        subb BRILLO                ; hacer DT = N-K.
        stb DT
        cmpa DT                 ; Si DT >= CONT_TICKS, se habilitan
        bls HAB_LED             ; los 7SEG y deshabilita los LEDs.

        lbra FIN_OC4_ISR

        ;; Manejo de habilitación de LEDS.
HAB_LED:
        movb #$FF,PTP           ; Carga $FF, pues no habilita
                                ; ningún valor especial en 7SEG.
        bclr PTJ,#$02           ; Se habilitan los LEDs.
        movb LEDS,PORTB         ; Se carga el valor de LEDS a PORTB.
        bra FIN_OC4_ISR

        ;; Manejo de habilitación de DIGITOS.
CERO:
        movb #100,CONT_TICKS    ; Cuándo CONT_TICKS ha llegado a cero
                                ; se recarga CONT_TICKS en 100.

        inc CONT_DIG            ; Además, aquí se incrementa CONT_DIG
        bset PTJ,#$02           ; y se deshabilitan los LEDs.

        ;; Se consulta cuál es el dígito a escribir, de acuerdo con
        ;; el contenido de CONT_DIG.
        brset CONT_DIG,#$03,HAB_DISP4
        brset CONT_DIG,#$02,HAB_DISP3
        brset CONT_DIG,#$01,HAB_DISP2

        ;; Habilita dígito 1
HAB_DISP1:
        ;; La habilitación de DISP1 es especial, si habilita en dos
        ;; casos, cuando se tiene un valor de 00 en CONT_DIG y cuando la cuenta excedió el valor

        tst CONT_DIG            ; La habilitación de DISP1 es especial,
        beq LOAD_DISP1           ; pues se habilita cuando la cuenta
        movb #$00,CONT_DIG      ; es cero o cuando se rebasó. En el
                                ; último caso se debe habilitar el
                                ; dígito y reestablecer el contador.

LOAD_DISP1:
        movb #$07,PTP           ; Se habilita el DISP1 en el PP
        movb DISP1,PORTB         ; y se carga su valor en PORTB.
        bra FIN_OC4_ISR

        ;; Habilita dígito 2
        ;; El dígito 2 tiene una particularidad, que cuando no se
        ;; imprimen las decenas, permanece inhabilitado.
HAB_DISP2:
        ldaa DISP2
        cmpa #$3F               ; Si el dígito es 0,
        beq FIN_OC4_ISR         ; no se imprime.

        ;; Si no es 0, se habilita DISP2 y se carga en el valor
        ;; correspondiente en PORTB.
        movb #$0B,PTP           ; Habilita DISP2.
LOAD_DISP2:
        movb DISP2,PORTB         ; Carga dígito en PORTB.
        bra FIN_OC4_ISR

        ;; Habilita dígito 3
HAB_DISP3:
        movb #$0D,PTP           ; Habilita DISP3
LOAD_DISP3:
        movb DISP3,PORTB         ; Carga dígito en PORTB.
        bra FIN_OC4_ISR

        ;; Habilita dígito 4
        ;; El dígito 4 tiene una particularidad, que cuando no se
        ;; imprimen las decenas, permanece inhabilitado.
HAB_DISP4:
        ldaa DISP4
        cmpa #$3F               ; Si el dígito es 0,
        beq FIN_OC4_ISR         ; no se imprime.
        movb #$0E,PTP           ; Habilita el DISP4
LOAD_DISP4:
        movb DISP4,PORTB         ; Carga dígito en PORTB.
        bra FIN_OC4_ISR

FIN_OC4_ISR:
        ;; Manejor de Cont_Delay para LCD
        tst CONT_DELAY
        beq CARGAR_TC4          ; Si CONT_DELAY != 0,
        dec CONT_DELAY          ; se decrementa su valor.
CARGAR_TC4:
        ;; Se lee TCNT y se recarga el próximo valor a comparar en
        ;; TC4.
        ldd TCNT
        addd #60
        std TC4
        movb #$10,TFLG1
        rti

;***********************************************
;          PANT_CTRL
;***********************************************
        ;; Descripción:
        ;; Esta subrutina es la encargada de calcular el retardo de
        ;; tiempo, con base en VELOC, para cambiar el mensaje en la
        ;; pantalla cuando el vehículo esté a 100m de la meta y luego
        ;; cuando el vehículo la haya superado. Para ello se calculan
        ;; aquí los contadores de ticks necesarios para desplegar el
        ;; primer mensaje y para cambiarlo luego de que el vehículo
        ;; supere la pantalla. Ya que el cálculo de ticks se hace
        ;; solo la primera vez que se en la subrutin, se emplea una
        ;; bandera llamada CALC_TICKS. Los ticks son decrementados
        ;; por la subrutina TCNT_ISR. En un nuevo llamado a la
        ;; subrutina, se espera PANT_FLAG=1 para cambiar el mensaje
        ;; en la pantalla  y desplegar el valor de la velocidad y la
        ;; velocidad límite en la pantalla 7SEG.

        ;; Además, esta subrutina habilita la bandera de ALERTA, si la
        ;; velocidad está fuera del rango aceptado.

        ;; Entradas:
        ;; Variable VELOC por memoria
        ;; Variable V_LIM por memoria
        ;; Bandera TICK_EN por memoria

        ;; Salidas:
        ;; Variable BIN1 por memoria
        ;; Variable BIN2 por memoria
        ;; Bandera ALERTA por memoria

PANT_CTRL:

        pshy
        pshx
        pshb
        psha

        ;; movb #$FF,LEDS
        bclr PIEH,$09           ; Deshabilita interrupción de PH(3,0).

        ;; Se verifica si 30km/h <= VELOC <= V_LIM
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

        movw #$0001,TICK_EN       ; Se carga 1 para encender la pantalla
                                ; rápido, conteniendo el mensaje de
                                ; alerta.

        movw #$005C,TICK_DIS      ; Se carga el valor respectivo para
                                ; hacer que la pantalla permanezca
                                ; encendida por 2s.
;; CARGAR_AA_VELOC:
        ;; Secuencia a realizarse cuando la velocidad medida excede los
        ;; límites.
        movb #$AA,VELOC         ; Se carga "--" en 7SEG de velocidad.

        bset BANDERAS+1,$20     ; Se hace CALC_TICKS=1.

        bra ASK_PANT_FLG

ALERTA:
        bset BANDERAS+1,$10       ; Se activa bandera de ALERTA.

ASK_CALC_TICKS:
        ;; Si CALC_TICKS=0, se calcula número de ticks.
        brclr BANDERAS+1,$20,CALC_TICKS

        ;; movb #$00,LEDS
ASK_PANT_FLG:
        ;; Si PANT_FLAG=1, se pregunta si está encendida.
        brset BANDERAS+1,$08,PANT_FLAG_EN

        ;; Si PANT_FLAG=0, se carga el mensaje de velocidad.
PANT_FLAG_DIS:
        ldaa BIN1
        cmpa #$BB
        beq FIN_PANT_CTRL

        ;; Se carga mensaje de ESPERANDO...
        jsr INICIALIZAR_LCD
        ldx #MSG4
        ldy #MSG8
        jsr CARGAR_LCD

        ;; Se carga $BB en BIN1 y BIN2 para asegurar que se
        ;; encuentran en este estado al inicio de la subrutina.
        movb #$BB,BIN1
        movb #$BB,BIN2
        movb #$00,VELOC
        bset PIEH,$09           ; Habilita interrupción de PH(3,0).
        bclr BANDERAS+1,$20     ; Se hace CALC_TICKS=0.
        bra FIN_PANT_CTRL

PANT_FLAG_EN:
        ldaa BIN1
        cmpa #$BB
        bne FIN_PANT_CTRL

        ;; Si se está en el tiempo de pantalla habilitada, e imprimiendo
        ;; el valor respectivo a 100m de la meta, se carga el mensaje
        ;; respectivo.
        jsr INICIALIZAR_LCD
        ldx #MSG4
        ldy #MSG5
        jsr CARGAR_LCD

        ;; Se cargan los valores de velocidad límite y velocidad medida
        ;; para ser desplegados en los 7SEG.
        movb V_LIM,BIN1
        movb VELOC,BIN2
        bra FIN_PANT_CTRL

CALC_TICKS:
        ;; Se calculan los ticks correspondientes a la pantalla
        ;; habilitada y deshabilitada.
        ldaa VELOC              ; tiempo de ticks a partir de la
        tfr A,X                 ; velocidad.
        ldd #36000                ; Convierte km/h a m/s y determina el
        idiv
        tfr X,D

        ;; Se calcula el valor de los ticks a partir del tiempo
        ;; estimado en que se recorren 100m, respecto a la velocidad
        ;; promedio calculada.
        ;; Se usa la siguiente fórmula:
        ;; Tiempo = (8*(2^16)*Ticks)/(24x10^6)
        ;;        => Ticks = ((24x10^6)*Time)/(8*(2^16))
        ;;        => Ticks = 46*Time
        ldy #46
        emul
        ldx #100
        idiv
        tfr X,D

        std TICK_EN             ; Se cargan ticks para enable.
        ;; lsld                    ; TICK_DES=TICK_EN*2, se multiplica x2.
        std TICK_DIS            ; Se cargan ticks para disable, y ya que
        bset BANDERAS+1,$20     ; Se hace CALC_TICKS=1.

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
        ;; Descripción:
        ;; Esta es la subrutina de servicio de interrupciones del
        ;; puerto H. Se habilita en el MODO_MEDICION. Se encarga de
        ;; calcular la velocidad del vehículo en KM/H. Se tienen dos
        ;; interrupciones diferentes:
        ;; * PH3: Pone TICK_VEL en cero.
        ;; * PH0: Se lee TICK_VEL y se calcula veloc. de vehículo, a
        ;; partir de dicho valor. Además, se reestablece TICK_VEL y se
        ;; imprime mensaje de "CACULANDO..."

        ;; Entradas:
        ;; Variable TICK_VEL por memoria

        ;; Salidas:
        ;; Variable VELOC por memoria

CALCULAR:

        tst CONT_REB
        bne SALIR_CALCULAR

        brset PIFH,#$01,PH0_PULSADO
        brset PIFH,#$08,PH3_PULSADO
        bra SALIR_CALCULAR

        ;; Inicial conteo de ticks para calcular velocidad.
PH3_PULSADO:
        bset BANDERAS,$02
        movb #$00,TICK_VEL
        movb #$0A,CONT_REB
        bra SALIR_CALCULAR

PH0_PULSADO:
        ;; Se calcula la velocidad a partir de TICK_VEL.
        ;; Se tiene que:
        ;;  VELOC = (40m/(TICK_VEL*20)) * (3600/1000) [km/h]
        ;;  VELOC = 144/(TICK_VEL*T_int_overflow) [km/h]
        ;; Sin embargo, ya que  T_int_overflow = 0.021845333.. es
        ;; requerido escalar dicho valor. Por tanto, se multiplica
        ;; T_int_overflow por 10000, para obtener una exactitud de 4
        ;; cifras significativas. Para obtener el valor en la escala
        ;; deseada, luego estos valores se dividen por 10000^2 y se
        ;; multiplican por el valor de conversión a km/h: 144.

        ;; Hace TICK_VEL*T_int_overflow*10000
        ldaa #218
        ldab TICK_VEL
        mul
        tfr D,X                 ; Se libera RR1, para usarlo luego.

        ;; Hace (144*10000)
        ldd #144
        ldy #10000
        emul

        ;; Hace (144*10000)/(TICK_VEL*T_int_overflow*10000)
        ;;      = (144)/(TICK_VEL*T_int_overflow)
        ;;      = VELOC
        ediv

        tfr Y,A

        staa VELOC
        movb #$00,TICK_VEL
        movb #$0A,CONT_REB
        bclr BANDERAS,$02

SALIR_CALCULAR:
        bset PIFH,$FF          ; Limpia la interrupción.
        rti

;***********************************************
; 	   BCD_BIN
;***********************************************
        ;; Descripción:
        ;; Esta subrutina ejecuta una conversión de los valores
        ;; ingresados al teclado matricial en formato BCD, a formato
        ;; binario.

        ;; Entradas:
        ;; Arreglo  Num_Array por memoria

        ;; Salidas:
        ;; Variable V_LIM por memoria

BCD_BIN:

        pshy
        pshx
        pshb
        psha

        ;; Se accede NUM_ARRAY por direccionamiento indexado de
        ;; offset contante con J.
        ldx #NUM_ARRAY

        ;; Primero se carga el MSNibble de BCD y seguidamente se convierte
        ;; el mismo a BIN.
        ldaa 1,X+
        ldab #10
        mul

        ;; Seguidamente se carga el LSNibble de BCD y se le suma el MSNibble ya
        ;; convertido a BIN.
        ldaa 0,X
        aba

        ;; El valor resultante se carga en V_LIM
        staa V_LIM

        pula
        pulb
        pulx
        puly

        rts

;***********************************************
; 	             TAREA_TECLADO
;***********************************************
        ;; Descripción:
        ;; Esta es una subrutina de administración, encargada de
        ;; llamar a la subrutina MUX_TECLADOS para que capture una
        ;; tecla presionada. Además, realiza las acciones relacionadas
        ;; a suprimir rebotes y definir el concept de tecla retenida,
        ;; leyendo la tecla hasta que la misma sea liberada.

        ;; Entradas:
        ;; Variable CONT_REB por memoria
        ;; Variable TECLA por memoria, desde MUX_TECLADO
        ;; Bandera TCL_LISTA por memoria
        ;; Bandera TCL_LEIDA por memoria

        ;; Salidas:
        ;; Variable TECLA_IN por memoria
        ;; Bandera ARRAY_OK por memoria

TAREA_TECLADO:

        pshy
        pshx
        pshb
        psha

        tst CONT_REB                ; Si no termina proceso de
        bne FIN_TAREA_TECLADO       ; rebote, descontar un rebote.

        ;; Con esto se garantiza que cada vez que se vaya a leer una
        ;; tecla, si no se leyó la tecla, esta será $FF.
        movb #$FF,TECLA

        ;; Se lee una tecla y se consulta si la misma fue leída hay
        ;; un valor válido de tecla leída.
        jsr MUX_TECLADO
        brset TECLA,$FF,COMPROBAR_LISTA

        ;; Si la tecla leída pareciera ser de un valor válido, se
        ;; procede a consultar si la bandera de TECLA_LEIDA fue
        ;; habilitada.

COMPROBAR_LEIDA:
        ;; Consulta si TECLA_LEIDA=1. Esto es un inidicio de que se
        ;; está ante la primera tecla leída.
        brset BANDERAS+1,$02,COMPROBAR_VALIDA

        ;; Si TECLA_LEIDA=0, se carga TECLA en TECLA_IN, se habilita
        ;; TECLA_LEIDA y se procede a recargar el contador de rebotes
        ;; CONT_REB.
        movb TECLA,TECLA_IN
        bset BANDERAS+1,$02
        movb #10,CONT_REB
        bra FIN_TAREA_TECLADO

        ;; Si la tecla pareciera tener un elemento válido, y la
        ;; bandera de la TECLA_LEIDA=1 (primera tecla ya fue leída),
        ;; se procede a comprobar si después de 10ms la tecla es la
        ;; misma.
COMPROBAR_VALIDA:
        ldaa TECLA
        cmpa TECLA_IN
        beq VALIDA

        ;; Si la tecla que fue leída luego de los 10ms no tiene el
        ;; valor medido previamnete (se midió un rebote o una señal
        ;; diferente a los patrones esperados), se recargan TECLA y
        ;; TECLA_IN con $FF.
NO_VALIDA:
        movb #$FF,TECLA
        movb #$FF,TECLA_IN
        bclr BANDERAS+1,$03
        bra FIN_TAREA_TECLADO

        ;; Si la tecla leída luego del contador de rebotes es la
        ;; misma que se leyó previamente, entonces se activa la
        ;; bandera TECLA_LISTA.
VALIDA:
        bset BANDERAS+1,$01
        bra FIN_TAREA_TECLADO

        ;; Si la tecla leída no pareciera ser de un valor válido, se
        ;; procede a consultar si la bandera de TECLA_LISTA fue
        ;; habilitada.
COMPROBAR_LISTA:
        brclr BANDERAS+1,$01,FIN_TAREA_TECLADO

        ;; Si TECLA_LISTA=1 (la tecla fue leída y validada), se
        ;; procede a limpiar las banderas TCL_LISTA y TCL_LEIDA y se
        ;; llama a FORMAR_ARRAY, para guardar la tecla leída.
        bclr BANDERAS+1,$03
        jsr FORMAR_ARRAY

        ;; Si TECLA_LISTA=0 (la tecla fue $FF y no es válida), se
        ;; retorna a la subrutina principal.
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

        ldx #NUM_ARRAY               ; Para acceder a NUM_ARRAY por direccionamiento
        ldab CONT_TCL                ; indexado por acumulador.

        ;; Si la tecla es $0B salte a la secuencia de borrado
        ldaa TECLA_IN
        cmpa #$0B
        beq BORRAR

        ;; Si la tecla es $0E cargue los valores a los LEDS.
        cmpa #$0E
        beq ENTER

CRG_TECLA:
        cmpb MAX_TCL            ; Si la tecla a cargar es la tercera
        bhs FIN_FORM_ARRY       ; y diferente de B o E, no la cargue.

        movb TECLA_IN,B,X       ; En caso cotrario, cárguela.
        incb                    ; Cuando se carga siguiente tecla, se suma el índice.

        ;; cmpb MAX_TCL               ; Si el índice excede el rango
        ;; beq REINICIAR_TCL       ; se reinicia.

        bra FIN_FORM_ARRY       ; Si no, se finaliza la secuencia.

REINICIAR_TCL:
        ;; Reinicio de VALOR para aceptar nuevos valores.
        ldb #$00

FIN_FORM_ARRY:
        stab CONT_TCL
        movb #$FF,TECLA_IN      ; Hace TECLA=$FF

        pula
        pulb
        pulx
        puly

        rts

BORRAR:
        ;; Si $0B se carga a TMP1, ignorar y cargar siguiente dato.
        tstb
        beq FIN_FORM_ARRY

        ;;  Si no se cumplen las condiciones antreriores, reducir el índice para
        ;; cargar el dato.
        decb
        movb #$FF,B,X
        bra FIN_FORM_ARRY
ENTER:
        ;; Si $0E se carga a TMP1, ignorar y cargar siguiente dato.
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
        movb #$EF,PORTA         ; Carga el primer patrón en PORTA para leer la
                                ; tecla.

        ;movb AUX_PA,PORTA      ; Se usa una variable auxiliar pues no se sabe
                                ; qué tendrá el PORTA dentro.

        movb #$00,PATRON        ; Se usa una variable para contabilizar la
                                ; cantidad de patrones escritos en PORTA.

SIG_PATRN:
        ldab #$03               ; Se usa acumulador B para hacer el indexado al
                                ; arreglo.

        ldaa PATRON             ; Si ya se escribió $EF, $DF, $BF, $7F en PORTA,
        cmpa #$04               ; ponga finalice la subrutina.
        beq FIN_MUX_TECLADO
        mul                     ; Si no, haga D <- A*B para indexar el arreglo
                                ; de valores a cargar.

        brclr PORTA,$01,LEER    ; Si se presionó un botón en la primera columna
                                ; no le sume nada al offset.

        brclr PORTA,$02,A_1     ; Si se presionó un botón en la segunda columna
                                ; sume 1 al offset.

        brclr PORTA,$04,A_2     ; Si se presionó un botón en la tercera columna
                                ; sume 2 al offset.
CRGR_SGNT_PATRN:

        ;; Si el patrón previo no generó una tecla presionada, incremente PATRON
        ;; y rote el valor cargado en el puerto A.
        inc PATRON
        sec                     ; Ya que se rotará el puerto A, se requiere que
                                ; C esté en 1.
        rol PORTA
        ;movb AUX_PA, PORTA
        bra SIG_PATRN

        ;; Caso de botón en primera columna.
A_1:
        incb
        bra LEER

        ;; Caso de botón en segunda columna.
A_2:
        addb #$02

LEER:
        ;; Trasdala el valor correspondiente a TECLA.
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
        ;; Descripción:
        ;; Esta subrutina es la encargada de actualizar el valor de
        ;; LEDS con el patrón de barrido de PB7-PB3, siempre que la
        ;; bandera ALERTA=1. Si ALERTA=0, apaga PB7 y PB3.

        ;; Entradas:
        ;; Bandera ALERTA por memoria

        ;; Salidas:
        ;; Variable LEDS por memoria

PATRON_LEDS:
        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        pshy
        psha
        pshb


        ;; Ya que los bits de modo son ajenos a los de alerta, los
        ;; mismos se deben guardar y reestablecer cuando se haya
        ;; modificado los bits de alerta.
        ldab LEDS
        andb #$07               ; Se extrae los bits de modo.
        pshb                    ; Se apila los LEDS de modo.

        ;; Se consulta si ALERTA=1.
        brclr BANDERAS+1,$10,LEDS_APAGADOS

        ;; Si ALERTA=1, se inicia la secuencia.
        ldaa LEDS
        anda #$F8               ; Se carga bits de alerta en R1.

        lsra                    ; Si no se ha llegado a máximo,
                                ; desplazar el registro.

        ;; Se consulta si el valor de los bits de alerta llegaron a
        ;; máximo valor.
        cmpa #$04               ; Si se llega a máximo, reiniciar el
        ble REINICIAR_CUENTA    ; patrón.


        bra RECUPERAR_BITS_MODO ; Se recuperan bits de modo.

        ;; Si ALERTA=0, se apaga los bits de alerta.
REINICIAR_CUENTA:
        ldaa #$80               ; Se coloca un 1 en el MSB.

        bra RECUPERAR_BITS_MODO ; Se recuperan bits de modo.

        ;; Si ALERTA=0, se apaga los LEDs.
LEDS_APAGADOS:
        lda #$00                ; Apaga los LEDs.

        ;; Aquí se restablece los bits de modo.
RECUPERAR_BITS_MODO:
        pulb                    ; Se desapila los LEDS de modo.

        aba                     ; Agrupa los bits de modo y de alerta,
        staa LEDS                ; y se guarda su valor en LEDS.

FIN_PATRON_LEDS:
        ;; Se retornan acumuladores e índices.

        pulb
        pula
        puly
        pulx

        rts


;***********************************************
;          CONV_BIN_BCD
;***********************************************
        ;; Descripción:
        ;; Esta subrutina implementa el manejo de la convarsió de
        ;; binario a BCD. Es la encargada de llamar a la subrutina
        ;; de conversión BIN_BCD, para lo cuál se envían las
        ;; direcciones de BIN1 BIN2 por el índice X. Además, esta
        ;; es la encargada de escribir una $B en los dígitos que deben
        ;; permanecer apagados.

        ;; Entradas:
        ;; Variable BIN1 por memoria
        ;; Variable BIN2 por memoria
        ;; Variable BCD_L por memoria

        ;; Salidas:
        ;; Dirección de variable BIN1 por índice X
        ;; Dirección de variable BIN2 por índice X
        ;; Variable BCD1 por memoria
        ;; Variable BCD2 por memoria

CONV_BIN_BCD:
        pshx
        pshy
        psha
        pshb

        ;; Se consulta si BIN1 contiene $BB
        brset BIN1,$BB,CONV_BIN2

        ;; Si no contiene $BB, convierte la variable a BCD.
        ldx #BIN1               ; Se pasa la dirección de la variable
                                ; a convertir por el índice X.

        jsr BIN_BCD             ; Llama subrutina BIN_BCD.

        movb BCD_L,BCD2         ; Se recibe el valor de BCD2 a través
                                ; de la variable BCD_L.


        ;; ldaa BCD_L
        ;; anda $0F
        ;; tbne A,BCD

        ;; Si contiene $BB, BIN1 permanece intacta y se procede a
        ;; cargar el valor respectivo de BIN2.
CONV_BIN2:

        ;; Se consulta si BIN1 contiene $BB
        brset BIN2,$BB,FIN_CONV_BIN_BCD

        ;; Si no contiene $BB, convierte la variable a BCD.
        ldx #BIN2               ; Se pasa la dirección de la variable
                                ; a convertir por el índice X.

        jsr BIN_BCD             ; Llama subrutina BIN_BCD.

        movb BCD_L,BCD1         ; Se recibe el valor de BCD1 a través
                                ; de la variable BCD_L.

FIN_CONV_BIN_BCD:
        pulb
        pula
        puly
        pulx
        rts

;***********************************************
;          BIN_BCD
;***********************************************
        ;; Descripción:
        ;; Esta subrutina implementa la conversión de binario a BCD.
        ;; Para ello se implementa el algoritmo visto en clase, el cual
        ;; consiste en 4 pasos principalmente:

        ;; 1) Se carga el número binario en BIN.
        ;; 2) Se desplaza sucesivamente hacia la izquierda el número
        ;; BIN.
        ;; 3) Se analizan los cuartetos resultantes del desplazamiento.
        ;; 4) Si algún cuarteto es mayor o igual que 5, antes del
        ;; último desplazamiento, se le debe sumar 4 a ese cuarteto.

        ;-------- SP
        ;
        ;-------- SP-1
        ; TEMP
        ;-------- SP-2
        ; LOW
        ;--------

        ;; Entradas:
        ;; Dirección de variable BIN1 por índice X
        ;; Dirección de variable BIN2 por índice X

        ;; Salidas:
        ;; Variable BCD1 por memoria
        ;; Variable BCD2 por memoria
        ;; Variable BCD_L por memoria
        ;; Variable BCD_H por memoria

BIN_BCD:
        ;; Se guarda el contexto de pila para evitar problemas si
        ;; se estaban empleando los registros previo a la subrutna.
        psha
        pshb
        pshx

        ldaa 0,X                ; Carga el valor a covertir, en R1.
        ldab #$07               ; Contador de bits traladados.
        movb #$00,BCD_L         ; Incializa BCD_L en cero.
        movb #$00,BCD_H         ; Incializa BCD_H en cero.

        ;; Aquí inicia conversión de CONT_FREE
NEXT_BIT_BCD:
        lsla                    ; Se desplaza un bit de R1.
        rol BCD_L               ; C se carga BCD_L.
        rol BCD_H               ; C se carga BCD_H.

        ;; Aqui se carga R1 a TEMP
        psha                    ; Se emplea SP-1 como variable TEMP.
        ldaa BCD_L
        anda #$0F               ; Se busca si el nibble menos
        cmpa #$05               ; significativo de BCD_L tine un 5.

        blt NOT_5_ON_L_BCD      ; Si no lo tiene, se busca en el
                                ; nibble más significativo.

        adda #$03               ; Si lo tiene, se le suma 3 al nibble
                                ; menos significativo.
NOT_5_ON_L_BCD:
        ;; Aqui se carga R1 a LOW
        psha                    ; Se emplea SP-1 como variable TEMP.
        ldaa BCD_L
        anda #$F0               ; Se busca si el nibble más
        cmpa #$50               ; significativo de BCD_L tine un 5.

        blt NOT_5_ON_H_BCD      ; Si no lo tiene, se avanza con el
                                ; algoritmo.

        adda #$30               ; Si lo tiene, se le suma 3 al nibble
                                ; más significativo.

NOT_5_ON_H_BCD:

        adda 0,SP               ; Aquí se suma LOW a R1.
        sta BCD_L               ; y se carga el resultado a BCD_L.

        ins                     ; Maneja la pila para apuntar a TEMP.
        pula                    ; Se carga TEMP a R1.

        dbeq B,FINALIZAR_BCD    ; Si se desplazaron todos los bits, ir
                                ; al final.

        bra NEXT_BIT_BCD        ; Si no, seguir con el algoritmo.
FINALIZAR_BCD:
        ;; Se desplaza el último bit en binario.
        lsla
        rol BCD_L
        rol BCD_H

        ;; Se restablece el contexto de pila.
        pulx
        pulb
        pula

        rts

;***********************************************
;          BCD_7SEG
;***********************************************
        ;; Descripción:
        ;; Esta subrutina implementa el manejo de la conversión de
        ;; BCD a 7SEG. Para ello se identifica el contenido de los
        ;; valores a cargar en BCD y a partir de los mismos se
        ;; determina un ofsset que sirve para indexar una tabla que
        ;; contiene los valores válidos a cargarse en los 7SEG de
        ;; acuerdo al valor en BCD.

        ;; Entradas:
        ;; Variable BIN1 por memoria
        ;; Variable BIN2 por memoria

        ;; Salidas:
        ;; Variable DISP1 por memoria
        ;; Variable DISP2 por memoria
        ;; Variable DISP3 por memoria
        ;; Variable DISP4 por memoria

BCD_7SEG:
        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        psha

        ldx #SEGMENT            ; Se carga la dirección de SEGMENT en
                                ; X para accederlo con
                                ; direccioneamiento indexado con
                                ; offset por acumulador.


        ;; Prepara DISP3
        ldaa BCD1
        anda #$0F               ; Se extrae el nibble menos
        psha                    ; significativo de BCD1 y se apila.

        ;; Prepara DISP1
        ldaa BCD2
        anda #$0F               ; Se extrae el nibble menos
        psha                    ; significativo de BCD2 y se apila.

        ;; Prepara DISP4
        ldaa BCD1               ; Se extrae el nibble más significativo
        lsra                    ; de BCD1. Para ello se divide el
        lsra                    ; dígito entre 16.
        lsra
        lsra
        psha                    ; Una vez dividido, se apila.

        ;; Prepara DISP2
        ldaa BCD2               ; Se extrae el nibble más significativo
        lsra                    ; de BCD2. Para ello se divide el
        lsra                    ; dígito entre 16.
        lsra
        lsra
        psha                    ; Una vez dividido, se apila.

        ;; Carga los valores de los dígitos
        pula
        movb A,X,DISP2           ; Se carga DISP2.
        pula
        movb A,X,DISP4           ; Se carga DISP4.
        pula
        movb A,X,DISP1           ; Se carga DISP1.
        pula
        movb A,X,DISP3           ; Se carga DISP3.


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
        ;; Se retornan acumuladores e índices.
        pula
        pulx
        rts

;***********************************************
;          INICIALIZAR_LCD
;***********************************************
        ;; Descripción:
        ;; Esta subrutina implementa la inicialización de la pantalla
        ;; LCD. Para ello, se envía una serie de comandos requeridos
        ;; para este propósito.

        ;; Entradas:
        ;; Arreglo iniDsp por memoria
        ;; Variable BIN2 por memoria

        ;; Salidas:

INICIALIZAR_LCD:

        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        pshy
        psha
        pshb

        ldx #iniDsp             ; Para acceder iniDsp por
                                ; direccionamiento indexado con offset
                                ; constante.

SEGUIR_IniDSP:
        ldaa 0,X
        jsr SEND_COMMAND        ; Envía comando De iniDsp.
        movb D40uS,Cont_Delay
        jsr Delay               ; Espera 40us.
        inx
        cpx #iniDsp+4           ; Si no se ha enviado todo iniDsp,
        bne SEGUIR_IniDSP       ; síga enviando.

        ldaa #$01
        jsr SEND_COMMAND        ;Envía comando de Clear Display.
        movb D2mS,Cont_Delay
        jsr Delay               ;Espera 2ms.

        ;; Se retornan acumuladores e índices.
        pulb
        pula
        puly
        pulx

        rts

;***********************************************
;          CARGAR_LCD
;***********************************************
        ;; Descripción:
        ;; Esta subrutina implementa la carga de mensajes a la pantalla
        ;; LCD. Esta subrutina se encarga de manejar la secuencia de
        ;; carga de mensajes y datos, necesaria para la correcta
        ;; escritura del mensaje enviado, a la LCD.

        ;; Entradas:
        ;; Constante ADD_L1 por memoria
        ;; Constante ADD_L2 por memoria
        ;; Arreglo MSG1 por acumulador X
        ;; Arreglo MSG2 por acumulador X

        ;; Salidas:

CARGAR_LCD:

        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        pshy
        psha
        pshb

        ldaa ADD_L1             ; Se envía el comando ADD_L1 para poner
        jsr SEND_COMMAND        ; el cursor en línea 1.
        movb D40uS,Cont_Delay
        jsr Delay               ; Esperar 40us
LOAD_MSG1:
        ;; Se espera el mensaje correspondiente a la la línea 1 por
        ;; el índice X. Se carga el mensaje byte a byte. Cuando se
        ;; recibe el caracter de fin de mensaje: EOM, se termina la
        ;; comunicación.
        ldaa 1,X+
        cmpa #EOM               ; Si se recibe EOM, se inicial la
        beq IS_EOM_MSG1         ; secuencia de configuración de L2.

        jsr SEND_DATA           ; Si no, se envía char de MSGL1.
        movb D40uS,Cont_Delay
        jsr Delay               ;Se espera 40us
        bra LOAD_MSG1
IS_EOM_MSG1:
        ldaa ADD_L2             ; Se envía el comando ADD_L2 para poner
        jsr SEND_COMMAND        ; el cursor en línea 2.
        movb D40uS,Cont_Delay
        jsr Delay               ; Se espera 40us
LOAD_MSG2:
        ;; Se espera el mensaje correspondiente a la la línea 2 por
        ;; el índice Y. Se carga el mensaje byte a byte. Cuando se
        ;; recibe el caracter de fin de mensaje: EOM, se termina la
        ;; comunicación.
        ldaa 1,Y+
        cmpa #EOM               ; Si se recibe EOM, se finaliza la
        beq IS_EOM_MSG2         ; subruitna.

        jsr SEND_DATA           ; Si no, se envía char de MSG2.
        movb D40uS,Cont_Delay
        jsr Delay               ; Se espera 40us
        bra LOAD_MSG2

IS_EOM_MSG2:
        ;; Se retornan acumuladores e índices.
        pulb
        pula
        puly
        pulx

        rts

;***********************************************
;          SEND_COMMAND
;***********************************************
        ;; Descripción:
        ;; Esta subrutina envía un comando a la pantalla LCD. El
        ;; comando a ser enviado es recibido por el acumulador A. La
        ;; subrutina envía primero la parte alta del byte y luego la
        ;; parte baja. Dichos nibbles son recibidos por el LCD en el
        ;; PORTK.5-PORTK.2. La subrutina se encarga de controlar la
        ;; temporización. Al enviar cada nibble genera un pulso de
        ;; 250usa en PORTK.1 (EN). Esta subrutina hace PORTK.0=1 (RS).

        ;; Entradas:
        ;; Comando  por acumulador A
        ;; Variable BIN2 por memoria

        ;; Salidas:
        ;; PORTK.5-PORTK.0

SEND_COMMAND:

        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        pshy
        psha
        pshb

        ;; Se carga el nibble más significativo en R1.
        psha
        anda #$F0
        lsra
        lsra

        ;; Se carga el nibble más significativo en PORTK.
        sta PORTK

        bclr PORTK,#$01         ; Se hace RS=0 (comando).
        bset PORTK,#$02         ; Se hace EN=1.
        movb D250uS,Cont_Delay
        jsr Delay               ; Se espera 250us.
        bclr PORTK,#$01         ; Se hace EN=0.

        ;; Se carga el nibble menos significativo en R1.
        pula
        anda #$0F
        lsla
        lsla

        ;; Se carga el nibble menos significativo en PORTK.
        sta PORTK

        bclr PORTK,#$01         ; Se hace RS=0 (comando).
        bset PORTK,#$02         ; Se hace EN=1.
        movb D250uS,Cont_Delay
        jsr Delay               ; Se espera 250us.
        bclr PORTK,#$02         ; Se hace EN=0.

        ;; Se retornan acumuladores e índices.
        pulb
        pula
        puly
        pulx

        rts


;***********************************************
;          SEND_DATA
;***********************************************
        ;; Descripción:
        ;; Esta subrutina envía un comando a la pantalla LCD. El
        ;; comando a ser enviado es recibido por el acumulador A. La
        ;; subrutina envía primero la parte alta del byte y luego la
        ;; parte baja. Dichos nibbles son recibidos por el LCD en el
        ;; PORTK.5-PORTK.2. La subrutina se encarga de controlar la
        ;; temporización. Al enviar cada nibble genera un pulso de
        ;; 250usa en PORTK.1 (EN). Esta subrutina hace PORTK.0=1 (RS).

        ;; Entradas:
        ;; Comando  por acumulador A
        ;; Variable BIN2 por memoria

        ;; Salidas:
        ;; PORTK.5-PORTK.0

SEND_DATA:

        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        pshy
        psha
        pshb

        ;; Se carga el nibble más significativo en R1.
        psha
        anda #$F0
        lsra
        lsra

        ;; Se carga el nibble más significativo en PORTK.
        sta PORTK

        bset PORTK,#$03         ; Se hace RS=0 (comando) y EN=1.
        movb D250uS,Cont_Delay
        jsr Delay               ; Se espera 250us.
        bclr PORTK,#$01         ; Se hace EN=0.

        ;; Se carga el nibble menos significativo en R1.
        pula
        anda #$0F
        lsla
        lsla

        ;; Se carga el nibble menos significativo en PORTK.
        sta PORTK               ;
        bset PORTK,#$03         ; Se hace RS=0 (comando) y EN=1.
        movb D250uS,Cont_Delay
        jsr Delay               ; Se espera 250us.
        bclr PORTK,#$02         ; Se hace EN=0.


        ;; Se retornan acumuladores e índices.
        pulb
        pula
        puly
        pulx

        rts


;***********************************************
;          DELAY
;***********************************************
        ;; Descripción:
        ;; Esta subrutina espera a que OC4_ISR decremente hasta cero
        ;; el CONT_DELAY. Dicho CONT_DELAY es cargado por la subrutina
        ;; que llame a DELAY, así la subrutina funciona para cualquier
        ;; retardo que pueda cargarse en un byte.

        ;; Entradas:
        ;; Variable CONT_DELAY por memoria

        ;; Salidas:

DELAY:
        pshx
        pshy
        psha
        pshb

DELAY_RET:
        ;; Se espera a que CONT_DELAY llegue a cero.
        tst CONT_DELAY
        bne DELAY_RET

        ;; Cuando llega a cero, retorna.

        pulb
        pula
        puly
        pulx

        rts
