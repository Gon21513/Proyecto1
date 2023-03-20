;Universidad del Valle de Guatemala
;IE2023 Programación de Microncontroladores
;Autor: LUIS PEDRO GONZALEZ 21513
;Compilador: PIC-AS (v2.40), MPLAB X IDE (v6.00)
;Proyecto: GENERADOR DE ONDAS
;Creado: 03/02/2023
;Última Modificación: 03/02/2023
; 
;---------------------------------------------------
PROCESSOR 16F887
#include <xc.inc>
;---------------------------------------------------
;Palabra de Configuración
;---------------------------------------------------
   
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF              ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON             ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF             ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF                ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF               ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = ON             ; Brown Out Reset Selection bits (BOR controlled by SBOREN bit of the PCON register)
  CONFIG  IESO = OFF              ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF             ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF               ; Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V          ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF               ; Flash Program Memory Self Write Enable bits (Write protection off)

PROCESSOR 16F887
#include <xc.inc>		; Processor specific variable definitions

  
  ;VARIABLES
PSECT udata_shr
    CONTADOR: DS 1; 1 BYTE
    W_TEMP: DS 1; 1 BYTE
    STATUS_TEMP: DS 1; 1 BYTE
    FRECUENCIA: DS 1; actualiza el tmr0
    VERIFICADOR: DS 1 ; 1 BYTE antirebote
    COUNT: DS 1         ; Inicializa el contador de la rampa ascendente
    DIRECTION: DS 1
    WAVES: DS 1

    
    ; Configuración de los registros

   
;-------------- vector reset----------
PSECT resVect, class=CODE, abs, delta=2
ORG 00h ; posición 0000h para el reset
resetVect:
    PAGESEL main
    goto main

;--------------INTERRUPCIONES----------
PSECT intVect, class=CODE, abs, delta=2
ORG 04h ; POSICION DE LA INTERRUPCION

PUSH:
    MOVWF W_TEMP    ;PONER EL VALOR DEL W EN EN WTEMP,ES DECIR LA VARIABLE TEMPORAL
    SWAPF STATUS, W    ;HACER SWAP Y GUARDAR EN W
    MOVWF STATUS_TEMP    ;MOVER EL VALOR DE W EN LA OTRA VARIABLE TEMPORAL

ISR:     
    BTFSC RBIF    ;REVISAR EL BIT DE INTERRUPCIONES DEL PUERTO B
    CALL INT_PORTB  ;IR A LA SUBRUTINA DE PORTB
    
    BTFSC T0IF ; REVISAR EL BIT DE INTERRUPCIONES DEL TMR0
    CALL INT_TMR0


 
POP:
    SWAPF STATUS_TEMP, W    ;CAMBIAR EL VALOR DE STATUS CON W
    MOVWF STATUS    ;CARGAR EL VALOR DEL STATUS, ES DECIR, W A STTUS
    SWAPF W_TEMP, F    ;CAMBIAR STATUS_TEMP DE W A F PARA QUE ESTEN EN ORDEN AL MOVERLOS
    SWAPF W_TEMP, W    ;MOVER EL VALOR DE W A W, SE ROTA DE NUEVO PARA NO MODIFICAR EL ORDEN Y GUARDAR EN W
    RETFIE    ;REGRESAR DE LA INTERRUPCIóN
    
;------------------SUBRUTINAS--------------------
   
///////////////////////////////////////////////////////////////
///////////////////////INTERRUPCION DEL TMR0//////////////////////
////////////////////////////////////////////////////////////
    
INT_TMR0:
/////////// INICIO EL TMR0///////////////////////
    BANKSEL TMR0 ; SELCCIONA EL TMR0
    //0.002 SEG = 4*1/4MHZ*256-N*256 Y SE DESPEJO N
    MOVLW 216 ; DELAY DE 2MS
    MOVWF TMR0 ; CARGAR EL VALOR AL TMRO

    CALL CHANGER ; LLAMA A LA SUBRUTINA QUE ELIJE ENTRE FUNCIONES 
    
    BCF T0IF 
    
 ; LLAMAR A LA SUBRUTINA DE GENERACION DE ONDAS CUADRDAS
    RETURN
    
    

