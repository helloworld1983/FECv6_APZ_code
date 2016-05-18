----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Sorin Martoiu
-- 
-- Create Date:    23:13:37 04/11/2012 
-- Design Name: 
-- Module Name:    apv_sync_det - Behavioral 
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
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity apv_sync_det is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           datain : in  STD_LOGIC_VECTOR (11 downto 0);
           threshold_low : in  STD_LOGIC_VECTOR (11 downto 0);
           threshold_high : in  STD_LOGIC_VECTOR (11 downto 0);
           sync_out : out  STD_LOGIC);
end apv_sync_det;

architecture Behavioral of apv_sync_det is
signal counter: std_logic_vector(5 downto 0);
signal y0, y1:std_logic;
begin
	
	y0 <= '1' when datain > threshold_high else '0';
	y1 <= '1' when datain < threshold_low  else '0';
	
	process(clk)
	begin
		if rst = '1' then
			counter <= "000000";
			sync_out <= '0';
		elsif rising_edge(clk) then
			if y0 = '1' then
				counter <= counter + 1;
			else
				counter <= "000000";
			end if;
			if y1 = '1' then
				if counter = 34 then
					sync_out <= '1';
				else
					sync_out <= '0';
				end if;
			end if;
		end if;
	end process;


end Behavioral;

