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

entity dualport_ram is
	 generic(M: natural);
    Port ( we 		  : in std_logic;						 -- write enable
           datain	  : in std_logic_vector(11 downto 0);   -- data input
           wclk 	  : in std_logic;						 -- writing clock
           rclk 	  : in std_logic;						 -- read clock
           
           wr_addr  : in std_logic_vector(M-1 downto 0);   -- write address 
           rd_addr  : in std_logic_vector(M-1 downto 0);   -- read address 
           dataout  : out std_logic_vector(11 downto 0)   -- data out 
           ); -- data out B
end dualport_ram;

architecture beh of dualport_ram is

type blockram_type is array (2**M - 1 downto 0) of std_logic_vector (8 downto 0);
signal blockram : blockram_type;

type distram_type is array (2**M - 1 downto 0) of std_logic_vector (2 downto 0);
signal distram : distram_type;

attribute ram_style: string;
attribute ram_style of blockram : signal is "block";
attribute ram_style of distram : signal is "block";


begin

	ram_write : process (wclk)
	begin
		if (wclk'event and wclk = '1') then
			if we = '1' then
				blockram(conv_integer(wr_addr)) <= datain(8 downto 0);
				distram(conv_integer(wr_addr)) <= datain(11 downto 9);
			end if;
		end if;
	end
	process ram_write;

	
	
	ram_read : process (rclk)
	begin
		if (rclk'event and rclk = '1') then
			dataout(8 downto 0) <= blockram(conv_integer(rd_addr));
			dataout(11 downto 9) <= distram(conv_integer(rd_addr));
		end if;
	end
	process ram_read;

		
	

end beh;
