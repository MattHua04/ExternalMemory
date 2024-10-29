<h1 align="center">GT ECE 2031 Final Project Fall 2024</h1>
<h3 align="center">SCOMP External Memory Peripheral API</h3>

## General I/O:
* A value sent to address 0x71 sets the memory mode and resets the read and write addresses to 0
    * 0b00: Normal
    * 0b01: Stack
    * 0b10: Queue
    * 0b11: Circular buffer
* A value sent to address 0x73 sets the metadata to use in later memory operations
    * Bits 0-13 reserved for access password for restricted data (cleared after every read or write operation for security)
    * Bit 14 for setting address availability where 0 denotes available and 1 denotes unavailable
    * Bit 15 for setting read permissions where 0 denotes unreadable and 1 denotes readable
    * Bit 16 for setting write permissions where 0 denotes unwritable and 1 denotes writable
* A value sent to address 0x74 sets the effective size of the memory in 16-bit words out of a maximum of 2^16 or 65,536 words

## Mode specific I/O:

### Normal mode:
* A value read from address 0x70 returns the data at the current memory address if the metadata allows reading or a matching password is provided in the current metadata register
* A value sent to address 0x70 is written to memory at the current memory address if the metadata allows writing or a matching password is provided in the current metadata register
* A value sent to address 0x72 sets the memory address

### Stack mode:
* A value read from address 0x70 returns the data at the read address, marks the data at the read address as available, and decrements both the read and write addresses if the stack is not empty
* A value sent to address 0x70 is written to memory at the write address and increments both the read and write addresses if the stack is not full

### Queue mode:
* A value read from address 0x70 returns the data at the read address, marks the data at the read address as available, and increments/wraps the read address if behind the write address
* A value sent to address 0x70 is written to memory at the write address and increments/wraps the write address if the queue is not full

### Circular buffer mode:
* A value read from address 0x70 returns the data at the read address, marks the data at the read address as available, and increments/wraps the read address if behind the write address
* A value sent to address 0x70 is written to memory at the write address, increments/wraps the write address, and increments/wraps the read address if the circular buffer is full