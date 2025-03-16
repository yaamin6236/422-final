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
		; initialize heap space
		LDR		R0, =HEAP_TOP
		LDR		R1, =HEAP_BOT
		MOV		R2, #0

zero_loop_heap
		CMP		R0, R1
		BHS		mcb_init
		
		STR		R2, [R0], #4
		
		B		zero_loop_heap

mcb_init
		; initialize MCB space
		LDR 	R0, =MCB_TOP	;R0 points to 0x20006800
		LDR 	R1, =MAX_SIZE	;R1 gets 0x4000, entire heap is available
		STRH 	R1, [R0], #2	;1st MCB entry gets MAX_SIZE, continues to next entry
		
		;zero out the rest of the mcb entries
		;R1 gets end address which is MCB_BOT
		LDR 	R1, =MCB_BOT

zero_loop_mcb
		CMP 	R0, R1
		BHS 	kinit_done		;if R0 >= end then done

		STRH 	R2, [R0], #2

		B		zero_loop_mcb

kinit_done
		BX		LR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
		;Save link register to preserve return address
		PUSH    {R4-R12, LR}            ;Save return address
		
		;R0 has requested size in bytes
		CMP     R0, #32         ;min allocation is MIN_SIZE (32bytes)
		BGE     _kalloc_continue
		MOV     R0, #32
		
_kalloc_continue
		LDR     R1, =MCB_TOP    ;R1 is left boundary, start of MCB region
		LDR     R2, =MCB_BOT    ;R2 is right boundary, end of MCB region
		BL      _ralloc         ;calls recursive helper
		MOV		R0, R3			; move return value of _ralloc to R0

_kalloc_done
		;Restore link register before returning
		POP     {R4-R12, LR}
		MOV		PC, LR              ;return with the heap pointer in R0
		
_ralloc
		;inputs are R0 for requested size in bytes, R1 for left boundary
		;address of current MCB region, R2 for right boundary
		
		; R3 will be reserved for heap_addr return value
		
		; calculate entire(R4) = right(R2) - left(R1) + mcb_ent_sz(R5)
		SUB		R4, R2, R1		; X = right - left
		LDR		R5, =MCB_ENT_SZ
		ADD		R4, R4, R5		; entire = X + mcb_ent_sz
		
		; calculate half(R5) = entire(R4) / 2
		LSR		R5, R4, #1
		
		; calculate midpoint(R6) = left(R1) + half(R5)
		ADD		R6, R1, R5
		
		; calculate act_entire_size(R4) = entire(R4) * 16
		LSL		R4, R4, #4
		
		; calculate act_half_size(R5) = half(R5) * 16
		LSL		R5, R5, #4
		
		; initialize heap_addr(R3) to NULL
		MOV		R3, #0
		
		; check if size(R0) > act_half_size(R4)
		CMP		R0, R5
		BGT		_occupy_chunk

_ralloc_left
		; save calculations and link register
		; R3 is reserved as a return register, do not save it
		PUSH	{R0-R2, R4-R6, LR}

		; set right(R2) = midpoint(R6) - mcb_ent_sz(R7)
		LDR		R7, =MCB_ENT_SZ
		SUB		R2, R6, R7
		
		; _ralloc( size, left, midpoint - mcb_ent_sz )
		BL		_ralloc
		
		; restore calculations and link register
		POP		{R0-R2, R4-R6, LR}
		
		; check if _ralloc_left succeeds
		CMP		R3, #INVALID
		BNE		_split_parent_mcb

_ralloc_right
		; save calculations and link register
		; R3 is reserved as a return register, do not save it
		PUSH	{R0-R2, R4-R6, LR}

		; set left(R1) = midpoint(R6)
		MOV		R1, R6
		
		; _ralloc( size, midpoint, right )
		BL		_ralloc
		
		; restore calculations and link register
		POP		{R0-R2, R4-R6, LR}
		
		; check if _ralloc_right fails
		CMP		R3, #INVALID
		BEQ		_return_invalid

_split_parent_mcb
		; access memory contents at midpoint(R6), store in R7
		LDRH	R7, [R6]
		
		; branch to _return_heap_addr if it's in use
		TST		R7, #0x01
		BNE		_return_heap_addr
		
		; store act_half_size(R5) in memory location pointed to by midpoint(R6)
		; branch to _return_heap_addr
		STRH	R5, [R6]
		B		_return_heap_addr
		
_occupy_chunk
		; retrieve mcb contents pointed to by left (R1)
		LDRH	R7, [R1]
		
		; branch to _return_invalid if it's in use
		TST		R7, #0x01
		BNE		_return_invalid
		
		; at this point, mcb contents pointed to by left is confirmed not in use
		; check if left's mcb contents size < act_entire_size(R4), if so, return invalid
		LDR		R7, [R1]
		CMP		R7, R4
		BLT		_return_invalid
		
		; otherwise, mark left's mcb contents as used
		ORR		R7, R4, #0x01
		STRH	R7, [R1]
		
		; calculate corresponding heap_addr
		; heap_addr = heap_top + (left - mcb_top) * 16
		
		; X = (left - mcb_top)
		LDR		R8, =MCB_TOP
		SUB		R7, R1, R8
		
		; Y = X * 16
		LSL		R7, R7, #4
		
		; heap_top + Y
		LDR		R8, =HEAP_TOP
		ADD		R7, R8, R7
		
		; store calculated heap_addr in R3 (temp designated return register)
		MOV		R3, R7
		
		; corresponding heap_addr is calculated, branch to _return_heap_addr
		B		_return_heap_addr
		
