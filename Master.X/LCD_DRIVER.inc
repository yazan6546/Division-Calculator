;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Copyright (c) 2013 Manolis Agkopian		  ;
;See the file LICENCE for copying permission.	  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	#include <LCD_PIN_SETTINGS.inc>

; Add code section for MPASM object file generation
LCD_CODE	code
 
	CBLOCK 0x70
		CNTA ;DELAY COUNTER A
		CNTB ;DELAY COUNTER B
		CNTC ;DELAY COUNTER C
		LCDTEMP ;TEMP VAR FOR CHAR / INSRUCTION
		TEMP_TING
	ENDC

;LCD INITIALIZATION (4 BIT MODE)
LCD_INIT:

	BSF  STATUS, RP0 ;SELECT BANK 01
	CLRF LCD_TRIS ;SET LCD_TRIS PINS TO OUTPUT MODE
	BCF  STATUS, RP0 ;SELECT BANK 00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;GIVE 15MS TO LCD TO START WORKING PROPERLY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CALL DEL05 ;DO 5MS DELAY
	CALL DEL05 ;DO 5MS DELAY
	CALL DEL05 ;DO 5MS DELAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SEND RESET INSTRUCTION TO LCD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	MOVLW 0x030
	MOVWF LCD_PORT

	CALL PULSE_E ;PULSE LCD_E
	CALL DEL05 ;DO 5MS DELAY

	CALL PULSE_E ;PULSE LCD_E
	CALL D16US ;DO 160US DELAY

	CALL PULSE_E ;PULSE LCD_E
	CALL D16US ;DO 160US DELAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;INITIALIZE THE LCD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	MOVLW 0x20 ;SPECIFY THE DATA LENGTH
	MOVWF LCD_PORT
	CALL PULSE_E ;PULSE LCD_E
	CALL D16US ;DO 160US DELAY

	MOVLW 0x28 ;SET INTERFACE LENGTH
	CALL LCDINS

	MOVLW 0x10 ;TURN OFF DISPLAY
	CALL LCDINS

	CALL LCD_CLR ;CLEAR DISPLAY RAM

	MOVLW 0x06 ;SET CURSOR MOVEMENT
	CALL LCDINS

	MOVLW 0x0C ;TURN ON DISPLAY / CURSOR
	CALL LCDINS

	movlw 0x0F     ; Display ON, Cursor ON, Blink ON
    call LCDINS   ; Send command to LCD

	CALL LCD_CLR ;CLEAR DISPLAY RAM
	RETURN


;SEND INSTRUCTION TO THE LCD
LCDINS:
	MOVWF LCDTEMP ;SAVE INSTRUCTION VALUE

	ANDLW 0xF0 ;CLEAR LSB OF W REG (THE LSB OF W REG IS THE LSB OF THE INSTRUCTION)
	MOVWF LCD_PORT ;PUT INSTAUCTION'S MSB TO THE DATA BUS
	BCF LCD_PORT, LCD_RS ;SET RS PIN LOW TO SELECT INSTRUCTION REGISTER
	CALL PULSE_E ;PULSE LCD_EF

	SWAPF LCDTEMP, W ;SWAP LSB AND MSB

	ANDLW 0xF0 ;CLEAR LSB OF W REG (THE LSB OF W REG IS THE MSB OF THE INSTRUCTION)
	MOVWF LCD_PORT ;PUT INSTAUCTION'S LSB TO THE DATA BUS
	BCF LCD_PORT, LCD_RS ;SET RS PIN LOW TO SELECT INSTRUCTION REGISTER
	CALL PULSE_E ;PULSE LCD_E

	CALL DEL01 ;DO 1MS DELAY

	MOVF LCDTEMP, W
	ANDLW 0xFC ;MORE DELAY FOR 0x00 TO 0x03 INSTRUCTIONS
	BTFSC STATUS, Z
	CALL DEL01 ;DO 1MS DELAY
	RETURN


;CONVERT DIGIT TO ASCII
LCD_CHARD:
	ADDLW 0x30
	RETURN


