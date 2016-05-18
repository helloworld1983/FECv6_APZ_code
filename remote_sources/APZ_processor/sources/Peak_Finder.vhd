----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
--
-- Create Date:    19:16:18 08/15/2011 
-- Design Name: 
-- Module Name:    Data_sorter - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use work.api_pack.all;

entity Peak_Finder is
Port ( clk : in  STD_LOGIC;
	        reset : in  STD_LOGIC;   
            -- data
 		     data_in : in  STD_LOGIC_VECTOR (APV_WORD_SIZE downto 0);
			  sample_in : in  STD_LOGIC_VECTOR(LOG2_MAX_SAMPLES-1 downto 0);
			  -- options
			  polarity : in  STD_LOGIC; --'0' negative, '1' positive
			  -- outputs
			  peak_value : out  STD_LOGIC_VECTOR (APV_WORD_SIZE  downto 0);
			  peak_time : out std_logic_vector (LOG2_MAX_SAMPLES-1 downto 0)
           );
end Peak_Finder;

architecture beh of Peak_Finder is

  signal peak_value_i :  STD_LOGIC_VECTOR (APV_WORD_SIZE  downto 0);
  signal peak_time_i : std_logic_vector (LOG2_MAX_SAMPLES-1 downto 0);
 
begin

	peak_find_proc : process (clk) 
   begin
      if rising_edge(clk) then
			if reset = '1' then
				peak_value_i <= (others => '0');
				peak_time_i <= (others => '0');
			else
				-- if it is the first sample
				-- initialize peak_value
				if sample_in = 0 then
					peak_value_i <= data_in;
					peak_time_i <= sample_in;
				else	
					-- update peak_value 
					if (data_in >= peak_value_i and polarity = '1') or 
					   (data_in <= peak_value_i and polarity = '0') then
						peak_value_i <= data_in;
						peak_time_i <= sample_in;
					end if;
				end if;
			end if;
		end if;
	 end process;
	 
	 peak_value <= peak_value_i;
	 peak_time <= peak_time_i;
	 
end beh;

