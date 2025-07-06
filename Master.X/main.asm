;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Displays "Welcome to" and "Division!" on LCD using lookup
; Strings stored in program memory using DT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    LIST        p=16f877a
    INCLUDE    <p16f877a.INC>
    INCLUDE    <LCD_DRIVER.INC>
    INCLUDE    <BCD_TO_LCD.INC> ; Include BCD to LCD conversion routines
    INCLUDE   <binary_to_bcd.inc> ; Include delay routines
    INCLUDE    <bcd_to_binary.inc> ; Include BCD to Binary conversion routines
    INCLUDE    <UART.inc> ; Include UART routines

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

BUTTON      EQU 1         ; button flag bit
TIMER       EQU 0         ; timer flag bit
DECIMAL_FLAG EQU  2 ; decimal point flag bit

; State definitions
STATE_FIRST_NUM_INT   EQU 0    ; Inputting first number
STATE_FIRST_NUM_DEC   EQU 1    ; Inputting first number

STATE_SECOND_NUM_INT  EQU 2    ; Inputting second number
STATE_SECOND_NUM_DEC  EQU 3    ; Inputting second number

STATE_RESULT      EQU 4    ; Showing result
MYDATA       UDATA                  ; Start uninitialized RAM section

    cblock 0x20
        INDEX
        INDEX_TEMP
        TEMP_CHAR
        TEMP_CHAR1 ; Temporary character for LCD display
        TEMP_CHAR2 ; Temporary character for LCD displays
        loop_counter
        button_pressed
        flags               ; Flags for button and timer
        led_status          ; LED on/off status for debugging
        state               ; Current state: 0=first_num, 1=second_num, 2=result
        W_TEMP              ; For interrupt context save
        STATUS_TEMP         ; For interrupt context save
        timer_h             ; Timer1 high preset value
        timer_l             ; Timer1 low preset value
        overflow_count      ; Count Timer1 overflows for 1 second
        number_1_bcd      :6 ; BCD representation of number 1
        number_2_bcd      :6 ; BCD representation of number 2
        number_1_binary   :5 ; Binary representation of number 1
        number_2_binary   :5 ; Binary representation of number 2
        result_binary   :5 ; Binary representation of result
        result_bcd      :6 ; BCD representation of result
    endc




;===============================================================================
; Main Code
;===============================================================================

MAIN_PROG    CODE                   ; Let linker place code

setup:
    clrf button_pressed ; Initialize button_pressed to 0
    clrf state          ; Initialize state to STATE_FIRST_NUM (0)
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
    call INIT_UART ; Initialize UART for debugging
      ; Initialize flags
    clrf flags         ; Clear flags
    clrf led_status       ; Clear LED status
    clrf INDEX
    call LCD_L2 ; Move cursor to 2nd line, column 0
    call print_number ; Print the number in button_pressed
    call LCD_L2 ; Move cursor to 2nd line, column 0
main_loop:
    ; Check if timer flag is set (1 second elapsed)
    btfsc flags, TIMER ; Check timer flag
    call handle_timer
    
    ; Check if button was pressed (flag set by ISR)
    btfsc flags, BUTTON ; Check button flag
    call handle_button
    
    goto main_loop        ; Continue main loop

handle_timer:
    ; Clear the timer flag
    bcf flags, TIMER

    btfsc PORTB, 0 ; Check if button is pressed
    goto button_not_pressed ; If not pressed, skip handling
    
    ; Button is held - handle state transitions
    goto handle_button_held

button_not_pressed:    
    ; Check current state and handle accordingly
    movf state, W
    sublw STATE_FIRST_NUM_INT
    btfsc STATUS, Z
    goto handle_timer_first_num_int
    
    movf state, W
    sublw STATE_FIRST_NUM_DEC
    btfsc STATUS, Z
    goto handle_timer_first_num_dec
    
    movf state, W
    sublw STATE_SECOND_NUM_INT
    btfsc STATUS, Z
    goto handle_timer_second_num_int
    
    movf state, W
    sublw STATE_SECOND_NUM_DEC
    btfsc STATUS, Z
    goto handle_timer_second_num_dec
    
    ; If in result state, just return
    return

handle_button_held:
    ; Handle button held based on current state
    movf state, W
    sublw STATE_FIRST_NUM_INT
    btfsc STATUS, Z
    goto button_held_first_int
    
    movf state, W
    sublw STATE_FIRST_NUM_DEC
    btfsc STATUS, Z
    goto button_held_first_dec
    
    movf state, W
    sublw STATE_SECOND_NUM_INT
    btfsc STATUS, Z
    goto button_held_second_int
    
    movf state, W
    sublw STATE_SECOND_NUM_DEC
    btfsc STATUS, Z
    goto button_held_second_dec
    
    return

