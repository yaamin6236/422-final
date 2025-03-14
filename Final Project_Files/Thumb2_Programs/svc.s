		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB
    IMPORT _timer_start
    IMPORT _signal_handler
    IMPORT _kalloc
    IMPORT _kfree

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init
		;write the address for _timer_start to SYS_ALARM memory 0x20007B04
		LDR		R0, =_timer_start	;address for _timer_start loaded into R0
		LDR		R1, =0x20007B04		;address where it should be stored, SYS_ALARM
		STR		R0, [R1]			;store  address
		
		;write address for _signal_handler into SYS_SIGNAL memory 0x20007B08
		LDR 	R0, =_signal_handler
		LDR 	R1, =0x20007B08
		STR 	R0, [R1]
		
		;write address for _kalloc to SYS_MALLOC memory 0x20007B0C
		LDR 	R0, =_kalloc
		LDR 	R1, =0x20007B0C
		STR 	R0, [R1]
		
		;write address for _kfree to SYS_FREE memory 0x20007B10
		LDR 	R0, =_kfree
		LDR 	R1, =0x20007B10
		STR 	R0, [R1]
	
		MOV		pc, lr		;return from function

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
        PUSH    {R4, LR}            ; Save LR and a register for address
        CMP     R7, #1              ; compare R7 with SYS_ALARM
        BEQ     syscall_alarm
        CMP     R7, #2              ; compare R7 with SYS_SIGNAL
        BEQ     syscall_signal
        CMP     R7, #3              ; compare R7 with SYS_MALLOC
        BEQ     syscall_malloc
        CMP     R7, #4              ; compare R7 with SYS_FREE
        BEQ     syscall_free
		
_syscall_table_jump_invalid
        ; no match, return 0
        MOV     R0, #0
		
_syscall_table_jump_done
        POP     {R4, PC}            ; Return directly by popping to PC
        
syscall_alarm
        LDR     R4, =0x20007B04     ; load SYS_ALARM entry address
        LDR     R4, [R4]            ; fetch address _timer_start
        BLX     R4                  ; Call with link so we can return
        B       _syscall_table_jump_done
        
syscall_signal
        LDR     R4, =0x20007B08     ; SYS_SIGNAL entry address
        LDR     R4, [R4]            ; fetch address _signal_handler
        BLX     R4                  ; Call with link so we can return
        B       _syscall_table_jump_done
        
syscall_malloc
        LDR     R4, =0x20007B0C     ; load SYS_MALLOC entry address
        LDR     R4, [R4]            ; fetch address _kalloc
        BLX     R4                  ; Call with link so we can return
        B       _syscall_table_jump_done
        
syscall_free
        LDR     R4, =0x20007B10     ; load SYS_FREE entry address
        LDR     R4, [R4]            ; fetch address _kfree
        BLX     R4                  ; Call with link so we can return
        B       _syscall_table_jump_done
        
        END


		
