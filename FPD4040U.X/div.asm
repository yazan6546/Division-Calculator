
 
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
    MOVLW 0x41
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
    MOVLW 0x40
    MOVWF BARG0
    MOVLW 0x42
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
    RETURN
    

; -------------- DIV PROCEDURE --------------
DIV    
SUB_LOOP
    ; test if dividend got to zero
    CALL TEST_IF_ZERO
    BTFSC STATUS, Z
    GOTO EXIT_DIV
    ; if not repeat subtraction
    CALL SUB
    ; test if divided got negative
    BTFSS STATUS, C
    GOTO NEG
    ; if not, increment quotient
    INCF RES0
    BTFSC STATUS, Z
    INCF RES1
    BTFSC STATUS, Z
    INCF RES2
    BTFSC STATUS, Z
    INCF RES3
    BTFSC STATUS, Z
    INCF RES4
    
    GOTO SUB_LOOP

; remainder is calculated here
NEG
    ; correct the result
    CALL ADD
          
EXIT_DIV
    RETURN
    
    

; -------------- MAIN --------------
START
    CALL INIT_UART
;REPEAT
    BANKSEL NUM_BYTES
    MOVLW D'10'
    MOVWF NUM_BYTES
    MOVLW 0x25
    MOVWF BUFFER
    CALL UART_RECV
    CALL CLEAR
    CALL DIV
    BANKSEL BUFFER
    MOVLW 0x20
    MOVWF BUFFER

    BANKSEL NUM_BYTES
    MOVLW D'10'
    MOVWF NUM_BYTES

    CALL UART_SEND
;    GOTO REPEAT
    
    

    GOTO $                          ; loop forever

    END