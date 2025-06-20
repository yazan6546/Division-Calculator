;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays "Welcome to" and "Division!" on LCD using lookup
; Strings stored in program memory using DT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LIST        p=16f877a
    INCLUDE    <p16f877a.INC>
    INCLUDE     <LCD_DRIVER.INC>

    __CONFIG _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _LVP_OFF & _BODEN_OFF  

;===============================================================================
; Variables
;===============================================================================
    cblock 0x20
        INDEX
        TEMP_CHAR
        loop_counter
        button_pressed
        W_TEMP              ; For interrupt context save
        STATUS_TEMP         ; For interrupt context save
    endc

;===============================================================================
; Reset and Interrupt Vectors
;===============================================================================
    ORG 0x00
    goto setup             ; Reset vector

    ORG 0x04
        goto isr_handler      ; Interrupt vector

;===============================================================================
; Main Code
;===============================================================================
    ORG 0x020              ; Start of main program

setup:
    clrf button_pressed ; Initialize button_pressed to 0
    call LCD_INIT          ; Initialize LCD
    call print_first_message ; Print initial messages

    call DEL250
    call DEL250
    call DEL250
    call DEL250
    call DEL250
    call DEL250
    call DEL250
    call DEL250

    call LCD_CLR          ; Clear LCD

    call print_number_message ; Print "Number 1"

    call LCD_L2            ; Move cursor to 2nd line
    call init_ports       ; Initialize ports and interrupts

    call print_number ; Print the number in button_pressed
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



print_first_message:
    movlw 4        
    movwf loop_counter   ; Initialize loop counter
    loop_message:
        call LCD_CLR           ; Clear LCD
        call DEL100
        call LCD_L1            ; Move cursor to 1st line
        call print_welcome     ; Print "Welcome to"
        call LCD_L2            ; Move cursor to 2nd line
        call print_division    ; Print "Division!"
        call DEL250
        call DEL250 ; Delay for effect
        decf loop_counter, F  ; Decrement loop counter
        bnz loop_message       ; If loop_counter == 0, exit loop

    return

print_number_message:
    clrf INDEX
    movlw HIGH(welcome_str)   ; Set PCLATH for correct table page
    movwf PCLATH

print_number_message_loop:
    movf INDEX, W
    call number_str
    movwf TEMP_CHAR
    movf TEMP_CHAR, F
    btfss STATUS, Z           ; If TEMP_CHAR == 0 → end of string
    goto continue_number_message
    clrf PCLATH
    
    return

continue_number_message:
    call LCD_CHAR
    incf INDEX, F
    goto print_number_message_loop





; 
;===============================================================================
; Print the number that is in button_pressed
;===============================================================================

print_number:
    
    movf button_pressed, W ; Get the number to print
    call LCD_CHARD ; convert to ascii
    CALL LCD_CHAR
    return


init_ports:
    ; Initialize ports first
    BANKSEL TRISB 
    bsf TRISB, 0            ; Set RB0 as input (for button)
    bcf TRISB, 1            ; Set RB1 as output (for LED)

    ; Configure interrupt edge
    BANKSEL OPTION_REG
    bcf OPTION_REG, INTEDG  ; Enable interrupt on falling edge

    ; Set up interrupts
    BANKSEL INTCON
    bcf INTCON, INTF        ; Clear external interrupt flag first
    bsf INTCON, INTE        ; Enable external interrupt (RB0)
    bsf INTCON, PEIE        ; Enable peripheral interrupts
    bsf INTCON, GIE         ; Enable global interrupts (do this last)

    BANKSEL 0               ; Return to bank 0
    return

isr_handler:
    ; Save context
    movwf W_TEMP            ; Save W register
    swapf STATUS, W         ; Swap STATUS to W
    movwf STATUS_TEMP       ; Save STATUS

    ; Check which interrupt occurred
    btfss INTCON, INTF      ; Check if external interrupt flag is set
    goto end_isr            ; If not, exit

    ; Handle button press
    incf button_pressed, F  ; Increment button pressed count
    movlw D'10'                ; Check if button_pressed exceeds 9
    xorwf button_pressed, W ; Compare with 10
    btfsc STATUS, Z         ; If button_pressed < 10, continue
    clrf button_pressed      ; Reset button_pressed to 0 if it exceeds 9

    call LCD_CLR            ; Clear LCD
    call print_number_message ; Print "Number 1"
    call LCD_L2            ; Move cursor to 2nd line
    call print_number      ; Print the number in button_pressed

    ; Clear interrupt flag
    bcf INTCON, INTF

end_isr:
    ; Restore context
    swapf STATUS_TEMP, W    ; Restore STATUS
    movwf STATUS
    swapf W_TEMP, F         ; Restore W register
    swapf W_TEMP, W
    retfie                  ; Return from interrupt

;===============================================================================
; String Tables (retlw-based lookup)
;===============================================================================
    ORG 0x100                 ; Place strings at page boundary

welcome_str:
    addwf PCL, F
    DT "Welcome to", 0

division_str:
    addwf PCL, F
    DT "Division!", 0

number_str:
    addwf PCL, F
    DT "Number 1", 0

    END


