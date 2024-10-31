; ExternalMemoryQueueTest.asm
;
; A brief demonstration of the queue memory mode of the external memory peripheral

ORG 0

Start:
    ; Display AAAA to represent start
    LOADI &HAA
    SHIFT 8
    ADDI &HAA
    OUT Hex0
    CALL WaitToContinue

; Test queue memory mode
QueueTest:
; Init
; ==========================
    CALL Clear
    
    ; Set memory size
    CALL WaitToContinue
    IN Switches
    OUT Hex0
    OUT ExtMemResize

    ; Set memory mode to queue
    LOAD Queue
    OUT ExtMemMode

    ; Set metadata to unavailable, read, write
    LOADI &B111
    OUT ExtMemMeta

    CALL WaitToContinue
; ==========================

; Write a series of numbers to the stack
; ==========================
    LOADI 0
    STORE Count
    DataPush:
        LOAD Count
        ADDI 1
        STORE Count
        
        OUT ExtMem
        OUT Hex0
        CALL SleepLong

        LOAD Count
        SUB TestLength
        JNEG DataPush
; ==========================

; Read the data back from the stack
; ==========================
    LOADI 0
    STORE Count
    DataPop:
        LOAD Count
        ADDI 1
        STORE Count

        IN ExtMem
        OUT Hex0
        CALL SleepLong

        LOAD Count
        SUB TestLength
        JNEG DataPop
; ==========================

End:
    ; Display FFFF to represent end
    LOADI &HFF
    SHIFT 8
    ADDI &HFF
    OUT Hex0
    CALL WaitToContinue

JUMP Start

; Wait for left switch to be toggled
WaitToContinue:
    ; Wait for left switch up
    Up:
        CALL Sleep
        IN Switches
        OUT LEDs
        SHIFT -9
        AND One
        JZERO Up
    ; Wait for left switch down
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

; Sleep for 0.5 seconds
SleepLong:
    OUT Timer
    WaitingLoopLong:
        IN Timer
        ADDI -5
        JNEG WaitingLoopLong
    RETURN

; Clear AC and Hex0
Clear:
    LOADI 0
    OUT Hex0
    RETURN

; Variables
One: DW 1
Count: DW 0
TestLength: DW 50
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