_return_invalid
		MOV		R3, #INVALID
		
_return_heap_addr
		BX		LR
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
		; save registers
		PUSH	{R4-R12, LR}

		; check if R0 is within range of dedicated heap memory
		
		; address is greater than HEAP_BOT
		LDR		R1, =HEAP_BOT
		CMP		R0, R1
		BGT		_kfree_invalid
		
		; address is less than HEAP_TOP
		LDR		R1, =HEAP_TOP
		CMP		R0, R1
		BLT		_kfree_invalid

		; if address is valid, compute corresponding MCB index
		; mcb_addr = mcb_top + (addr - heap_top) / 16
		
		; X = (addr - heap_top)
		SUB		R0, R0, R1
		
		; Y = X / 16
		LSR		R0, R0, #4
		
		; mcb_top + Y
		LDR		R1, =MCB_TOP
		ADD		R0, R0, R1
		
		; corresponding mcb_addr is located in R0
		; call recursive free function
		BL		_rfree
		
		; branch to _kfree_done if _rfree operation successful
		; otherwise, set return value to 0 and return
		CMP		R0, #INVALID
		BNE		_kfree_done

_kfree_invalid
		; return NULL if address is invalid
		MOV		R0, #0

_kfree_done
		; restore registers
		POP		{R4-R12, LR}
		BX		LR
	
_rfree
		; save registers, so we can go back to previous _rfree recursive calls (including initial _rfree call)
		PUSH	{R4-R12, LR}
		
		; retrieve
		;	- mcb_contents (R1): stored in memory at mcb_addr (R0)
		;	- mcb_offset (R2): 
		;	- mcb_chunk (R3): mcb_contents /= 16
		;	- my_size (R4): mcb_contents *= 16
		
		; retrieve mcb_contents, store in R1
		LDRH	R1, [R0]
		
		; calculate mcb_offset = (mcb_addr(R0) - mcb_top(R3)), store in R2
		LDR		R3, =MCB_TOP
		SUB		R2, R0, R3
		
		; calculate mcb_chunk (mcb_contents(R1) / 16)
		LSR		R3, R1, #4
		
		; calculate mcb_size (mcb_contents(R1) * 16)
		LSL		R4, R1, #4

		; clear mcb's used bit and store in memory located at R0
		BIC		R4, R1, #0x01
		STRH	R4, [R0]

		; check if mcb is on the left or right
		; (mcb_offset / mcb_chunk) % 2
		; 0 is on left, 1 is on right
		UDIV	R5, R2, R3		; R5 = (mcb_offset(R2) / mcb_chunk(R3))
		
		; if R5 LSB is one, mcb is on left, otherwise mcb is on right
		TST		R5, #0x01
		BNE		is_on_right

is_on_left
		; check if buddy is located beyond MCB_BOT. if so, branch to _rfree_done
		; location of buddy = mcb_addr(R0) + mcb_chunk(R3)
		ADD		R5, R0, R3
		LDR		R6, =MCB_BOT
		CMP		R5, R6
		BGE		_rfree_invalid

		; else, buddy is within range
		; access contents at location of buddy (R5)
		LDRH	R6, [R5]
		
		; check if buddy is in use by getting LSB from its contents(R6)
		; if in use, branch to _rfree_done
		TST		R6, #0x01
		BNE		_rfree_done
		
		; clear bits 4-0 to get buddy's size
		LSR		R6, R6, #5
		LSL		R6, R6, #5
		
		; check if buddy's size is equal to our size
		; if not equal, branch to _rfree_done
		CMP		R6, R4
		BNE		_rfree_done
		
		; buddy is same size so we can clear and merge buddy (R5)
		; R5 is location of buddy in MCB
		MOV		R7, #0
		STRH	R7, [R5]
		
		; double our size (R4 is our size)
		LSL		R4, R4, #1
		
		; merge my buddy to me mcb_addr(R0)
		STRH	R4, [R0]
		
		; promote ourselves
		; recursively call _rfree with us (mcb_addr) !!!
		BL		_rfree

is_on_right
		; check if buddy is located below MCB_TOP. if so, branch to _rfree_done
		; location of buddy = mcb_addr(R0) - mcb_chunk(R3)
		SUB		R5, R0, R3
		LDR		R6, =MCB_TOP
		CMP		R5, R6
		BLT		_rfree_invalid
		
		; else, buddy is within range
		; access contents at location of buddy (R5)
		LDRH	R6, [R5]
		
		; check if buddy is in use by getting LSB from its contents(R6)
		; if in use, branch to _rfree_done
		TST		R6, #0x01
		BNE		_rfree_done
		
		; clear bits 4-0 to get buddy's size
		LSR		R6, R6, #5
		LSL		R6, R6, #5
		
		; check if buddy's size is equal to our size
		; if not equal, branch to _rfree_done
		CMP		R6, R4
		BNE		_rfree_done
		
		; buddy is same size so we can clear and merge ourselves (R0)
		; R5 is location of buddy in MCB
		MOV		R7, #0
		STRH	R7, [R0]
		
		; double buddy's size (R6 is buddy's size)
		LSL		R6, R6, #1
		
		; merge me to my buddy !!! (R5 is location of buddy)
		STRH	R6, [R5]
		
		; promote buddy
		MOV		R0, R5
		
		; recursively call _rfree with buddy (mcb_addr - mcb_chunk) !!!
		BL		_rfree

_rfree_invalid
		MOV		R0, #INVALID

_rfree_done
		POP		{R4-R12, LR}
		BX		LR

		END
