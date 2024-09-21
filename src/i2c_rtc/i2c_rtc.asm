;***********************************************
;                  TAREA 7
;***********************************************

#include "../../include/registers.inc"

;***********************************************
; REDIRECCIONAMIENTO DEL VECTOR DE INTERRUPCION
;***********************************************
        org $3E40               ; Vec. interrupción I2C
        dw I2C_ISR

        org $3E4C               ; Vec. interrupción IRQ
        dw PTH_ISR

        org $3E70               ; Vec. interrupción RTI
        dw RTI_ISR

        org $3E64               ; Vec. interrupcón por Comparador Ch5.
        dw OC5_ISR

        org $3E66               ; Vec. interrupcón por Comparador Ch4.
        dw OC4_ISR

;***********************************************
; 	       DECLARACION DE MEMORIA
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
; 	     INICIALIZACIÓN DE LCD
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
; 	     INICIO DE MENSAJES
;***********************************************
        org $1050
EOM:    EQU $04
MSG0:   FCC "     RELOJ"
        db EOM
MSG1:   FCC " DESPERTADOR 623"
        db EOM

;***********************************************
; 	     CONFIGURACION DE HARDWARE
;***********************************************

		org $2000

	lds #$3BFF               ; Carga puntero de pila.

        ;; Configuración de LEDS
	movb #$FF,DDRB           ; Puerto B: escritura.
        bset DDRJ,#$03           ; PJ1 escritura.
	bclr PTJ,#$02            ; PJ1 como GND.
        movb #$FF,DDRP           ; PORTJ: Entrada.

        ;; Configuración de PK para LCD
        movb #$FF,DDRK

        ;; Confguración I2C
        movb #$1F,IBFD          ; Configura SCL a 1kHz y
                                ; SDA_Hold=1.375us.

        ;; Habilita respectivamente:  ; I_Bus, I_Bus Interrupt,
        ;; Modo Master y Transmisión
        movb #$F0,IBCR          ; I_BEN=1, IBIE=1, MS/SL=1, Tx/Rx=1.

        ;; Configuación de RTI_ISR
        movb #$75,RTICTL       ; Define interrupciones de 50ms.
        bset CRGINT,#$80       ; Para habilitar interrupción RTI.

        ;; Configuración de PTH_ISR
        movb #$09,PIEH          ; Habilita interrupción de PH(3,0).
        bclr PPSH,#$0F          ; Selección de interrupción por
                                ; flanco decreciente.

        ;; Configuración de OC4_ISR y OC5_ISR
        movb #$90,TSCR1         ; Habilita TCNT y funcion de TFFCA.
        movb #$03,TSCR2         ; Prescalador de 8.
        movb #$10,TIOS          ; Habilita el IOS4.
        movb #$05,TCTL1         ; Canal 4 y 5 como Toggle.
        movb #$10,TIE           ; Habilita TC4.




;***********************************************
; 	     INICIALIZACIÓN_DE_VARIABLES
;***********************************************

;***************** RTI  ***************************
        movb  #20,CONT_RTI       ; Para contar 1s.

;***************** PANTALLAS ***************************
        ;; Se inicializan las variables de las pantallas
        ;; X:X:X:X:X:PTH1_PRS:RD_FLG:RW_RTC
        movb #$00,BANDERAS
        movb #$0A,BRILLO        ; Para 7SEG encendida en inicio.
        movb #$00,CONT_DIG
        movb #100,CONT_TICKS    ; Para contar 1s.
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
        movb #$64,D2mS          ; Para contar 2ms.
        movb #$0D,D260uS        ; Para contar 260uS.
        movb #$02,D40uS         ; Para contar 40us.
        movb #$00,Clear_LCD
        movb #$80,ADD_L1        ; Para direcciona a L1 de LCD.
        movb #$C0,ADD_L2        ; Para direcciona a L2 de LCD.

;***************** I2C ***************************
        ;; Se inicializan la variable y arreglo del I2C.
        movb #$00,INDEX_RTC
        ldx #T_READ_RTC-1
        ldaa #7
