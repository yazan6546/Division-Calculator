;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays "Welcome to" and "Division!" on LCD using lookup
; Strings stored in program memory using DT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LIST        p=16f877a
    #include    <p16f877a.inc>
    INCLUDE     <LCD_DRIVER.INC>

    __CONFIG _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _LVP_OFF & _BODEN_OFF  

;===============================================================================
; Variables
;===============================================================================
    cblock 0x20
        INDEX
        TEMP_CHAR
    endc

;===============================================================================
; Reset and Interrupt Vectors
;===============================================================================
    ORG 0x00
    goto setup             ; Reset vector

    ORG 0x04
    retfie                 ; Interrupt vector (not used)

;===============================================================================
; Main Code
;===============================================================================
    ORG 0x020              ; Start of main program

setup:
    call LCD_INIT          ; Initialize LCD

    call LCD_L1            ; Move cursor to 1st line
    call print_welcome     ; Print "Welcome to"

    call LCD_L2            ; Move cursor to 2nd line
    call print_division    ; Print "Division!"

    goto $                 ; Stay here forever

;===============================================================================
; Print "Welcome to"
;===============================================================================
print_welcome:
    clrf INDEX
    movlw HIGH(welcome_str)   ; Set PCLATH for correct table page
    movwf PCLATH

print_welcome_loop:
    movf INDEX, W
    call welcome_str
    movwf TEMP_CHAR
    movf TEMP_CHAR, F
    btfss STATUS, Z           ; If TEMP_CHAR == 0 → end of string
    goto continue_welcome
    clrf PCLATH
    return

continue_welcome:
    call LCD_CHAR
    incf INDEX, F
    goto print_welcome_loop

;===============================================================================
; Print "Division!"
;===============================================================================
print_division:
    clrf INDEX
    movlw HIGH(division_str)  ; Set PCLATH for correct table page
    movwf PCLATH

print_division_loop:
    movf INDEX, W
    call division_str
    movwf TEMP_CHAR
    movf TEMP_CHAR, F
    btfss STATUS, Z
    goto continue_division
    clrf PCLATH
    return

continue_division:
    call LCD_CHAR
    incf INDEX, F
    goto print_division_loop

;===============================================================================
; String Tables (retlw-based lookup)
;===============================================================================
    ORG 0x200                 ; Place strings far from code & vectors

welcome_str:
    addwf PCL, F
    DT "Welcome to", 0

division_str:
    addwf PCL, F
    DT "Division!", 0

    END
