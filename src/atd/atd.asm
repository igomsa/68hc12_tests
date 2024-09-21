;***********************************************
;                  TAREA 6
;***********************************************

#include "../../include/registers.inc"

;***********************************************
; REDIRECCIONAMIENTO DEL VECTOR DE INTERRUPCION
;***********************************************
        ;; Redireccionamiento del vector de interrupción
        ;; de convertidor analógico a digital.
        org $3E52
        dw ATD0_ISR

        ;; Redireccionamiento del vector de interrupción
        ;; de otuput compare del canal 5.
        org $3E64
        dw OC5_ISR
;***********************************************
; 	       DECLARACION DE MEMORIA
;***********************************************
        ;; Reservación en memoria de variables requeridas
                org $1010
Nivel_PROM:     ds 2
NIVEL:          ds 1
VOLUMEN:        ds 2
CONT_OC:        ds 1
BCD1:           ds 1
BCD2:           ds 1
BCD_L:          ds 1
BCD_H:          ds 1


        ;; Mensajes a cargar.
        ;; Estos se encuentran en ASCII.
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
; 	     CONFIGURACION DE HARDWARE
;***********************************************

               org $2000
        ;; Se carga el puntero de pila.
        lds #$3BFF

        ;; Configuración del relé.
        bset DDRE,$04           ; PORTE.2 como salida.
        bclr PORTE,$04          ; PORTE.2 apagado al encendido.

        ;; Configuración del SC1
        movw #38,SC1BDH         ; SRB=38, para Data_Rate=8400 baudios.

        movb #$02,SC1CR1        ; PE=1 y PT=0, para habilitar bit de
                                ; paridad con paridad par.

        movb #$08,SC1CR2        ; TE=1, habilita transmisión de datos.

        ;; Configuración del ATD
        movb #$C2,ATD0CTL2      ; ADPU=1 para habilitar el ATD y
                                ; AFFC=1 para

        ;; Se deja un tiempo de espera para permitir que el
        ;; convertidor se habilite.
        ldab #160
DEC_B:
        dbne B,DEC_B
        movb #$30,ATD0CTL3      ; Configura 6 conversiones en un solo
                                ; comando.

        movb #$30,ATD0CTL4      ; Configura SRES8=0 para una
                                ; conversión a 10 bits, SMP=$00 para
                                ; un tiempo de muestreo de 2 periodos
                                ; de ATD y PRS=16 para una frecuencia
                                ; de 700kHz aprox.

        movb #$87,ATD0CTL5      ; DJM=1 para justificar resultado a
                                ; la derecha y CC=CB=CA=1 para definir
                                ; al potenciómetro como la entrada de
                                ; las mediciones.


        ;; Configuración de OC5_ISR
        movb #$90,TSCR1         ; Habilita TCNT y funcion de TFFCA
        movb #$06,TSCR2         ; Prescalador de 64
        movb #$20,TIOS          ; Habilita el IOS5
        movb #$20,TIE           ; C5I=1 para habilitar interrupción
                                ; por output compare del canal 5.

        ;; Habilitación de interrupciones
	cli		; Carga 0 en I en CCR

;***********************************************
; 	     PROGRAMA PRINCIPAL
;***********************************************
        ;; Inicialización de variables.
        ;; Ya que no hay ningún caso especial, se inicailizan en 0.
        movw #$00,Nivel_PROM
        movb #$00,NIVEL
        movw #$0000,VOLUMEN
        movb #$08,CONT_OC
        movb #$00,BCD1
        movb #$00,BCD2
        movb #$00,BCD_L
        movb #$00,BCD_H

        ;; Se habilita la interrupción por output compare.
        ldd TCNT
        addd #46875
        std TC5

ESPERE:
        bra ESPERE
        end