///////////////////////////////////////////////////////////////
/////////INTERRUPCION DEL PUERTO B(PUSHBUTTONS)///////////
///////////////////////////////////////////////////////////
INT_PORTB:
    
    BANKSEL PORTA; LLAMR AL BANCO
    
  
    BTFSC PORTB, 7 ; REVISAR SI SE PRESIONA EL BOTON
    CALL VERIFICADOR1 ; LLAMAR AL ANTIRREBOTE
    BTFSS PORTB, 7 ; REVISAR SI SE DEJA DE PRESIONAR
    CALL CHANGE_WAVE
    RETURN		    ;REGRESAR 
   
    
VERIFICADOR1:
    BSF VERIFICADOR, 0 ; COLOCAR LA CONDICION COMO 1, bit 0
    RETURN ; REGREAR AL LOOP DE CHEQUEO 
    
CHANGE_WAVE:
    BTFSS VERIFICADOR, 0 ; SI EL TERCER BIT DE CONDICION NO ES 1, NO PRESIONADO, REGRESAR AL LOOP, SI ES 1, INCREMENTAR
    RETURN ; REGRESA AL LOOP DE CHEQUEO
    INCF WAVES, F
    CLRF VERIFICADOR ; REINICIAR LA CONDICION
    CLRF PORTA
    RETURN ; REGRESA AL CALL DE LA FUNCION   

CHANGER:
    MOVF WAVES, 0   ; MOVER LA VARIABLE QUE CAMBIA EL BOTON A W
    
    
    BTFSC STATUS, 2	 ; CHEQUEAR SI ERA LA PRIMERA, ES DECIR, DEFAULT 
    goto CUADRADA	 ; DEFAULT ES LA FUNCION CUADRADA
    MOVF WAVES, 0   ; MOVER LA VARIABLE QUE CAMBIA EL BOTON A W
    SUBLW 1		 ; SI NO ERA LA PRIMERA, CHEQUEAR SI ES LA SEGUNDA
    BTFSC STATUS, 2

    goto TRIANGULAR	 ; SEGUNDA ES TRIANGULAR
    MOVF WAVES, 0   ; MOVER LA VARIABLE QUE CAMBIA EL BOTON A W
    SUBLW 2		 ; SI NO ES LA TERCERA, ES LA CUARTA
    BTFSC STATUS, 2

    RETURN
    CLRF WAVES       ; REINICIAR LA VARIABLE
    CLRF PORTA
    RETURN


    
/////////////////////////////////////////////////\
    ///////////////////FUNCION DE ONDA CUADRDA
////////////////////////////////////
CUADRADA:
    MOVF CONTADOR, W ; MOVER EL VALOR DEL CONTTADOR SE MUEVE A W
    XORLW 0xff ; SE INVIERTEN LOS BITS
    MOVWF CONTADOR ;EL RESULTADO SE ALMACENA EN EL CONTADOR
    MOVF CONTADOR, W ; SE CARGA EL VALOR DEL CONTADOR A W
    MOVWF PORTA ; SE MUEVE EL VALOR DE W A PORT D 
    BCF T0IF ; LIMPIAR LA BANDERA DE OVERFLOW DEL TMR0
    ////////////////////////
    RETURN
    

    
   ///////////////////////////////////////////////////////////////
/////////////////////////////////////FUNCION TRIANGULAR    
/////////////////////////////////////////////////////////////////////
TRIANGULAR:
   MOVF DIRECTION, W     ; Carga el valor de la variable direction en W
   BTFSS STATUS, 2       ; Si direction es 0, salta la siguiente instrucción
   GOTO INCREMENT_COUNT  ; Si direction es 1, salta a increment_count
   
DECREMENT_COUNT:
      DECFSZ COUNT, F    ; Decrementa la cuenta en 1
      GOTO END_ISR       ; Si count no ha llegado a 0, salta a end_isr
      BSF DIRECTION, 0    ; Si count llega a 0, invierte la dirección a descendente
      GOTO END_ISR
      RETURN
