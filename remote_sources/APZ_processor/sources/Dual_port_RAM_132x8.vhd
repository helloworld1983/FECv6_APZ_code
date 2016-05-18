library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Dual_Port_RAM_132x8 is
    Port ( clk   : in  STD_LOGIC;
           we : in  STD_LOGIC;
           Awr   : in  STD_LOGIC_VECTOR (7 downto 0);
           Ard   : in  STD_LOGIC_VECTOR (7 downto 0);
           Din   : in  STD_LOGIC_VECTOR (7 downto 0);
           Dout  : out STD_LOGIC_VECTOR (7 downto 0)
         );
end Dual_Port_RAM_132x8;

architecture DistributedRAM of Dual_Port_RAM_132x8 is
type RAM_type is array(0 to 131) of STD_LOGIC_VECTOR(7 downto 0);
signal memory : RAM_type;   
begin
  process begin
    wait until rising_edge(CLK);
    if (we='1') then
      memory(to_integer(unsigned(Awr))) <= Din;
    end if;
  end process;

  Dout <= memory(to_integer(unsigned(Ard)));

end DistributedRAM;