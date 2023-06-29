----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/29/2022 12:06:39 PM
-- Design Name: 
-- Module Name: temp - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
generic(
max_counter: integer:=10416
);
Port (
clk: in std_logic;
rst: in std_logic;
an : out STD_LOGIC_VECTOR(3 downto 0);
seg : out STD_LOGIC_VECTOR(6 downto 0);
RsRx: in std_logic;
RsTx: out std_logic;

PB0 : in std_logic;--for reset transmitter, reciever, timing circuit

PB1 : in std_logic;--for tx_start signal to timing circuit

full : out std_logic;

empty : out std_logic
);
end main;

architecture Behavioral of main is

type states is (idle, rx_wait, rx_done,
tx_begin,tx_pre_wait , tx_wait);


signal state : states := Idle;


signal reciever_output :std_logic_vector(7 downto 0);

signal rx_full : std_logic;

signal transmitter_input: std_logic_vector(7 downto 0);

signal ld_tx : std_logic := '0';

signal tx_empty: std_logic;

signal tx_start : std_logic;

signal size_of_fifo : integer range -1 to 18 :=0;

signal bram_write_index : std_logic_vector (2 downto 0);
signal bram_input : std_logic_vector(7 downto 0);
signal bram_output : std_logic_vector(7 downto 0);

signal bram_we : std_logic_vector(0 to 0) := "0";
signal bram_e_write: std_logic:='0' ;
signal bram_read_index: std_logic_vector(2 downto 0);

signal bram_e_read : std_logic:='0';
signal reset_signal : std_logic :='0';

signal display_number: STD_LOGIC_VECTOR(7 downto 0):= (others => '0');

signal refresh_counter : STD_LOGIC_VECTOR(31 downto 0);

signal sel : STD_LOGIC_VECTOR(1 downto 0);
signal pb: std_logic;

signal temp_num: STD_LOGIC_VECTOR(3 downto 0);

signal read_index : unsigned(2 downto 0):= "000";
signal write_index : unsigned(2 downto 0):= "000";
signal counter: integer:=1;
begin

Debouncer: entity work.debouncer (Behavioral)
port map(
clk=>clk,
input=>PB1,
output=>pb
);


Reciever: entity work.UART_R(RTL_R)
port map(
clk => clk,
i_R_Serial => RsRx,
output => reciever_output,
done => rx_full,
rst =>PB0

--an => an,

--seg => seg

);


BRAM: entity work.BRAM_wrapper (STRUCTURE)
port map(

BRAM_PORTA_addr => bram_write_index,
BRAM_PORTA_clk => clk,
BRAM_PORTA_din => reciever_output,
BRAM_PORTB_dout => bram_output,

BRAM_PORTA_we => bram_we,

BRAM_PORTA_en =>bram_e_write,
BRAM_PORTB_addr =>bram_read_index,
BRAM_PORTB_clk =>clk,

BRAM_PORTB_en => bram_e_read
);


transmitter: entity work. UART_T(RTL_T)

port map(

clk =>clk,
ld_tx => ld_tx, -- it telles u whether your 8 bit input are ready or not for the processing
i_T_Byte =>bram_output,
output => RsTx,
rst=>PB0,
sent=>tx_empty

);

process(clk)
begin
    if PB0='1' then
        reset_signal<='1';
        size_of_fifo<= 0;
        read_index <= "000";
        write_index <= "000";
        bram_e_write<='0';
        bram_e_read<='0';
        state<=idle;
        counter<=1;
        
    elsif rising_edge(clk) then
        counter<=counter+1;
        if counter=10416 then
            counter<=1;
        end if;
        ld_tx<='0';
        if (pb='1' and size_of_fifo >0) then
            tx_start<='1';
            rx_full<='0';
            state<=idle;
        elsif(pb = '0') then
            tx_start <= '0';
            state<=idle;
        
        end if;
        
        if(size_of_fifo <=0) then
            empty <= '1';
            full <= '0';
        elsif(size_of_fifo >=8) then
            full <= '1';
            empty <= '0';
        else
            full <= '0';
            empty <= '0';
        end if;
        
        case state is
     
        when idle=>
            if rx_full='0' and tx_start='0' and PB0='0' and size_of_fifo<8 then
                bram_e_read <= '0';
                bram_e_write<= '1';
                state<=rx_wait;
            elsif tx_start='1' and PB0='0' and size_of_fifo>0 then
                bram_e_read <= '1';
                bram_e_write<= '0';
                state<=tx_begin;
            else
                state<=idle;
            end if;
