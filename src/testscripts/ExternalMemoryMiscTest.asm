; ExternalMemoryMiscTest.asm
;
; A brief demonstration of some miscellaneous functionality of the external memory peripheral

ORG 0

Start:
    ; Display AAAA to represent start
    LOADI &HAA
    SHIFT 8
    ADDI &HAA
    OUT Hex0
    CALL WaitToContinue

; Test memory mode retrieval
MemModeTest:
; Init
; ==========================
    ; Display BBBB
    LOADI &HBB
    SHIFT 8
    ADDI &HBB
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test normal memory mode
; ==========================
    ; Set memory mode to normal
    LOAD Normal
    OUT ExtMemMode
    OUT Hex0
    CALL WaitToContinue

    CALL Clear
    CALL WaitToContinue

    ; Retrieve memory mode
    IN ExtMemMode
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test stack memory mode
; ==========================
    CALL Clear

    ; Set memory mode to stack
    LOAD Stack
    OUT ExtMemMode
    OUT Hex0
    CALL WaitToContinue

    CALL Clear
    CALL WaitToContinue

    ; Retrieve memory mode
    IN ExtMemMode
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test queue memory mode
; ==========================
    CALL Clear

    ; Set memory mode to queue
    LOAD Queue
    OUT ExtMemMode
    OUT Hex0
    CALL WaitToContinue

    CALL Clear
    CALL WaitToContinue

    ; Retrieve memory mode
    IN ExtMemMode
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test circular memory mode
; ==========================
    CALL Clear

    ; Set memory mode to circular
    LOAD Circular
    OUT ExtMemMode
    OUT Hex0
    CALL WaitToContinue

    CALL Clear
    CALL WaitToContinue

    ; Retrieve memory mode
    IN ExtMemMode
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test memory address retrieval
MemAddrTest:
; Init
; ==========================
    ; Display CCCC
    LOADI &HCC
    SHIFT 8
    ADDI &HCC
    OUT Hex0

    ; Set memory mode to normal
    LOAD Normal
    OUT ExtMemMode

    ; Set memory size to max
    LOADI &HFF
    SHIFT 8
    ADDI &HFF
    OUT ExtMemResize
    CALL WaitToContinue
; ==========================

; Test memory address retrieval
; ==========================
    CALL Clear

    ; Set memory address to 0x22
    LOADI &H22
    OUT ExtMemAddr
    OUT Hex0
    CALL WaitToContinue

    CALL Clear
    CALL WaitToContinue

    ; Retrieve memory address
    IN ExtMemAddr
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test memory metadata retrieval
MemMetaTest:
; Init
; ==========================
    ; Display DDDD
    LOADI &HDD
    SHIFT 8
    ADDI &HDD
    OUT Hex0
; ==========================

; Test memory metadata retrieval
; ==========================
    CALL Clear

    ; Set memory metadata to 0b101
    LOADI &B101
    OUT ExtMemMeta
    OUT Hex0
    CALL WaitToContinue

    CALL Clear
    CALL WaitToContinue

    ; Retrieve memory metadata
    IN ExtMemMeta
    OUT Hex0
    CALL WaitToContinue
; ==========================

; Test memory resize
MemResizeTest:
; Init
; ==========================
    ; Display EEEE
    LOADI &HEE
    SHIFT 8
    ADDI &HEE
    OUT Hex0
; ==========================

; Test memory resize
; ==========================
    CALL Clear

    ; Set memory size to 0x55
    LOADI &H55
    OUT ExtMemResize
    OUT Hex0
    CALL WaitToContinue

    CALL Clear
    CALL WaitToContinue

    ; Retrieve memory size
    IN ExtMemResize
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

WaitToContinue:
    ; Wait for switch up
    Up:
        CALL Sleep
        IN Switches
        OUT LEDs
        SHIFT -9
        AND One
        JZERO Up
    ; Wait for switch down
    Down:
        CALL Sleep
        IN Switches
        OUT LEDs
        SHIFT -9
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

; Clear AC and Hex0
Clear:
    LOADI 0
    OUT Hex0
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