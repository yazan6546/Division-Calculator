; ============================================================================
; BINARY TO BCD CONVERSION TEST
; File: test_binary_to_bcd.asm
; Author: ahmadqaimari
; Date: 2025-06-28
; Purpose: Test the binary_to_bcd.inc library with various test cases
; ============================================================================

    list p=16f877a
    #include <p16f877a.inc>
    
    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_OFF & _LVP_OFF & _CPD_OFF

; ============================================================================
; VARIABLE DEFINITIONS
; ============================================================================
    cblock 0x20
        ; Function parameters (REQUIRED by binary_to_bcd.inc)
        INPUT_BASE_ADDR     ; Base address of 40-bit binary input
        OUTPUT_BASE_ADDR    ; Base address of 48-bit BCD output
        
        ; Working variables (REQUIRED by binary_to_bcd.inc)
        BIT_COUNT           ; Counter for 40 bits
        TEMP_REG            ; Temporary register
        CURRENT_ADDR        ; Current address pointer
        BYTE_COUNT          ; Byte counter for loops
        FSR_BACKUP          ; Backup for FSR register
    endc
    
    cblock 0x70
        ; Working copies (REQUIRED by binary_to_bcd.inc)
        WORK_BIN_0          ; Working copy of binary input (gets consumed)
        WORK_BIN_1
        WORK_BIN_2
        WORK_BIN_3
        WORK_BIN_4
    endc

; ============================================================================
; TEST DATA AREAS
; ============================================================================
    cblock 0x30
        ; Test Case 1: 123456789 (0x075BCD15)
        TEST1_INPUT
        TEST1_INPUT_1
        TEST1_INPUT_2
        TEST1_INPUT_3
        TEST1_INPUT_4
    endc
    
    cblock 0x40
        ; Test Case 1 Output
        TEST1_OUTPUT
        TEST1_OUTPUT_1
        TEST1_OUTPUT_2
        TEST1_OUTPUT_3
        TEST1_OUTPUT_4
        TEST1_OUTPUT_5
    endc
    
    cblock 0x50
        ; Test Case 2: 999999999 (0x3B9AC9FF)
        TEST2_INPUT
        TEST2_INPUT_1
        TEST2_INPUT_2
        TEST2_INPUT_3
        TEST2_INPUT_4
    endc
    
    cblock 0x60
        ; Test Case 2 Output
        TEST2_OUTPUT
        TEST2_OUTPUT_1
        TEST2_OUTPUT_2
        TEST2_OUTPUT_3
        TEST2_OUTPUT_4
        TEST2_OUTPUT_5
    endc

; ============================================================================
; PROGRAM START
; ============================================================================
    org 0x00
    goto MAIN

    org 0x04
    ; Interrupt vector (not used in this example)
    retfie

; ============================================================================
; MAIN PROGRAM
; ============================================================================
MAIN:
    ; Initialize ports
    call INIT_SYSTEM
    
    ; Run all test cases
    call TEST_CASE_1
    call TEST_CASE_2
    ; Add more test cases as needed
    
LOOP:
    goto LOOP

; ============================================================================
; SYSTEM INITIALIZATION
; ============================================================================
INIT_SYSTEM:
    ; Clear all ports
    clrf PORTA
    clrf PORTB
    clrf PORTC
    clrf PORTD
    clrf PORTE
    
    ; Clear working copies
    clrf WORK_BIN_0
    clrf WORK_BIN_1
    clrf WORK_BIN_2
    clrf WORK_BIN_3
    clrf WORK_BIN_4
    
    return

; ============================================================================
; TEST CASE 1: Convert 123456789 (0x075BCD15)
; Expected BCD: 00 01 23 45 67 89 (big-endian format)
; ============================================================================
TEST_CASE_1:
    ; Load test data: 123456789 = 0x075BCD15
    movlw 0x15              ; LSB
    movwf TEST1_INPUT
    movlw 0xCD
    movwf TEST1_INPUT_1
    movlw 0x5B
    movwf TEST1_INPUT_2
    movlw 0x07
    movwf TEST1_INPUT_3
    movlw 0x00              ; MSB
    movwf TEST1_INPUT_4
    
    ; Clear output area
    clrf TEST1_OUTPUT
    clrf TEST1_OUTPUT_1
    clrf TEST1_OUTPUT_2
    clrf TEST1_OUTPUT_3
    clrf TEST1_OUTPUT_4
    clrf TEST1_OUTPUT_5
    
    ; Set function parameters
    movlw TEST1_INPUT
    movwf INPUT_BASE_ADDR
    movlw TEST1_OUTPUT
    movwf OUTPUT_BASE_ADDR
    
    ; Call conversion function
    call BIN_TO_BCD_FUNCTION
    
    ; Test can be verified by checking TEST1_OUTPUT area
    ; Should contain: 00 01 23 45 67 89 (big-endian format)
    
    return

; ============================================================================
; TEST CASE 2: Convert 999999999 (0x3B9AC9FF)
; Expected BCD: 00 00 99 99 99 99 (big-endian format)
; ============================================================================
TEST_CASE_2:
    ; Load test data: 999999999 = 0x3B9AC9FF
    movlw 0xFF              ; LSB
    movwf TEST2_INPUT
    movlw 0xC9
    movwf TEST2_INPUT_1
    movlw 0x9A
    movwf TEST2_INPUT_2
    movlw 0x3B
    movwf TEST2_INPUT_3
    movlw 0x00              ; MSB
    movwf TEST2_INPUT_4
    
    ; Clear output area
    clrf TEST2_OUTPUT
    clrf TEST2_OUTPUT_1
    clrf TEST2_OUTPUT_2
    clrf TEST2_OUTPUT_3
    clrf TEST2_OUTPUT_4
    clrf TEST2_OUTPUT_5
    
    ; Set function parameters
    movlw TEST2_INPUT
    movwf INPUT_BASE_ADDR
    movlw TEST2_OUTPUT
    movwf OUTPUT_BASE_ADDR
    
    ; Call conversion function
    call BIN_TO_BCD_FUNCTION
    
    ; Test can be verified by checking TEST2_OUTPUT area
    ; Should contain: 00 00 99 99 99 99 (big-endian format)
    
    return

; ============================================================================
; INCLUDE THE BINARY TO BCD CONVERSION LIBRARY
; ============================================================================
#include "binary_to_bcd.inc"

    end