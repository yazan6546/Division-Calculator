; filepath: main.asm
;******************************************************************************
; PIC16F877A LED Blinker - Human Written Assembly
; Author: Programmer
; Date: June 19, 2025
; Description: Blinks 8 LEDs connected to PORTB in various patterns
; Clock: 20MHz Crystal Oscillator
;******************************************************************************

    list        p=16f877a           ; Tell assembler which PIC we're using
    #include    <p16f877a.inc>      ; Include register definition
    #include	<LCD_DRIVER.inc>
;******************************************************************************
; Configuration Bits
;******************************************************************************
    __config    _HS_OSC & _WDT_OFF & _PWRTE_ON & _BODEN_ON & _LVP_OFF & _CPD_OFF

;******************************************************************************
; Variable Definitions
;******************************************************************************
    cblock  0x20                   ; Start of user RAM
        delay_count1                ; Delay counter 1
        delay_count2                ; Delay counter 2
        delay_count3                ; Delay counter 3
        pattern_counter             ; Pattern selection counter
        temp_reg                    ; Temporary register
    endc

;******************************************************************************
; Reset Vector
;******************************************************************************
ORG 0x00
    goto main        ; Jump to main code on reset

ORG 0x04
;    goto isr         ; Jump to interrupt routine

ORG 0x05
main:
;******************************************************************************
; Main Program
;******************************************************************************
    ; Initialize the PIC
    MESSG "ahahaa"
    call    init_ports              ; Set up I/O ports
    clrf    pattern_counter         ; Start with pattern 0

main_loop:
    ; Cycle through different LED patterns
    movf    pattern_counter, w      ; Get current pattern
    andlw   0x03                    ; Keep only lower 2 bits (0-3)
    movwf   temp_reg
    
    ; Jump to appropriate pattern using lookup table
    call    pattern_jump
    goto    main_loop

pattern_jump:
    movf    temp_reg, w
    addwf   PCL, f                  ; Computed goto
    goto    pattern_simple_blink    ; Pattern 0
    goto    pattern_running_left    ; Pattern 1
    goto    pattern_running_right   ; Pattern 2
    goto    pattern_alternating     ; Pattern 3

;******************************************************************************
; Pattern 0: Simple All LEDs Blink
;******************************************************************************
pattern_simple_blink:
    movlw   0xFF                    ; All LEDs ON
    movwf   PORTB
    call    delay_500ms             ; Wait 500ms
    
    clrf    PORTB                   ; All LEDs OFF
    call    delay_500ms             ; Wait 500ms
    
    incf    pattern_counter, f      ; Next pattern
    return

;******************************************************************************
; Pattern 1: Running Light Left to Right
;******************************************************************************
pattern_running_left:
    movlw   0x01                    ; Start with leftmost LED
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x02                    ; Next LED
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x04
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x08
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x10
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x20
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x40
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x80                    ; Rightmost LED
    movwf   PORTB
    call    delay_200ms
    
    incf    pattern_counter, f      ; Next pattern
    return

;******************************************************************************
; Pattern 2: Running Light Right to Left
;******************************************************************************
pattern_running_right:
    movlw   0x80                    ; Start with rightmost LED
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x40
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x20
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x10
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x08
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x04
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x02
    movwf   PORTB
    call    delay_200ms
    
    movlw   0x01                    ; Leftmost LED
    movwf   PORTB
    call    delay_200ms
    
    incf    pattern_counter, f      ; Next pattern
    return

;******************************************************************************
; Pattern 3: Alternating Pattern
;******************************************************************************
pattern_alternating:
    movlw   0xAA                    ; Binary: 10101010
    movwf   PORTB
    call    delay_300ms
    
    movlw   0x55                    ; Binary: 01010101
    movwf   PORTB
    call    delay_300ms
    
    clrf    pattern_counter         ; Reset to pattern 0
    return

;******************************************************************************
; Initialize I/O Ports
;******************************************************************************
init_ports:
    ; Set up PORTB as output for LEDs
    bsf     STATUS, RP0             ; Switch to Bank 1
    clrf    TRISB                   ; Make PORTB all outputs
    clrf    TRISD                   ; Make PORTD all outputs (spare)
    bcf     STATUS, RP0             ; Switch back to Bank 0
    
    ; Clear all outputs
    clrf    PORTB                   ; Turn off all LEDs
    clrf    PORTD                   ; Clear PORTD
    
    return

;******************************************************************************
; Delay Routines
;******************************************************************************

; Delay approximately 500ms at 20MHz
delay_500ms:
    movlw   0x05                    ; Outer loop count
    movwf   delay_count1
delay_500_outer:
    call    delay_100ms             ; Call 100ms delay 5 times
    decfsz  delay_count1, f
    goto    delay_500_outer
    return

; Delay approximately 300ms at 20MHz  
delay_300ms:
    movlw   0x03                    ; Outer loop count
    movwf   delay_count1
delay_300_outer:
    call    delay_100ms             ; Call 100ms delay 3 times
    decfsz  delay_count1, f
    goto    delay_300_outer
    return

; Delay approximately 200ms at 20MHz
delay_200ms:
    movlw   0x02                    ; Outer loop count
    movwf   delay_count1
delay_200_outer:
    call    delay_100ms             ; Call 100ms delay 2 times
    decfsz  delay_count1, f
    goto    delay_200_outer
    return

; Delay approximately 100ms at 20MHz
delay_100ms:
    movlw   0xC8                    ; 200 decimal
    movwf   delay_count2
delay_100_outer:
    movlw   0xFA                    ; 250 decimal  
    movwf   delay_count3
delay_100_inner:
    nop                             ; 1 cycle
    nop                             ; 1 cycle
    decfsz  delay_count3, f         ; 1 cycle (2 if skip)
    goto    delay_100_inner         ; 2 cycles
    decfsz  delay_count2, f
    goto    delay_100_outer
    return  

;******************************************************************************
; End of Program
;******************************************************************************
    end