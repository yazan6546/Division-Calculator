BCD_TO_LCD CODE

    CBLOCK 0x60
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
; Output: Displays the BCD values on the LCD without leading zeros
PRINT_BCD_TO_LCD:
    MOVLW 6 ; Number of BCD bytes to print
    MOVWF NUM_BYTES ; Store count in NUM_BYTES

    ; Load the BCD byte from the address in WREG
    MOVF WREG, W
    MOVWF FSR
    
    ; Initialize leading zero flag (0 = still in leading zeros, 1 = found non-zero)
    CLRF TEMP_CHAR1 ; Use TEMP_CHAR1 as leading zero flag
    
PRINT_BCD_LOOP:
    MOVF INDF, W ; Load BCD byte into W
    MOVWF WREG ; Store it back in WREG for processing
    
    ; Process high nibble (tens digit)
    SWAPF WREG, W ; Get high nibble
    ANDLW 0x0F ; Mask to get only the nibble
    MOVWF TEMP_CHAR2 ; Store high nibble temporarily
    
    ; Check if high nibble is zero and we're still in leading zeros
    MOVF TEMP_CHAR2, F ; Test if high nibble is zero
    BTFSS STATUS, Z ; Skip if zero
    GOTO PRINT_HIGH_NIBBLE ; Not zero, print it
    
    ; High nibble is zero - check if we're still in leading zeros
    MOVF TEMP_CHAR1, F ; Test leading zero flag
    BTFSC STATUS, Z ; If flag is 0 (still leading zeros)
    GOTO SKIP_HIGH_NIBBLE ; Skip this zero digit
    
    ; We've found non-zero before, so print this zero
    GOTO PRINT_HIGH_NIBBLE
    
PRINT_HIGH_NIBBLE:
    ; Set flag to indicate we've found a non-zero digit
    MOVLW 1
    MOVWF TEMP_CHAR1 ; Set leading zero flag
    
    ; Print the high nibble
    MOVF TEMP_CHAR2, W
    ADDLW '0' ; Convert to ASCII
    CALL LCD_CHAR
    
SKIP_HIGH_NIBBLE:
    ; Process low nibble (ones digit)
    MOVF WREG, W ; Get original byte
    ANDLW 0x0F ; Mask to get low nibble
    MOVWF TEMP_CHAR2 ; Store low nibble temporarily
    
    ; Check if low nibble is zero and we're still in leading zeros
    MOVF TEMP_CHAR2, F ; Test if low nibble is zero
    BTFSS STATUS, Z ; Skip if zero
    GOTO PRINT_LOW_NIBBLE ; Not zero, print it
    
    ; Low nibble is zero - check if we're still in leading zeros
    MOVF TEMP_CHAR1, F ; Test leading zero flag
    BTFSC STATUS, Z ; If flag is 0 (still leading zeros)
    GOTO SKIP_LOW_NIBBLE ; Skip this zero digit
    
    ; We've found non-zero before, so print this zero
    GOTO PRINT_LOW_NIBBLE
    
PRINT_LOW_NIBBLE:
    ; Set flag to indicate we've found a non-zero digit
    MOVLW 1
    MOVWF TEMP_CHAR1 ; Set leading zero flag
    
    ; Print the low nibble
    MOVF TEMP_CHAR2, W
    ADDLW '0' ; Convert to ASCII
    CALL LCD_CHAR
    
SKIP_LOW_NIBBLE:
    ; Increment FSR to point to the next BCD byte
    INCF FSR, F
    ; Decrement the byte count
    DECFSZ NUM_BYTES, F
    ; If not zero, repeat the loop
    GOTO PRINT_BCD_LOOP

    ; Check if we printed nothing (all zeros case)
    MOVF TEMP_CHAR1, F ; Test if we printed anything
    BTFSS STATUS, Z ; If we printed something, we're done
    GOTO PRINT_BCD_DONE
    
    ; All zeros case - print a single "0"
    MOVLW '0'
    CALL LCD_CHAR

PRINT_BCD_DONE:
    ; End of BCD_TO_LCD code
    RETURN

; Convert 2 characters to BCD format
; Input: TEMP_CHAR1 contains first character, TEMP_CHAR2 contains second character, 
;        FSR contains the base address for storing BCD values
; Output: BCD values stored in memory at the address in WREG
CONVERT_CHAR_TO_BCD:

    ; Convert TEMP_CHAR1 to BCD
    MOVF TEMP_CHAR1, W ; Load first character into W

    ; Store the BCD value in memory
    MOVWF INDF ; Store the BCD value at the address in WREG
    SWAPF INDF, F ; Swap nibbles to prepare for second character
    MOVF TEMP_CHAR2, W ; Load second character into W
    ; Store the second BCD value in memory
    IORWF INDF, F ; Store the second BCD value in the lower nibble

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

; Convert BCD to ASCII for LCD display (Simple version without leading zero suppression)
; Input: WREG contains BCD byte
; Output: Displays the BCD value on the LCD
PRINT_ONE_BCD_SIMPLE:
    ; Save the original BCD byte
    MOVWF TEMP_CHAR2
    
    ; Print high nibble (tens digit)
    SWAPF TEMP_CHAR2, W ; Swap nibbles to get tens digit
    ANDLW 0x0F          ; Mask to get only the high nibble
    ADDLW '0'           ; Convert to ASCII
    CALL LCD_CHAR
    
    ; Print low nibble (ones digit)
    MOVF TEMP_CHAR2, W  ; Get original byte
    ANDLW 0x0F          ; Mask to get the units digit
    ADDLW '0'           ; Convert to ASCII
    CALL LCD_CHAR
    
    RETURN

; Print 6 bytes of BCD values to LCD (Simple version)
; Input: WREG contains address of initial BCD byte
; Output: Displays all BCD values on the LCD
PRINT_BCD_SIMPLE:
    MOVLW 3             ; Number of BCD bytes to print
    MOVWF TEMP_CHAR1    ; Store count in TEMP_CHAR1
    
    ; Load the BCD byte from the address in WREG
    MOVF WREG, W
    MOVWF FSR
    
PRINT_BCD_SIMPLE_LOOP:
    MOVF INDF, W        ; Load BCD byte into W
    CALL PRINT_ONE_BCD_SIMPLE ; Print the BCD byte
    
    ; Increment FSR to point to the next BCD byte
    INCF FSR, F
    ; Decrement the byte count
    DECFSZ TEMP_CHAR1, F
    ; If not zero, repeat the loop
    GOTO PRINT_BCD_SIMPLE_LOOP
    
    RETURN

