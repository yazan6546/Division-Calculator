
bcd_to_binary CODE

; ============================================================================
; VARIABLE DEFINITIONS
; ============================================================================
    cblock 0x60
        ; Function parameters (REQUIRED by bcd_to_binary.inc)
        BCD_INPUT_BASE_ADDR     ; Base address of 48-bit BCD input
        BCD_OUTPUT_BASE_ADDR    ; Base address of 40-bit binary output
        
        ; Working variables (REQUIRED by bcd_to_binary.inc)
        BIT_COUNT               ; Counter for 40 bits
        TEMP_REG                ; Temporary register
        CURRENT_ADDR            ; Current address pointer
        BYTE_COUNT              ; Byte counter for loops
        FSR_BACKUP              ; Backup for FSR register
        
        ; Working copy of BCD data (REQUIRED by bcd_to_binary.inc)
        WORK_BCD_0              ; Working copy of BCD data
        WORK_BCD_1
        WORK_BCD_2
        WORK_BCD_3
        WORK_BCD_4
        WORK_BCD_5

        
        ; WORK_BIN = Working area AND final output! (REQUIRED by bcd_to_binary.inc)
        WORK_BIN_0              ; Binary result (LSB)
        WORK_BIN_1              ; Binary result
        WORK_BIN_2              ; Binary result
        WORK_BIN_3              ; Binary result
        WORK_BIN_4              ; Binary result (MSB)
    endc

; ============================================================================
; BCD TO BINARY CONVERSION LIBRARY
; File: bcd_to_binary.inc
; Author: ahmadqaimari
; Date: 2025-06-28
; Purpose: Convert 48-bit BCD to 40-bit binary using reverse double dabble algorithm
; ============================================================================

; ============================================================================
; FUNCTION: BCD_TO_BIN_FUNCTION
; PURPOSE: Convert BCD to Binary, result stays in WORK_BIN variables
; INPUT: BCD_INPUT_BASE_ADDR points to 6-byte BCD input, BCD_OUTPUT_BASE_ADDR points to 5-byte binary output
; OUTPUT: WORK_BIN_0 to WORK_BIN_4 contains 40-bit binary result
; PRESERVES: Original BCD input data (untouched)
; REQUIREMENTS:
;   - Variable BCD_INPUT_BASE_ADDR must be defined
;   - Working variables BIT_COUNT, CURRENT_ADDR, BYTE_COUNT, FSR_BACKUP must be defined
;   - Working BCD area WORK_BCD_0 through WORK_BCD_5 must be defined
;   - Working binary area WORK_BIN_0 through WORK_BIN_4 must be defined
; ============================================================================
BCD_TO_BIN_FUNCTION:
    ; Save FSR register
    movf FSR, W
    movwf FSR_BACKUP
    
    ; Copy BCD input to working area (preserves original)
    call COPY_BCD_TO_WORK
    
    ; Clear binary working area (this will become the final result)
    clrf WORK_BIN_0
    clrf WORK_BIN_1
    clrf WORK_BIN_2
    clrf WORK_BIN_3
    clrf WORK_BIN_4
    
    ; Initialize bit counter for 40 bits
    movlw .40
    movwf BIT_COUNT
    
REVERSE_CONVERT_LOOP:
    ; Shift right the entire 88-bit number (48 BCD + 40 binary)
    call SHIFT_RIGHT_88BIT_FUNC
    
    ; Subtract 3 from any BCD digit that became >= 8 after shift
    call SUB_3_IF_GE_8_FUNC
    
    ; Decrement bit counter
    decfsz BIT_COUNT, F
    goto REVERSE_CONVERT_LOOP
    
    ; No copying needed! Result is already in WORK_BIN_0-4
    
    ; Restore FSR register
    movf FSR_BACKUP, W
    movwf FSR

    call COPY_TO_OUTPUT_BASE_ADDRESS ; Copy result to output base address
    return

; ============================================================================
; FUNCTION: COPY_TO_OUTPUT_BASE_ADDRESS
; PURPOSE: Copy working binary result to output base address
; INPUT: BCD_OUTPUT_BASE_ADDR points to 5-byte binary output
; OUTPUT: WORK_BIN_0 to WORK_BIN_4 copied to BCD_OUTPUT_BASE_ADDR
; PRESERVES: Original working binary data (untouched)
; REQUIREMENTS:
;   - Variable BCD_OUTPUT_BASE_ADDR must be defined
;   - Working binary area WORK_BIN_0 through WORK_BIN_4 must be defined
; ============================================================================
; Note: This function is called in BCD_TO_BIN_FUNCTION to save the result

COPY_TO_OUTPUT_BASE_ADDRESS:
    ; Copy working binary result to output base address
    movf BCD_OUTPUT_BASE_ADDR, W
    movwf FSR
    movf WORK_BIN_0, W
    movwf INDF
    incf FSR, F
    movf WORK_BIN_1, W
    movwf INDF
    incf FSR, F
    movf WORK_BIN_2, W
    movwf INDF
    incf FSR, F
    movf WORK_BIN_3, W
    movwf INDF
    incf FSR, F
    movf WORK_BIN_4, W
    movwf INDF

    RETURN
