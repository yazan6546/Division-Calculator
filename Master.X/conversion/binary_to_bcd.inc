; ============================================================================
; BINARY TO BCD CONVERSION LIBRARY
; File: binary_to_bcd.inc
; Author: ahmadqaimari
; Date: 2025-06-28
; Purpose: Convert 40-bit binary to 48-bit BCD using double dabble algorithm
; Note: Updated to accept BIG-ENDIAN binary input (MSB at base_addr+0, LSB at base_addr+4)
; ============================================================================

; ============================================================================
; FUNCTION: BIN_TO_BCD_FUNCTION
; PURPOSE: Convert 40-bit binary to 48-bit BCD using double dabble
; INPUTS: 
;   INPUT_BASE_ADDR  - Base address of 5-byte binary input (BIG-ENDIAN: MSB at addr+0, LSB at addr+4)
;   OUTPUT_BASE_ADDR - Base address of 6-byte BCD output (LSB first)
; OUTPUTS:
;   BCD result stored at OUTPUT_BASE_ADDR location
; PRESERVES:
;   - Original binary input data (untouched)
;   - All registers except W and STATUS
; WORKING:
;   - Uses WORK_BIN as sacrificial working copy
; REQUIREMENTS:
;   - Variables INPUT_BASE_ADDR, OUTPUT_BASE_ADDR must be defined
;   - Working variables BIT_COUNT, CURRENT_ADDR, BYTE_COUNT, FSR_BACKUP must be defined
;   - Working area WORK_BIN_0 through WORK_BIN_4 must be defined
; ============================================================================
BIN_TO_BCD_FUNCTION:
    ; Save FSR register
    movf FSR, W
    movwf FSR_BACKUP
    
    ; Copy input data to working area to preserve original
    call COPY_INPUT_TO_WORK
    
    ; Clear BCD output area (6 bytes) at parameter-specified address
    call CLEAR_BCD_OUTPUT
    
    ; Initialize bit counter
    movlw .40
    movwf BIT_COUNT
    
CONVERT_LOOP:
    ; Check BCD digits and add 3 if >= 5
    call ADD_3_IF_GE_5_FUNC
    
    ; Shift left the entire 88-bit number (40 binary + 48 BCD)
    ; Working with WORK_BIN copies + parameter-specified BCD output
    call SHIFT_LEFT_88BIT_FUNC
    
    decfsz BIT_COUNT, F
    goto CONVERT_LOOP
    
    ; Restore FSR register
    movf FSR_BACKUP, W
    movwf FSR
    
    return

; ============================================================================
; SUBROUTINE: COPY_INPUT_TO_WORK
; PURPOSE: Copy input data to working area to preserve original
; ============================================================================
COPY_INPUT_TO_WORK:
    ; Copy input data to working area to preserve original (BIG-ENDIAN INPUT)
    ; Input format: MSB at base_addr+0, LSB at base_addr+4
    ; Working format: LSB at WORK_BIN_0, MSB at WORK_BIN_4
    movf INPUT_BASE_ADDR, W
    movwf FSR
    movf INDF, W            ; Get MSB from input[0]
    movwf WORK_BIN_4        ; Store as MSB in working area
    incf FSR, F
    movf INDF, W            ; Get input[1]
    movwf WORK_BIN_3        ; Store as working[3]
    incf FSR, F
    movf INDF, W            ; Get input[2]
    movwf WORK_BIN_2        ; Store as working[2]
    incf FSR, F
    movf INDF, W            ; Get input[3]
    movwf WORK_BIN_1        ; Store as working[1]
    incf FSR, F
    movf INDF, W            ; Get LSB from input[4]
    movwf WORK_BIN_0        ; Store as LSB in working area
    return

; ============================================================================
; SUBROUTINE: CLEAR_BCD_OUTPUT
; PURPOSE: Clear BCD output area at parameter-specified address
; ============================================================================
CLEAR_BCD_OUTPUT:
    movf OUTPUT_BASE_ADDR, W
    movwf FSR
    clrf INDF               ; Clear byte 0
    incf FSR, F
    clrf INDF               ; Clear byte 1
    incf FSR, F
    clrf INDF               ; Clear byte 2
    incf FSR, F
    clrf INDF               ; Clear byte 3
    incf FSR, F
    clrf INDF               ; Clear byte 4
    incf FSR, F
    clrf INDF               ; Clear byte 5
    return

; ============================================================================
; SUBROUTINE: ADD_3_IF_GE_5_FUNC
; PURPOSE: Add 3 to BCD digits >= 5 in parameter-specified output area
; ============================================================================
ADD_3_IF_GE_5_FUNC:
    movf OUTPUT_BASE_ADDR, W
    movwf CURRENT_ADDR
    movlw .6
    movwf BYTE_COUNT
    
CHECK_NEXT_BCD_BYTE:
    movf CURRENT_ADDR, W
    movwf FSR
    
    ; Check lower nibble
    movf INDF, W
    andlw 0x0F              ; Mask lower nibble
    sublw .4                ; Subtract from 4
    btfss STATUS, C         ; Skip if carry set (digit <= 4)
    goto ADD3_LOWER_NIBBLE
    
CHECK_UPPER_NIBBLE:
    ; Check upper nibble
    movf INDF, W
    swapf INDF, W           ; Swap nibbles
    andlw 0x0F              ; Mask lower nibble (was upper)
    sublw .4                ; Subtract from 4
    btfss STATUS, C         ; Skip if carry set (digit <= 4)
    goto ADD3_UPPER_NIBBLE
    goto NEXT_BCD_BYTE
    
ADD3_LOWER_NIBBLE:
    movlw 0x03
    addwf INDF, F           
    goto CHECK_UPPER_NIBBLE
    
ADD3_UPPER_NIBBLE:
    movlw 0x30              
    addwf INDF, F           
    
NEXT_BCD_BYTE:
    incf CURRENT_ADDR, F    
    decfsz BYTE_COUNT, F    
    goto CHECK_NEXT_BCD_BYTE
    
    return

; ============================================================================
; SUBROUTINE: SHIFT_LEFT_88BIT_FUNC
; PURPOSE: Shift left 88-bit number (40 binary working + 48 BCD output)
; ============================================================================
SHIFT_LEFT_88BIT_FUNC:
    bcf STATUS, C           
    
    ; Shift WORKING COPY of binary part (5 bytes) - start from LSB
    ; This preserves the original input data!
    rlf WORK_BIN_0, F       ; Byte 0 (LSB) - working copy
    rlf WORK_BIN_1, F       ; Byte 1 - working copy
    rlf WORK_BIN_2, F       ; Byte 2 - working copy
    rlf WORK_BIN_3, F       ; Byte 3 - working copy
    rlf WORK_BIN_4, F       ; Byte 4 (MSB) - working copy
    
    ; Continue shift into BCD output area (parameter-specified address)
    movf OUTPUT_BASE_ADDR, W
    movwf FSR
    rlf INDF, F             ; BCD Byte 0 (LSB)
    incf FSR, F
    rlf INDF, F             ; BCD Byte 1
    incf FSR, F
    rlf INDF, F             ; BCD Byte 2
    incf FSR, F
    rlf INDF, F             ; BCD Byte 3
    incf FSR, F
    rlf INDF, F             ; BCD Byte 4
    incf FSR, F
    rlf INDF, F             ; BCD Byte 5 (MSB)
    
    return

; End of binary_to_bcd.inc