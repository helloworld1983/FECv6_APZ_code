----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:36:13 03/07/2011 
-- Design Name: 
-- Module Name:    scInitSys - Behavioral 
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
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity scInitSys is
    Port ( clk : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
			  -- input sc bus
           sc_port_in : in  STD_LOGIC_VECTOR (15 downto 0);
           sc_data_in : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_addr_in : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_subaddr_in : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_frame_in : in  STD_LOGIC;
           sc_op_in : in  STD_LOGIC;
           sc_wr_in : in  STD_LOGIC;
           sc_ack_in : out  STD_LOGIC;
			  -- out sc bus
           sc_port_out : out  STD_LOGIC_VECTOR (15 downto 0);
           sc_data_out : out  STD_LOGIC_VECTOR (31 downto 0);
           sc_addr_out : out  STD_LOGIC_VECTOR (31 downto 0);
           sc_subaddr_out : out  STD_LOGIC_VECTOR (31 downto 0);
           sc_frame_out : out  STD_LOGIC;
           sc_op_out : out  STD_LOGIC;
           sc_wr_out : out  STD_LOGIC;
           sc_ack_out : in  STD_LOGIC;
			  ---
           sc_rply_data : in  STD_LOGIC_VECTOR (31 downto 0);
			  ---
           warm_init : in  STD_LOGIC;
           rstn_eth : out  STD_LOGIC;
           rstn_rxtx : out  STD_LOGIC;
			  rstn_sc : out  STD_LOGIC;
           rstn_app : out  STD_LOGIC);
end scInitSys;

architecture Behavioral of scInitSys is

signal countend: integer := 9;

--type rom_type is array (0 to countend) of std_logic_vector (31 downto 0); 
type rom_type is array (0 to 12) of std_logic_vector (31 downto 0); 
signal rdaddrrom:rom_type := 
	(	x"A0F10078",	-- version
		x"A0F2007A",	-- mac_vendor
		x"A0F2007D",	-- mac_id
		x"A0F30000",	-- IP
		x"A0F10004",	-- daq port
		x"A0F10006",	-- sc port
		x"A0F10008",	-- framedly
		x"A0F1000A",	-- tot frames
		x"A0F1000C",	-- eth mode
		x"A0F1000E",	-- sc mode
		x"A0F30012",	-- daq ip
		x"A0F30016",	-- dtc ctrl
		x"A0F3001A"--,	-- mclk_sel
--		x"A0F3001E",	-- mclk_status
--		x"A0F30022",	-- reserved
	);
type state_type is (stIdle, stReset, stStartInit, stStartInit2, stRead, stReadEnd, stWrite, stWriteEnd); 
signal state: state_type;
constant read_port : std_logic_vector(15 downto 0) := x"1787";
constant write_port : std_logic_vector(15 downto 0) := x"1777";

signal sc_op_i, sc_wr_i: std_logic;
signal sc_data_i, sc_addr_i, writedata: std_logic_vector(31 downto 0);
signal sc_port_i : std_logic_vector(15 downto 0);
signal counter  : std_logic_vector(7 downto 0);

begin
	sc_op_out <= sc_op_in when state = stIdle else sc_op_i;
	sc_wr_out <= sc_wr_in when state = stIdle else sc_wr_i;
	sc_frame_out <= sc_frame_in when state = stIdle else '0';
	sc_data_out <= sc_data_in when state = stIdle else sc_data_i;
	sc_addr_out <= sc_addr_in when state = stIdle else sc_addr_i;
	sc_port_out <= sc_port_in when state = stIdle else sc_port_i;
	sc_subaddr_out <= sc_subaddr_in when state = stIdle else x"FFFFFFFF";
	sc_ack_in <= sc_ack_out when state = stIdle else '0';
	
--	rstn_eth <= '1' when state = stIdle else '0';
--	rstn_rxtx <= '1' when state = stIdle else '0';
--	rstn_app <= '1' when state = stIdle else '0';
--	rstn_sc <= '0' when (state = stReset) or (state = stStartInit) else '1';

	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stReset;
			countend <= 9;
			counter <= (others => '0');
			sc_op_i <= '0';
			sc_wr_i <= '0';
			sc_addr_i <= (others => '0');
			sc_data_i <= (others => '0');
			sc_port_i <= (others => '0');
			rstn_eth <= '0';
			rstn_rxtx <= '0';
			rstn_app <= '0';
			rstn_sc <= '0';
		elsif clk'event and clk = '1' then
			case state is
				when stReset =>		
					state <= stStartInit;
					counter <= (others => '0');
				when stStartInit =>	
					rstn_eth <= '0';
					rstn_rxtx <= '0';
					rstn_app <= '0';
					rstn_sc <= '0';
					countend <= 9;
					counter <= counter + 1;
					sc_op_i <= '0';
					if counter > 100 then
						state <= stStartInit2;
						counter <= (others => '0');
					end if;
				when stStartInit2 =>	
					rstn_sc <= '1';
					counter <= counter + 1;
					sc_op_i <= '0';
					if counter > 100 then
						state <= stRead;
						counter <= (others => '0');
					end if;
				when stRead =>
					sc_op_i <= '1';
					sc_wr_i <= '0';
					sc_addr_i <= rdaddrrom(conv_integer(counter));
					sc_data_i <= x"00000000";
					sc_port_i <= read_port;
					if sc_ack_out = '1' then
						state <= stReadEnd;
						writedata <= sc_rply_data;
					end if;
				when stReadEnd =>
					sc_op_i <= '0';
					if sc_ack_out = '0' then
						if counter = 0 and ((writedata(7 downto 0) = 0) or (writedata(7 downto 0) = x"FF")) then
							state <= stIdle;
							-- extended registers
							if writedata(15) = '1' then
								countend <= 12;
							end if;
						else
							state <= stWrite;
						end if;
					end if;
				when stWrite =>
					sc_op_i <= '1';	
					sc_wr_i <= '1';
					sc_data_i <= writedata;
					sc_addr_i <= x"000000" & counter;
					sc_port_i <= write_port;
					if sc_ack_out = '1' then
						state <= stWriteEnd;
					end if;
				when stWriteEnd =>
					sc_op_i <= '0';
					if sc_ack_out = '0' then
						if counter > countend - 1 then
							state <= stIdle;
							counter <= (others => '0');
						else
							counter <= counter + 1;
							state <= stRead;
						end if;
					end if;
				when stIdle =>
					rstn_eth <= '1';
					rstn_rxtx <= '1';
					rstn_app <= '1';
					rstn_sc <= '1';
					counter <= (others => '0');
					sc_op_i <= '0';
					if warm_init = '1' then
						state <= stStartInit;
					end if;
				when others =>
					state <= stIdle;
			end case;
		end if;
	end process;
						
end Behavioral;

