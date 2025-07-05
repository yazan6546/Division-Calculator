binary_to_bcd CODE

; ============================================================================
; VARIABLE DEFINITIONS
; ============================================================================
    cblock 0x40
        ; Function parameters (REQUIRED by binary_to_bcd.inc)
        B2BCD_INPUT_BASE_ADDR     ; Base address of 40-bit binary input
        B2BCD_OUTPUT_BASE_ADDR    ; Base address of 48-bit BCD output
        
        ; Working variables (REQUIRED by binary_to_bcd.inc)
        B2BCD_BIT_COUNT           ; Counter for 40 bits
        B2BCD_TEMP_REG            ; Temporary register
        B2BCD_CURRENT_ADDR        ; Current address pointer
        B2BCD_BYTE_COUNT          ; Byte counter for loops
        B2BCD_FSR_BACKUP          ; Backup for FSR register
        
        ; Working copy of binary data (REQUIRED by binary_to_bcd.inc)
        B2BCD_WORK_BIN_0          ; Working copy of binary input (LSB)
        B2BCD_WORK_BIN_1          ; Working copy of binary input
        B2BCD_WORK_BIN_2          ; Working copy of binary input
        B2BCD_WORK_BIN_3          ; Working copy of binary input
        B2BCD_WORK_BIN_4          ; Working copy of binary input (MSB)
        
        ; WORK_BCD = Working area AND final output! (REQUIRED by binary_to_bcd.inc)
        B2BCD_WORK_BCD_0          ; BCD result (LSB)
        B2BCD_WORK_BCD_1          ; BCD result
        B2BCD_WORK_BCD_2          ; BCD result
        B2BCD_WORK_BCD_3          ; BCD result
        B2BCD_WORK_BCD_4          ; BCD result
        B2BCD_WORK_BCD_5          ; BCD result (MSB)
    endc

; ============================================================================
; BINARY TO BCD CONVERSION LIBRARY
; File: binary_to_bcd.inc
; Author: ahmadqaimari
; Date: 2025-06-28
; Purpose: Convert 40-bit binary to 48-bit BCD using double dabble algorithm
; Output: Big-endian BCD format (MSB at base address + 0, LSB at base address + 5)
; ============================================================================

; ============================================================================
; FUNCTION: BIN_TO_BCD_FUNCTION
; PURPOSE: Convert 40-bit binary to 48-bit BCD using double dabble
; INPUTS: 
;   B2BCD_INPUT_BASE_ADDR  - Base address of 5-byte binary input (LSB first)
;   B2BCD_OUTPUT_BASE_ADDR - Base address of 6-byte BCD output (BIG-ENDIAN: MSB first)
; OUTPUTS:
;   BCD result stored at B2BCD_OUTPUT_BASE_ADDR location in big-endian format
;   (MSB at B2BCD_OUTPUT_BASE_ADDR+0, LSB at B2BCD_OUTPUT_BASE_ADDR+5)
;   Working result also available in B2BCD_WORK_BCD_0 to B2BCD_WORK_BCD_5 (LSB to MSB)
; PRESERVES:
;   - Original binary input data (untouched)
;   - All registers except W and STATUS
; WORKING:
;   - Uses B2BCD_WORK_BIN as sacrificial working copy of input
;   - Uses B2BCD_WORK_BCD as working area for BCD result
; REQUIREMENTS:
;   - Variables B2BCD_INPUT_BASE_ADDR, B2BCD_OUTPUT_BASE_ADDR must be defined
;   - Working variables B2BCD_BIT_COUNT, B2BCD_CURRENT_ADDR, B2BCD_BYTE_COUNT, B2BCD_FSR_BACKUP, B2BCD_TEMP_REG must be defined
;   - Working area B2BCD_WORK_BIN_0 through B2BCD_WORK_BIN_4 must be defined
;   - Working area B2BCD_WORK_BCD_0 through B2BCD_WORK_BCD_5 must be defined
; ============================================================================
BIN_TO_BCD_FUNCTION:
    ; Save FSR register
    movf FSR, W
    movwf B2BCD_FSR_BACKUP
    
    ; Copy input data to working area to preserve original
    call COPY_INPUT_TO_WORK
    
    ; Clear BCD working area (6 bytes)
    call CLEAR_BCD_WORKING
    
    ; Initialize bit counter
    movlw .40
    movwf B2BCD_BIT_COUNT
    
CONVERT_LOOP:
    ; Check BCD digits and add 3 if >= 5
    call ADD_3_IF_GE_5_FUNC
    
    ; Shift left the entire 88-bit number (40 binary + 48 BCD)
    ; Working with B2BCD_WORK_BIN copies + B2BCD_WORK_BCD variables
    call SHIFT_LEFT_88BIT_FUNC
    
    decfsz B2BCD_BIT_COUNT, F
    goto CONVERT_LOOP
    
    ; Copy result from working area to output address (big-endian)
    call COPY_RESULT_TO_OUTPUT
    
    ; Restore FSR register
    movf B2BCD_FSR_BACKUP, W
    movwf FSR
    
    return