INICIALIZAR_T_READ_RTC:
        movb #$00,A,X
        dbne A,INICIALIZAR_T_READ_RTC

;************ INTERRUPCIONES ********************
        cli		        ; Carga 0 en I en CCR

        ;; Para generar ticks de 50 KHz.
        ldd TCNT
        addd #60
        std TC4

;***********************************************
; 	     PRINCIPAL
;***********************************************
        ;; Se carga mensaje en LCD:
        ;;      RELOJ
        ;;  DESPERTADOR 623
        jsr INICIALIZAR_LCD     ; Se limpia la LCD.
        ldx #MSG0               ; Carga MSG0 en línea.
        ldy #MSG1               ; Carga MSG1 en línea.
        jsr CARGAR_LCD          ; Se carga mensaje en LCD.

RETORNAR:

        ;; Si la alarma está encencidad, la misma debe permanecer
        ;; encendida hasta que la PTH1 la deshabilite.
        brset TIE,#$20,RETORNAR

        ;; Si la alarma no está encendida, se consulta si ya la hora
        ;; y minutos del RTC coinciden con los programados en la
        ;; alarma.
        ldx #T_READ_RTC         ; Lee el contenido del arreglo de
        ldd 1,X                 ; lectura de RTC.
        cpd ALARMA              ; Si coincide con la hora y minutos
        beq ACTIVAR_ALARMA      ; preestablecida, se activa la alarma.


        bclr BANDERAS,$04       ; Se desactiva la bandera de PTH1_PRS.

        bra RETORNAR

ACTIVAR_ALARMA:
        ;; Si la alarma fue reciéntemente apagada por interrupción
        ;; PH1, no se enciende.
        brset BANDERAS,$04,RETORNAR

        bset TIOS,$20           ; Habilita el IOS5.

        bset TIE,$20            ; Habilita TC5 (Alarma).

        ;; Para generar frecuenca de 440 KHz.
        ldd TCNT
        addd #13636
        std TC5

        bra RETORNAR

        end

;***********************************************
; 	             PTH_ISR
;***********************************************
PTH_ISR:
        ;; Si se presionó PTH2, se reduce el brillo.
        brset PIFH,#$04,REDUCIR_BRILLO

        ;; Si se presionó PTH3, se incrementa el brillo.
        brset PIFH,#$08,AUMENTAR_BRILLO

        ;; Si se presionó PTH1, se deshabilita la interrupción OC5,
        ;; la cual implementa el buzzer de la alarma.
        brset PIFH,#$02,DESHABILITAR_ALARMA

        ;; Si no se presionó ninguno de los anteriores, por descarte,
        ;; se presionó PH0. Por tanto se procede a escribir el byte de
        ;; START y CALLING ADDRESS, para dar por iniciado la escritura
        ;; a los registros de RTC del DS1307.
CALL_W:
        bclr BANDERAS,$02       ;Deshabilita la lectura a cada segundo
                                ;del RTC.

        bset BANDERAS,$01       ; W_FLAG=1.

        bset IBCR,#$30          ; Se activa señal de START.

        movb DIR_WR,IBDR        ; Se escribe WRITE CALL ADDR en bus.

        bra SALIR_PTH           ; Se retorna al final de subrutina.

        ;; Esta subrutina reduce el brillo.
REDUCIR_BRILLO:
        ldaa BRILLO
        suba #$05               ; El brillo se reduce de 5 en 5.

        tsta                    ; Si BRILLO llega a mínimo,
        blt SALIR_PTH           ; se finaliza subrutina.

        sta BRILLO              ; Si no, se guarda el valor aumentado
                                ; en variable BRILLO.

        bra SALIR_PTH           ; Se retorna al final de subrutina.

        ;; Esta subrutina aumenta el brillo.