;***********************************************
; 	             CALCULO
;***********************************************
CALCULO:
        ;; Cálculo de nivel

        ;; Aquí se hace una regla de 3 para convertir
        ;; el nivel promedio de bits a metros.
        ldd Nivel_PROM
        ldy #30
        emul                    ; Nivel_PROM * 30
        ldx #1024
        idiv                    ; (Nivel_PROM * 30)/1024
        tfr X,A
        sta NIVEL               ; NIVEL=(Nivel_PROM * 30)/1024

        ;; Cálculo de volumen

        ;; Para este paso se propone escalar los valores
        ;; de radio y pi para trabajar con decimales.
        ;; Con esto se logra tener precisión de 1 decimal.

        ldd #19375              ; (2.5^2)*100 * 3.1*10

        ldx #1000               ; Se divide entre 1000
                                ; para volver a escala
                                ; original

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
        ;; Subrutina de conversión de binario a BCD vista en clase.
BIN_BCD:
        ;; Apila acumuladores e índices usados en subrutina,
        ;; por si se usaba en otras subrutinas.
        pshx
        psha
        pshb

        ;; Aquí inicia conversión de las decenas y centenas de
        ;; VOLUMEN.
        ldab #$0F
        ;; Se apila el valor de R2, ya que se usará el regitro RR1.
        pshb
        ldd 0,X
        movb #$00,BCD_L
        movb #$00,BCD_H
NEXT_BIT_BCD1:
        lsld
        rol BCD_L
        rol BCD_H
        ;; Aqui se carga RR1 a TEMP
        pshd
        ldaa BCD_L
        anda #$0F
        cmpa #$05
        blt NOT_5_ON_L_BCD1
        adda #$03
NOT_5_ON_L_BCD1:
        ;; Aqui se carga R1 a LOW
        psha
        ldaa BCD_L
        anda #$F0
        cmpa #$50
        blt NOT_5_ON_H_BCD1
        adda #$30
NOT_5_ON_H_BCD1:
        ;; Aquí se suma LOw a R1
        adda 0,SP
        sta BCD_L
        ;; Se desapila y decrementa B, se pregunta si es 0. Si lo es,
        ;; termina el proceso y si no, entonces se vuelve a apilar B.
        ins
        leas 2,SP
        pulb
        dbeq B,FINALIZAR_BCD1
        pshb
        leas -2,SP
        ;; Aquí se carga TEMP a RR1
        puld
        bra NEXT_BIT_BCD1
FINALIZAR_BCD1:
        lsla
        rol BCD_L
        rol BCD_H
        movb BCD_L,BCD1




        ;; Aquí inicia conversión de nibble más significativo
        ;; centenas de VOLUMEN.
        ldaa BCD_H
        ldab #$07
        movb #$00,BCD_L
NEXT_BIT_BCD2:
        lsla
        rol BCD_L
        rol BCD_H
        ;; Aqui se carga R1 a TEMP
        psha
        ldaa BCD_L
        anda #$0F
        cmpa #$05
        blt NOT_5_ON_L_BCD2
        adda #$03
NOT_5_ON_L_BCD2:
        ;; Aqui se carga R1 a LOw
        psha
        ldaa BCD_L
        anda #$F0
        cmpa #$50
        blt NOT_5_ON_H_BCD2
        adda #$30
NOT_5_ON_H_BCD2:
        ;; Aquí se suma LOw a R1
        adda 0,SP
        sta BCD_L
        ;; Aquí se carga TEMP a R1
        ins
        pula
        dbeq B,FINALIZAR_BCD2
        bra NEXT_BIT_BCD2
FINALIZAR_BCD2:
        lsla
        rol BCD_L
        rol BCD_H
        movb BCD_L,BCD2


        ;; Se retornan acumuladores e índices.
        pulb
        pula
        pulx
        rts