; ============================================================================
; SUBROUTINE: COPY_INPUT_TO_WORK
; PURPOSE: Copy input data to working area to preserve original
; ============================================================================
COPY_INPUT_TO_WORK:
    ; Copy 5 bytes from input area to working area
    movf B2BCD_INPUT_BASE_ADDR, W
    movwf FSR
    movf INDF, W            ; Get byte 0
    movwf B2BCD_WORK_BIN_0        ; Save to working copy
    incf FSR, F
    movf INDF, W            ; Get byte 1
    movwf B2BCD_WORK_BIN_1        ; Save to working copy
    incf FSR, F
    movf INDF, W            ; Get byte 2
    movwf B2BCD_WORK_BIN_2        ; Save to working copy
    incf FSR, F
    movf INDF, W            ; Get byte 3
    movwf B2BCD_WORK_BIN_3        ; Save to working copy
    incf FSR, F
    movf INDF, W            ; Get byte 4
    movwf B2BCD_WORK_BIN_4        ; Save to working copy
    return

; ============================================================================
; SUBROUTINE: CLEAR_BCD_WORKING
; PURPOSE: Clear BCD working area variables
; ============================================================================
CLEAR_BCD_WORKING:
    clrf B2BCD_WORK_BCD_0         ; Clear BCD working area (LSB)
    clrf B2BCD_WORK_BCD_1
    clrf B2BCD_WORK_BCD_2
    clrf B2BCD_WORK_BCD_3
    clrf B2BCD_WORK_BCD_4
    clrf B2BCD_WORK_BCD_5         ; Clear BCD working area (MSB)
    return

; ============================================================================
; SUBROUTINE: ADD_3_IF_GE_5_FUNC
; PURPOSE: Add 3 to BCD digits >= 5 in working BCD variables
; ============================================================================
ADD_3_IF_GE_5_FUNC:
    ; Check WORK_BCD_0 (LSB)
    call CHECK_AND_ADD_BYTE_0
    ; Check WORK_BCD_1
    call CHECK_AND_ADD_BYTE_1
    ; Check WORK_BCD_2
    call CHECK_AND_ADD_BYTE_2
    ; Check WORK_BCD_3
    call CHECK_AND_ADD_BYTE_3
    ; Check WORK_BCD_4
    call CHECK_AND_ADD_BYTE_4
    ; Check WORK_BCD_5 (MSB)
    call CHECK_AND_ADD_BYTE_5
    
    return

CHECK_AND_ADD_BYTE_0:
    ; Check lower nibble of B2BCD_WORK_BCD_0
    movf B2BCD_WORK_BCD_0, W
    andlw 0x0F              ; Mask lower nibble
    sublw .4                ; Subtract from 4
    btfss STATUS, C         ; Skip if carry set (digit <= 4)
    goto ADD3_LOWER_0
    
    ; Check upper nibble of B2BCD_WORK_BCD_0
    swapf B2BCD_WORK_BCD_0, W
    andlw 0x0F              ; Mask lower nibble (was upper)
    sublw .4                ; Subtract from 4
    btfss STATUS, C         ; Skip if carry set (digit <= 4)
    goto ADD3_UPPER_0
    return
    
ADD3_LOWER_0:
    movlw 0x03
    addwf B2BCD_WORK_BCD_0, F
    ; Check upper nibble
    swapf B2BCD_WORK_BCD_0, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_0
    return
    
ADD3_UPPER_0:
    movlw 0x30
    addwf B2BCD_WORK_BCD_0, F
    return

CHECK_AND_ADD_BYTE_1:
    movf B2BCD_WORK_BCD_1, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_LOWER_1
    
    swapf B2BCD_WORK_BCD_1, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_1
    return
    
ADD3_LOWER_1:
    movlw 0x03
    addwf B2BCD_WORK_BCD_1, F
    swapf B2BCD_WORK_BCD_1, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_1
    return
    
ADD3_UPPER_1:
    movlw 0x30
    addwf B2BCD_WORK_BCD_1, F
    return

CHECK_AND_ADD_BYTE_2:
    movf B2BCD_WORK_BCD_2, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_LOWER_2
    
    swapf B2BCD_WORK_BCD_2, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_2
    return
    
ADD3_LOWER_2:
    movlw 0x03
    addwf B2BCD_WORK_BCD_2, F
    swapf B2BCD_WORK_BCD_2, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_2
    return
    
ADD3_UPPER_2:
    movlw 0x30
    addwf B2BCD_WORK_BCD_2, F
    return

