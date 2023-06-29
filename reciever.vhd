--receiver same as assignment 7

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity UART_R is
port (
clk : in std_logic;
i_R_Serial : in std_logic;

rst: in std_logic;



--an : out std_logic_vector(3 downto 0);
--seg : out std_logic_vector(6 downto 0);
output : out std_logic_vector(7 downto 0);
done : out std_logic

);
end UART_R;


architecture RTL_R of UART_R is

type states is (s_Idle, s_R_Start_Bit, s_R_Data_Bits,
s_R_Stop_Bit, s_Cleanup);


signal r_state : states := s_Idle;

signal counter : integer range 0 to 10415 := 0;
signal r_Bit_Index : integer range 0 to 7 := 0; -- 8 Bits Total


signal r_Byte : std_logic_vector(7 downto 0) := (others => '0');

--edit by gaurav
--signal display_number: STD_LOGIC_VECTOR(15 downto 0):= (others => '0');

--signal refresh_counter : STD_LOGIC_VECTOR(31 downto 0);

--signal sel : STD_LOGIC_VECTOR(1 downto 0);


--signal temp_num: STD_LOGIC_VECTOR(3 downto 0);


begin

--process(clk)
--begin
--if(rising_edge(clk)) then
--refresh_counter <= refresh_counter + 1;
--end if;
--end process;


--sel <= refresh_counter(19 downto 18);


--process(temp_num)

--begin
--case temp_num is
--when "0000" => seg <= "1000000";
--when "0001" => seg <= "1111001";
--when "0010" => seg <= "0100100";
--when "0011" => seg <= "0110000";
--when "0100" => seg <= "0011001";
--when "0101" => seg <= "0010010";
--when "0110" => seg <= "0000010";
--when "0111" => seg <= "1111000";
--when "1000" => seg <= "0000000";
--when "1001" => seg <= "0010000";
--when "1010" => seg <= "0001000";
--when "1011" => seg <= "0000011";
--when "1100" => seg <= "1000110";
--when "1101" => seg <= "0100001";
--when "1110" => seg <= "0000110";
--when "1111" => seg <= "0001110";
--when others => seg <= "1111111";
--end case;

--end process;



--process(sel)

--begin

--case sel is
--when "00" =>
--an(0) <= '1';
--an(1) <= '1';
--an(2) <= '1';
--an(3) <= '1';

--when "01" => an(0) <= '1';
--an(1) <= '1';
--an(2) <= '1';
--an(3) <= '1';

--when "10" => an(0) <= '1';
--an(1) <= '0';
--an(2) <= '1';
--an(3) <= '1';
--temp_num <= r_Byte(7 downto 4);

--when others => an(0) <= '0';
--an(1) <= '1';
--an(2) <= '1';
--an(3) <= '1';
--temp_num <= r_Byte(3 downto 0);
--end case;



--end process;

-- Purpose: Control RX state machine
p_UART_R : process (clk)
begin

if rising_edge(clk) then

if(rst= '1') then-- all things are cleared

--refresh_counter<=(others=>'0');
r_state <= s_Idle;
r_Byte <= (others=>'0');
r_Bit_Index <= 0;
counter<=0;

end if;


case r_state is

when s_Idle =>

done<= '0'; --we make done =0

counter <= 0;
r_Bit_Index <= 0;

if i_R_Serial = '0' then -- Start bit detected
r_state <= s_R_Start_Bit; --move to next state
else
r_state <= s_Idle; --else remain in same state
end if;


-- Check middle of start bit to make sure it's still low
--if it is '0' move to next state and reset counter
--else move back to idle state

--in this state(s_R_Start_Bit) : increase the counter counter
--by with each rising edge , it remain in the same state

when s_R_Start_Bit => 
if counter = (10415)/2 then
if i_R_Serial = '0' then
counter <= 0; -- reset counter since we found the middle
r_state <= s_R_Data_Bits;
else
r_state <= s_Idle;
end if;
else
counter <= counter + 1;

end if;


-- Wait g_CLKS_PER_BIT-1 clock cycles to sample serial data
--in this state after each g_CLKS_PER_BIT clock cycles we
--are sampling the data i.e puting the input bit into our
--final 8 byte register register
--after filling our all the 8 bits we go to next state s_R_Stop_Bit
when s_R_Data_Bits =>
if counter < 10415 then
counter <= counter + 1;

else
counter <= 0;
r_Byte(r_Bit_Index) <= i_R_Serial ;

-- Check if we have sent out all bits
if r_Bit_Index < 7 then
r_Bit_Index <= r_Bit_Index + 1;

else
r_Bit_Index <= 0;
r_state <= s_R_Stop_Bit;
end if;
end if;


-- Receive Stop bit. Stop bit = 1


when s_R_Stop_Bit => 
-- Wait g_CLKS_PER_BIT-1 clock cycles for Stop bit to finish
if counter < 10415 then
counter <= counter + 1;

else

counter <= 0;
r_state <= s_Cleanup;

done <= '1'; --we receive all 8 bits and stop bit
end if;


-- Stay here 1 clock
when s_Cleanup =>
r_state <= s_Idle;

when others =>

r_state <= s_Idle;

end case;
end if;
end process p_UART_R;

output <= r_Byte; --calculating that 8 byte number


end RTL_R;