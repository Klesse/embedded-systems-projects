Org 0000h
		
RS 			Equ  	P1.3
E			Equ		P1.2


; R4 - Correct accumulator

; R/W* is hardwired to 0V, therefore it is always in write mode
; ---------------------------------- Main -------------------------------------
Main:		
			Clr RS		   		; RS=0 - Instruction register is selected. 
			MOV R6, #0
			MOV R3, #0
			Mov DPTR, #PASS ; Password in data pointer
;-------------------------- Instructions Code ---------------------------------
			Call FuncSet		; Function set (4-bit mode)
	
			Call DispCon		; Turn display and cusor on/off 
			
			Call EntryMode		; Entry mode set - shift cursor to the right
;----------------------------- Scan for the keys -------------------------------		
Next:		Call ScanKeyPad
			CLR A
			MOVC A, @A+DPTR
			CJNE A, 07H, NotEqual
			Inc R6
NotEqual:		
			Inc DPTR
			SetB RS				; RS=1 - Data register is selected.
			Clr A
			Mov A,#'*' ; R7 if you want to see the value
			Call SendChar		;Display the key that is pressed.
			Cjne R7,#'#',Next	;Check for "#", if yes, terminate.

EndHere:	Jmp $
;------------------------------ *End Of Main* ---------------------------------
;--------------- Note: Use 7 for Update Frequency in EdSim51 -----------------
;-------------------------------- Subroutines ---------------------------------				
; ------------------------- Function set --------------------------------------
FuncSet:	Clr  P1.7		
			Clr  P1.6		
			SetB P1.5		; | bit 5=1
			Clr  P1.4		; | (DB4)DL=0 - puts LCD module into 4-bit mode 
	
			Call Pulse

			Call Delay		; wait for BF to clear

			Call Pulse
							
			SetB P1.7		; P1.7=1 (N) - 2 lines 
			Clr  P1.6
			Clr  P1.5
			Clr  P1.4
			
			Call Pulse
			
			Call Delay
			Ret
;------------------------------------------------------------------------------
;------------------------------- Display on/off control -----------------------
; The display is turned on, the cursor is turned on
DispCon:	Clr P1.7		; |
			Clr P1.6		; |
			Clr P1.5		; |
			Clr P1.4		; | high nibble set (0H - hex)

			Call Pulse

			SetB P1.7		; |
			SetB P1.6		; |Sets entire display ON
			SetB P1.5		; |Cursor ON
			SetB P1.4		; |Cursor blinking ON
			Call Pulse

			Call Delay		; wait for BF to clear	
			Ret

;----------------------------- Entry mode set (4-bit mode) ----------------------
;    Set to increment the address by one and cursor shifted to the right
EntryMode:	Clr P1.7		; |P1.7=0
			Clr P1.6		; |P1.6=0
			Clr P1.5		; |P1.5=0
			Clr P1.4		; |P1.4=0

			Call Pulse

			Clr  P1.7		; |P1.7 = '0'
			SetB P1.6		; |P1.6 = '1'
			SetB P1.5		; |P1.5 = '1'
			Clr  P1.4		; |P1.4 = '0'
 
			Call Pulse

			Call Delay		; wait for BF to clear
			Ret
;--------------------------------------------------------------------------------			
;------------------------------------ Pulse --------------------------------------
Pulse:		SetB E		; |*P1.2 is connected to 'E' pin of LCD module*
			Clr  E		; | negative edge on E	
			Ret
;---------------------------------------------------------------------------------
;------------------------------------- SendChar ----------------------------------			
SendChar:	Mov C, ACC.7		; |
			Mov P1.7, C			; |
			Mov C, ACC.6		; |
			Mov P1.6, C			; |
			Mov C, ACC.5		; |
			Mov P1.5, C			; |
			Mov C, ACC.4		; |
			Mov P1.4, C			; | high nibble set
			;Jmp $
			Call Pulse

			Mov C, ACC.3		; |
			Mov P1.7, C			; |
			Mov C, ACC.2		; |
			Mov P1.6, C			; |
			Mov C, ACC.1		; |
			Mov P1.5, C			; |
			Mov C, ACC.0		; |
			Mov P1.4, C			; | low nibble set

			Call Pulse

			Call Delay			; wait for BF to clear
			
			Mov R1,#55h
			Ret
;--------------------------------------------------------------------------------
;------------------------------------- Delay ------------------------------------			
Delay:		Mov R0, #500
			Djnz R0, $
			Ret
