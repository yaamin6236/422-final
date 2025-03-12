		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      	; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512			; 2^9 = 512 entries
	
INVALID		EQU		-1			; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_kinit
_kinit
		;initialize MCB area
		LDR 	R0, =MCB_TOP	;R0 points to 0x20006800
		LDR 	R1, =MAX_SIZE	;R1 gets 0x4000, entire heap is available
		STRH 	R1, [R0]		;1st MCB entry gets MAX_SIZE
		
		;sero out the rest of the mcb entries
		;R2 gets end address which is MCB_BOT + 2
		LDR 	R2, =MCB_BOT
		ADD 	R2, R2, #2		;mcb end
		;R0 points to next entry
		ADD 	R0, R0, #2
zero_loop
		CMP 	R0, R2
		BCS 	kinit_done		;if R0 >= end then done
		MOV 	R1, #0
		STRH 	R1, [R0]
		ADD 	R0, R0, #2		;next entry
		B		zero_loop
kinit_done
		BX		LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
	;; Implement by yourself
		MOV 	R0, #0x400 		;dummy valid pointer
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
	;; Implement by yourself
		MOV		pc, lr					; return from rfree( )
		
		END
