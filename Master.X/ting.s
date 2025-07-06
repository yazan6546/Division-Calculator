INCLUDE "P16F877A.INC" 
INCLUDE "UART.INC"
    
__CONFIG 0x3731   
    
RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program

   
ORG 0x004        ; Interrupt vector
GOTO UART_RECV_ISR

MAIN_PROG CODE                      ; let linker place main program
 
CBLOCK 0x20
    RES0    
    RES1    
    RES2    
    RES3    
    RES4    
    AARG0   
    AARG1   
    AARG2   
    AARG3   
    AARG4   
    BARG0   
    BARG1   
    BARG2  
    BARG3   
    BARG4
    BREG
ENDC
 
 
PREP_OPERANDS
    ; initialization 0x002540BE40, 0x00000F4240 => 0x0000000271
    ; first operand
    BANKSEL AARG0
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
    
PREP_OPERANDS_ASCII
    ; initialization 0x002540BE40, 0x00000F4240 => 0x0000000271
    ; first operand
    MOVLW 'g'
    MOVWF AARG0
    MOVLW 'h'
    MOVWF AARG1
    MOVLW 'a'
    MOVWF AARG2
    MOVLW 'z'
    MOVWF AARG3
    MOVLW 'i'
    MOVWF AARG4
    
    ; second operand
    MOVLW 'a'
    MOVWF BARG0
    MOVLW 'h'
    MOVWF BARG1
    MOVLW 'm'
    MOVWF BARG2
    MOVLW 'e'
    MOVWF BARG3
    MOVLW 'd'
    MOVWF BARG4
    
    RETURN     
    
    


;DELAY:
;	MOVLW 0xF0
;	MOVWF CNT1
;D1:
;	MOVLW 0xFA
;	MOVWF CNT0
;D0:
;	DECFSZ CNT0
;	GOTO D0
;	
;	DECFSZ CNT1
;	GOTO D1
;
;	RETURN
;    
    
   
START
    
REPEAT
    CALL INIT_UART ; initialize UART
    CALL PREP_OPERANDS ; prepare operands
    MOVLW D'10'
    MOVWF NUM_BYTES
    MOVLW 0x25
    MOVWF BUFFER
    CALL UART_SEND ; send operands
    INCF AARG0
    BANKSEL BUFFER
    MOVLW 0x20
    MOVWF BUFFER
    CALL UART_RECV ; receive results
;    GOTO REPEAT
    
EXIT    
    GOTO $                          ; loop forever

    END
