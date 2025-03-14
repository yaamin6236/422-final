		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; store current state of registers before performing any operations
		PUSH		{R1-R11, LR}
		
		; store original address of *s (R0) in R2
		MOV			R2, R0
		
		; store immediate value of 0 into R3
		MOV			R3, #0

_bzero_loop
		; check if n is equal to 0
		; branch to _bzero_end if true
		CMP			R1, #0
		BEQ			_bzero_end
		
		; decrement n var (R1)
		SUB			R1, R1, #1
		
		; zero-initialize current memory location
		; accesses contents of R0 and stores byte R3 (set to immediate value 0) in it
		; increment to next byte in R0
		STRB		R3, [R0], #1
		
		; continue to next iteration
		B			_bzero_loop

_bzero_end
		; store original address of *s (R2) back into R0 (*s)
		MOV			R0, R2

		; restores original state of registers (before _bzero function call)
		POP		{R1-R11, LR}
		
		; return back to main function
		BX		LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   	dest 	- pointer to the buffer to copy to
;	src	- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; store current state of registers before performing any operations
		PUSH		{R1-R11, LR}
		
		; store original address of *dest (R0) in R3
		MOV			R3, R0
		
		; store original address of *src (R1) in R4
		MOV			R4, R1
		
_strncpy_loop
		; check if size var equal to 0
		; branch to _strncpy_end if condition evaluates to true
		CMP			R2, #0
		BEQ			_strncpy_end
		
		; decrement size var (R2)
		SUB			R2, R2, #1
		
		; load byte at current memory location of *src (R1) and load into R5
		; increment to next byte in src*
		LDRB		R5, [R1], #1
		
		; store byte stored in R5 and access and store in current memory location of *dest (R0)
		; increment to next byte in dest*
		STRB		R5, [R0], #1
		
		; continue to next iteration
		B			_strncpy_loop
	
_strncpy_end
		; store original address of dest (R3) back into R0 (*dest)
		MOV			R0, R3
		
;		; store original address of src (R4) back into R1 (*src)
;		MOV			R1, R4
		
		; restores original state of registers (before _strncpy function call)
		POP		{R1-R11, LR}
		
		; return back to main function
		BX		LR
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; save registers
		PUSH	{R4-R11}
		
		; set the system call #3 for SYS_MALLOC to R7
		MOV 	R7, #3
		
		;issue supervisor call
	    SVC     #0x3
		
		; resume registers/return to caller
		POP		{R4-R11}
		BX		LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		; save registers
		PUSH	{R4-R11}
		
		; set the system call #4 for SYS_FREE to R7
		MOV 	R7, #4
		
		;issue supervisor call
		SVC     #0x4
		
		; resume registers/return to caller
		POP		{R4-R11}
		BX		LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		PUSH	{R4-R11}
		
		; set the system call #1 for SYS_ALARM to R7
		MOV 	R7, #1
		
		;issue supervisor call
        SVC     #0x1
		
		; resume registers/return to caller	
		POP		{R4-R11}
		BX		LR
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		PUSH	{R4-R11}
		
		; set the system call #2 for SYS-SIGNAL to R7
		MOV 	R7, #2
		
		;issue supervisor call
        SVC     #0x2
		
		; resume registers/return to caller
		POP		{R4-R11}
		BX		LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
