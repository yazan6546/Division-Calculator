ALU5B_DATA UDATA
    
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
ENDC
    
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
    
   
    