button_held_first_int:
    ; Transition from first number integer to decimal part
    movlw STATE_FIRST_NUM_DEC
    movwf state
    movlw D'6'
    movwf INDEX
    MoveCursorReg 2, INDEX
    return

button_held_first_dec:
    ; Transition from first number decimal to second number integer
    movlw STATE_SECOND_NUM_INT
    movwf state
    clrf INDEX
    call LCD_CLR
    call print_number2_message
    call LCD_L2
    call print_number
    call LCD_L2
    return

button_held_second_int:
    ; Transition from second number integer to decimal part
    movlw STATE_SECOND_NUM_DEC
    movwf state
    movlw D'6'
    movwf INDEX
    MoveCursorReg 2, INDEX
    return

button_held_second_dec:
    ; Transition from second number decimal to result
    call LCD_CLR
    call LCD_L1
    movlw '='
    call LCD_CHAR
    call DEL250
    call DEL250
    call DEL250
    call DEL250

    goto transition_to_result




handle_timer_first_num_int:
    ; Check if we've reached 6 digits for first number integer part
    movf INDEX, W
    sublw D'5'
    btfsc STATUS, Z
    goto wrap_to_zero_first_int
    
    ; Use common timer handler with first number BCD base address
    movlw number_1_bcd
    call handle_timer_common
    return

wrap_to_zero_first_int:
    ; Wrap INDEX back to 0 for integer part without incrementing further
    clrf INDEX
    MoveCursorReg 2, INDEX
    return

handle_timer_first_num_dec:
    ; Check if we've reached 12 digits for first number decimal part
    movf INDEX, W
    sublw D'12'
    btfsc STATUS, Z
    goto transition_to_second_num
    
    ; Use common timer handler with first number BCD base address
    movlw number_1_bcd
    call handle_timer_common
    return

handle_timer_second_num_int:
    ; Check if we've reached 6 digits for second number integer part
    movf INDEX, W
    sublw D'5'
    btfsc STATUS, Z
    goto wrap_to_zero_second_int
    
    ; Use common timer handler with second number BCD base address
    movlw number_2_bcd
    call handle_timer_common
    return

wrap_to_zero_second_int:
    ; Wrap INDEX back to 0 for integer part without incrementing further
    clrf INDEX
    MoveCursorReg 2, INDEX
    return

handle_timer_second_num_dec:
    ; Check if we've reached 12 digits for second number decimal part
    movf INDEX, W
    sublw D'12'
    btfsc STATUS, Z
    goto button_held_second_dec
    
    ; Use common timer handler with second number BCD base address
    movlw number_2_bcd
    call handle_timer_common
    return

; Common timer handler for both numbers
; Input: W contains the base address for BCD storage (number_1_bcd or number_2_bcd)
handle_timer_common:
    movwf TEMP_CHAR ; Store base address temporarily
    
    ; Continue with number input
    movf INDEX, w
    addlw 1 ; Increment INDEX for next character
    movwf INDEX_TEMP ; Store incremented index in INDEX_TEMP
    MoveCursorReg 2, INDEX_TEMP; Move cursor to row 2, column INDEX+1

    ; Save digit to number storage
    movf button_pressed, W
    btfss INDEX, 0 ; Check if index is odd
    goto save_even ; Save button_pressed for number
    ; Convert button_pressed to BCD and display on LCD
    movwf TEMP_CHAR2
    RRF INDEX, W ; Rotate right to divide by 2
    addwf TEMP_CHAR, W ; Add to base address
    movwf FSR ; Store in FSR
    
    call CONVERT_CHAR_TO_BCD ; Convert button_pressed to BCD and display on LCD
    goto skip_save
save_even:
    ; If index is even, save to TEMP_CHAR1
    movwf TEMP_CHAR1 ; Save button_pressed to TEMP_CHAR for display

skip_save:
    incf INDEX, F ; Increment index for next character
    return

transition_to_second_num:

    ; Set function parameter
    movlw number_1_bcd
    movwf INPUT_BASE_ADDR

    movlw number_1_binary ; Set binary output base address
    movwf OUTPUT_BASE_ADDR
    
    ; Call BCD to Binary conversion
    call BCD_TO_BIN_FUNCTION


    clrf button_pressed ; Reset button pressed count
    ; Transition from first number to second number
    movlw STATE_SECOND_NUM_INT
    movwf state
    clrf INDEX              ; Reset index for second number
    call LCD_CLR            ; Clear LCD
    call print_number2_message ; Print "Number 2"
    call LCD_L2             ; Move cursor to 2nd line
    call print_number ; Print the number in button_pressed
    call LCD_L2             ; Move cursor to 2nd line
    return