;SEND CHAR TO THE LCD
LCD_CHAR:
	MOVWF LCDTEMP ;SAVE CHAR VALUE
	ANDLW 0xF0 ;SEND MSB FIRST
	MOVWF LCD_PORT
	BSF LCD_PORT, LCD_RS
	CALL PULSE_E

	SWAPF LCDTEMP, W ;SWAP MSB WITH LSB

	ANDLW 0xF0 ;SEND LSB SECOND
	MOVWF LCD_PORT
	BSF LCD_PORT, LCD_RS
	CALL PULSE_E

	CALL DEL01 ;DO 1MS DELAY
	RETURN

 
;MOVE CURSOR TO 1ST ROW
LCD_L1:
	MOVLW 0x80
	CALL LCDINS
	RETLW 0x00


;MOVE CURSOR TO 2ND ROW
LCD_L2:
	MOVLW 0xC0
	CALL LCDINS
	RETLW 0x00


;CLEAR DISPLAY
LCD_CLR:
	MOVLW 0x01
	CALL LCDINS
	RETLW 0x00


;PULSE E LCD PIN TO WRITE DATA FROM PORTB INTO LCD TROUGH DATA BUS OF LCD
PULSE_E:
	BSF LCD_PORT, LCD_E
	BCF LCD_PORT, LCD_E
	RETLW 0x00
 
 
;DELAY ROUTINES
D16US:
	CLRF CNTC 
	BSF CNTC, 5 ;DELAY 160US
	BSF CNTC, 4
	DECFSZ CNTC, F
	GOTO $ - 1
	RETURN
 
;SELECT DELAY TIME
DEL250:
	MOVLW 0xFA ;DELAY 250MS
	GOTO D0
DEL255:
	MOVLW 0xFF ;DELAY 255MS
	GOTO D0
DEL200:
	MOVLW D'200' ;DELAY 200MS
	GOTO D0
DEL100:  
	MOVLW D'100' ;DELAY 100MS
	GOTO D0
DEL50: 
	MOVLW D'50' ;DELAY 50MS
	GOTO D0
DEL20:
	MOVLW D'20' ;DELAY 20MS
	GOTO D0
DEL05:  
	MOVLW 0x05 ;DELAY 5.000MS (4 MHz clock)
	GOTO D0
DEL01:
	MOVLW 0x01 ;DELAY 1.000MS (4 MHz clock)

;DO SELECTED DELAY
D0:
	MOVWF CNTC
D1:
	MOVLW 0xC7 ;DELAY 1MS
	MOVWF CNTA
	MOVLW 0x01
	MOVWF CNTB
DEL_0:
	DECFSZ CNTA,F
	GOTO $ + 2
	DECFSZ CNTB,F
	GOTO DEL_0
	DECFSZ CNTC,F
	GOTO D1
	RETLW 0x00


; Improved macro to move cursor to row/column with register
MoveCursorReg macro row, colreg

	movf colreg, w         ; Get column register value
	movwf TEMP_TING ; Save it temporarily

	; check if colreg is >= 6 (decimal digits)
	; if colreg >= 6, we increment by one to skip the decimal point position
	movlw 0x06            ; Load W with 6
	subwf colreg, w       ; Subtract 6 from colreg (W = colreg - 6)
	btfss STATUS, C       ; Skip if colreg >= 6 (C=1 means colreg >= 6)
	goto $+2              ; If colreg < 6, don't increment (skip next instruction)
	incf colreg, f        ; If colreg >= 6, increment to skip decimal point

    ; Get row base address (assembly time check)
    if row == 1
        movlw 0x80            ; Row 1 base address
    else
        movlw 0xC0            ; Row 2 base address
    endif
    
    ; Save row base temporarily
    movwf LCDTEMP
    
    ; Runtime bounds checking for column (0-15)
    movf colreg, w
    sublw .12               ; W = 12 - colreg  
    btfss STATUS, C           ; Skip if colreg <= 12
    movlw .12                 ; If colreg > 12, use 12
    btfss STATUS, C
    movwf colreg              ; Update colreg with max value
    
    ; Add column offset to row base
    movf colreg, w
    addwf LCDTEMP, w          ; W = base + colreg
    call LCDINS               ; Send to LCD

	movf TEMP_TING, w ; Restore column value
	movwf colreg ; Restore column register
    endm