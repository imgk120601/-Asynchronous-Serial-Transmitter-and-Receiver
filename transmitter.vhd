----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
-- This file contains the UART Transmitter. This transmitter is able
-- to transmit 8 bits of serial data, one start bit, one stop bit,
-- and no parity bit. When transmit is complete o_TX_Done will be
-- driven high for one clock cycle.
--
-- Set Generic g_CLKS_PER_BIT as follows:
-- g_CLKS_PER_BIT = (Frequency of clk)/(Frequency of UART)
-- Example: 10 MHz Clock, 115200 baud UART
-- (10000000)/(115200) = 87
--
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity UART_T is
port (
clk : in std_logic;
ld_tx : in std_logic; -- it telles u whether your 8 bit input are ready or not for the processing
-- ld_tx: in std_logic;--load 8 bits input in transmitter's personal register
--here r_T_Data is tranmitter's personal register
i_T_Byte : in std_logic_vector(7 downto 0);
output : out std_logic;
rst : in std_logic;
sent: out std_logic


);
end UART_T;


architecture RTL_T of UART_T is

type states is (s_Idle, s_T_Start_Bit, s_T_Data_Bits,
s_T_Stop_Bit, s_Cleanup);
signal r_state : states := s_Idle;

signal counter : integer range 0 to 10415 := 0;
signal r_Bit_Index : integer range 0 to 7 := 0; -- 8 Bits Total
signal r_T_Data: std_logic_vector(7 downto 0) := (others => '0');
signal personal_register_loaded : std_logic :='0';

begin

process (clk)
begin

if(rst= '1') then

r_state <= s_Idle;
counter<=0;
output<='1';
r_Bit_Index<=0;
r_T_Data <= (others=>'0');

elsif rising_edge(clk) then
case r_state is

--in this we are sending just '1' - it means we have
--yet not send our start bit i.e '0' -> 10415 times
when s_Idle =>

output <= '1'; -- Drive Line High for Idle
counter <= 0;
r_Bit_Index <= 0;
sent<='0';

--if data is received
--we store our 8 byte input into r_TX_Data
--and move to next state

--here r_T_Data is tranmitter's personal register

-- if(ld_tx = '1') then
-- r_T_Data <= i_T_Byte;
-- personal_register_loaded <= '1';
-- end if;

if (ld_tx = '1') then
r_T_Data<= i_T_Byte;
r_state <= s_T_Start_Bit;
else
r_state <= s_Idle;
end if;


-- Send out Start Bit. Start bit = 0
--in this state we are sending '0' 10415 times
-- it our start bit btw
--after sending sending 10415 zeros we move to next state

when s_T_Start_Bit =>

output <= '0';

-- Wait g_CLKS_PER_BIT-1 clock cycles for start bit to finish
if counter < 10415 then
counter <= counter + 1;
else
counter <= 0;
r_state <= s_T_Data_Bits;
end if;


-- Wait g_CLKS_PER_BIT-1 clock cycles for data bits to finish
--we are sending every byte of the data 10415 times
--and after we send all our bits we move to next state

when s_T_Data_Bits => output <= r_T_Data(r_Bit_Index);



if counter < 10415 then
counter <= counter + 1;
else
counter <= 0;

-- Check if we have sent out all bits
if r_Bit_Index < 7 then
r_Bit_Index <= r_Bit_Index + 1;
else
r_Bit_Index <= 0;
r_state <= s_T_Stop_Bit;
end if;
end if;


-- Send out Stop bit. Stop bit = 1

--in this state we send '1' 10415 denoting end bit
when s_T_Stop_Bit => output <= '1';


-- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
if counter < 10415 then
counter <= counter + 1;
else
counter <= 0;
r_state <= s_Cleanup;
sent<='1';
end if;


-- Stay here 1 clock
when s_Cleanup =>
r_state <= s_Idle;
personal_register_loaded <= '0';--at this st
when others =>

r_state <= s_Idle;

end case;


end if;

end process ;


end RTL_T;