INCREMENT_COUNT:
      INCFSZ COUNT, F    ; Incrementa la cuenta en 1
      GOTO END_ISR       ; Si count no ha llegado a 255, salta a end_isr
      BCF DIRECTION, 0    ; Si count ha llegado a 255, invierte la dirección a ascendente
      RETURN
END_ISR:
      MOVF COUNT, W      ; Carga el valor de la cuenta en W
      MOVWF PORTA         ; Escribe el valor de la cuenta en el puerto D para generar la señal analógica
      RETURN                   ; Salir de la interrupción                ; Salir de la interrupción                 ; Salir de la interrupción


    
;----------- Código Principal ----------
PSECT CODE, delta=2, abs
 ORG 100h
 
 
////////////////////////////////////////////////////////
 ////TABLA DE FRECUANCIAS PARA INGRESAR AL TMR0
 ///////////////////////////////////
FRECUENCIAS:
    CLRF PCLATH ; limpiar pclath
    BSF PCLATH, 0 ; estbalecel el bit 0 de pclath, es decir en 01
    
    ANDLW 0x0F     ; 15 A W PARA ESTABLECER LIMITE Y QUE W SOLO TENGA LOS 4 BITS MENOS SINIFICATIVOS
    ADDWF PCL      ;SUMA EL PCL Y W, ASI PC = PCLATH+PCL+W, INDICA POSICION EN PC
    
    
    ///////////////////////valores de 128 prescaler
    RETLW 01100100B ;0;100
    RETLW 10110001B ;1;200
    RETLW 11001011B ;2;300
    RETLW 11011000B ;3;400
    RETLW 11100000B ;4;500
    RETLW 11100101B ;5;600
    RETLW 11101001B ;6;700
    RETLW 11101100B ;7;800
    RETLW 11101110B ;8;900
    RETLW 11110000B ;9;1khz
    ///////////////////////valores de 64 prescaler
    RETLW 11100011B ;10;1.1khz
    RETLW 11100101B ;11;1.2khz
    RETLW 11100111B ;12;1.3khz
    RETLW 11101001B ;13;1.4
    RETLW 11101011B ;14;1.5
    RETLW 11101100B ;15;1.6
    RETLW 11101101B ;16;1.7
    RETLW 11101110B ;17;1.8
    RETLW 11101111B ;18;1.9
    //////////////////////valores de 32
    RETLW 11100000B ;2.0;19
    RETLW 11100010B ;2.1;20
    RETLW 11100011B ;2.2;21
    RETLW 11100100B ;2.3;22
    RETLW 11100101B ;2.4;23
    RETLW 11100111B ;2.5;24
    RETLW 11100111B ;25;2.6
    RETLW 11101000B ;2.7;26
    RETLW 11101001B ;2.8;27
    RETLW 11101010B ;2.9;28
    ////////////////////////valores de 16
    RETLW 11010110B ;29;3.0
    RETLW 11010111B ;30;3.1
    RETLW 11011000B ;31;3.2
    RETLW 11011010B ;32;3.3
    RETLW 11011011B ;33;3.4
    RETLW 11011100B ;34;3.5
    RETLW 11011101B ;37;3.6
    RETLW 11011110B ;36; 3.7
    RETLW 11011111B ;37;3.8
    RETLW 11011111B ;3.9;38
    RETLW 11100000B ;39;4.0

 
; CONFIGURACIONES
   
main:
   
///////////////////////////////////////////////////////////
 ///////////CONFIGURACION DE PUERTOS
 //////////////////////////////////////
BANKSEL ANSEL ; INGRESAR AL BANCO DE ANSEL
CLRF ANSEL
CLRF ANSELH ;CONGIFURAR PUERTOS COMO DIGITALES
   
       
;PONER  PUERTO COMO SALIDAS
BANKSEL TRISA
CLRF TRISA    ;PUERTO D COMO SALIDA

BANKSEL TRISB
BSF TRISB,6      ;RD6 COMO ENTRADA push buttons CUAD
BSF TRISB, 7      ;RA7 COMO ENTRADA TRIA 


 ;INICIAR PUERTOS