AUMENTAR_BRILLO:
        ldaa BRILLO
        adda #$05               ; El brillo se aumenta de 5 en 5.

        cmpa #$64               ; Si BRILLO llega a máximo,
        bgt SALIR_PTH           ; finaliza subrutina.

        sta BRILLO              ; Si no, se guarda el valor aumentado
                                ; en variable BRILLO.

        bra SALIR_PTH           ; Se retorna al final de subrutina.

        ;; Esta subrutina deshabilita la alarma.
DESHABILITAR_ALARMA:
        bset BANDERAS,$04       ; Se activa la bandera de PTH1_PRS.

        bclr TIOS,#$20          ; Desabilita el IOS5.

        bclr TIE,#$20           ; Deshabilita TC5

        ;; Finalización de subrutina.
SALIR_PTH:
        bset PIFH, $0F          ; Limpia la interrupción.
        rti

;***********************************************
;                   RTI_ISR
;***********************************************
RTI_ISR:
        dec CONT_RTI            ; Se decrementa CONT_RTI.

        tst CONT_RTI            ; Si no se ha llegado a 1s,
        bne FIN_RTI             ; se finaliza la subrutina.

        ;; Cuando se ha llegado a 1s, se procede a realizar la
        ;; secuencia propia de la subrutina.
CONT_RTI_CERO:
        movb #20,CONT_RTI       ; Se recarga contador de 1s.

        ;; Si RD_FLG=1, es porque ya se escribió un valor en los
        ;; registros del DS1307 y se debe proceder a realizar su
        ;; lectura cada segundo. Para eso, se escribe el bit de START
        ;; y se envía el CALLING ADDRESS de lectura.
        brset BANDERAS,$02,CALL_R

        ;; Si RD_FLG=0, no se ha escrito nada en el registro del
        ;; DS1307 y por tanto, el mismo no se debe leer.
        bra FIN_RTI

CALL_R:
        brset IBSR,$20,*        ; Espera a que bus I2C se libere.

        bclr BANDERAS,$01       ; W_FLAG=0.

        bset IBCR,$30           ; Se activa señal de START.

        movb DIR_WR,IBDR        ; Se escribe CALL ADDR en bus.

FIN_RTI:
        bset CRGFLG,#$80        ; Se limpia bandera de interrupción.
        rti

;***********************************************
;                   I2C_ISR
;***********************************************
I2C_ISR:
        ;; Se consulta si se encuentra en el proceso de lectura o
        ;; escritura (Bandera WR_FLG).
        brset BANDERAS,$01,WRITE_RTC ; Si WR_FLG=1, ir a escritura.

        jsr READ_RTC                 ; Si no, ir a lectura.

RETORNAR_I2C_ISR:
        bset IBSR,$02           ;Se limpia la bandera de interrupción.
        rti

;***********************************************
;                  WRITE_RTC
;***********************************************
WRITE_RTC:
        ;; Se consulta si se está ante la primera interrupción
        tst INDEX_RTC
        bne W_BYTE

        ;; Si se está ante la primera interrupción se transmite la
        ;; dirección del registro puntero.
        brset IBSR,$01,*        ; Verifica ACK recibido.

        inc INDEX_RTC           ; Se incrementa el índice.

        movb DIR_SEG,IBDR       ; Se escribe el register pointer.


        bra RETORNAR_I2C_ISR    ; Se retorna a I2C_ISR.

        ;; Se escriben byte a byte los valores correspondientes de los
        ;; registros del DS1307.
W_BYTE:

        ldaa INDEX_RTC          ; Se carga en R1 el contenido de
                                ; índice de interrupción.

        ;; Se consulta si ya se transmitió el último byte.
        cmpa #8
        beq INDEX_RTC_W_I9

        ldx #T_WRITE_RTC        ; Se accede T_WRITE_RTC por
        tfr A,B                 ; direccionamiento indexado por
        subb #1                 ; acumulador R2. Y R2 se referencia
                                ; al índice de interrupción.

        brset IBSR,$01,*        ; Verifica ACK recibido.

        movb B,X,IBDR           ; Se escribe el byte respectivo para
                                ; configurar el RTC.

        ;; Si no se llegó a la última interrupción, se incrementa el
        ;; índice de interrupción y se retorna a la subrutina I2C_ISR.
        inc INDEX_RTC
        bra RETORNAR_I2C_ISR

        ;; Si ya se transmitió el último byte, se manda la señal STOP.
