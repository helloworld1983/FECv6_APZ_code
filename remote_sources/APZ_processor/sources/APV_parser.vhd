----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
--
-- Create Date:    20:44:46 03/16/2011 
-- Design Name: 
-- Module Name:    APV_parser - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity APV_parser is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  threshold : in  STD_LOGIC_VECTOR (11 downto 0);
           datain : in  STD_LOGIC_VECTOR (11 downto 0);
           address : out  STD_LOGIC_VECTOR(7 downto 0);
           error : out  STD_LOGIC;
           dataout : out  STD_LOGIC_VECTOR (11 downto 0);
			  channel : out  STD_LOGIC_VECTOR (6 downto 0);
           datavalid : out  STD_LOGIC);
end APV_parser;

architecture Behavioral of APV_parser is

--constant threshold : integer := 1750 ; 

signal y, header_found, pipe_reset: std_logic;
signal pipe,datain_r : std_logic_vector(11 downto 0);
signal channel_i :  std_logic_vector(6 downto 0);
signal header :  std_logic_vector(2 downto 0);

begin
	
	-- converts 12-bit voltage value to 1-bit
	comparator : process (datain,threshold)
	begin
		if datain < threshold then
			y <= '1';
		else
			y <= '0';
		end if;
	end process;
	
	
	parsing_pipeline: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' or pipe_reset = '1' then
				pipe <= (others => '0');
			else 
				pipe <= y & pipe(11 downto 1) ;
			end if;
			
		end if;
	end process;
   
	-- data parsing
	header <= pipe(2 downto 0);
	
	ctrl_FSM: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				header_found <= '0';
				channel_i <= (others => '0');
				pipe_reset <= '0';
				--dataout <= (others => '0');
				--datain_r <= (others => '0');
				--header <= (others => '0');
				address <= (others => '0');
				error <= '1';
				
			else
			
			  -- datain_r <= datain;
				dataout <= datain;
				
				-- default
				pipe_reset <= '0';
				
				-- header recognized
				if header_found='0' and header = "111" then
					channel_i <= (others => '0');
					
					
					
					header_found <= '1';
					pipe_reset <= '1';
					
					-- address comes MSB first
					for i in 0 to 7 loop
					address(7-i) <= pipe(3+i); 
					end loop;
					
					error <= pipe(11);
					
				elsif (header_found='1') and (channel_i < 127) then
					header_found <= '1';
					channel_i <= channel_i +1;
					
					pipe_reset <= '1';
					
				elsif (header_found='1') and (channel_i = 127) then
					header_found <='0';
					channel_i <= (others => '0');
					pipe_reset <= '0';
					
				end if;
				
				-- MUST renable pipeline 2 channels in advance
				if header_found='1' and (channel_i = 126) then
					pipe_reset <= '0';
				end if;
				
			end if;
			
		end if;
	end process;
	
	datavalid <= header_found;
	channel <= channel_i;
end Behavioral;

