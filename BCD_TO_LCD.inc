BCD_TO_LCD CODE

    CBLOCK 0x20
        WREG         ; Working register for first BCD Address
        NUM_BYTES   ; Number of BCD bytes to print
    ENDC
 
; Convert BCD to ASCII for LCD display
; Input: WREG contains BCD byte
; Output: Displays the BCD value on the LCD
PRINT_ONE_BCD_TO_LCD:

    ; Mask to get the ones digit
    SWAPF WREG, W ; Swap nibbles to get tens digit
    ANDLW 0x0F
    ; Convert ones digit to ASCII
    ADDLW '0'; Adjust for ASCII conversion
    CALL LCD_CHAR

    MOVF WREG, W ; Swap nibbles to get tens digit
    ; Mask to get the units digit
    ANDLW 0x0F
    ; Convert units digit to ASCII
    ADDLW '0' ; Adjust for ASCII conversion
    CALL LCD_CHAR

    RETURN


; Print 6 bytes of bcd values to LCD
; Input: WREG contains address of initial BCD byte
; Output: Displays the BCD values on the LCD
PRINT_BCD_TO_LCD:
    MOVLW 6 ; Number of BCD bytes to print
    MOVWF NUM_BYTES ; Store count in TEMP_CHAR1
PRINT_BCD_LOOP:
    ; Load the BCD byte from the address in WREG
    MOVF WREG, W
    MOVWF FSR
    MOVF INDF, W ; Load BCD byte into W
    MOVWF WREG ; Store it back in WREG for processing
    ; Call the conversion routine to print the BCD byte
    CALL PRINT_ONE_BCD_TO_LCD
    ; Increment FSR to point to the next BCD byte
    INCF FSR, F
    ; Decrement the byte count
    DECFSZ NUM_BYTES, F
    ; If not zero, repeat the loop
    GOTO PRINT_BCD_LOOP

    ; End of BCD_TO_LCD code
    RETURN


; Initialize BCD values in memory
; This routine sets up the BCD values in the specified memory locations
; Input : Base address in WREG
; Output: BCD values initialized in memory
INIT_BCD:
    ; Initialize BCD values in memory
    MOVF WREG, W ; Load base address into WREG
    MOVWF FSR ; Set FSR to point to the base address
    MOVLW 0x12 ; Example BCD value 0x12
    MOVWF INDF ; Store at address in FSR (WREG points to base address
    INCF FSR, F ; Move to next address
    MOVLW 0x34 ; Example BCD value 0x34
    MOVWF INDF ; Store at next address
    INCF FSR, F ; Move to next address
    MOVLW 0x56 ; Example BCD value 0x56
    MOVWF INDF ; Store at next address
    INCF FSR, F ; Move to next address
    MOVLW 0x78 ; Example BCD value 0x78
    MOVWF INDF ; Store at next address
    INCF FSR, F ; Move to next address
    MOVLW 0x98 ; Example BCD value 0x9A
    MOVWF INDF ; Store at next address
    INCF FSR, F ; Move to next address

    MOVLW 0x64 ; Example BCD value 0xBC
    MOVWF INDF ; Store at next address
    INCF FSR, F ; Move to next address

    RETURN