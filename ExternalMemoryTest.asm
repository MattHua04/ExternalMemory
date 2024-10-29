; ExternalMemoryTest.asm

ORG 0

Start:
    ; Display AAAA to represent start
    LOADI &HAA
    SHIFT 8
    ADDI &HAA
    OUT Hex0
    CALL WaitToContinue

; Test normal memory mode
NormalTest:
; Init
; ==========================
    ; Set memory size
    LOADI 100
    OUT ExtMemResize

    ; Set memory mode to normal
    LOAD Normal
    OUT ExtMemMode
; ==========================
; Write data to addr 0
; ==========================
    ; Set data password
    LOADI &HAB
    SHIFT 3
    ; Set metadata to unavailable, /read, write
    ADDI &B101
    OUT ExtMemMeta
    ; Set address to 0
LOADI 0
    OUT ExtMemAddr
    ; Write some data to external memory
    LOADI &H12
    OUT Hex0
    OUT ExtMem
    CALL WaitToContinue
; ==========================

; Write data to addr 11
; ==========================
    ; Set data password
    LOADI &HAB
    SHIFT 3
    ; Set metadata to unavailable, /read, write
    ADDI &B101
    OUT ExtMemMeta

    ; Set address to 11
    LOADI 11
    OUT ExtMemAddr
    ; Write some data to external memory
    LOADI &H34
    OUT Hex0
    OUT ExtMem
    CALL WaitToContinue
; ; ==========================

; Write data to addr 22
; ==========================
    ; Set data password
    LOADI &HAB
    SHIFT 3
    ; Set metadata to unavailable, read, /write
    ADDI &B110
    OUT ExtMemMeta

    ; Set address to 22
    LOADI 22
    OUT ExtMemAddr
    ; Write some data to external memory
    LOADI &H56
    OUT Hex0
    OUT ExtMem
    CALL WaitToContinue
; ==========================

; Read data from addr 0 without password (access denied)
; ==========================
    LOADI 0
    OUT ExtMemAddr
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Read data from addr 11 with password (access granted)
; ==========================
    ; Set data password
    LOADI &HAB
    SHIFT 3
    OUT ExtMemMeta
    ; Read from address 11
    LOADI 11
    OUT ExtMemAddr
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
; ==========================
; Write data to addr 22 without password (access denied)
; ==========================
    ; Set address to 22
 	LOADI 22
    OUT ExtMemAddr

    ; Write some data to external memory without password
    LOADI &H78
    OUT Hex0
    OUT ExtMem
    CALL WaitToContinue

    ; Read the data back from address 22 to verify it was not written
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Write data to addr 22 with password (access granted)
; ==========================
    ; Set data password
    LOADI &HAB
    SHIFT 3
    ; Set metadata to unavailable, read, write
    ADDI &B111
    OUT ExtMemMeta

    ; Write some data to external memory with password (access granted)
    LOADI &H78
    OUT Hex0
    OUT ExtMem
    CALL WaitToContinue

    ; Read the data back from address 22 to verify it was written
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test stack memory mode
StackTest:
; Init
; ==========================
    ; Set memory size
    LOADI 100
    OUT ExtMemResize

    ; Set memory mode to stack
    LOAD Stack
    OUT ExtMemMode

    ; Set metadata to unavailable, read, write
    LOADI &B111
    OUT ExtMemMeta
; ==========================

; Write 1, 2, 3 to external memory
; ==========================
    LOADI 1
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue

    LOADI 2
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue

    LOADI 3
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue

	LOADI 0 ; Clear AC
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Read the data back (should be 3, 2, 1)
; ==========================
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test queue memory mode
QueueTest:
; Init
; ==========================
    ; Set memory size
    LOADI 100
    OUT ExtMemResize

    ; Set memory mode to queue
    LOAD Queue
    OUT ExtMemMode

    ; Set metadata to unavailable, read, write
    LOADI &B111
    OUT ExtMemMeta
; ==========================

; Write 1, 2, 3 to external memory
; ==========================
    LOADI 1
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue

    LOADI 2
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue

    LOADI 3
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue
    
	LOADI 0 ; Clear AC
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Read the data back (should be 1, 2, 3)
; ==========================
    ; Read the data back
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test circular buffer memory mode
CircularTest:
; Init
; ==========================
    ; Set memory size
    LOADI 100
    OUT ExtMemResize

    ; Set memory mode to queue
    LOAD Circular
    OUT ExtMemMode

    ; Set metadata to unavailable, read, write
    LOADI &B111
    OUT ExtMemMeta
; ==========================

; Write 1, 2, 3 to external memory
; ==========================
    LOADI 1
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue

    LOADI 2
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue

    LOADI 3
    OUT ExtMem
    OUT Hex0
    CALL WaitToContinue
    
	LOADI 0 ; Clear AC
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Read the data back (should be 1, 2, 3)
; ==========================
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
    IN ExtMem
    OUT Hex0
    CALL WaitToContinue
; ==========================

End:
    ; Display FFFF to represent end
    LOADI &HFF
    SHIFT 8
    ADDI &HFF
    OUT Hex0
    CALL WaitToContinue

JUMP Start

; Wait for switch to be toggled
WaitToContinue:
    ; Wait for switch up
    Up:
        CALL Sleep
        IN Switches
        OUT LEDs
        AND One
        JZERO Up
    ; Wait for switch down
    Down:
        CALL Sleep
        IN Switches
        OUT LEDs
        AND One
        JPOS Down
    RETURN

; Sleep for 0.1 seconds
Sleep:
    OUT Timer
    WaitingLoop:
        IN Timer
        ADDI -1
        JNEG WaitingLoop
    RETURN

; Variables
One: DW 1
Normal: DW &B00
Stack: DW &B01
Queue: DW &B10
Circular: DW &B11

; IO address constants
Switches: EQU 000
LEDs: EQU 001
Timer: EQU 002
Hex0: EQU 004
Hex1: EQU 005
ExtMem: EQU &H070
ExtMemMode: EQU &H071
ExtMemAddr: EQU &H072
ExtMemMeta: EQU &H073
ExtMemResize: EQU &H074