;***********************************************
; 	             OC5_ISR
;***********************************************
OC5_ISR:
        ;; Se pregunta si el contador de la transmisión ya llegó a
        ;; cero, con el fin de saber si se debe transmitir un dato.
        ;; Los datos se transmiten cada 1s.
        tst CONT_OC
        bne DEC_CONT

        ;; Se carga encabezado: "MEDICION DE VOLUMEN"
        ldx #MSG0
        jsr ESCRIBIR

        ;; Se carga mensaje de: "VOLUMEN ACTUAL"
        ldx #MSG1
        jsr ESCRIBIR

        ;; Se convierte volumen a BCD.
        ldx #VOLUMEN
        jsr BIN_BCD

        ;; Se recibe el nibble más significativo de VOLUMEN por
        ;; memoria en la variable BCD2 y se convierte a ASCII.
        ldaa BCD2
        adda #$30

        ;; Se carga el nibble más significativo para ser enviado por
        ;; SCI.
        sta MSG2
        ldx #MSG2
        jsr ESCRIBIR

        ;; Se recibe el nibble de las decenas y el de las unidades de
        ;; VOLUMEN por memoria en la variable BCD1.

        ;; Primero se extrae el nibble de las decenas se convierte a
        ;; ASCII.
        ldaa BCD1
        lsra
        lsra
        lsra
        lsra
        adda #$30

        ;; Se carga el nibble de las decenas para ser enviado por SCI.
        sta MSG2
        ldx #MSG2
        jsr ESCRIBIR

        ;; Se extrae el nibble de las unidades y se convierte a ASCII.
        ldaa BCD1
        anda #$0F
        adda #$30


        ;; Se carga el nibble de las unidades para ser enviado por SCI.
        sta MSG3
        ldx #MSG3
        jsr ESCRIBIR

        ;; Se pregunta si VOLUMEN =< 15%
        ldaa NIVEL
        cmpa #5
        bgt PREGUNTAR_30        ; Si NIVEL>15%, preguntar
                                ; si NIVEL>30%

        bset PORTE,$04          ; Si NIVEL=<15%, activar
                                ; relé

        ;; Se pregunta si VOLUMEN =< 30%
PREGUNTAR_30:

        ;; Si VOLUMEN =< 30% && RELE = ON,
        ;; se imprime el mensaje de alarma.
        brclr PORTE,$04,RECARGAR_OC
        cmpa #9
        bgt PREGUNTAR_90
        ldx #MSG4
        jsr ESCRIBIR
        bra RECARGAR_OC

        ;; Se pregunta si VOLUMEN =< 90%
PREGUNTAR_90:
        cmpa #27
        blt RECARGAR_OC

        ;; VOLUMEN > 90%, se imprime el mensaje de tanque lleno.
        ldx #MSG5
        jsr ESCRIBIR
        bclr PORTE,$04          ; Si VOLUMEN > 90%, RELE = OFF.

RECARGAR_OC:
        movb #$08,CONT_OC       ; Recarga CONT_OC.
        bra FIN_OC5

DEC_CONT:
        dec CONT_OC             ; Reduce el valor de CONT_OC.

FIN_OC5:
        ;; Limpia las banderas de interrupción y carga el próximo
        ;; valor a comparar en TC5.
        ldd TCNT
        addd #46875
        std TC5
        rti

        ;; Subrutina de escritura de datos
ESCRIBIR:
        ldaa SC1SR1             ; Se lee reg. de status.
        ldab #$00
RETORNO:
        ldaa B,X                ; Carga dato en R1.
        cmpa #EOM
        beq FIN_ESCRIBIR        ; Si DATO=EOM, terminar.
L1:     brclr SC1SR1,$80,L1     ; Espera a transmisión hecha.
        sta SC1DRL              ; Carga dato para transmitir.
L2:     brclr SC1SR1 #$40 L2
        incb                    ; Incrementa offset de registro.
        bra RETORNO
FIN_ESCRIBIR:
        rts


;***********************************************
; 	             ATD0_ISR
;***********************************************
ATD0_ISR:
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
        stx Nivel_PROM          ; El promedio se guarda en Nivel_PROM.

        ;; Se llama a subrutina CALCULO para calcular NIVEL y VOLUMEN.
        jsr CALCULO

        ;; Se rehabilita la interrupción por ATD.
        movb #$87,ATD0CTL5
        rti