INDEX_RTC_W_I9:
        brset IBSR,$01,*        ; Verifica ACK recibido.

        bset BANDERAS,$02       ; Habilita la lectura a cada segundo
                                ; del RTC.

        movb #$00,INDEX_RTC     ; Restablece el índice de interrupción.

        bclr IBCR,#$20          ; Manda señal de STOP.

        bra RETORNAR_I2C_ISR    ; Se retorna a I2C_ISR.

;***********************************************
;                  READ_RTC
;***********************************************
READ_RTC:
        ldaa INDEX_RTC          ; Se carga en R1 el contenido de
                                ; índice de interrupción.

        ldx #T_READ_RTC         ; Se accede T_READ_RTC por
        tfr A,B                 ; direccionamiento indexado por
        subb #3                 ; acumulador R2. Y R2 se referencia
                                ; al índice de interrupción.
        ;; Se consulta si es la primera interrupción.
        tsta
        beq INDEX_RTC_R_I1

        ;; Se consulta si es la segunda interrupción.
        cmpa #01
        beq INDEX_RTC_R_I2

        ;; Se consulta si es la tercera interrupción.
        cmpa #02
        beq INDEX_RTC_R_I3

        ;; Se consulta si es la última interrupción.
        cmpa #10
        beq INDEX_RTC_R_I11

        ;; Se consulta si es la penúltima interrupción.
        cmpa #09
        beq INDEX_RTC_R_I9

LEER_IBDR:

        movb IBDR,B,X           ; Lee el registro del RTC y lo guarda
                                ; en la tabla en memoria del S12.

FINALIZANDO_READ_RTC:
        inc INDEX_RTC           ; Incrementa el índice de interrupción.

FIN_READ_RTC:
        rts                     ; Fin de subrutina.

        ;; Secuencia para primera interrupción.
INDEX_RTC_R_I1:
        ;; Si se está ante la primera interrupción se transmite la
        ;; dirección del registro puntero.
        brset IBSR,$01,*        ; Espera un ACK.

        movb DIR_SEG,IBDR       ; Se escribe el register pointer.

        bra FINALIZANDO_READ_RTC ; Se incrementa índice y retorna.

        ;; Secuencia para segunda interrupción.
INDEX_RTC_R_I2:
        brset IBSR,$01,*        ; Espera un ACK.

        bset IBCR,$04           ; Se envía señal de REPEAT START.

        movb DIR_RD,IBDR        ; Se escribe READ CALL ADDR en bus.

        bra FINALIZANDO_READ_RTC ; Se incrementa índice y retorna.

        ;; Secuencia para tercera interrupción.
INDEX_RTC_R_I3:
        brset IBSR,$01,*        ; Espera un ACK.

        bclr IBCR,$18           ; Se habilita TXACK y se pone Master
                                ; como RX.

        ldaa IBDR                ; Lectura dummy.

        bra FINALIZANDO_READ_RTC ; Se incrementa índice y retorna.

        ;; Secuencia para última interrupción.
INDEX_RTC_R_I11:
        ;; bset IBCR,#$10          ; Se pone Master como TX.

        movb #$00,INDEX_RTC     ; Restablece el índice de interrupción.

        bclr IBCR,#$38          ; Manda señal de STOP.

        movb 1,X,BCD2           ; Lee el contenido del arreglo de
        movb 2,X,BCD1           ; lectura de RTC y lo pone en pantalla
                                ; 7SEG.

        ;; bclr IBCR,#$08           ; Se pone NACK en trama.

        bra FIN_READ_RTC

        ;; Secuencia para penúltima interrupción.
