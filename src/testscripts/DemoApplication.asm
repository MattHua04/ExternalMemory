; DemoApplication.asm
;
; An interactive demonstration of the external memory peripheral.
; Uses the circular buffer memory mode of the external memory peripheral to record switch inputs and play them back on the LEDs.

ORG 0

Start:
    ; Display AAAA to represent start
    LOADI &HAA
    SHIFT 8
    ADDI &HAA
    OUT Hex0

    ; Initialize external memory
    LOAD Circular
    OUT ExtMemMode
    LOADI &B111
    OUT ExtMemMeta

    CALL WaitToContinue

; Record switch inputs, stop when left switch goes up
Record:
    CALL SleepShort

    ; Record switch inputs
    IN Switches
    OUT ExtMem
    OUT LEDs

    ; Check for break condition
    SHIFT -9
    AND One
    JZERO Record

; Playback recorded data, stop when left switch goes down
Playback:
    CALL SleepShort
    
    ; Display stored data
    IN ExtMem
    OUT LEDs

    ; Check for break condition
    IN Switches
    SHIFT -9
    AND One
    JPOS Playback

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

; Sleep for about 1/60 seconds
SleepShort:
    LOADI 0
    STORE Count
    Loop:
        LOAD Count
        ADDI 1
        STORE Count
        SUB MaxCount
        JNEG Loop
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
Count: DW 0
MaxCount: DW 13335
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