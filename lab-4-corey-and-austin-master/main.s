;****************** main.s ***************
; Program written by: **-UUU-*Your Names**update this***
; Date Created: 2/14/2017
; Last Modified: 2/12/2018
; Brief description of the program
;   The LED toggles at 8 Hz and a varying duty-cycle
;   Repeat the functionality from Lab3 but now we want you to 
;   insert debugging instruments which gather data (state and timing)
;   to verify that the system is functioning as expected.
; Hardware connections (External: One button and one LED)
;  PE1 is Button input  (1 means pressed, 0 means not pressed)
;  PE0 is LED output (1 activates external LED on protoboard)
;  PF2 is Blue LED on Launchpad used as a heartbeat
; You will only verify the variable duty-cycle feature of Lab 3 and not the "breathing" feature. 
; Instrumentation data to be gathered is as follows:
; After Button(PE1) press collect one state and time entry. 
; After Buttin(PE1) release, collect 7 state and
; time entries on each change in state of the LED(PE0): 
; An entry is one 8-bit entry in the Data Buffer and one 
; 32-bit entry in the Time Buffer
;  The Data Buffer entry (byte) content has:
;    Lower nibble is state of LED (PE0)
;    Higher nibble is state of Button (PE1)
;  The Time Buffer entry (32-bit) has:
;    24-bit value of the SysTick's Current register (NVIC_ST_CURRENT_R)
; Note: The size of both buffers is 50 entries. Once you fill these
;       entries you should stop collecting data
; The heartbeat is an indicator of the running of the program. 
; On each iteration of the main loop of your program toggle the 
; LED to indicate that your code(system) is live (not stuck or dead).

GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C

GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

; RAM Area
           AREA    DATA, ALIGN=2
;-UUU-Declare  and allocate space for your Buffers 
;    and any variables (like pointers and counters) here
dataBuffer		SPACE	50
timerBuffer		SPACE	200
NEntries		SPACE	2
dataPtr			SPACE	4
timerPtr		SPACE	4
NVIC_ST_CTRL_R        EQU 0xE000E010
NVIC_ST_RELOAD_R      EQU 0xE000E014
NVIC_ST_CURRENT_R     EQU 0xE000E018
; ROM Area
       IMPORT  TExaS_Init
	   IMPORT  SysTick_Init

;-UUU-Import routine(s) from other assembly files (like SysTick.s) here
       AREA    |.text|, CODE, READONLY, ALIGN=2
       THUMB
       EXPORT  Start

Start
 ; TExaS_Init sets bus clock at 80 MHz
      BL  TExaS_Init ; voltmeter, scope on PD3
	  
	LDR R1, =SYSCTL_RCGCGPIO_R      ; 1) activate clock for Port F AND E
	LDR R0, [R1]
	ORR R0, #0x30             		  ; set bit 5 and 4 to turn on clock
	STR R0, [R1]
	NOP
	NOP                             ; allow time for clock to finish
  
	LDR R1, =GPIO_PORTF_PUR_R      
	AND R0, #0x04                  
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_DIR_R       ; 5) set direction register
	LDR	R0, [R1]
	ORR R0, #0x04                    ; PF2 OUTPUT
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_AFSEL_R     ; 6) regular port function
	BIC R0, #0X04                      ; 0 means disable alternate function
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTF_DEN_R       ; 7) enable Port F digital port
	ORR R0, #0x04                   ; 1 means enable digital I/O
	STR R0, [R1]
	
	;PORT E INITIALIZATION 
  
	LDR R1, =GPIO_PORTE_DIR_R		; 5) set direction register
	LDR R0, [R1]
	ORR	R0,#0X01					;PE0 output
	BIC	R0,#0X02					;PE1 input
	STR R0, [R1]
		
	LDR R1, =GPIO_PORTE_AFSEL_R     ; 6) regular port function
	BIC R0, #0X03                    ; 0 means disable alternate function
	STR R0, [R1]
	
	LDR R1, =GPIO_PORTE_DEN_R 
	LDR	R0,[R1]						; 7) enable Port E digital port
	ORR	R0, #0X03					; 1 means enable digital I/O
	STR R0, [R1]
	
	MOV	 R0, #0X00FFFFFF
	SUB	 R0, #0X00F00000
	ADD  R0, #0X0000F000
	ADD	 R0, #0X0000F000
	ADD	 R12, R0, #0X0000F000
	MOV	 R0, #2
	MUL	 R12, R0
	
	MOV	R0, #5
	UDIV R1,R12,R0
	MOV	R8,#1
	MOV	R9,#0
	
	MOV R10, #0xFF78
	MOV	R11, #0
	
	
	
	
	
	
	
	PUSH	{R8,LR}
	
	BL	Debug_Init
 ;place your initializations here
      CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
	  
	  
	  
	  
	 
	  
