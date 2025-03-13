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
		;R0 has requested size in bytes
		CMP		R0, #32			;min allocation is MIN_SIZE (32bytes)
		BGE		kalloc_continue
		MOV		R0, #32
kalloc_continue
		LDR 	R1, =MCB_TOP	;R1 is left boundary, start of MCB region
		LDR 	R2, =MCB_BOT	;R2 is right boundary, end of MCB region
		BL		_ralloc			;calls recursive helper
		BX		LR				;return with the heap pointer in R0
		
		EXPORT 	_ralloc
_ralloc
		;inputs are R0 for requested size in bytes, R1 for left boundary
		;address of current MCB region, R2 for right boundary
		;STEP 1: calculate the total number of MCB bytes in this region (entire)
		SUB		R3, R2, R1		;R3 is difference in bytes between R2 and R1
		ADD		R3, R3, #2		;R3 is entire = difference plus 2
		
		;STEP 2: now get half of entire, in MCB bytes
		LSRS 	R4, R3, #1		;R4 is half
		
		;STEP 3: get midpoint in MCB region which is R1 + half
		ADD		R5, R1, R4		;R5 is midpoint
		
		;STEP 4 convert MCB sizes to heap sizes
		;MCB byte = 16 heap bytes
		;actual entire size = entire * 16, actual half size = half * 16
		MOV 	R6, R3
		LSL		R6, R6, #4		;R6 is actual entire size
		MOV 	R7, R4
		LSL 	R7, R7, #4		;R7 is actual half size
		
		;STEP 5 check if requested size in R0 is <= actual half size
		CMP 	R0, R7
		BLE		ralloc_left		;if so, allocate from left recursively
		;STEP 6: if not, attempt allocate entire block at current left boundary R1
		LDRH 	R8, [R1]		;load mcb entry at R1
		AND		R8, R8, #1		;test used bit, bit 0
		CMP 	R8, #0
		BNE 	ralloc_fail		;if block is used, fail in this region
		;if block is free, check if available size is big enough
		LDRH 	R8, [R1]		;reload full mcb entry
		BIC		R8, R8, #1		;clear used bit to get available size
		CMP 	R8, R6
		BLT		ralloc_fail		;if available size less than actual entire size then we fail
		;otherwise mark block as allocated by setting used bit
		ORR 	R8, R8, #1
		STRH 	R8, [R1]
		;STEP 7 compute corresponding heap address
		;heap address = HEAP_TOP + (((MCB entry address - MCB_TOP) / MCB_ENT_SZ) * 16)
		LDR 	R9, =HEAP_TOP 	;R9=HEAP_TOP
		LDR 	R10, =MCB_TOP	;R10=MCB_TOP
		SUB 	R11, R1, R10	;R11 is offset in bytes in MCB region
		ASRS 	R11, R11, #1	;divide offset by 2 (entries are 2bytes)
		LSL 	R11, R11, #4	;multiply by 16 (entries correspond to 16 heap bytes)
		ADD 	R0, R9, R11		;R0 gets heap address to return
		BX 		LR
		
ralloc_left
		;STEP 8: try allocating from left half of current region
		;left remains R1, right becomes midpint-MCB_ENT_SZ
		SUB 	R12, R5, #2		;R12 is new right boundary (R5 - 2)
		;save registers 1-8 and link register before recursion
		PUSH 	{R1-R8, LR}
		;new boundaries are set, R1 unchanged, R2 becomes R12
		MOV 	R2, R12
		BL 		_ralloc			;recursive attempt to allocate in left half
		POP 	{R1-R8, LR} 	;restore registers
		CMP 	R0, #0
		BNE 	ralloc_return	;if left allocation success, return it
		
		;STEP 9: if left failed, try right
		PUSH 	{R1-R8, LR} 	;save regosters again before recursion
		MOV 	R1, R5			;new left boundary is midpoint
		;original right boudnary R2 stays the same
		BL 		_ralloc
		POP 	{R1-R8, LR}
		BX 		LR				;return result, R0 is 0 if allocation fails
		
