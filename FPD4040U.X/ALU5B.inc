ALU5B_DATA UDATA
    
CBLOCK 0x20
    RES0    
    RES1    
    RES2    
    RES3    
    RES4
    RES0F
    RES1F
    RES2F
    RES3F
    RES4F
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
    REM0
    REM1
    REM2
    REM3
    REM4
ENDC
    
MUL_CNT EQU 0x50
MUL_TIMES EQU 0x51
REM_HANDLE EQU 0x52
 
NUM_BYTES_SEND EQU 0x53 
    
ALU5B_CODE CODE
    
ADD
    ; first byte
    MOVF BARG0, W
    ADDWF AARG0
    
    ; second byte
    MOVF BARG1, W
    BTFSC STATUS, C
    INCFSZ BARG1, W
    ADDWF AARG1
    
    ; third byte
    MOVF BARG2, W
    BTFSC STATUS, C
    INCFSZ BARG2, W
    ADDWF AARG2
    
    ; fourth byte
    MOVF BARG3, W
    BTFSC STATUS, C
    INCFSZ BARG3, W
    ADDWF AARG3
    
    ; fifth byte
    MOVF BARG4, W
    BTFSC STATUS, C
    INCFSZ BARG4, W
    ADDWF AARG4
    
    RETURN
    
    
ADD_R
    ; first byte
    MOVF REM0, W
    ADDWF AARG0
    
    ; second byte
    MOVF REM1, W
    BTFSC STATUS, C
    INCFSZ REM1, W
    ADDWF AARG1
    
    ; third byte
    MOVF REM2, W
    BTFSC STATUS, C
    INCFSZ REM2, W
    ADDWF AARG2
    
    ; fourth byte
    MOVF REM3, W
    BTFSC STATUS, C
    INCFSZ REM3, W
    ADDWF AARG3
    
    ; fifth byte
    MOVF REM4, W
    BTFSC STATUS, C
    INCFSZ REM4, W
    ADDWF AARG4
    
    RETURN    
    
    
    
SUB
    ; first byte
    MOVF BARG0, W
    SUBWF AARG0
    
    ; second byte
    MOVF BARG1, W
    BTFSS STATUS, C
    INCFSZ BARG1, W
    SUBWF AARG1
    
    ; third byte
    MOVF BARG2, W
    BTFSS STATUS, C
    INCFSZ BARG2, W
    SUBWF AARG2
    
    ; fourth byte
    MOVF BARG3, W
    BTFSS STATUS, C
    INCFSZ BARG3, W
    SUBWF AARG3
    
    ; fifth byte
    MOVF BARG4, W
    BTFSS STATUS, C
    INCFSZ BARG4, W
    SUBWF AARG4
    
    RETURN
    
    
TEST_IF_ZERO
    MOVF    AARG0,W
    IORWF   AARG1,W
    IORWF   AARG2,W
    IORWF   AARG3,W
    IORWF   AARG4,W
    
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
    
    BTFSS REM_HANDLE, 0
    GOTO INTEGER
    
FRACTION
    INCF RES0F
    BTFSC STATUS, Z
    INCF RES1F
    BTFSC STATUS, Z
    INCF RES2F
    BTFSC STATUS, Z
    INCF RES3F
    BTFSC STATUS, Z
    INCF RES4F
    GOTO SUB_LOOP
    
    
INTEGER   ; increment quotient 
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
    BTFSC REM_HANDLE, 0
    GOTO EXIT_DIV
    
    CLRF REM_HANDLE
    INCF REM_HANDLE
    CALL ADD
    
    
    
    ; remainder is in AARGx
    MOVLW D'6'
    MOVWF MUL_TIMES
    
MUL_BY_M
    MOVF AARG0, W
    MOVWF REM0
    MOVF AARG1, W
    MOVWF REM1
    MOVF AARG2, W
    MOVWF REM2
    MOVF AARG3, W
    MOVWF REM3
    MOVF AARG4, W
    MOVWF REM4
    CALL MUL
    DECFSZ MUL_TIMES
    
    
    GOTO MUL_BY_M
    
    CALL DIV
          
EXIT_DIV
    BCF REM_HANDLE, 0
    RETURN

    
MUL
    MOVLW D'9'
    MOVWF MUL_CNT
    
MUL_LOOP
    CALL ADD_R
    DECFSZ MUL_CNT
    GOTO MUL_LOOP
    
    RETURN
    
    
    
    


 