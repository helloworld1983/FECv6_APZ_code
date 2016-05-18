----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
-- 
-- Create Date:    15:36:26 08/15/2011 
-- Design Name: 
-- Module Name:    fileregister - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity file_register is
	 generic(M: natural; N: natural);
    Port ( we 		: in std_logic;							  -- write enable
           datain	: in std_logic_vector(N-1 downto 0);    -- data input
           wclk 	: in std_logic;							  -- writing clock
           addrA  : in std_logic_vector(M-1 downto 0);  -- address B
           addrB  : in std_logic_vector(M-1 downto 0);  -- address A
           dataA  : out std_logic_vector(N-1 downto 0);  -- data out A
           dataB  : out std_logic_vector(N-1 downto 0)); -- data out B
end file_register;

architecture beh of file_register is

type ram_type is array (2**M - 1 downto 0) of std_logic_vector (N-1 downto 0);
signal RAM : ram_type;

attribute ram_style: string;
attribute ram_style of ram : signal is "distributed";

begin

	regs : process (wclk)
	begin
		if (wclk'event and wclk = '1') then
			if we = '1' then
				ram(conv_integer(addrA)) <= dataIN;
			end if;
		end if;
	end
	process regs;

	dataA <= ram(conv_integer(addrA));
	dataB <= ram(conv_integer(addrB));

end beh;