transition_to_result:
    
    ; Set function parameter
    movlw number_2_bcd
    movwf INPUT_BASE_ADDR

    movlw number_2_binary ; Set binary output base address
    movwf OUTPUT_BASE_ADDR
    
    ; Call BCD to Binary conversion
    call BCD_TO_BIN_FUNCTION

    movlw number_1_binary ; Set first number binary base address
    movwf BUFFER
    movlw D'10' ; Set number of bytes to send
    movwf UART_NUM_BYTES ; Set number of bytes to send via UART
    call UART_SEND ; Send numbers via UART

    movlw result_binary ; Set result binary base addres
    movwf BUFFER
    movlw D'5'
    movwf UART_NUM_BYTES ; Set number of bytes to send via UART
    call UART_RECV

    ; Convert result to BCD
    movlw result_binary ; Set binary input base address
    movwf B2BCD_INPUT_BASE_ADDR
    movlw result_bcd ; Set BCD output base address
    movwf B2BCD_OUTPUT_BASE_ADDR
    call BIN_TO_BCD_FUNCTION ; Convert binary result to BCD

    ; Transition to result state
    movlw STATE_RESULT
    movwf state
    call LCD_CLR            ; Clear LCD
    call LCD_L1             ; Move to first line
    call print_result_message ; Print result

    call LCD_L2             ; Move cursor to 2nd line
    clrf INDEX              ; Reset index for result display

    movlw result_bcd ; Set result BCD base address
    movwf WREG
    call PRINT_BCD_TO_LCD
    return

handle_button:
    ; Clear the button flag
    bcf flags, BUTTON    

    ; Check current state and handle accordingly
    movf state, W
    sublw STATE_FIRST_NUM_INT
    btfsc STATUS, Z
    goto handle_button_first_num
    
    movf state, W
    sublw STATE_FIRST_NUM_DEC
    btfsc STATUS, Z
    goto handle_button_first_num
    
    movf state, W
    sublw STATE_SECOND_NUM_INT
    btfsc STATUS, Z
    goto handle_button_second_num
    
    movf state, W
    sublw STATE_SECOND_NUM_DEC
    btfsc STATUS, Z
    goto handle_button_second_num
    
    movf state, W
    sublw STATE_RESULT
    btfsc STATUS, Z
    goto handle_button_result
    
    return

handle_button_first_num:
    ; Handle button press during first number input
    call print_number     ; Print the number in button_pressed
    MoveCursorReg 2, INDEX ; Move cursor to row 2, column INDEX
    return

handle_button_second_num:
    ; Handle button press during second number input
    call print_number     ; Print the number in button_pressed
    MoveCursorReg 2, INDEX ; Move cursor to row 2, column INDEX
    return

handle_button_result:
    ; Handle button press when showing result - restart the process
    movlw STATE_FIRST_NUM_INT
    movwf state
    clrf INDEX              ; Reset index
    clrf button_pressed     ; Reset button counter
    call LCD_CLR            ; Clear LCD
    call print_number_message ; Print "Number 1"
    call LCD_L2             ; Move cursor to 2nd line
    call print_number       ; Print the current button value
    call LCD_L2             ; Move cursor to 2nd line
    return

;===============================================================================
; Print "Welcome to"
;===============================================================================
print_welcome:
    clrf INDEX_TEMP
    movlw HIGH(welcome_str)   ; Set PCLATH for correct table page
    movwf PCLATH

print_welcome_loop:
    movf INDEX_TEMP, W
    call welcome_str
    movwf TEMP_CHAR
    movf TEMP_CHAR, F
    btfss STATUS, Z           ; If TEMP_CHAR == 0 → end of string
    goto continue_welcome
    clrf PCLATH
    
    return

continue_welcome:
    call LCD_CHAR
    incf INDEX_TEMP, F
    goto print_welcome_loop

;===============================================================================
; Print "Division!"
;===============================================================================
print_division:
    clrf INDEX_TEMP
    movlw HIGH(division_str)  ; Set PCLATH for correct table page
    movwf PCLATH

print_division_loop:
    movf INDEX_TEMP, W
    call division_str
    movwf TEMP_CHAR
    movf TEMP_CHAR, F
    btfss STATUS, Z
    goto continue_division
    clrf PCLATH
    return

continue_division:
    call LCD_CHAR
    incf INDEX_TEMP, F
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
    clrf INDEX_TEMP
    movlw HIGH(number_str)    ; Set PCLATH for correct table page
    movwf PCLATH

