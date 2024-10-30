-- ExternalMemory.vhd
-- 2024.10.22
--
-- This peripheral provides up to 2^16 or 65,536 16-bit words of external memory for SCOMP.
-- The memory can be configured to operate in four different modes: normal, stack, queue, and circular buffer.
-- The effective memory size can be set dynamically and metadata can be set for read/write access control.

library ieee;
library lpm;
library altera_mf;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use lpm.lpm_components.all;
use altera_mf.altera_mf_components.all;

entity ExternalMemory is
    port(
        clock      : in    std_logic;
        resetn     : in    std_logic;
        io_write   : in    std_logic;
        cs         : in    std_logic;  -- Chip select: 0x70
        mode_en    : in    std_logic;  -- Set memory mode: 0x71
        addr_en    : in    std_logic;  -- Set memory address: 0x72
        meta_en    : in    std_logic;  -- Set metadata: 0x73
        resize_en  : in    std_logic;  -- Set memory size: 0x74
        io_data    : inout std_logic_vector(15 downto 0);

        dbg_mem_out_data : out std_logic_vector(31 downto 0);
        dbg_mem_addr : out std_logic_vector(15 downto 0);
        dbg_mem_out_data_permitted : out std_logic_vector(31 downto 0);
        dbg_write_addr : out std_logic_vector(15 downto 0);
        dbg_read_addr : out std_logic_vector(15 downto 0);
        dbg_size : out std_logic_vector(31 downto 0);
        dbg_cs: out std_logic
    );
end ExternalMemory;

architecture a of ExternalMemory is
    -- Effective memory size
    signal effective_size : integer := 65536;

    -- Memory device mode signals
    signal mem_mode : std_logic_vector(1 downto 0) := "00";
        -- normal: 00
            -- read: specified address
            -- write: specified address (optional metadata)
        -- stack: 01
            -- read: read from top, decrements both read and write addresses (capped if full)
            -- write: write to top, increments both read and write addresses (capped if full)
        -- queue: 10
            -- read: read from head, increments read address (wrapping)
            -- write: write to tail, increments write address (wrapping) (capped if full)
        -- circular: 11
            -- read: read from head, increments read address (wrapping)
            -- write: write to tail, increments write address (wrapping) (overwrite and increment read address if full)

    -- Metadata signal
    signal mem_meta : std_logic_vector(15 downto 0) := (15 downto 3 => '0') & "111";
        -- left 13 bits (not cached so must be passed in for every operation on restricted data): password for access to read or write only data
        -- availability (cached): 0: available, 1: unavailable
        -- read permission (cached): 0: no, 1: yes
        -- write permission (cached): 0: no, 1: yes

    -- Read/write operation signals
    signal io_out : std_logic;  -- Read access control
    signal read_addr : integer := 0;  -- Read address for stack/queue/circular modes
    signal write_addr : integer := 0;  -- Write address for stack/queue/circular modes
    signal mem_out_data_permitted : std_logic_vector(31 downto 0);  -- Permission filtered output data

    -- Altsyncram signals
    -- Port A: mainly handles write/pop operations, used to read in normal mode
    signal mem_addr_a             : std_logic_vector(15 downto 0);
    signal mem_in_data_a          : std_logic_vector(31 downto 0);
    signal mem_out_data_a         : std_logic_vector(31 downto 0);
    signal write_enable           : std_logic := '0';
    -- Port B: only handles read operations
    signal mem_addr_b             : std_logic_vector(15 downto 0);
    signal mem_in_data_b          : std_logic_vector(31 downto 0);
    signal mem_out_data_b         : std_logic_vector(31 downto 0);

