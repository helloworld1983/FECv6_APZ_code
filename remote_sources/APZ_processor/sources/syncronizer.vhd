-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity syncronizer is
	 generic (size: positive := 3 );
    Port ( clk : in  STD_LOGIC;
           async_in : in  STD_LOGIC; 
			  sync_out : out  STD_LOGIC);
end syncronizer;

architecture Behavioral of syncronizer is
signal Q: std_logic_vector(size-1 downto 0);

begin

	process (clk) 
	begin
		if rising_edge(clk) then
				Q <= Q(size-2 downto 0) & async_in;
		end if;
	
	end process;

sync_out <= Q(size-1);
			

end Behavioral;