print_number_message_loop:
    movf INDEX_TEMP, W
    call number_str
    movwf TEMP_CHAR
    movf TEMP_CHAR, F
    btfss STATUS, Z           ; If TEMP_CHAR == 0 → end of string
    goto continue_number_message
    clrf PCLATH
    
    return

continue_number_message:
    call LCD_CHAR
    incf INDEX_TEMP, F
    goto print_number_message_loop

print_number2_message:
    clrf INDEX_TEMP
    movlw HIGH(number2_str)    ; Set PCLATH for correct table page
    movwf PCLATH

print_number2_message_loop:
    movf INDEX_TEMP, W
    call number2_str
    movwf TEMP_CHAR
    movf TEMP_CHAR, F
    btfss STATUS, Z           ; If TEMP_CHAR == 0 → end of string
    goto continue_number2_message
    clrf PCLATH
    
    return

continue_number2_message:
    call LCD_CHAR
    incf INDEX_TEMP, F
    goto print_number2_message_loop

print_result_message:
    clrf INDEX_TEMP
    movlw HIGH(result_str)    ; Set PCLATH for correct table page
    movwf PCLATH

print_result_message_loop:
    movf INDEX_TEMP, W
    call result_str
    movwf TEMP_CHAR
    movf TEMP_CHAR, F
    btfss STATUS, Z           ; If TEMP_CHAR == 0 → end of string
    goto continue_result_message
    clrf PCLATH
    
    return

continue_result_message:
    call LCD_CHAR
    incf INDEX_TEMP, F
    goto print_result_message_loop





; 
;===============================================================================
; Print the number that is in button_pressed
;===============================================================================

print_number:
    bcf flags, DECIMAL_FLAG ; Clear decimal point flag

    ; put the number of digits in w
    movf INDEX, W ; Get the current index
    sublw D'12' ; Calculate 12 - INDEX (original logic)
    movwf loop_counter ; Store the number of digits to print in loop_counter

    sublw D'6' ; Check if we are at the 6th digit
    btfsc STATUS, Z ; If loop_counter == 6, we are at the decimal point position
    bsf flags, DECIMAL_FLAG ; Set decimal point flag

print_number_loop:
    ; if decimal flag is set, we do not print decimal point, if not set, we proceed with cond
    btfsc flags, DECIMAL_FLAG ; Check if decimal point flag is set
    goto print_char ; If not set, just print character

    ; test if loop counter is 6 (decimal point position)
    movf loop_counter, W ; Get the current loop counter value
    sublw D'6' ; Check if we are at the 6th digit
    btfsc STATUS, Z ; If loop_counter == 6, we are at the decimal point position
    goto print_decimal_point ; If at 6th digit, print decimal point
print_char:

    movf button_pressed, W ; Use current button_pressed value
    call LCD_CHARD ; convert to ascii
    CALL LCD_CHAR
    DECFSZ loop_counter, F ; Decrement remaining count
    goto print_number_loop ; Loop until all digits printed
    return

print_decimal_point:

    ; Print decimal point at the 6th position
    movlw '.' ; Load decimal point character
    call LCD_CHAR ; Display decimal point
    goto print_char ; Continue printing remaining digits


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
    btfsc PIR1, TMR1IF      ; Check Timer1 overflow flag
    goto timer_handler       ; If not set, check button interrupt
      ; Handle Timer1 overflow (0.25 second elapsed)

    BANKSEL INTCON
    btfsc INTCON, INTF      ; Check if external interrupt (button press) occurred
    goto check_button        ; If set, handle button press

    ; Check if USART RX interrupt occurred
    BANKSEL PIR1
    BTFSC PIR1, RCIF
    goto UART_RECV_ISR       ; If USART RX interrupt, handle it

    goto end_isr            ; If no relevant interrupt, just exit

timer_handler
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
    bsf flags, TIMER       ; Set timer flag for main loop to handle
    
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
    bsf flags, BUTTON     ; Set button pressed flag
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

    goto end_isr            ; Exit ISR


UART_RECV_ISR:
    MOVF COUNT, W
    ADDWF BUFFER, W
    MOVWF FSR
    ; Read received byte into buffer
    MOVF RCREG, W
    MOVWF INDF
    
    INCF COUNT

    goto end_isr


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

result_str:
    addwf PCL, F
    DT "Result:", 0

    END







; i have to handle the looping again, in the first iteration, whatever is in button_pressed will be printed, but 
; in the next iteration, whatever in memory should be printed, and button press should not cause any change in the other digits not yet reached
; no change in saving mechanism should be implemented. What if the user skipped when the index is odd???????????????
; this should be handled in save_number function, which is called in skip!!!!!!!!
; i have to handle the looping thing first, then go into skip thing