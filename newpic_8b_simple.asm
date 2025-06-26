;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays "Welcome to" and "Division!" on LCD using lookup
; Strings stored in program memory using DT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LIST        p=16f877a
    INCLUDE    <p16f877a.INC>
    INCLUDE     <LCD_DRIVER.INC>

    __CONFIG _XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF & _LVP_OFF & _BODEN_OFF  


;==========================
; 1. RESET VECTOR
;==========================
RESET_VECT   CODE    0x0000         ; Reset vector
    GOTO    setup

; Interrupt vector at 0x0004
INT_VECT     code    0x0004
    goto    isr_handler

;===============================================================================
; Variables
;===============================================================================

MYDATA       UDATA                  ; Start uninitialized RAM section

    cblock 0x20
        INDEX
        TEMP_CHAR
        loop_counter
        button_pressed
        button_flag         ; Flag to indicate button was pressed
        timer_flag          ; Flag to indicate 1 second elapsed
        led_status          ; LED on/off status for debugging
        W_TEMP              ; For interrupt context save
        STATUS_TEMP         ; For interrupt context save
        timer_h             ; Timer1 high preset value
        timer_l             ; Timer1 low preset value
        overflow_count      ; Count Timer1 overflows for 1 second
    endc



;===============================================================================
; Main Code
;===============================================================================

MAIN_PROG    CODE                   ; Let linker place code

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
    call DEL250

    call LCD_CLR          ; Clear LCD

    call print_number_message ; Print "Number 1"
    call LCD_L2           ; Move cursor to 2nd line  
    call init_ports       ; Initialize ports and interrupts
      ; Initialize flags
    clrf button_flag      ; Clear button flag initially
    clrf timer_flag       ; Clear timer flag initially
    clrf led_status       ; Clear LED status

    call print_number ; Print the number in button_pressed

main_loop:
    ; Check if timer flag is set (1 second elapsed)
    btfsc timer_flag, 0
    call handle_timer
    
    ; Check if button was pressed (flag set by ISR)
    btfsc button_flag, 0
    call handle_button
    
    goto main_loop        ; Continue main loop

handle_timer:
    ; Clear the timer flag
    bcf timer_flag, 0
    
    ; Move cursor right
    movlw 0x14            ; LCD command: cursor right
    call LCDINS           ; Send command to LCD
    return

handle_button:
    ; Clear the button flag
    bcf button_flag, 0    
    
    ; Visual indication of timer reset - move cursor to home position
    movlw 0x02            ; LCD command: return home (cursor to position 0)
    call LCDINS           ; Send command to LCD
    
    call LCD_CLR          ; Clear LCD
    call print_number_message ; Print "Number 1"
    call LCD_L2           ; Move cursor to 2nd line
    call print_number     ; Print the number in button_pressed
    return

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
    ; Timer1 setup for exactly 1 second with 4MHz crystal
    ; 4MHz -> 1MIPS, with 1:8 prescaler = 125kHz  
    ; For 0.25 second: 65536 - 31250 = 34286 = 0x85EE
    ; We'll count 4 overflows for 1 full second
    movlw 0x85
    movwf timer_h           ; High byte preset  
    movlw 0xEE
    movwf timer_l           ; Low byte preset
    
    ; Initialize overflow counter for 1 second (4 x 0.25s)
    movlw .4
    movwf overflow_count    ; Initialize Timer1
    call reset_timer1_full  ; Load preset values and reset overflow counter; Configure Timer1 (T1CON register) - Bank 0
    BANKSEL 0
    movlw b'00110001'       ; TMR1ON=1, T1CKPS=11 (1:8 prescaler), TMR1CS=0 (internal clock)
    movwf T1CON

    ; Enable Timer1 interrupt
    BANKSEL PIE1
    bsf PIE1, TMR1IE        ; Enable Timer1 overflow interrupt
    
    ; Clear any pending Timer1 interrupt
    BANKSEL PIR1
    bcf PIR1, TMR1IF

    ; Initialize ports first
    BANKSEL TRISB 
    bsf TRISB, 0            ; Set RB0 as input (for button)
    bcf TRISB, 1            ; Set RB1 as output (for LED)

    ; Configure interrupt edge
    BANKSEL OPTION_REG
    bcf OPTION_REG, INTEDG  ; Enable interrupt on falling edge    ; Set up interrupts
    BANKSEL INTCON
    bcf INTCON, INTF        ; Clear external interrupt flag first
    call DEL100             ; Small delay to settle the button signal
    bsf INTCON, INTE        ; Enable external interrupt (RB0)
    bsf INTCON, PEIE        ; Enable peripheral interrupts
    bsf INTCON, GIE         ; Enable global interrupts (do this last)

    BANKSEL 0               ; Return to bank 0
    return

