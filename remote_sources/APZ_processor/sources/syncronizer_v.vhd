-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity syncronizer_v is
	 generic (depth: positive := 3; wordsize : positive := 1);
    Port ( clk : in  STD_LOGIC;
           async_in : in  STD_LOGIC_VECTOR (wordsize - 1 downto 0); 
		   sync_out : out  STD_LOGIC_VECTOR(wordsize - 1 downto 0));
end syncronizer_v;

architecture struct of syncronizer_v is

begin


synchgen : for i in 0 to wordsize generate 
begin
  	synch_i : syncronizer PORT MAP(
		clk => clk,
		async_in => async_in(i),
		sync_out => sync_out(0) 
	);	

end generate;


end struct;

