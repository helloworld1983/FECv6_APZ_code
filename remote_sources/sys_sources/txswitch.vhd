----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:47:19 03/05/2013 
-- Design Name: 
-- Module Name:    txswitch - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity txswitch is
    Port ( clk125 : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
			  cfg: in std_logic_vector(7 downto 0);
			  daqtotframes: in std_logic_vector(15 downto 0);
			  roxoff_send: in  STD_LOGIC;
			  roxoff_evcr: in  STD_LOGIC;
           ro_txreq : in  STD_LOGIC;
           ro_txdone : in  STD_LOGIC;
           ro_txack : out  STD_LOGIC;
           sc_txreq : in  STD_LOGIC;
           sc_txdone : in  STD_LOGIC;
           sc_txack : out  STD_LOGIC);
end txswitch;

architecture Behavioral of txswitch is

	type state_type is (st_idle, st_ro_ack, st_sc_ack);
	signal state : state_type;
	
	signal event_count: std_logic_vector(15 downto 0);
	signal ro_xoffen, ro_xoff, ro_xoff_1: std_logic;

begin
	
	ro_xoffen 	<= '0' when daqtotframes = 0 else '1';
	ro_xoff_1 	<= '1' when event_count >= daqtotframes else '0';
	ro_xoff 		<= ro_xoff_1 and ro_xoffen;
						
	
	process(clk125, rstn)
	begin
		if rstn  = '0' then
			state <= st_idle;
			event_count <= (others => '0');
		elsif clk125'event and clk125 = '1' then
			case state is 
				when st_idle =>
					if ro_txreq = '1' and ro_xoff = '0' then
						state <= st_ro_ack;
						if ro_xoffen = '1' then
							event_count <= event_count + 1;
						end if;
					elsif sc_txreq = '1' then
						state <= st_sc_ack;
					end if;
				when st_ro_ack => 
					if ro_txdone = '1' then
						state <= st_idle;
					end if;
				when st_sc_ack => 
					if sc_txdone = '1' then
						state <= st_idle;
					end if;
				when others =>
					state <= st_idle;
			end case;
			-- xoff commands
			-- reset counters
			if roxoff_evcr = '1' then
				event_count <= (others => '0');
			-- resume readout
			elsif roxoff_send = '1' and ro_xoff = '1' then
				event_count <= (others => '0');
			end if;
		end if;
	end process;
	
	ro_txack <= '1' when state = st_ro_ack else '0';
	sc_txack <= '1' when state = st_sc_ack else '0';
	

end Behavioral;

