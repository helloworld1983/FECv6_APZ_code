--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package scports_pkg is

	type scport_list_type is array (integer range <>) of std_logic_vector(15 downto 0);
	
	-- list of slow control ports
	-- each new application will have to override this list locally
	constant scports_list : scport_list_type := (x"1787", x"1797", x"1877", x"1798", x"1977");
	
	-- function returns '1' if dstport is in scports_list
	function scports_portAck  (signal dstport : in std_logic_vector(15 downto 0)) return std_logic;

end scports_pkg;

package body scports_pkg is


	-- function returns '1' if dstport is in scports_list
	function scports_portAck  (signal dstport : in std_logic_vector(15 downto 0)) return std_logic is
--		variable portAck_array: std_logic_vector(scports_portlist'length - 1 downto 0);
		variable result: std_logic := '0';
	begin
		for i in 0 to scports_list'length - 1 loop
--			portAck_array(i) := '1' when dstport = scports_portlist(i) else '0';
			result := '1' when dstport = scports_list(i) else result;
		end loop;
		return result;
	
	end scports_portAck;
 
end scports_pkg;