;--------------------------------------------------------------------------------				
;------------------------------- Scan Row ---------------------------------------
ScanKeyPad:	CLR P0.3			;Clear Row3
			CALL IDCode0		;Call scan column subroutine
			SetB P0.3			;Set Row 3
			JB F0,Done  		;If F0 is set, end scan 
						
			;Scan Row2
			CLR P0.2			;Clear Row2
			CALL IDCode1		;Call scan column subroutine
			SetB P0.2			;Set Row 2
			JB F0,Done		 	;If F0 is set, end scan 						

			;Scan Row1
			CLR P0.1			;Clear Row1
			CALL IDCode2		;Call scan column subroutine
			SetB P0.1			;Set Row 1
			JB F0,Done			;If F0 is set, end scan

			;Scan Row0			
			CLR P0.0			;Clear Row0
			CALL IDCode3		;Call scan column subroutine
			SetB P0.0			;Set Row 0
			JB F0,Done			;If F0 is set, end scan 
														
			JMP ScanKeyPad		;Go back to scan Row3
							
Done:		Clr F0		        ;Clear F0 flag before exit
			Ret
;--------------------------------------------------------------------------------			
;---------------------------- Scan column subroutine ----------------------------
IDCode0:	JNB P0.4, KeyCode03	;If Col0 Row3 is cleared - key found
			JNB P0.5, KeyCode13	;If Col1 Row3 is cleared - key found
			JNB P0.6, KeyCode23	;If Col2 Row3 is cleared - key found
			RET					

KeyCode03:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'3'		;Code for '3'
			RET				

KeyCode13:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'2'		;Code for '2'
			RET				

KeyCode23:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'1'		;Code for '1'
			RET				

IDCode1:	JNB P0.4, KeyCode02	;If Col0 Row2 is cleared - key found
			JNB P0.5, KeyCode12	;If Col1 Row2 is cleared - key found
			JNB P0.6, KeyCode22	;If Col2 Row2 is cleared - key found
			RET					

KeyCode02:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'6'		;Code for '6'
			RET				

KeyCode12:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'5'		;Code for '5'
			RET				

KeyCode22:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'4'		;Code for '4'
			RET				

IDCode2:	JNB P0.4, KeyCode01	;If Col0 Row1 is cleared - key found
			JNB P0.5, KeyCode11	;If Col1 Row1 is cleared - key found
			JNB P0.6, KeyCode21	;If Col2 Row1 is cleared - key found
			RET					

KeyCode01:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'9'		;Code for '9'
			RET				

KeyCode11:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'8'		;Code for '8'
			RET				

KeyCode21:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'7'		;Code for '7'
			RET				

IDCode3:	JNB P0.4, KeyCode00	;If Col0 Row0 is cleared - key found
			JNB P0.5, KeyCode10	;If Col1 Row0 is cleared - key found
			JNB P0.6, KeyCode20	;If Col2 Row0 is cleared - key found
			RET					

KeyCode00:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'#'		;Code for '#'
			CJNE R6, #4, PassDenied
			SJMP PassAllowed 
			RET				

KeyCode10:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'0'		;Code for '0'
			RET				

KeyCode20:	SETB F0			;Key found - set F0
			CALL Debounce
			Mov R7,#'*'	   	;Code for '*' 
			RET						

PassDenied: MOV DPTR, #DENIED
			CALL SecondLine
BackDenied: CLR A
			MOVC A, @A+DPTR
			JZ Finish
			CALL SendChar
			Inc DPTR
			JMP BackDenied

PassAllowed: MOV DPTR, #ALLOWED
			CALL SecondLine

BackAllowed: CLR A
			 MOVC A, @A+DPTR
			 JZ Finish
		     CALL SendChar
			 Inc DPTR
			 JMP BackAllowed
SecondLine:
			CLR RS
			SETB P1.7
			SETB P1.6
			CLR P1.5
			CLR P1.4
			CALL Pulse
			CLR P1.7
			CLR P1.6
			CLR P1.5
			CLR P1.4
			CALL Pulse
			CALL Delay
			SETB RS
			RET

Debounce: 
	MOV A,P0
	ANL A,#070h
	CJNE A, #070h,Debounce

	MOV TMOD, #01h
	MOV TH0,  #08ah
	MOV TL0,  #0cfh
	SETB tr0
	JNB tf0, $
	CLR tr0
	CLR tf0
	RET

Finish: JMP $
;--------------------------------- End of subroutines ---------------------------

Org 0200h
PASS: DB '1', '2', '3', '4'

Org 0300h
ALLOWED: DB 'A', 'C', 'C', 'E', 'S', 'S', ' ', 'A', 'L', 'L', 'O', 'W', 'E', 'D',0

Org 0400h
DENIED: DB 'A', 'C', 'C', 'E', 'S', 'S', ' ', 'D', 'E', 'N', 'I', 'E', 'D',0

Stop:		Jmp $
	
End


