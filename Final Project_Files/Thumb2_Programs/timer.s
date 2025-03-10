		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14			; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
		; load STCTRL_STOP val and address of SysTick Control and Status Register
		LDR		R0, =STCTRL_STOP
		LDR		R1, =STCTRL
		; store STCTRL_STOP val in SysTick Control and Status Register
		STR		R0, [R1]
		
		; load STRELOAD_MX val and address of SysTick Reload Value Register
		LDR		R0, =STRELOAD_MX
		LDR		R1, =STRELOAD
		; store STRELOAD_MX val in SysTick Reload Value Register
		STR		R0, [R1]
		
		BX		LR		; return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
		; retrieve current seconds paremeter from address, 0x20007B80 (SECONDS_LEFT address)
		; this value will be the return value, so load value into R0
		MOV		R1, R0		; move new seconds value to R1
		LDR		R2, =SECOND_LEFT		; load address of SECOND_LEFT to R2
		LDR		R0, [R2]		; access previous seconds value from R2 and move into R0 (as return value)

		; store new seconds value (stored in R1) to address 0x20007B80 (stored in R2)
		STR		R1, [R2]
		
		; enable SysTick by storing STCTRL_GO value in STCTRL
		LDR		R1, =STCTRL_GO
		LDR		R2, =STCTRL
		STR		R1, [R2]
		
		; clear by storing STCURR_CLR in STCURRENT
		LDR		R1, =STCURR_CLR
		LDR		R2, =STCURRENT
		STR		R1, [R2]
	
		BX		LR		; return to caller

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
	;; Implement by yourself
	
		MOV		pc, lr		; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;; Implement by yourself
	
		MOV		pc, lr		; return to Reset_Handler
		
		END		
