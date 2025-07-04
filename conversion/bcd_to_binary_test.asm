; ============================================================================
; BCD TO BINARY CONVERSION TEST
; File: test_bcd_to_binary.asm
; Author: ahmadqaimari
; Date: 2025-06-28
; Purpose: Test the bcd_to_binary.inc library with various test cases
; Note: Updated to test BIG-ENDIAN input format (MSB first)
; ============================================================================

    list p=16f877a
    #include <p16f877a.inc>
    #include "bcd_to_binary.inc"

    __CONFIG _CP_OFF & _WDT_OFF & _BODEN_OFF & _PWRTE_ON & _HS_OSC & _WRT_OFF & _LVP_OFF & _CPD_OFF


; ============================================================================
; TEST DATA AREAS
; ============================================================================
    cblock 0x40
        ; Test Case 1: BCD 123456789 (BIG-ENDIAN: 00 01 23 45 67 89)
        TEST1_BCD_INPUT
        TEST1_BCD_INPUT_1
        TEST1_BCD_INPUT_2
        TEST1_BCD_INPUT_3
        TEST1_BCD_INPUT_4
        TEST1_BCD_INPUT_5
    endc
    
    cblock 0x50
        ; Test Case 2: BCD 999999999 (BIG-ENDIAN: 00 00 99 99 99 99)
        TEST2_BCD_INPUT
        TEST2_BCD_INPUT_1
        TEST2_BCD_INPUT_2
        TEST2_BCD_INPUT_3
        TEST2_BCD_INPUT_4
        TEST2_BCD_INPUT_5
    endc
    
    cblock 0x60
        ; Test Case 3: BCD 000000001 (BIG-ENDIAN: 00 00 00 00 00 01)
        TEST3_BCD_INPUT
        TEST3_BCD_INPUT_1
        TEST3_BCD_INPUT_2
        TEST3_BCD_INPUT_3
        TEST3_BCD_INPUT_4
        TEST3_BCD_INPUT_5
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
    ; Initialize system
    call INIT_SYSTEM
    
    ; Run all test cases
    call TEST_CASE_1
    call TEST_CASE_2
    call TEST_CASE_3
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
    
    ; Clear working areas
    clrf WORK_BCD_0
    clrf WORK_BCD_1
    clrf WORK_BCD_2
    clrf WORK_BCD_3
    clrf WORK_BCD_4
    clrf WORK_BCD_5
    
    clrf WORK_BIN_0
    clrf WORK_BIN_1
    clrf WORK_BIN_2
    clrf WORK_BIN_3
    clrf WORK_BIN_4
    
    return

; ============================================================================
; TEST CASE 1: Convert BCD 123456789 (00 01 23 45 67 89) - BIG-ENDIAN INPUT
; Expected Binary: 0x075BCD15 = 15 CD 5B 07 00 (LSB to MSB in WORK_BIN)
; ============================================================================
TEST_CASE_1:
    ; Load BCD test data for 123456789 in BIG-ENDIAN format
    ; Input: MSB at addr+0, LSB at addr+5
    movlw 0x00              ; Leading zeros (MSB)
    movwf TEST1_BCD_INPUT
    movlw 0x01              ; Digits 0,1
    movwf TEST1_BCD_INPUT_1
    movlw 0x23              ; Digits 2,3
    movwf TEST1_BCD_INPUT_2
    movlw 0x45              ; Digits 4,5
    movwf TEST1_BCD_INPUT_3
    movlw 0x67              ; Digits 6,7
    movwf TEST1_BCD_INPUT_4
    movlw 0x89              ; Digits 8,9 (LSB)
    movwf TEST1_BCD_INPUT_5
    
    ; Set function parameter
    movlw TEST1_BCD_INPUT
    movwf BCD_INPUT_BASE_ADDR
    
    ; Call BCD to Binary conversion
    call BCD_TO_BIN_FUNCTION
    
    ; Result is now in WORK_BIN_0 through WORK_BIN_4!
    ; Expected: WORK_BIN_0=15, WORK_BIN_1=CD, WORK_BIN_2=5B, WORK_BIN_3=07, WORK_BIN_4=00
    ; Original BCD input at TEST1_BCD_INPUT is preserved!
    
    return

; ============================================================================
; TEST CASE 2: Convert BCD 999999999 (99 99 99 99 00 00) - BIG-ENDIAN INPUT
; Expected Binary: 0x3B9AC9FF = FF C9 9A 3B 00 (LSB to MSB in WORK_BIN)
; ============================================================================
TEST_CASE_2:
    ; Load BCD test data for 999999999 in BIG-ENDIAN format
    ; Input: MSB at addr+0, LSB at addr+5
    movlw 0x00              ; Leading zeros (MSB)
    movwf TEST2_BCD_INPUT
    movlw 0x00              ; Digits 0,1
    movwf TEST2_BCD_INPUT_1
    movlw 0x99              ; Digits 2,3
    movwf TEST2_BCD_INPUT_2
    movlw 0x99              ; Digits 4,5
    movwf TEST2_BCD_INPUT_3
    movlw 0x99              ; Digits 6,7
    movwf TEST2_BCD_INPUT_4
    movlw 0x99              ; Digits 8,9 (LSB)
    movwf TEST2_BCD_INPUT_5
    
    ; Set function parameter
    movlw TEST2_BCD_INPUT
    movwf BCD_INPUT_BASE_ADDR
    
    ; Call BCD to Binary conversion
    call BCD_TO_BIN_FUNCTION
    
    ; Result is now in WORK_BIN_0 through WORK_BIN_4!
    ; Expected: WORK_BIN_0=FF, WORK_BIN_1=C9, WORK_BIN_2=9A, WORK_BIN_3=3B, WORK_BIN_4=00
    ; Original BCD input at TEST2_BCD_INPUT is preserved!
    
    return

; ============================================================================
; TEST CASE 3: Convert BCD 000000001 (01 00 00 00 00 00) - BIG-ENDIAN INPUT
; Expected Binary: 0x00000001 = 01 00 00 00 00 (LSB to MSB in WORK_BIN)
; ============================================================================
TEST_CASE_3:
    ; Load BCD test data for 1 in BIG-ENDIAN format
    ; Input: MSB at addr+0, LSB at addr+5
    movlw 0x00              ; Leading zeros (MSB)
    movwf TEST3_BCD_INPUT
    movlw 0x00              ; All other digits zero
    movwf TEST3_BCD_INPUT_1
    movlw 0x00
    movwf TEST3_BCD_INPUT_2
    movlw 0x00
    movwf TEST3_BCD_INPUT_3
    movlw 0x00
    movwf TEST3_BCD_INPUT_4
    movlw 0x01              ; Digit 1 (LSB)
    movwf TEST3_BCD_INPUT_5
    
    ; Set function parameter
    movlw TEST3_BCD_INPUT
    movwf BCD_INPUT_BASE_ADDR
    
    ; Call BCD to Binary conversion
    call BCD_TO_BIN_FUNCTION
    
    ; Result is now in WORK_BIN_0 through WORK_BIN_4!
    ; Expected: WORK_BIN_0=01, WORK_BIN_1=00, WORK_BIN_2=00, WORK_BIN_3=00, WORK_BIN_4=00
    ; Original BCD input at TEST3_BCD_INPUT is preserved!
    
    return

; ============================================================================
; INCLUDE THE BCD TO BINARY CONVERSION LIBRARY
; ============================================================================

    end