loop  		POP {R8, LR}

			LDR	R0,=GPIO_PORTF_DATA_R
			LDR	R1,[R0]
			EOR	R1,#0X04					;TOGGLE HEAQRTBEAT
			STR	R1,[R0]



skip		
			LDR	R6,=GPIO_PORTE_DATA_R
			LDR	R7, [R6]
			AND R7, R7, #0x02				;ISOLATE PE1 BIT
			CMP	R7,#0
			BEQ	compare						;IF PE1 BIT IS 0, BRANCH TO TELL WHICH DATA CYCLE TO USE
			BL	Debug_Capture
button		LDR	R6,=GPIO_PORTE_DATA_R
			LDR	R7, [R6]
			CMP R7, R9
			BNE button						;IF PE1 BIT IS 1, WAIT UNTIL BUTTON IS RELEASED AND PE1 BIT IS 0
			MOV	R11,#7
			ADD	R8, R8, #1					;INCREMENT R8 TO POINT TO NEXT DUTY CYCLE
			
compare		ADD	R8, R8, #0
			CMP R8,R9
			BEQ	zero
			
			SUB	R8, R8, #1
			CMP R8, R9
			BEQ	twenty
			
			SUB	R8, R8, #1
			CMP R8, R9
			BEQ	fourty
			
			SUB	R8, R8, #1
			CMP R8, R9
			BEQ	sixty
			
			SUB	R8, R8, #1
			CMP R8, R9
			BEQ	eighty
			
			SUB	R8, R8, #1
			CMP R8, R9
			BEQ	hundo
			
			B zero
			
			


			
			

zero		AND	R0,#0
			ADD	R0,R12						; PUT MUGUFFIN IN R0
zeroL		SUBS R0,#1
			BPL  zeroL
			CMP	R11,#0
			BLE	skip_Z1
			BL 	Debug_Capture
			sub	r11,#1
skip_Z1		MOV	R8,#0
			PUSH	{R8, LR}
			B	loop
	
twenty		LDR	R0,=GPIO_PORTE_DATA_R		;get data adress
			LDR	R4,[R0]						;LOAD DATA INTO R4
			ORR	R4,#0X01					;TURN PE0 ON	
			STR	R4,[R0]						;STORE DATA
			CMP	R11,#0
			BLE	skip_T1
			BL 	Debug_Capture
			sub	r11,#1
skip_T1		LDR	R3,=0X000845D8					;INCREMENT ONCOUNTER
twentyon	SUBS	R3,#1					;DELAY WHILE ON
			BPL	twentyon						;
			AND	R4,#0XFE					;turn off PE0
			STR	R4,[R0]						;store data
			CMP	R11,#0
			BLE	skip_T2
			BL 	Debug_Capture
			sub	r11,#1
skip_T2		LDR	R2,=0X00211760					;decrement offcounter
twentyoff	SUBS	R2,#1					;DELAY WHILE OFF
			BPL	twentyoff
			MOV	R8,#1
			PUSH	{R8, LR}
			B loop	
			
fourty		LDR	R0,=GPIO_PORTE_DATA_R		;get data address
			LDR	R4,[R0]						;LOAD DATA INTO R4
			ORR	R4,#0X01					;TURN PE0 ON	
			STR	R4,[R0]						;STORE DATA
			CMP	R11,#0
			BLE	skip_F1
			BL 	Debug_Capture
			sub	r11,#1
skip_F1		LDR	R3,=0X000AFC80
			ADD	R3,R3,R1					;INCREMENT ONCOUNTER
			LDR	R3,=0X000AdC80
fourtyon	SUBS	R3,#1					;DELAY WHILE ON
			BPL	fourtyon					;
			AND	R4,#0XFE					;turn off PE0
			STR	R4,[R0]						;store data
			CMP	R11,#0
			BLE	skip_F2
			BL 	Debug_Capture
			sub	r11,#1
skip_F2		LDR	R2,=0X00EA600
fourtyoff	SUBS	R2,#1					;DELAY WHILE OFF
			BPL	fourtyoff
			MOV	R8,#2
			PUSH	{R8, LR}
			B loop
			
			
hundo		b	hundoLink


sixty		LDR	R0,=GPIO_PORTE_DATA_R		;get data address
			LDR	R4,[R0]						;LOAD DATA INTO R4
			ORR	R4,#0X01					;TURN PE0 ON	
			STR	R4,[R0]						;STORE DATA
			CMP	R11,#0
			BLE	skip_S1
			BL 	Debug_Capture
			sub	r11,#1
skip_S1		SUB	R3,R12,R1					;INCREMENT ONCOUNTER
			LDR	R3,=0X001B0210		