CHECK_AND_ADD_BYTE_3:
    movf B2BCD_WORK_BCD_3, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_LOWER_3
    
    swapf B2BCD_WORK_BCD_3, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_3
    return
    
ADD3_LOWER_3:
    movlw 0x03
    addwf B2BCD_WORK_BCD_3, F
    swapf B2BCD_WORK_BCD_3, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_3
    return
    
ADD3_UPPER_3:
    movlw 0x30
    addwf B2BCD_WORK_BCD_3, F
    return

CHECK_AND_ADD_BYTE_4:
    movf B2BCD_WORK_BCD_4, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_LOWER_4
    
    swapf B2BCD_WORK_BCD_4, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_4
    return
    
ADD3_LOWER_4:
    movlw 0x03
    addwf B2BCD_WORK_BCD_4, F
    swapf B2BCD_WORK_BCD_4, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_4
    return
    
ADD3_UPPER_4:
    movlw 0x30
    addwf B2BCD_WORK_BCD_4, F
    return

CHECK_AND_ADD_BYTE_5:
    movf B2BCD_WORK_BCD_5, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_LOWER_5
    
    swapf B2BCD_WORK_BCD_5, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_5
    return
    
ADD3_LOWER_5:
    movlw 0x03
    addwf B2BCD_WORK_BCD_5, F
    swapf B2BCD_WORK_BCD_5, W
    andlw 0x0F
    sublw .4
    btfss STATUS, C
    goto ADD3_UPPER_5
    return
    
ADD3_UPPER_5:
    movlw 0x30
    addwf B2BCD_WORK_BCD_5, F
    return

; ============================================================================
; SUBROUTINE: SHIFT_LEFT_88BIT_FUNC
; PURPOSE: Shift left 88-bit number (40 binary working + 48 BCD working)
; ============================================================================
SHIFT_LEFT_88BIT_FUNC:
    bcf STATUS, C           
    
    ; Shift WORKING COPY of binary part (5 bytes) - start from LSB
    ; This preserves the original input data!
    rlf B2BCD_WORK_BIN_0, F       ; Byte 0 (LSB) - working copy
    rlf B2BCD_WORK_BIN_1, F       ; Byte 1 - working copy
    rlf B2BCD_WORK_BIN_2, F       ; Byte 2 - working copy
    rlf B2BCD_WORK_BIN_3, F       ; Byte 3 - working copy
    rlf B2BCD_WORK_BIN_4, F       ; Byte 4 (MSB) - working copy
    
    ; Continue shift into BCD working area (LSB to MSB)
    rlf B2BCD_WORK_BCD_0, F       ; BCD Byte 0 (LSB)
    rlf B2BCD_WORK_BCD_1, F       ; BCD Byte 1
    rlf B2BCD_WORK_BCD_2, F       ; BCD Byte 2
    rlf B2BCD_WORK_BCD_3, F       ; BCD Byte 3
    rlf B2BCD_WORK_BCD_4, F       ; BCD Byte 4
    rlf B2BCD_WORK_BCD_5, F       ; BCD Byte 5 (MSB)
    
    return

; ============================================================================
; SUBROUTINE: COPY_RESULT_TO_OUTPUT
; PURPOSE: Copy BCD result from working variables to output address (big-endian)
; ============================================================================
COPY_RESULT_TO_OUTPUT:
    ; Copy BCD result to output address in big-endian format
    ; B2BCD_WORK_BCD_0 (LSB) -> B2BCD_OUTPUT_BASE_ADDR+5
    ; B2BCD_WORK_BCD_5 (MSB) -> B2BCD_OUTPUT_BASE_ADDR+0
    movf B2BCD_OUTPUT_BASE_ADDR, W
    movwf FSR
    movf B2BCD_WORK_BCD_5, W      ; Get MSB from working area
    movwf INDF              ; Store at B2BCD_OUTPUT_BASE_ADDR+0 (MSB position)
    incf FSR, F
    movf B2BCD_WORK_BCD_4, W
    movwf INDF              ; Store at B2BCD_OUTPUT_BASE_ADDR+1
    incf FSR, F
    movf B2BCD_WORK_BCD_3, W
    movwf INDF              ; Store at B2BCD_OUTPUT_BASE_ADDR+2
    incf FSR, F
    movf B2BCD_WORK_BCD_2, W
    movwf INDF              ; Store at B2BCD_OUTPUT_BASE_ADDR+3
    incf FSR, F
    movf B2BCD_WORK_BCD_1, W
    movwf INDF              ; Store at B2BCD_OUTPUT_BASE_ADDR+4
    incf FSR, F
    movf B2BCD_WORK_BCD_0, W      ; Get LSB from working area
    movwf INDF              ; Store at B2BCD_OUTPUT_BASE_ADDR+5 (LSB position)
    return

; End of binary_to_bcd.inc