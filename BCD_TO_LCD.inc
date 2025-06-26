BCD_TO_LCD CODE

    CBLOCK 0x20
        WREG         ; Working register for first BCD Address
        NUM_BYTES   ; Number of BCD bytes to print
    ENDC
 
; Convert BCD to ASCII for LCD display
; Input: WREG contains address of BCD byte
; Output: Displays the BCD value on the LCD
PRINT_ONE_BCD_TO_LCD:

    ; Mask to get the ones digit
    ANDLW 0x0F
    ; Convert ones digit to ASCII
    ADDLW 'A'; Adjust for ASCII conversion
    CALL LCD_CHAR

    SWAPF WREG, W ; Swap nibbles to get tens digit
    ; Mask to get the units digit
    ANDLW 0x0F
    ; Convert units digit to ASCII
    ADDLW 'A' ; Adjust for ASCII conversion
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


    