begin
    -- Debug
    dbg_mem_out_data <= mem_out_data_b;
    dbg_mem_out_data_permitted <= mem_out_data_permitted;
    dbg_mem_addr <= mem_addr_a;
    dbg_write_addr <= std_logic_vector(to_unsigned(write_addr, 16));
    dbg_read_addr <= std_logic_vector(to_unsigned(read_addr, 16));
    dbg_size <= std_logic_vector(to_unsigned(effective_size, 32));
    dbg_cs <= cs;

    -- Dual port altsyncram component
    altsyncram_component: altsyncram
        generic map (
            operation_mode => "BIDIR_DUAL_PORT",
            width_a => 32,
            width_B => 32,
            numwords_a => 65536,
            numwords_b => 65536,
            outdata_reg_a => "UNREGISTERED",
            outdata_reg_b => "UNREGISTERED",
            widthad_a => 16,
            widthad_b => 16,
            init_file => "ExternalMemoryInit.mif"
        )
        port map (
            clock0    => clock,
            clock1    => clock,
            wren_a    => write_enable,
            wren_b    => '0',
            rden_a    => '1',
            rden_b    => '1',
            address_a => mem_addr_a,
            address_b => mem_addr_b,
            data_a    => mem_in_data_a,
            data_b    => mem_in_data_b,
            q_a       => mem_out_data_a,
            q_b       => mem_out_data_b
        );

    -- Bidirectional I/O bus management
    io_bus: lpm_bustri
        generic map (
            lpm_width => 16
        )
        port map (
            data     => mem_out_data_permitted(15 downto 0),
            enabledt => io_out,
            tridata  => io_data
        );

    -- Control memory read access
    io_out <= (cs and not(io_write));
    process(clock)
    begin
        if (rising_edge(clock)) then
            -- Check read permission in stack, queue, and circular modes, override if password matches metadata
            if mem_mode /= "00" and (mem_out_data_b(18) = '0' or mem_out_data_b(17) = '1' or mem_meta(15 downto 3) = mem_out_data_b(31 downto 19)) then
                mem_out_data_permitted <= mem_out_data_b;
            -- Check for valid read address and read permission in normal mode, override if password matches metadata
            elsif mem_mode = "00" and (to_integer(unsigned(mem_addr_a)) < effective_size) and (mem_out_data_a(18) = '0' or mem_out_data_a(17) = '1' or mem_meta(15 downto 3) = mem_out_data_a(31 downto 19)) then
                mem_out_data_permitted <= mem_out_data_a;
            else
                mem_out_data_permitted <= (others => '0');  -- Null output if access denied
            end if;
        end if;
    end process;

    -- Main memory control process
    process (clock, resetn)
    begin
        if resetn = '0' then
            mem_mode <= "00";  -- Reset to normal mode
            effective_size <= 65536;  -- Reset effective size
            mem_meta <= (others => '0');  -- Reset metadata
            write_enable <= '0';  -- Disable writing
            read_addr <= 0;  -- Reset read address
            write_addr <= 0;  -- Reset write address
            mem_addr_a <= (others => '0');
            mem_addr_b <= (others => '0');
        
        elsif (rising_edge(clock)) then
            -- Setting memory device mode, address, and metadata based on IO address
            if (mode_en = '1') then
                mem_mode <= io_data(1 downto 0);  -- Set mode
                if (mem_mode /= io_data(1 downto 0)) then
                    read_addr <= 0;  -- Reset read address on mode change
                    write_addr <= 0;  -- Reset write address on mode change
                    mem_addr_a <= (others => '0');
                    mem_addr_b <= (others => '0');
                end if;
            -- Only set address in normal mode
            elsif (addr_en = '1' and mem_mode = "00") then
                mem_addr_a <= io_data;
            -- Set metadata
            elsif (meta_en = '1') then
                mem_meta <= io_data;
            -- Resize memory
            elsif (resize_en = '1') then
                effective_size <= to_integer(unsigned(io_data));
            -- Write to memory
            elsif (cs = '1' and io_write = '1') then
                mem_meta(15 downto 3) <= (others => '0');  -- Clear password bits on write for security
                case mem_mode is
                    when "00" =>  -- Normal mode
                        -- Load data to be written to memory
                        mem_in_data_a(31 downto 16) <= mem_meta;  -- Load metadata
                        mem_in_data_a(15 downto 0) <= io_data;  -- Load data

                        -- Check for valid write address and metadata for write permission from the memory output data
                        if (to_integer(unsigned(mem_addr_a)) < effective_size) and ((mem_out_data_a(16) = '1') or (mem_out_data_a(18) = '0') or (mem_meta(15 downto 3) = mem_out_data_a(31 downto 19))) then
                            write_enable <= '1';
                        else
                            write_enable <= '0';
                        end if;

                    when "01" =>  -- Stack mode
                        mem_in_data_a(31 downto 16) <= mem_meta;  -- Load metadata
                        mem_in_data_a(15 downto 0) <= io_data;  -- Load data
                        mem_addr_a <= std_logic_vector(to_unsigned(write_addr, 16));  -- Set memory address to write to

                        -- Cap read and write addresses, don't write when full
                        if (read_addr < (effective_size - 1) and write_addr < effective_size) then
                            read_addr <= write_addr;  -- Set read address to previous write address
                            mem_addr_b <= std_logic_vector(to_unsigned(write_addr, 16));  -- Watch read address for future popping
                            write_addr <= write_addr + 1;  -- Increment write address
                            write_enable <= '1';
                        else
                            write_enable <= '0';
                        end if;

                    when "10" =>  -- Queue mode
                        mem_in_data_a(31 downto 16) <= mem_meta;  -- Load metadata
                        mem_in_data_a(15 downto 0) <= io_data;  -- Load data
                        mem_addr_a <= std_logic_vector(to_unsigned(write_addr, 16));  -- Set memory address tp write to
                        mem_addr_b <= std_logic_vector(to_unsigned(read_addr, 16));  -- Watch read address for future popping
                        -- Cap write address if full, don't write when full
                        if (write_addr + 1 /= read_addr and write_addr < (effective_size - 1)) then
                            write_addr <= write_addr + 1;  -- Increment write address
                            write_enable <= '1';
                        -- Wrap write address
                        elsif (write_addr = (effective_size - 1) and read_addr /= 0) then
                            write_addr <= 0;
                            write_enable <= '1';
                        else
                            write_enable <= '0';
                        end if;

                    when "11" =>  -- Circular mode
                        mem_in_data_a(31 downto 16) <= mem_meta;  -- Load metadata
                        mem_in_data_a(15 downto 0) <= io_data;  -- Load data
                        mem_addr_a <= std_logic_vector(to_unsigned(write_addr, 16));  -- Set memory address to write to

                        if (write_addr + 1 = read_addr or (write_addr = (effective_size - 1) and read_addr = 0)) then
                            read_addr <= read_addr + 1;  -- Increment read address if full
                            mem_addr_b <= std_logic_vector(to_unsigned(read_addr + 1, 16));  -- Watch read address for future popping
                        else
                            mem_addr_b <= std_logic_vector(to_unsigned(read_addr, 16));  -- Watch read address for future popping
                        end if;

                        -- Wrap write address
                        if write_addr = (effective_size - 1) then
                            write_addr <= 0;
                        else
                            write_addr <= write_addr + 1;  -- Increment write address
                        end if;

                        -- Always enable writing in circular mode
                        write_enable <= '1';

                    when others =>  -- Default case
                        write_enable <= '0';  -- Disable writing in all other cases
                end case;
            -- Read from memory
            elsif (cs = '1' and io_write = '0') then
                mem_meta(15 downto 3) <= (others => '0');  -- Clear password bits on read for security
                case mem_mode is
                    when "00" =>  -- Normal mode
                        write_enable <= '0';

                    when "01" =>  -- Stack mode
                        mem_addr_a <= std_logic_vector(to_unsigned(read_addr, 16));  -- Set address to pop from
                        mem_in_data_a <= mem_out_data_b;  -- Preserve data and permissions
                        mem_in_data_a(18) <= '0';  -- Mark as available
                        write_enable <= '1';

                        -- Update addresses
                        if read_addr > 0 then
                            read_addr <= read_addr - 1;  -- Decrement read address
                            mem_addr_b <= std_logic_vector(to_unsigned(read_addr - 1, 16));  -- Watch read address for future popping
                        else
                            mem_addr_b <= std_logic_vector(to_unsigned(read_addr, 16));  -- Watch read address for future popping
                        end if;
                        if write_addr > 0 then
                            write_addr <= write_addr - 1;  -- Decrement write address
                        end if;

                    when "10" =>  -- Queue mode
                        mem_addr_a <= std_logic_vector(to_unsigned(read_addr, 16));  -- Set address to pop from
                        mem_in_data_a <= mem_out_data_b;  -- Preserve data and permissions
                        mem_in_data_a(18) <= '0';  -- Mark as available
                        write_enable <= '1';

                        -- Update read address
                        if read_addr = (effective_size - 1) then
                            -- Wrap read address
                            read_addr <= 0;
                            mem_addr_b <= std_logic_vector(to_unsigned(0, 16));  -- Watch read address for future popping
                        elsif read_addr < write_addr then
                            read_addr <= read_addr + 1;  -- Increment read address
                            mem_addr_b <= std_logic_vector(to_unsigned(read_addr + 1, 16));  -- Watch read address for future popping
                        end if;

                    when "11" =>  -- Circular mode
                        mem_addr_a <= std_logic_vector(to_unsigned(read_addr, 16));  -- Set address to pop from
                        mem_in_data_a <= mem_out_data_b;  -- Preserve data and permissions
                        mem_in_data_a(18) <= '0';  -- Mark as available
                        write_enable <= '1';

                        -- Update read address
                        if read_addr = (effective_size - 1) then
                            read_addr <= 0;  -- Wrap read address
                            mem_addr_b <= std_logic_vector(to_unsigned(0, 16));  -- Watch read address for future popping
                        elsif read_addr < write_addr then
                            read_addr <= read_addr + 1;  -- Increment read address
                            mem_addr_b <= std_logic_vector(to_unsigned(read_addr + 1, 16));  -- Watch read address for future popping
                        end if;

                    when others =>  -- Default case
                        write_enable <= '0';  -- Disable writing in all other cases
                end case;
            else
                write_enable <= '0';  -- Disable writing in all other cases
            end if;
        end if;
    end process;

end a;