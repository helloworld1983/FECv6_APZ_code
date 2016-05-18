-------------------------------------------------------------------------------
-- Title      : Dual Port RAM
-- Project    : Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File       : dualRAM.vhd
-- Author     : Alfonso Tarazona Martinez (ATM)
-- Company    : NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update: 2010/03/10
-- Platform   : Virtex5 XC5VLX50T FFG1136 -1
-------------------------------------------------------------------------------
-- Description: Dual Port RAM With Enable on Each Port
-------------------------------------------------------------------------------
-- Revisions  :
-- Date           Version  	Author  	Description
-- 
-------------------------------------------------------------------------------
-- More Information: XST User Guide (Xilinx)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity dualRAM is
  generic (
    RAM_STYLE_ATTRIBUTE : string := "AUTO";
    DATA_WIDTH : integer := 8;
    ADDR_WIDTH : integer := 14
  );
  port (
    clk   : in  std_logic;  															-- Global clock
    ena   : in  std_logic;  															-- Primary global enable
		enb   : in  std_logic;  															-- Dual global enable
		wea   : in  std_logic;  															-- Primary synchronous write enable
		addra : in  std_logic_vector(ADDR_WIDTH-1 downto 0);	-- Write address/Primary read address
		addrb : in  std_logic_vector(ADDR_WIDTH-1 downto 0); 	-- Dual read address
		dia   : in  std_logic_vector(DATA_WIDTH-1 downto 0); 	-- Primary data input
		doa   : out std_logic_vector(DATA_WIDTH-1 downto 0); 	-- Primary output port
		dob   : out std_logic_vector(DATA_WIDTH-1 downto 0)  	-- Dual output port
  );
end dualRAM;

architecture arch_dualRAM of dualRAM is

	constant RAM_DEPTH :integer := 2**ADDR_WIDTH;

	type ram_type is array (RAM_DEPTH-1 downto 0) of std_logic_vector (DATA_WIDTH-1 downto 0);
	signal RAM : ram_type;
	
	signal read_addra : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal read_addrb : std_logic_vector(ADDR_WIDTH-1 downto 0);
	
	--SM: attribute for RAM type
	attribute RAM_STYLE : string;
	attribute KEEP : string;
	attribute KEEP of RAM: signal is "TRUE";
	attribute RAM_STYLE of RAM: signal is RAM_STYLE_ATTRIBUTE;

	
begin

	process (clk)
	begin
		if clk'event and clk = '1' then
			if ena = '1' then
				if wea = '1' then
					RAM(conv_integer(addra)) <= dia;
				end if;
				read_addra <= addra;
			end if;
			
			if enb = '1' then
				read_addrb <= addrb;
			end if;
		end if;
	end process;
	
	doa <= RAM(conv_integer(read_addra));
	dob <= RAM(conv_integer(read_addrb));
	
end arch_dualRAM;