;===============================================================================
; Reset Timer1 to preset values (restart 1-second countdown)
;===============================================================================
reset_timer1:
    ; Stop Timer1 temporarily
    BANKSEL T1CON
    bcf T1CON, TMR1ON       ; Stop Timer1
    
    ; Load preset values
    BANKSEL TMR1H
    movf timer_h, W         ; Load preset high byte (0x85)
    movwf TMR1H
    movf timer_l, W         ; Load preset low byte (0xEE)
    movwf TMR1L
    
    ; Clear Timer1 overflow flag
    BANKSEL PIR1
    bcf PIR1, TMR1IF
    
    ; Restart Timer1
    BANKSEL T1CON
    bsf T1CON, TMR1ON       ; Restart Timer1
    
    BANKSEL 0               ; Return to bank 0
    return

; Separate function to reset both timer and overflow counter (for button press)
reset_timer1_full:
    call reset_timer1       ; Reset timer values
    movlw .4                ; Reset overflow counter to 4
    movwf overflow_count
    return

isr_handler:
    ; Save context
    movwf W_TEMP            ; Save W register
    swapf STATUS, W         ; Swap STATUS to W
    movwf STATUS_TEMP       ; Save STATUS    ; Check for Timer1 overflow interrupt
    BANKSEL PIR1
    btfss PIR1, TMR1IF      ; Check Timer1 overflow flag
    goto check_button       ; If not set, check button interrupt
      ; Handle Timer1 overflow (0.25 second elapsed)
    bcf PIR1, TMR1IF        ; Clear Timer1 overflow flag
    call reset_timer1       ; Restart timer for next 0.25-second period
    
    ; Decrement overflow counter
    BANKSEL 0
    decf overflow_count, f   ; Decrease counter
    btfss STATUS, Z         ; Skip if zero (1 full second elapsed)
    goto end_isr            ; Not yet 1 second, just exit
      ; 1 full second has elapsed - set timer flag and reset counter
    movlw .4                ; Reset counter for next second
    movwf overflow_count
    bsf timer_flag, 0       ; Set timer flag for main loop to handle
    
    ; Toggle LED for debugging (RB1)
    BANKSEL PORTB
    btfss led_status, 0     ; Check LED status
    goto turn_on_led
    bcf PORTB, 1            ; Turn off LED
    bcf led_status, 0       ; Update status
    goto end_isr
turn_on_led:
    bsf PORTB, 1            ; Turn on LED  
    bsf led_status, 0       ; Update status
    goto end_isr

check_button:
    ; Check for external interrupt (button press)
    BANKSEL INTCON
    btfss INTCON, INTF      ; Check if external interrupt flag is set
    goto end_isr            ; If not, exit
    
    ; Clear external interrupt flag IMMEDIATELY to prevent multiple triggers
    bcf INTCON, INTF
    
    ; Handle button press - reset timer and set flag
    call reset_timer1_full  ; Reset timer and overflow counter on button press
      ; Set button flag for main loop to handle LCD updates
    BANKSEL 0
    bsf button_flag, 0      ; Set button pressed flag
    incf button_pressed, F  ; Increment button pressed count
    movlw D'10'             ; Check if button_pressed reaches 10
    subwf button_pressed, W ; Subtract 10 from button_pressed
    btfsc STATUS, Z         ; If result is zero (button_pressed == 10)
    clrf button_pressed     ; Reset button_pressed to 0
    
    ; Quick LED blink for debugging button press
    BANKSEL PORTB
    bsf PORTB, 1            ; Turn on LED briefly
    call DEL100             ; Short delay
    bcf PORTB, 1            ; Turn off LED

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
STRINGS_SECTION   CODE

welcome_str:
    addwf PCL, F
    DT "Welcome to", 0

division_str:
    addwf PCL, F
    DT "Division!", 0

number_str:
    addwf PCL, F
    DT "Number 1", 0

number2_str:
    addwf PCL, F
    DT "Number 2", 0

    END