ralloc_fail
		MOV 	R0, #0			;return 0 because failed
		BX 		LR
ralloc_return
		BX 		LR
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
		; R0 contains the starting address to be freed from memory
		; if R0 is NULL, immediately branch to _kfree_done
		CMP		R0, #0
		BEQ		_kfree_done
		
		; check if starting address goes beyond dedicated space for HEAP
		LDR		R1, =HEAP_BOT
		CMP		R0, R1
		BGT		_kfree_done
		
		LDR		R1, =HEAP_TOP
		CMP		R0, R1
		BLT		_kfree_done

		; calculate MCB index (R0 - HEAP_TOP) / MIN_SIZE
		SUB		R0, R0, R1
		LDR		R1, =MIN_SIZE
		UDIV	R0, R0, R1

		; calculate MCB address of R0
		; MCB_TOP + (MCB_index * 2)
		LDR		R1, =MCB_TOP
		ADD		R0, R1, R0, LSL #1
		
		; call recursive free function
		BL		_rfree
		
_kfree_done
		MOV		R0, #0		; return NULL
		BX		LR
		
_rfree
		; at this point, R0 contains the respective MCB address for the pointer
		PUSH	{R4-R11, LR}       ; Save registers
		
		; load MCB contents value located at R0, update status to available, and store back in R0
		LDRH	R1, [R0]
		BIC		R1, R1, #1
		STRH	R1, [R0]
		
		; extract heap size associated with MCB entry, store in R2
		LSR		R2, R1, #4
		BIC		R2, R2, #0xF000
		
		; check if merging is possible (i.e. if heap size retrieved above is not the max of 16KB)
		; if merging not possible, branch to _rfree_done
		LDR		R3, =MAX_SIZE
		CMP		R2, R3
		BEQ		_rfree_done
		
		; calculate the current MCB index
		; (curr_MCB_addr - MCB_TOP) / 2
		LDR		R3, =MCB_TOP
		SUB		R4, R0, R3
		LSR		R4, R4, #1
		
		; calculate MCB index of buddy
		; curr_MCB_index ^ (block_size / MIN_SIZE)
		MOV		R5, R2
		LSR		R5, R5, #5
		EOR		R5, R4, R5
		
		; retrieve buddy's MCB address
		LSL		R5, R5, #1
		ADD		R5, R3, R5
		
		; check if buddy is available
		; if not available, merging not possible, branch to _rfree_done
		LDRH	R6, [R5]
		TST		R6, #1
		BNE		_rfree_done
		
		; check if buddy has same size as current
		; if buddy is different size, not possible to merge, branch to _rfree_done
		LSR		R7, R6, #4
		BIC		R7, R7, #0xF000
		CMP		R7, R2
		BNE		_rfree_done
		
		; otherwise, merge buddy with current
		; check which buddy is on the left
		CMP		R0, R5			; double check, R4 is current_MCB_index and R5 is buddy actual address
		BHI		_rfree_buddy_left
		
		; current is on the left (R4 < R5)
		; zero out buddy's MCB entry
		MOV		R7, #0
		STRH	R7, [R5]
		
		; double size of current block
		LSL		R2, R2, #5
		STRH	R2, [R0]
		
		; recursively check if we can merge any further, if not, branch to _rfree_done
		BL		_rfree
		B		_rfree_done		; check if this is necessary
		
_rfree_buddy_left
		; buddy is on the left
		; zero out current's MCB entry
		MOV		R7, #0
		STRH	R7, [R0]
		
		; double size of buddy block
		LSL		R2, R2, #5
		STRH	R2, [R5]
		
		; recursively check if we can merge any further, if not, branch to _rfree_done
		MOV		R0, R5		; set buddy as new current block
		BL		_rfree
		
_rfree_done
		; restore registers and return
		POP {R4-R11, PC}

		END
