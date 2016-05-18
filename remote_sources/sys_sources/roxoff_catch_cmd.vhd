----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:19:43 03/05/2013 
-- Design Name: 
-- Module Name:    roxoff_catch_resume - Behavioral 
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

entity roxoff_catch_cmd is
    Port ( clk125 : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
           cfg_daqport : in  STD_LOGIC_VECTOR (15 downto 0);
           cfg_daq_ip : in  STD_LOGIC_VECTOR (31 downto 0);
           cfg_xoffcmd : in  STD_LOGIC_VECTOR (3 downto 0);
           udprx_dstPort : in  STD_LOGIC_VECTOR (15 downto 0);
           udprx_srcIP : in  STD_LOGIC_VECTOR (31 downto 0);
           udprx_data : in  STD_LOGIC_VECTOR (7 downto 0);
           udprx_datavalid : in  STD_LOGIC;
           udprx_checksum : in  STD_LOGIC_VECTOR (15 downto 0);
           udprx_portAck : out  STD_LOGIC;
           roxoff_send : out  STD_LOGIC;
           roxoff_evcr : out  STD_LOGIC);
end roxoff_catch_cmd;

architecture Behavioral of roxoff_catch_cmd is

	constant dstport_pos: integer := 2;
	constant data_pos: integer := 8;
	
	type state_type is (st_idle, st_rx);
	signal state : state_type;
	signal word : std_logic_vector(31 downto 0);
	signal count : std_logic_vector(3 downto 0);
	signal srcIP_flag, srcIP_flag_i: std_logic;

begin

	srcIP_flag_i <= '1' when udprx_srcIP = cfg_daq_ip else '0';

	process(clk125, rstn)
	begin
		if rstn  = '0' then
			state <= st_idle;
			word <= (others => '0');
			count <= (others => '0');
			srcIP_flag <= '0';
			udprx_portAck <= '0';
			roxoff_send <= '0';
			roxoff_evcr <= '0';
		elsif clk125'event and clk125 = '1' then
			roxoff_send <= '0';
			roxoff_evcr <= '0';
			case state is
				when st_idle =>
					udprx_portAck <= '0';
					srcIP_flag <= '0';
					count <= (others => '0');
					word <= (others => '0');
					if udprx_datavalid = '1' then
						state <= st_rx;
						count <= count + 1;
						srcIP_flag <= srcIP_flag_i;
					end if;
					
				when st_rx =>
					if udprx_datavalid = '0' then 
						state <= st_idle;
						udprx_portAck <= '0';
						-- decode command
						if ((count = data_pos + 4) or (cfg_xoffcmd(1) = '0')) and 
							((udprx_checksum = x"FFFF") or (cfg_xoffcmd(0) = '0')) and
							((srcIP_flag = '1') or (cfg_xoffcmd(2) = '0')) then
							
								if 	word = x"45564352" then	roxoff_evcr <= '1'; -- "EVCR"
								elsif word = x"53454E44" then	roxoff_send <= '1'; -- "SEND"
								end if;
						end if;
					else
						if (count = dstport_pos + 2) and udprx_dstPort = cfg_daqport then
							udprx_portAck <= '1';
						end if;
						if ((count and "1100") = data_pos) then
							word <= word(23 downto 0) & udprx_data;
						end if;
						
						if count < data_pos + 5 then
							count <= count + 1;
						end if;
						
					end if;
				when others =>
					state <= st_idle;
			end case;
		end if;
	end process;
				


end Behavioral;