; ============================================================================
; SUBROUTINE: COPY_BCD_TO_WORK
; PURPOSE: Copy BCD input to working registers (preserves original)
; ============================================================================
COPY_BCD_TO_WORK:
    ; Copy BCD input to working area
    movf BCD_INPUT_BASE_ADDR, W
    movwf FSR
    movf INDF, W
    movwf WORK_BCD_0
    incf FSR, F
    movf INDF, W
    movwf WORK_BCD_1
    incf FSR, F
    movf INDF, W
    movwf WORK_BCD_2
    incf FSR, F
    movf INDF, W
    movwf WORK_BCD_3
    incf FSR, F
    movf INDF, W
    movwf WORK_BCD_4
    incf FSR, F
    movf INDF, W
    movwf WORK_BCD_5
    return

; ============================================================================
; SUBROUTINE: SHIFT_RIGHT_88BIT_FUNC
; PURPOSE: Shift right the entire 88-bit number (48 BCD + 40 binary)
; NOTE: WORK_BIN serves as both working area AND final result location
; ============================================================================
SHIFT_RIGHT_88BIT_FUNC:
    bcf STATUS, C           ; Clear carry
    
    ; Shift BCD part right (6 bytes) - start from MSB
    rrf WORK_BCD_5, F       ; BCD Byte 5 (MSB)
    rrf WORK_BCD_4, F       ; BCD Byte 4
    rrf WORK_BCD_3, F       ; BCD Byte 3
    rrf WORK_BCD_2, F       ; BCD Byte 2
    rrf WORK_BCD_1, F       ; BCD Byte 1
    rrf WORK_BCD_0, F       ; BCD Byte 0 (LSB)
    
    ; Continue shift into binary part (5 bytes)
    ; This is where the final result accumulates!
    rrf WORK_BIN_4, F       ; Binary Byte 4 (MSB)
    rrf WORK_BIN_3, F       ; Binary Byte 3
    rrf WORK_BIN_2, F       ; Binary Byte 2
    rrf WORK_BIN_1, F       ; Binary Byte 1
    rrf WORK_BIN_0, F       ; Binary Byte 0 (LSB)
    
    return

; ============================================================================
; SUBROUTINE: SUB_3_IF_GE_8_FUNC
; PURPOSE: Subtract 3 from any BCD digit that is >= 8
; ============================================================================
SUB_3_IF_GE_8_FUNC:
    ; Check WORK_BCD_0
    call CHECK_AND_SUB_BYTE_0
    ; Check WORK_BCD_1
    call CHECK_AND_SUB_BYTE_1
    ; Check WORK_BCD_2
    call CHECK_AND_SUB_BYTE_2
    ; Check WORK_BCD_3
    call CHECK_AND_SUB_BYTE_3
    ; Check WORK_BCD_4
    call CHECK_AND_SUB_BYTE_4
    ; Check WORK_BCD_5
    call CHECK_AND_SUB_BYTE_5
    
    return

CHECK_AND_SUB_BYTE_0:
    ; Check lower nibble of WORK_BCD_0
    movf WORK_BCD_0, W
    andlw 0x0F
    sublw .7                ; Subtract from 7
    btfsc STATUS, C         ; Skip if no carry (digit >= 8)
    goto CHECK_UPPER_0
    movlw 0x03
    subwf WORK_BCD_0, F     ; Subtract 3 from lower nibble
    
CHECK_UPPER_0:
    ; Check upper nibble of WORK_BCD_0
    swapf WORK_BCD_0, W
    andlw 0x0F
    sublw .7                ; Subtract from 7
    btfsc STATUS, C         ; Skip if no carry (digit >= 8)
    return
    movlw 0x30              ; 3 in upper nibble position
    subwf WORK_BCD_0, F     ; Subtract 3 from upper nibble
    return

CHECK_AND_SUB_BYTE_1:
    movf WORK_BCD_1, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    goto CHECK_UPPER_1
    movlw 0x03
    subwf WORK_BCD_1, F
    
CHECK_UPPER_1:
    swapf WORK_BCD_1, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    return
    movlw 0x30
    subwf WORK_BCD_1, F
    return

CHECK_AND_SUB_BYTE_2:
    movf WORK_BCD_2, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    goto CHECK_UPPER_2
    movlw 0x03
    subwf WORK_BCD_2, F
    
CHECK_UPPER_2:
    swapf WORK_BCD_2, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    return
    movlw 0x30
    subwf WORK_BCD_2, F
    return

CHECK_AND_SUB_BYTE_3:
    movf WORK_BCD_3, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    goto CHECK_UPPER_3
    movlw 0x03
    subwf WORK_BCD_3, F
    
CHECK_UPPER_3:
    swapf WORK_BCD_3, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    return
    movlw 0x30
    subwf WORK_BCD_3, F
    return

CHECK_AND_SUB_BYTE_4:
    movf WORK_BCD_4, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    goto CHECK_UPPER_4
    movlw 0x03
    subwf WORK_BCD_4, F
    
CHECK_UPPER_4:
    swapf WORK_BCD_4, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    return
    movlw 0x30
    subwf WORK_BCD_4, F
    return

CHECK_AND_SUB_BYTE_5:
    movf WORK_BCD_5, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    goto CHECK_UPPER_5
    movlw 0x03
    subwf WORK_BCD_5, F
    
CHECK_UPPER_5:
    swapf WORK_BCD_5, W
    andlw 0x0F
    sublw .7
    btfsc STATUS, C
    return
    movlw 0x30
    subwf WORK_BCD_5, F
    return

; End of bcd_to_binary.inc