BANKSEL PORTA     ;ir al banco de puertos
CLRF PORTA; INICIA EL PUERTO D
CLRF PORTB ; INICIA EL PUERTO B


//////////////////////////////////////////////
/////INTERRUPCIONES DEL PORTB ON CHANGE
/////////////////////////////////////////////////////////////
BANKSEL IOCB ;ABRIR EL BANCO DONDE SE CONFIGURAN LS INTERRUPCIONED
   
BSF IOCB, 6 ;PORTB6 INTERRUPCION PARA PUSHBUTTON
BSF IOCB, 7; PORTB7 INTERRUPCION PARA PUSHBUTTON
   
BANKSEL PORTA
MOVF PORTB, W ; CARGAR EL VALOR DE PORTB A W PARA FINALIZAR MISMATCH
BCF RBIF ; LIMPIAR LA BANDER DE INT ON CHANGE DE PORTB
   
   
/////////////////////////////////////////////////////
/////////////////PULL UPS
/////////////////////////////////////////////////////
BANKSEL OPTION_REG
BCF OPTION_REG, 7    ;SE LIMPIA RBPU PARA USAR PULL UPS
BANKSEL WPUB    ;DETERMINAR PINES QUE VAN A LLEVAR PULL-UPS
BSF WPUB, 6    ; PULL-UP
BSF WPUB, 7    ; PULL-UP
   


/////////////////////////////////////////////////////////
 //configuracion del oscilador
/////////////////////////////////////////////////////////
// 8MHZ COMO OSCILADOR
BANKSEL OSCCON ; aqui se encuentra la configurcion del oscildor
BSF IRCF2 ; 1 en el bit 6
BSF IRCF1 ;1 en el bit 5
BSF IRCF0 ; 1  en el bit 4
BSF SCS ; selecciona el oscilador interno

   
 ///////////////////////////////////////////////////////////////////////////////
    //CONFIGURACION DEL PRESCALER
    ////////////////////////////////////////////////////////////
BANKSEL TRISA ; SELECCIONAR EL OR
    ;TMR0 RATE 1:256 ES 111 eb=n datasheet
    ;Prescaler Assignment bit
;BCF PSA ;SE LE ASIGNA EL PRESCALER AL TIMER, PRE EN 0
;BSF PS2 ; PS2 EN 1
;BSF PS1; PS1 EN 1
;BSF PS0 ; PS0 EN 1
;BCF T0CS ; PONER T0CS EN 0 PARA QUE OPERE COMO TIMER,  Timer0 Clock Source Select bit    
MOVLW 0b00000110
MOVWF OPTION_REG
BCF T0CS ; PONER T0CS EN 0 PARA QUE OPERE COMO TIMER,  Timer0 Clock Source Select bit    
    ; Configurar el Timer0 con un preescaler de 128


///////////////////////////////////////////////////
//////////////INTERRUPCIONES GLOBALES
/////////////////////////////////////////////
    
BANKSEL INTCON
BSF GIE ; HABILTAR LAS INTERUPPCIONES GLOBALES
BSF T0IE ; ACTIVAR INTERRUPCION DEL TMR0
BCF T0IF ;BANDERA DEL TMR0

    
BSF RBIE ; ACTIVAR EL CAMBIO DE INTERRUPCIONES EN PORTB
BCF RBIF ; LIMPIAR LA BANDER DE PORTB
    
//////////////////////////////////////
/////////// INICIO EL TMR0///////////////////////
//////////////////////////////////////////////////
BANKSEL TMR0 ; SELCCIONA EL TMR0
    //0.002 SEG = 4*1/4MHZ*256-N*256 Y SE DESPEJO N
MOVLW 216 ; DELAY DE 2MS
MOVWF TMR0 ; CARGAR EL VALOR AL TMRO
BCF T0IF ; LIMPIAR LA BANDERA DE OVERFLOW DEL TMR0
      
;MOVLW 0b00000110
;MOVWF OPTION_REG
;BCF T0CS ; PONER T0CS EN 0 PARA QUE OPERE COMO TIMER,  Timer0 Clock Source Select bit    
    ; Configurar el Timer0 con un preescaler de 128
LOOP:

    GOTO    LOOP

END