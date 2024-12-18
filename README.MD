<h1 align="center">GT ECE 2031 Final Project Fall 2024</h1>
<h3 align="center">SCOMP External Memory Peripheral Usage</h3>
<div align="center">
<a href="docs/SCOMP_External_Memory_Peripheral_API.pdf">View the peripheral API for additional details</a>
</div>

### General I/O:

__In:__
* A value read from address ```0x71``` corresponds with the numerical identifier of the current __memory mode__ (see below for details)
* A value read from address ```0x72``` corresponds with the current __write address__
* A value read from address ```0x73``` corresponds with the current metadata __excluding the access password__
* A value read from address ```0x74``` corresponds with the current __effective memory size__

__Out:__
* A value sent to address ```0x71``` sets the __memory mode__ and __resets the read and write addresses to 0__
    * ```0b00```: Normal
    * ```0b01```: Stack
    * ```0b10```: Queue
    * ```0b11```: Circular buffer
* A value sent to address ```0x73``` sets the __metadata__ to use in later memory operations
    * Bit ordering from left to right 0-16
    * Bits __0-13__ set the __access password__ for restricted data __(cleared after every read or write operation for security)__
    * Bit __14__ sets the __address availability__ where ```0 = available``` and ```1 = unavailable```
    * Bit __15__ sets the __read permissions__ where ```0 = restricted``` and ```1 = unrestricted```
    * Bit __16__ sets the __write permissions__ where ```0 = restricted``` and ```1 = unrestricted```
* A value sent to address ```0x74``` sets the __effective size__ of the memory peripheral in 16-bit words out of a maximum of __2^16__ or __65,536__ words

### Mode specific I/O:

#### Normal mode:
* Reading from address ```0x70``` returns the data at the current memory address __(only if the metadata allows reading or a matching password is provided in the current metadata register)__
* A value sent to address ```0x70``` is written to memory at the current memory address __(only if the metadata allows writing or a matching password is provided in the current metadata register)__
* A value sent to address ```0x72``` sets the __memory address__ for subsequent memory operations

#### Stack mode:
* Reading from address ```0x70``` returns the data at the read address __(only if the metadata allows reading or a matching password is provided in the current metadata register)__
    * Data at the read address is marked available
    * __If the stack is not empty__:
        * Decrements both the read and write addresses
* A value sent to address ```0x70``` is written to memory at the write address __(only if the stack is not full, write permissions at target address ignored)__
    * __If the stack is not full__:
        * Increments both the read and write addresses

#### Queue mode:
* Reading from address ```0x70``` returns the data at the read address __(only if the metadata allows reading or a matching password is provided in the current metadata register)__
    * Data at the read address is marked available
    * __If the read address is behind the write address__:
        * Increments/wraps the read address
* A value sent to address ```0x70``` is written to memory at the write address __(only if the queue is not full, write permissions at target address ignored)__
    * __If the queue is not full__:
        * Increments/wraps the write address

#### Circular buffer mode:
* Reading from address ```0x70``` returns the data at the read address __(only if the metadata allows reading or a matching password is provided in the current metadata register)__
    * Data at the read address is marked available
    * __If the read address is behind the write address__:
        * Increments/wraps the read address
* A value sent to address ```0x70``` is written to memory at the write address __(only if the circular buffer is not full, write permissions at target address ignored)__
    * Increments/wraps the write address
    * __If the circular buffer is full__:
        * Increments/wraps the read address
