;***********************************************
;                  TAREA #4
;***********************************************

#include "../../include/registers.inc"

;***********************************************
; REDIRECCIONAMIENTO DEL VECTOR DE INTERRUPCION
;***********************************************

	org $3E4C               ; Vec. interrupción IRQ
	dw PTH_ISR

        org $3E70               ; Vec. interrupción RTI
        dw RTI_ISR

;***********************************************
; 	       DECLARACION DE MEMORIA
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
; 	     CONFIGURACION DE HARDWARE
;***********************************************
		org $1100

	lds #$3BFF              ; Carga puntero de pila.

        ;; Configuración del Puerto A para teclado
	movb #$01,PUCR          ; Habilitación del resistencia de
                                ; pull-up para puerto A.

        movb #$F0,DDRA          ; PA4-7: salida
                                ; PA0-3: entrada

        ;; Configuración de RTI_ISR
        movb #$14, RTICTL       ; Define interrupciones de 1ms
        bset CRGINT, #$80       ; Habilita interrupción RTI

        ;; Configuración de PTH_ISR
        bset DDRJ,#$03           ; PJ1 escritura
	bclr PTJ,#$02            ; PJ1 como GND
        bset PIEH,#$01          ; Habilita interrupción de PH0
        bclr PPSH,#$01          ; Selección de interrupción por
                                ; flanco decreciente

;***********************************************
; 	   PROGRAMA PRINCIPAL
;***********************************************

        ;; Se inicializan las variables en cero
        movb #$06,MAX_TCL
        movb #$FF,TECLA
        movb #$FF,TECLA_IN
        movb #$00,CONT_REB
        movb #$00,CONT_TCL
        movb #$00,PATRON
        movb #$00,BANDERAS

        ;; Inicialización de Arreglo
        ldaa MAX_TCL
        ldx  #NUM_ARRAY
INIT_ARR:
        movb #$FF,1,X+
        dbne A,INIT_ARR

        ;; Habilitación de interrupciones
	cli		        ; Carga 0 en I en CCR

        ;ldab #$00               ; A usar en direccionamiento
                                ; indexado con acumulador
ESPERE:
        ;; Si hay Array_OK, entonces proceda a crear las secuencias de teclas
        ;; leídas. Si no, siga esperando a TECLA_LISTA.
        brclr BANDERAS,$04,TAREA_TECLADO
        bra ESPERE
        end

;***********************************************
; 	             TAREA_TECLADO
;***********************************************
TAREA_TECLADO:

        tst CONT_REB                ; Si no termina proceso de
        bne FIN_TAREA_TECLADO       ; rebote, descontar un rebote.

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
        cmpb #$06               ; Si la tecla a cargar es la tercera
        bge FIN_FORM_ARRY       ; y diferente de B o E, no la cargue.

        movb TECLA_IN,B,X       ; En caso cotrario, cárguela.
        incb                    ; Cuando se carga siguiente tecla, se suma el índice.

        cmpb #$07               ; Si el índice excede el rango
        beq REINICIAR_TCL       ; se reinicia.

        bra FIN_FORM_ARRY       ; Si no, se finaliza la secuencia.

REINICIAR_TCL:
        ;; Reinicio de VALOR y BANDERAS para aceptar nuevos valores.
        ldb #$00

FIN_FORM_ARRY:
        stab CONT_TCL
        movb #$FF,TECLA_IN      ; Hace TECLA=$FF

        rts

BORRAR:
        ;; Si $0B se carga a TMP1, ignorar y cargar siguiente dato.
        tstb
        beq FIN_FORM_ARRY
        ;; cmpb #$06
        ;; beq BORRADO_ESPECIAL

        ;;  Si no se cumplen las condiciones antreriores, reducir el índice para
        ;; cargar el dato.
        decb
        movb #$FF,B,X

;;         bra FINALIZAR_BORRADO

;; BORRADO_ESPECIAL:
;;         decb
;;         movb #$FF,B,X

;; FINALIZAR_BORRADO
        bra FIN_FORM_ARRY
ENTER:
        ;; Si $0E se carga a TMP1, ignorar y cargar siguiente dato.
        tstb
        beq FIN_FORM_ARRY
        bset BANDERAS,$04
        bra FIN_FORM_ARRY

;***********************************************
; 	             MUX_TECLADO
;***********************************************
MUX_TECLADO:

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
        rts


;***********************************************
; 	   PTH_ISR
;***********************************************
PTH_ISR:
        bclr BANDERAS,$04

        ;; Inicialización de Arreglo
        ldaa MAX_TCL
        ldx  #NUM_ARRAY
INIT_ARR1:
        movb #$FF,1,X+
        dbne A,INIT_ARR1
        bset PIFH, $01          ; Limpia la interrupción.
        rti

;***********************************************
; 	             RTI_ISR
;***********************************************
RTI_ISR:
        ;; Reduce el valor de CONT_REB si este es diferente de cero.
        tst CONT_REB
        beq RETORNAR
        dec CONT_REB
RETORNAR:
        bset crgflg, #$80       ; Se rehabilita la interrupción
        rti
