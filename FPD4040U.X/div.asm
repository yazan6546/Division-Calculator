
 
INCLUDE "P16F877A.INC"     
INCLUDE "UART.INC"
INCLUDE "ALU5B.INC"     
    
__CONFIG 0x3731   
    
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

   
ORG 0x004        ; Interrupt vector
GOTO UART_RECV_ISR

MAIN_PROG CODE                      ; let linker place main program
 
    
PREP_OPERANDS
    ; initialization 0x002540BE40, 0x00000F4240 => 0x0000000271
    ; first operand
    MOVLW 0x40
    MOVWF AARG0
    MOVLW 0xBE
    MOVWF AARG1
    MOVLW 0x40
    MOVWF AARG2
    MOVLW 0x25
    MOVWF AARG3
    MOVLW 0x00
    MOVWF AARG4
    
    ; second operand
    MOVLW 0x11
    MOVWF BARG0
    MOVLW 0x11
    MOVWF BARG1
    MOVLW 0x0F
    MOVWF BARG2
    MOVLW 0x00
    MOVWF BARG3
    MOVLW 0x00
    MOVWF BARG4
    
    RETURN
    
    
CLEAR
    ; initialize result registers
    CLRF RES0
    CLRF RES1
    CLRF RES2
    CLRF RES3
    CLRF RES4
    CLRF RES0F
    CLRF RES1F
    CLRF RES2F
    CLRF RES3F
    CLRF RES4F
    RETURN
    

   
    

; -------------- MAIN --------------
START
   
REPEAT
    CALL INIT_UART ; initialize UART
    BANKSEL NUM_BYTES
    MOVLW D'10'
    MOVWF NUM_BYTES
    MOVLW 0x2A
    MOVWF BUFFER
    CALL UART_RECV
    CALL CLEAR
   
    CALL DIV
    BANKSEL BUFFER
    MOVLW 0x20
    MOVWF BUFFER

    BANKSEL NUM_BYTES
    MOVLW D'5'
    MOVWF NUM_BYTES

    CALL UART_SEND
;    GOTO REPEAT
    
    

    GOTO $                          ; loop forever

    END