INDEX_RTC_R_I9:
        bset IBCR,#$08           ; Se pone NACK en trama.

        movb IBDR,B,X           ; Lee el registro del RTC y lo guarda
                                ; en la tabla en memoria del S12.

        bra FINALIZANDO_READ_RTC ; Se incrementa índice y retorna.


;***********************************************
;                  OC5_ISR
;***********************************************
OC5_ISR:
        ;; Para generar frecuencia audible de 440 KHz.
        ldd TCNT
        addd #13636
        std TC5

        rti


;***********************************************
;          OC4_ISR
;***********************************************
OC4_ISR:
        ;; Cuenta para refrescar valor de dígitos.
        ldd CONT_7SEG           ; Se incrementa el contador de 7SEG
        addd #$01               ; para llevar la cuenta de los 100ms
        std CONT_7SEG           ; en que se debe llamar a BCD_7SEG.

        ;; Cuenta para control por ciclo de trabajo.
        dec CONT_TICKS          ; Se descuenta el contador de ticks
        tst CONT_TICKS          ; que funciona como el N en el manejo
        ble CERO                ; de multiplexación de pantallas.

        ;; Determina el ancho de pulso de habilitación de LEDs.
        ldaa CONT_TICKS         ; Tomando a N=100  y a K=BRILLO,
        ldab #100               ; se determina el valor de DT al
        subb BRILLO             ; hacer DT = N-K.
        stb DT
        cmpa DT                 ; Si DT >= CONT_TICKS, se habilitan
        ble HAB_LED             ; los 7SEG y deshabilita los LEDs.

        ;; Se consulta si el valor de CONT_7SEG ya llegó a su máxumo.
        ldd CONT_7SEG
        cpd #5000
        lblt FIN_OC2_ISR        ; Si alcanzó el máximo,
        movw #$0000,CONT_7SEG   ; se recarga CONT_7SEG en cero,
        jsr BCD_7SEG            ; Y se convierte variables BCD a 7SEG.
        bra FIN_OC2_ISR

        ;; Manejo de habilitación de LEDS.
HAB_LED:
        movb #$FF,PTP           ; Carga $FF, pues no habilita
                                ; ningún valor especial en 7SEG.

        bclr PTJ,#$02           ; Se deshabilitan los LEDs.

        movb LEDS,PORTB         ; Se carga el valor de LEDS a PORTB.
        bra FIN_OC2_ISR

        ;; Manejo de habilitación de DIGITOS.
CERO:
        movb #100,CONT_TICKS    ; Cuándo CONT_TICKS ha llegado a cero
                                ; se recarga CONT_TICKS en 100.

        inc CONT_DIG            ; Además, aquí se incrementa CONT_DIG
        bset PTJ,#$02           ; y se habilitan los LEDs.

        ;; Se consulta cuál es el dígito a escribir, de acuerdo con
        ;; el contenido de CONT_DIG.
        brset CONT_DIG,#$03,HAB_DIG4
        brset CONT_DIG,#$02,HAB_DIG3
        brset CONT_DIG,#$01,HAB_DIG2

        ;; Habilita dígito 1
HAB_DIG1:
        ;; La habilitación de DIG1 es especial, si habilita en dos
        ;; casos, cuando se tiene un valor de 00 en CONT_DIG y cuando la cuenta excedió el valor

        tst CONT_DIG            ; La habilitación de DIG1 es especial,
        beq LOAD_DIG1           ; pues se habilita cuando la cuenta
        movb #$00,CONT_DIG      ; es cero o cuando se rebasó. En el
                                ; último caso se debe habilitar el
                                ; dígito y reestablecer el contador.

LOAD_DIG1:
        movb #$07,PTP           ; Se habilita el DIG1 en el PP
        movb DIG1,PORTB         ; y se carga su valor en PORTB.
        bra FIN_OC2_ISR

        ;; Habilita dígito 2
HAB_DIG2:
        movb #$0B,PTP           ; Habilita DIG2.
LOAD_DIG2:
        movb DIG2,PORTB         ; Carga dígito en PORTB.
        bra FIN_OC2_ISR

        ;; Habilita dígito 3
