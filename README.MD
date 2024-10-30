<h1 align="center">GT ECE 2031 Final Project Fall 2024</h1>
<h3 align="center">SCOMP External Memory Peripheral API</h3>

### General I/O:

---

* A value sent to address ```0x71``` sets the __memory mode__ and __resets the read and write addresses to 0__ (if the passed in mode is not the same as the current mode)
    * ```0b00```: Normal
    * ```0b01```: Stack
    * ```0b10```: Queue
    * ```0b11```: Circular buffer
* A value sent to address ```0x73``` sets the __metadata__ to use in later memory operations
    * Bits __0-13__ set the access password for restricted data __(cleared after every read or write operation for security)__
    * Bit __14__ sets the address availability where __0 = available__ and __1 = unavailable__
    * Bit __15__ sets the read permissions where __0 = unreadable__ and __1 = readable__
    * Bit __16__ sets the write permissions where __0 = unwritable__ and __1 = writable__
* A value sent to address ```0x74``` sets the __effective size__ of the memory in 16-bit words out of a maximum of __2^16__ or __65,536__ words

### Mode specific I/O:

---

#### Normal mode:
* A value read from address ```0x70``` returns the data at the current memory address __(only if the metadata allows reading or a matching password is provided in the current metadata register)__
* A value sent to address ```0x70``` is written to memory at the current memory address __(only if the metadata allows writing or a matching password is provided in the current metadata register)__
* A value sent to address ```0x72``` sets the __memory address__

#### Stack mode:
* A value read from address ```0x70``` returns the data at the read address __(only if the metadata allows reading or a matching password is provided in the current metadata register)__
    * Data at read address is marked available
    * __If the stack is not empty__:
        * Decrements both the read and write addresses
* A value sent to address ```0x70``` is written to memory at the write address __(always writes)__
    * __If the stack is not full__:
        * Increments both the read and write addresses

#### Queue mode:
* A value read from address ```0x70``` returns the data at the read address __(only if the metadata allows reading or a matching password is provided in the current metadata register)__
    * Data at the read address is marked available
    * __If read address is behind write address__:
        * Increments/wraps read address
* A value sent to address ```0x70``` is written to memory at the write address __(always writes)__
    * __If the queue is not full__:
        * Increments/wraps write address

#### Circular buffer mode:
* A value read from address ```0x70``` returns the data at the read address __(only if the metadata allows reading or a matching password is provided in the current metadata register)__
    * Data at the read address is marked available
    * __If read address is behind write address__:
        * Increments/wraps read address
* A value sent to address ```0x70``` is written to memory at the write address __(always writes)__
    * Increments/wraps write address
    * __If the circular buffer is full__:
        * Increments/wraps read address
