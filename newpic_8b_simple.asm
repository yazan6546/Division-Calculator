;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Copyright (c) 2013 Manolis Agkopian			      ;
;See the file LICENCE for copying permission.		      ;
;							      ;
;THIS IS JUST SOME TEST CODE THA USES THE LCD DRIVER TO PRINT ;
;THE NUMBERS FROM 0 TO 9 TO THE LCD WITH A DELAY              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	list        p=16f877a           ; Tell assembler which PIC we're using
    #include    <p16f877a.inc>      ; Include register definition
    INCLUDE <LCD_DRIVER.INC>

    
	__CONFIG _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _LVP_OFF & _BODEN_OFF  

    cblock 0x20
        INDEX
        TEMP_CHAR
    endc

; Reset Vector
;******************************************************************************
    ORG 0x00
    goto setup        ; Jump to main code on reset    ORG 0x100
    ; String lookup tables
welcome_str:
    addwf   PCL, f
    dt      "Welcome to", 0

division_str:
    addwf   PCL, f  
    dt      "Division!", 0

    ORG 0x04
;   goto isr         ; Jump to interrupt routine

ORG 0x020
setup:
    CALL LCD_INIT ;FIRST OF ALL WE HAVE TO INITIALIZE LCD
    CALL LCD_L1 ;MOVE CURSOR TO 1ST ROW
    CALL print_welcome ; Print welcome message
    CALL LCD_L2 ; Move cursor to 2nd row    
    CALL print_division ; Print division message

    ; Infinite loop to keep the program running    goto $
    goto $ ; Stay here forever

print_welcome:
    clrf INDEX
read_loop:
    movf INDEX, W        ; Load current index
    call welcome_str     ; Get character at index (via retlw)
    ; Check if it's the null terminator
    movwf TEMP_CHAR     
    movf TEMP_CHAR, f    ; Test TEMP_CHAR
    btfss STATUS, Z      ; Skip if zero (end of string)
    goto continue        ; If W != 0, continue processing
    return               ; Return if we reached the end of the string

    ; W now has the character
    ; CALL DEL250          ; DO 250MS DELAY, JUST FOR THE EFFECT
    

continue: 
    CALL LCD_CHAR        ; LCD_CHAR WRITES AN ASCII CODE CHAR TO THE LCD
    incf INDEX, f        ; Move to next char
    goto read_loop

print_division:
    clrf INDEX
read_loop1:
    movf INDEX, W        ; Load current index    call division_str    ; Get character at index (via retlw)
    
    call division_str     ; Get character at index (via retlw)
    ; W now has the character
    movwf TEMP_CHAR     
    movf TEMP_CHAR, f    ; Test TEMP_CHAR
    btfss STATUS, Z      ; Skip if zero (end of string)
    goto continue1       ; If W != 0, continue processing
    return               ; Return if we reached the end of the string

continue1:
    call LCD_CHAR        ; LCD_CHAR WRITES AN ASCII CODE CHAR TO THE LCD
    incf INDEX, f        ; Move to next char
    goto read_loop1

    END