sixtyon		SUBS	R3,#1					;DELAY WHILE ON
			BPL	sixtyon						;
			AND	R4,#0XFE					;turn off PE0
			STR	R4,[R0]						;store data
			CMP	R11,#0
			BLE	skip_S2
			BL 	Debug_Capture
			sub	r11,#1
skip_S2		LDR	R2,=0X000BB1B0
			LDR	R2,=0X00120160					;decrement offcounter
sixtyoff	SUBS	R2,#1					;DELAY WHILE OFF
			BPL	sixtyoff
			MOV	R8,#3
			PUSH	{R8, LR}
			B loop
			
eighty		LDR	R0,=GPIO_PORTE_DATA_R		;get data address
			LDR	R4,[R0]						;LOAD DATA INTO R4
			ORR	R4,#0X01					;TURN PE0 ON	
			STR	R4,[R0]						;STORE DATA
			CMP	R11,#0
			BLE	skip_E1
			BL 	Debug_Capture
			sub	r11,#1
skip_E1		SUB	R3,R12,R1					;INCREMENT ONCOUNTER
			SUB	R3, R3, R1
			LDR	R6,=0X00000000
			LDR	R3,=0X00186A00
			
					
eightyon	SUBS	R3,#1					;DELAY WHILE ON
			BPL	eightyon					;
			AND	R4,#0XFE					;turn off PE0
			STR	R4,[R0]						;store data
			CMP	R11,#0
			BLE	skip_E2
			BL 	Debug_Capture
			sub	r11,#1
skip_E2		LDR	R2,=0X000B71B0
			ADD	R2,R1, R1					;decrement offcounter
			LDR	R3,=0X00061A80
eightyoff	SUBS	R3,#1					;DELAY WHILE OFF
			BPL	eightyoff
			MOV	R8,#4
			PUSH	{R8, LR}
			B loop

hundoLink	LDR	R0,=GPIO_PORTE_DATA_R		;get data address
			LDR	R4,[R0]
			ORR	R4,#0X01
			STR	R4,[R0]						;TURN ON PE0CMP	R11,#0
			CMP	R11,#0
			BLE	skip_hund
			BL 	Debug_Capture
			sub	r11,#1
skip_hund	MOV R3,R12
hundoL 		SUBS	R3,#1
			BPL hundoL
			AND	R4,#0XFE					;turn off PE0
			STR	R4,[R0]	
			MOV	R8,#5
			PUSH	{R8, LR}
			B    loop

Debug_Init
			PUSH	{R0-R6,LR}
			LDR		R1,=dataBuffer				;R1 = &dataBuffer
			MOV		R2,R1
			ADD		R2,#50					;R2 = &dataBuffer + 200
			MOV		R3,#0XFF
InitLoop1	STR		R3,[R1]
			ADD		R1,#0X01
			CMP		R1,R2
			BNE		InitLoop1
			
			LDR		R1,=dataBuffer
			LDR		R2,=dataPtr					
			STR		R1,[R2]						;[dataPtr] = &dataBuffer
			
			LDR		R1,=timerBuffer
			MOV		R5,R1
			ADD		R5,#0XC8
			MOV		R4,#0XFFFFFFFF
InitLoop2	STR		R4,[R1]
			ADD		R1,#0X04
			CMP		R1,R5
			BNE		InitLoop2
			
			LDR		R1,=timerBuffer
			ldr		r2,=timerPtr
			STR		R1,[R2]
			
			BL		SysTick_Init
			pop		{R0-R6,PC}
			
			
			
Debug_Capture
			PUSH	{R0-R8,LR} 		
			
			LDR		R0, =dataPtr
			LDR		R2, [R0]     		; R2 = pointer to DataBuffer
			
			LDR		R6,	=dataBuffer
			ADD		R6,#50				;if entries >= 50, exit subroutine
			CMP		R2,R6
			BEQ		done
			
			LDR		R5, =timerPtr
			LDR		R7, [R5]    		 ; R7 = pointer to TimeBuffer

			
			LDR		R3, =GPIO_PORTE_DATA_R 
			LDR		R3, [R3]   			  ; R3 = pe1
			LSL		R3, #3
			BIC		R3,#0XEF
			LDR		R4, =GPIO_PORTE_DATA_R
			LDR		R4, [R4]   			  ; R4 = pe0
			BIC		R4,#0XFE
			ADD		R4, R3, R4 			 
			STRB	R4, [R2]    			 ; Store in DataBuffer
			ADD		R2, #0x01
			STR		R2, [R0]    			 ; Increment DataPt
			
			LDR		R8, =NVIC_ST_CURRENT_R
			LDR		R8, [R8]
			STR		R8, [R7]   				  ; Store time in TimeBuffer
			ADD		R7, #0x04
			STR		R7, [R5]    			 ; Increment TimePtr
done		POP		{R0-R8, PC}
            	

      ALIGN      ; make sure the end of this section is aligned
      END        ; end of file

