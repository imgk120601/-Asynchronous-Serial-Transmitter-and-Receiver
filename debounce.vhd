library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debouncer is
 Port (
    clk: in std_logic;
    input : in std_logic;
    output : out std_logic
     );
end debouncer;

architecture Behavioral of debouncer is
    constant count_max : integer:=100;
    constant active : std_logic := '1';
    signal count: integer := 0;
    signal state : std_logic:='0';
    

begin

    process(clk)
    begin
        if(rising_edge(clk)) then
            case (state) is
                when '0' =>
                    if (input = active) then
                        state <= '1';
                    end if;
                    output<='0';
                when '1' =>
                    if (input = active) then
                        if (count=count_max) then
                            output <= '1';
                        else
                            count <= count + 1;
                        end if;
                    else
                        state <= '0';
                        count <= 0;
                    end if;
                when others=>
                    state<='0';     
            end case;
        end if;
    end process;

end Behavioral;