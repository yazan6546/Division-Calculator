UART_DATA UDATA
    
BUFFER EQU 0x40
NUM_BYTES EQU 0x41
COUNT EQU 0x42
 
UART_CODE CODE 
 
INIT_UART
    ; Set TX (RC6) output, RX (RC7) input
    BANKSEL TRISC
    BCF TRISC, 6
    BSF TRISC, 7

    ; Baud rate setup (9600, BRGH = 1, SPBRG = 25)
    MOVLW d'25'
    MOVWF SPBRG
    BANKSEL TXSTA
    BSF TXSTA, BRGH
    BSF TXSTA, TXEN
    BANKSEL RCSTA
    BSF RCSTA, SPEN
    BSF RCSTA, CREN

    ; Enable Receive Interrupt
    BANKSEL PIE1
    BSF PIE1, RCIE     ; Enable USART Receive interrupt
    BSF INTCON, PEIE   ; Enable Peripheral Interrupts
    RETURN
    
    
UART_RECV_ISR
    ; Check if USART RX interrupt occurred
    BANKSEL PIR1
    BTFSS PIR1, RCIF
    GOTO NOT_RX

    MOVF COUNT, W
    ADDWF BUFFER, W
    MOVWF FSR
    ; Read received byte into buffer
    MOVF RCREG, W
    MOVWF INDF
    
    INCF COUNT

NOT_RX
    RETFIE             ; Return from interrupt
  
; UART receive procedure
; input: COUNT: # bytes, BUFFER: address of buffer to receive bytes
UART_RECV
    BSF INTCON, GIE
    BANKSEL COUNT
    CLRF COUNT
WAIT_RX
    MOVF COUNT, W
    SUBWF NUM_BYTES, W
    BTFSS STATUS, Z
    GOTO WAIT_RX
    
    RETURN
   
; UART send procedure
; Input: COUNT: # bytes, BUFFER: address of buffer of bytes to send
UART_SEND   
    CLRF COUNT
SEND_LOOP    
    BANKSEL TXSTA
    BTFSS TXSTA, TRMT
    GOTO SEND_LOOP

    BANKSEL TXREG
    MOVF COUNT, W
    ADDWF BUFFER, W
    MOVWF FSR
    MOVF INDF, W
    MOVWF TXREG

    INCF COUNT, F
    MOVF COUNT, W
    SUBWF NUM_BYTES, W
    BTFSS STATUS, Z
    GOTO SEND_LOOP
    
    RETURN    