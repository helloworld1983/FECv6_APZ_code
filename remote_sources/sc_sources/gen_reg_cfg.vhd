----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:09:48 03/02/2011 
-- Design Name: 
-- Module Name:    gen_reg_cfg - Behavioral 
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

entity gen_reg_cfg is
	 Generic (
			gen_port : std_logic_vector(15 downto 0) := x"1777";
			rstval_00 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_01 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_02 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_03 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_04 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_05 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_06 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_07 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_08 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_09 : std_logic_vector(31 downto 0) := x"00000000";
			rstval_0A : std_logic_vector(31 downto 0) := x"00000000";
			rstval_0B : std_logic_vector(31 downto 0) := x"00000000";
			rstval_0C : std_logic_vector(31 downto 0) := x"00000000";
			rstval_0D : std_logic_vector(31 downto 0) := x"00000000";
			rstval_0E : std_logic_vector(31 downto 0) := x"00000000";
			rstval_0F : std_logic_vector(31 downto 0) := x"00000000"
			);
    Port ( clk : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
           sc_port : in  STD_LOGIC_VECTOR (15 downto 0);
           sc_data : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_addr : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_subaddr : in  STD_LOGIC_VECTOR (31 downto 0);
           sc_op : in  STD_LOGIC;
           sc_frame : in  STD_LOGIC;
           sc_wr : in  STD_LOGIC;
           sc_ack : out  STD_LOGIC;
           sc_rply_data : out  STD_LOGIC_VECTOR (31 downto 0);
           sc_rply_error : out  STD_LOGIC_VECTOR (31 downto 0);
			  rstreg : out  STD_LOGIC_VECTOR (15 downto 0);
           regout : out  STD_LOGIC_VECTOR (511 downto 0));
end gen_reg_cfg;

architecture Behavioral of gen_reg_cfg is
type state_type is (stIdle, stEx, stAck0, stAck1);
signal state: state_type;

type regarray_type is array(0 to 15) of std_logic_vector(31 downto 0);
signal regarray : regarray_type;
signal rst_delay_cnt, rst_width_cnt: std_logic_vector(7 downto 0);
signal rst_reg_i, rst_reg_out : std_logic_vector(15 downto 0);

begin

	sc_rply_error <= (OTHERS => '0');
	REGS: for i in 0 to 15 generate
	begin
		regout((i*32 + 31) downto (i*32)) <= regarray(i);
	end generate;

	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stIdle;
			sc_ack <= '0';
			sc_rply_data <= (others => '0');
			regarray(0) <= rstval_00;
			regarray(1) <= rstval_01;
			regarray(2) <= rstval_02;
			regarray(3) <= rstval_03;
			regarray(4) <= rstval_04;
			regarray(5) <= rstval_05;
			regarray(6) <= rstval_06;
			regarray(7) <= rstval_07;
			regarray(8) <= rstval_08;
			regarray(9) <= rstval_09;
			regarray(10) <= rstval_0A;
			regarray(11) <= rstval_0B;
			regarray(12) <= rstval_0C;
			regarray(13) <= rstval_0D;
			regarray(14) <= rstval_0E;
			regarray(15) <= rstval_0F;
		elsif clk'event and clk = '1' then
			case state is
				when stIdle =>
					sc_ack <= '0';
					sc_rply_data <= (others => '0');
--					if ((sc_frame and sc_op) = '1') and (sc_port = gen_port) then
					if (sc_op = '1') and (sc_port = gen_port) then
						state <= stEx;
					end if;
				when stEx =>
					state <= stAck0;
					sc_ack <= '1';
					if sc_addr < 16 then
						if sc_wr = '1' then
							regarray(conv_integer(sc_addr)) <= sc_data;
							sc_rply_data <= sc_data;
						else
							sc_rply_data <= regarray(conv_integer(sc_addr));
						end if;
					elsif sc_addr = x"FFFFFFFF" then
						if sc_wr = '1' then
							sc_rply_data <= sc_data;
						else
							sc_rply_data <= rst_delay_cnt & rst_width_cnt & rst_reg_out;
						end if;
					end if;
				when stAck0 =>
					sc_ack <= '1';
					if sc_op = '0' then
						state <= stAck1;
						sc_ack <= '0';
					end if;
				when stAck1 =>
					sc_ack <= '0';
					if sc_frame = '0' then
						state <= stIdle;
					elsif sc_op = '1' then
						state <= stEx;
					end if;
				when others =>
					state <= stIdle;
			end case;
		end if;
	end process;

	
	process(clk, rstn)
	begin
		if rstn = '0' then
			rst_reg_out <= x"0000";
			rst_reg_i <= x"0000";
			rst_delay_cnt <= x"00";
			rst_width_cnt <= x"00";
		elsif clk'event and clk = '1' then
			rst_reg_out <= x"0000";
			if (state = stEx) and (sc_addr = x"FFFFFFFF") then
				rst_delay_cnt <= sc_data(31 downto 24);
				rst_width_cnt <= sc_data(23 downto 16);
				rst_reg_i <= sc_data(15 downto 0);
				if sc_data(31 downto 24) = x"00" then
					rst_reg_out <= sc_data(15 downto 0);
				end if;
			elsif rst_delay_cnt > 0 then
				rst_delay_cnt <= rst_delay_cnt - 1;
				if rst_width_cnt = 0 then
					rst_reg_out <= rst_reg_i;
				end if;
			elsif rst_width_cnt > 0 then
				rst_reg_out <= rst_reg_i;
				rst_width_cnt <= rst_width_cnt - 1;
			else
				rst_reg_out <= x"0000";
			end if;
		end if;
	end process;
	
	rstreg <= rst_reg_out;

end Behavioral;