--            if rx_full='1' and size_of_fifo <8 then
--                bram_e_read <= '0';
--                bram_e_write<= '1';
--                bram_we <= "0";
--                state<=rx_wait;
--            elsif (tx_start='1' and size_of_fifo>0) then
--                bram_e_read <= '1';
--                bram_e_write<= '0';
--                state<=tx_begin;
--            else
--                state<=idle;
--            end if;
            
--            ld_tx<= '0';
--            bram_e_read <= '0';
--            bram_e_write<= '0';
            
        when rx_wait=>
            
            if rx_full='1' and size_of_fifo<8 then
                bram_we <= "1";
                state<=rx_done;
                 --bram_input <= reciever_output;
            else
                state<=rx_wait;
            end if;
         
        when rx_done=>
  
                size_of_fifo <= size_of_fifo+1;
                bram_write_index<=std_logic_vector(write_index);
                display_number <= reciever_output;
                write_index<=write_index+1;
                state<=idle;
                
        when tx_begin=>
         
            bram_e_read<= '1';
            bram_e_write <= '0';
            ld_tx <= '1';
            bram_read_index <= std_logic_vector(read_index);
            state <= tx_pre_wait;

        when tx_pre_wait=>
        
            display_number<=bram_output;
            read_index <= read_index+1;
--            bram_read_index <= bram_read_index+ "001";
            bram_e_read<= '0';
            ld_tx <= '0';
            size_of_fifo<= size_of_fifo-1;
            state <= tx_wait;


        when tx_wait=>
            if tx_empty='1' then
                if size_of_fifo= -1 then
                    state<=idle;
                    
                else
                    state<=tx_begin;
                end if;
                
                
            else
                state<=tx_wait;
            end if;
        when others=>
            state<=idle;
        end case;
    end if;
end process;



process(clk)
begin
if(rising_edge(clk)) then
refresh_counter <= refresh_counter + 1;
end if;
end process;


sel <= refresh_counter(19 downto 18);


process(temp_num)

begin
if(size_of_fifo<=0) then
seg<= "0111111";
else
    
    case temp_num is
    when "0000" => seg <= "1000000";
    when "0001" => seg <= "1111001";
    when "0010" => seg <= "0100100";
    when "0011" => seg <= "0110000";
    when "0100" => seg <= "0011001";
    when "0101" => seg <= "0010010";
    when "0110" => seg <= "0000010";
    when "0111" => seg <= "1111000";
    when "1000" => seg <= "0000000";
    when "1001" => seg <= "0010000";
    when "1010" => seg <= "0001000";
    when "1011" => seg <= "0000011";
    when "1100" => seg <= "1000110";
    when "1101" => seg <= "0100001";
    when "1110" => seg <= "0000110";
    when "1111" => seg <= "0001110";
    when others => seg <= "1111111";
    end case;

end if;

end process;



process(sel)

begin

case sel is
when "00" =>
an(0) <= '1';
an(1) <= '1';
an(2) <= '1';
an(3) <= '1';

when "01" => an(0) <= '1';
an(1) <= '1';
an(2) <= '1';
an(3) <= '1';

when "10" => an(0) <= '1';
an(1) <= '0';
an(2) <= '1';
an(3) <= '1';
temp_num <= display_number(7 downto 4);

when others => an(0) <= '0';
an(1) <= '1';
an(2) <= '1';
an(3) <= '1';
temp_num <= display_number(3 downto 0);
end case;

end process;

end Behavioral;