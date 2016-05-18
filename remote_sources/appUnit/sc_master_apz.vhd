----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:04:05 04/06/2012 
-- Design Name: 
-- Module Name:    sc_master_apz - Behavioral 
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
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sc_master_apz is
    Port ( clk, clk10M : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
			  
				-- sc bus input
				sc_port : IN std_logic_vector(15 downto 0);
				sc_data, sc_addr, sc_subaddr : IN std_logic_vector(31 downto 0);
				sc_frame, sc_op, sc_wr : IN std_logic;
				sc_ack : OUT std_logic;
				sc_rply_data, sc_rply_error : OUT std_logic_vector(31 downto 0);
				-- sc bus output
				sc_port_o : out std_logic_vector(15 downto 0);
				sc_data_o, sc_addr_o, sc_subaddr_o : out std_logic_vector(31 downto 0);
				sc_frame_o, sc_op_o, sc_wr_o : out std_logic;
				sc_ack_o : in std_logic;
				sc_rply_data_o, sc_rply_error_o : in std_logic_vector(31 downto 0);
			  
           api_i2c_request : in  STD_LOGIC;
           api_i2c_done : out  STD_LOGIC;
           api_i2c_ctr2 : in  STD_LOGIC_VECTOR (4 downto 0);
           api_apv_select : in  STD_LOGIC_VECTOR (3 downto 0));
end sc_master_apz;

architecture Behavioral of sc_master_apz is

signal		sc_port_i :  std_logic_vector(15 downto 0);
signal		sc_data_i, sc_addr_i, sc_subaddr_i :  std_logic_vector(31 downto 0);
signal		sc_frame_i, sc_op_i, sc_wr_i :  std_logic;
--signal		sc_ack_i :  std_logic;
--signal		sc_rply_data_i, sc_rply_error_i :  std_logic_vector(31 downto 0);

type state_type is (stIdle, stLocal, stWaitAck, stWaitAckRelease);
signal state : state_type;

signal hchannel : std_logic_vector(7 downto 0);
signal done : std_logic;

begin
	process (api_apv_select)
	begin
		case conv_integer(api_apv_select(3 downto 1)) is
			when 0 	=> 	hchannel <= "00001000";
			when 1 	=> 	hchannel <= "00000100";
			when 2 	=> 	hchannel <= "00000010";
			when 3 	=> 	hchannel <= "00000001";
			when 4 	=> 	hchannel <= "10000000";
			when 5 	=> 	hchannel <= "01000000";
			when 6 	=> 	hchannel <= "00100000";
			when 7 	=> 	hchannel <= "00010000";
			when others 	=> 	hchannel <= "00001000";
		end case;
	end process;

	sc_port_o <= sc_port when state = stIdle else sc_port_i;
	sc_data_o <= sc_data when state = stIdle else sc_data_i;
	sc_addr_o <= sc_addr when state = stIdle else sc_addr_i;
	sc_subaddr_o <= sc_subaddr when state = stIdle else sc_subaddr_i;
	sc_frame_o <= sc_frame when state = stIdle else sc_frame_i;
	sc_op_o <= sc_op when state = stIdle else sc_op_i;
	sc_wr_o <= sc_wr when state = stIdle else sc_wr_i;
	
	sc_rply_data <= sc_rply_data_o when state = stIdle else x"00000000";
	sc_rply_error <= sc_rply_error_o when state = stIdle else x"00000000";
	sc_ack <= sc_ack_o when state = stIdle else '0';
	
	process(clk10M, rstn)
	begin
		if rstn = '0' then
			state <= stIdle;
			sc_port_i 		<= x"0000";
			sc_data_i		<= x"00000000";
			sc_addr_i 		<= x"00000000";
			sc_subaddr_i 	<= x"00000000";
			sc_frame_i 		<= '0';
			sc_op_i 			<= '0';
			sc_wr_i 			<= '0';
		elsif clk10M'event and clk10M = '1' then
			if state = stIdle then
				sc_port_i 		<= x"0000";
				sc_data_i 		<= x"00000000";
				sc_addr_i 		<= x"00000000";
				sc_subaddr_i 	<= x"00000000";
				sc_frame_i 		<= '0';
				sc_op_i 			<= '0';
				sc_wr_i 			<= '0';
				
				if sc_frame = '0' and sc_op = '0' then
					if api_i2c_request = '1' then
						state <= stLocal;
					end if;
				end if;
				
			elsif state = stLocal then
				if api_i2c_request = '1' and sc_ack_o = '0' then
					sc_port_i 		<= x"1877";
					sc_data_i 		<= x"000000" & "000" & api_i2c_ctr2;
					sc_addr_i 		<= x"00000001";
					sc_subaddr_i 	<= x"0000" & hchannel & x"00";
					sc_frame_i 		<= '1';
					sc_op_i 			<= '1';
					sc_wr_i 			<= '1';
					
					state <= stWaitAck;
				else
					state <= stIdle;
				end if;
			elsif state = stWaitAck then
				if sc_ack_o = '1' then
					sc_frame_i 	<= '1';
					sc_op_i 		<= '0';
					sc_wr_i 		<= '0';
					
					state <= stWaitAckRelease;
				end if;
			elsif state = stWaitAckRelease then
				if sc_ack_o = '0' then
					state <= stIdle;
				end if;
			end if;
		end if;
	end process;
	
	done <= '1' when state = stWaitAckRelease and sc_ack_o = '0' else '0';
	
--	api_i2c_done <= done and ( not api_i2c_request );
	api_i2c_done <= done;


end Behavioral;