HAB_DIG3:
        movb #$0D,PTP           ; Habilita DIG3
LOAD_DIG3:
        movb DIG3,PORTB         ; Carga dígito en PORTB.
        bra FIN_OC2_ISR

        ;; Habilita dígito 4
HAB_DIG4:
        movb #$0E,PTP           ; Habilita el DIG4
LOAD_DIG4:
        movb DIG4,PORTB         ; Carga dígito en PORTB.
        bra FIN_OC2_ISR

FIN_OC2_ISR:
        ;; Manejor de Cont_Delay para LCD
        tst CONT_DELAY
        beq CARGAR_TC4          ; Si CONT_DELAY != 0,
        dec CONT_DELAY          ; se decrementa su valor.
CARGAR_TC4:
        ;; Se lee TCNT y se recarga el próximo valor a comparar en
        ;; TC2.
        ldd TCNT
        addd #60
        std TC4
        rti

;***********************************************
;          BCD_7SEG
;***********************************************
BCD_7SEG:
        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        psha
        pshb

        ldx #SEGMENT            ; Se carga la dirección de SEGMENT en
                                ; X para accederlo con
                                ; direccioneamiento indexado con
                                ; offset por acumulador.

        ;; Prepara DIG3
        ldaa BCD1
        anda #$0F               ; Se extrae el nibble menos
        psha                    ; significativo de BCD1 y se apila.

        ;; Prepara DIG1
        ldaa BCD2
        anda #$0F               ; Se extrae el nibble menos
        psha                    ; significativo de BCD2 y se apila.

        ;; Prepara DIG4
        ldaa BCD1               ; Se extrae el nibble más significativo
        lsra                    ; de BCD1. Para ello se divide el
        lsra                    ; dígito entre 16.
        lsra
        lsra
        psha                    ; Una vez dividido, se apila.

        ;; Prepara DIG2
        ldaa BCD2               ; Se extrae el nibble más significativo
        lsra                    ; de BCD2. Para ello se divide el
        lsra                    ; dígito entre 16.
        lsra
        lsra
        psha                    ; Una vez dividido, se apila.

        ;; Carga los valores de los dígitos
        pula
        movb A,X,DIG2           ; Se carga DIG2.
        pula
        movb A,X,DIG4           ; Se carga DIG4.
        pula
        movb A,X,DIG1           ; Se carga DIG1.
        pula
        movb A,X,DIG3           ; Se carga DIG3.

        ldaa T_READ_RTC         ; Se extrae el nibble más significativo
        lsla                    ; de BCD2. Para ello se divide el
        lsla                    ; dígito entre 16.
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




        ;; Se retornan acumuladores e índices.
        pulb
        pula
        pulx
        rts

;***********************************************
;          INICIALIZAR_LCD
;***********************************************
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
CARGAR_LCD:

        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        pshy
        psha
        pshb

        ldaa ADD_L1             ;Se envía el comando ADD_L1 para poner
        jsr SEND_COMMAND        ;el cursor en línea 1.
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
        movb D260uS,Cont_Delay
        jsr Delay               ; Se espera 260uS.
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
        movb D260uS,Cont_Delay
        jsr Delay               ; Se espera 260uS.
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
        movb D260uS,Cont_Delay
        jsr Delay               ; Se espera 260uS.
        bclr PORTK,#$01         ; Se hace EN=0.

        ;; Se carga el nibble menos significativo en R1.
        pula
        anda #$0F
        lsla
        lsla

        ;; Se carga el nibble menos significativo en PORTK.
        sta PORTK               ;
        bset PORTK,#$03         ; Se hace RS=0 (comando) y EN=1.
        movb D260uS,Cont_Delay
        jsr Delay               ; Se espera 260uS.
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
DELAY:
        ;; Se espera a que CONT_DELAY llegue a cero.
        tst CONT_DELAY
        bne DELAY
        ;; Cuando llega a cero, retorna.
        rts
