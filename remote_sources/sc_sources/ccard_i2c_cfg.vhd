----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:07:00 03/02/2011 
-- Design Name: 
-- Module Name:    ccard_i2c_cfg - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 3.0 - Added ATCA support (G_ADC_COUNT generic)
-- Revision: 2.0 - Added configuration registers
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
--library work;
--use work.ethernet_pkg.all;

entity ccard_i2c_cfg is
	 Generic( PORT_CCARD_I2C : std_logic_vector(15 downto 0) := x"1977";
				constant G_ADC_COUNT : natural := 2);
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
           scl : inout  STD_LOGIC;
           sda : inout  STD_LOGIC;
           cfg_i2c_scl : in  STD_LOGIC_VECTOR (7 downto 0);
           cfg_i2c_sda : in  STD_LOGIC_VECTOR (7 downto 0));
end ccard_i2c_cfg;

architecture Behavioral of ccard_i2c_cfg is

	COMPONENT i2c_2byte_core_v2
	PORT(
		clk : IN std_logic;
		rst_n : IN std_logic;
		mode : IN std_logic_vector(7 downto 0);
		reverse_i2c : in  STD_LOGIC := '0';
		clkdiv_reg : IN std_logic_vector(7 downto 0);
		sda_delay : IN std_logic_vector(7 downto 0);
		addr_rw : IN std_logic_vector(7 downto 0);
		tx_data : IN std_logic_vector(15 downto 0);
		cs : IN std_logic;    
		scl : INOUT std_logic;
		sda : INOUT std_logic;      
		rx_data : OUT std_logic_vector(15 downto 0);
		busy : OUT std_logic;
		error : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

type state_type is (stIdle, stREG, stI2C0, stI2C1, stAck0, stAck1);
signal state: state_type;
signal i2crst_counter : std_logic_vector(9 downto 0);
signal i2c_mode, i2c_addr, i2c_error : std_logic_vector(7 downto 0);
signal i2c_data, i2c_data_i, i2c_rxdata: std_logic_vector(15 downto 0);
signal i2c_cs, i2c_len, i2c_busy : std_logic;

signal ccardaddr:  std_logic_vector(3 downto 0);

signal cfg_i2c_scl_reg, cfg_i2c_sda_reg: std_logic_vector(7 downto 0);
signal i2c_mode_reg: std_logic_vector(6 downto 0);
signal sc_rply_error_i2c, sc_rply_data_i2c: std_logic_vector(31 downto 0);
signal reverse_i2c_reg: std_logic;
signal reverse_i2c, reverse_i2c_auto: std_logic;
signal sc_data_mapped: std_logic_vector(15 downto 0);
signal sc_addr_mapped: std_logic_vector(7 downto 0);

begin

	ccardaddr <= "0100";
	
	process(clk, rstn)
	begin
		if rstn = '0' then
--			ccardaddr <= "0100";
			cfg_i2c_scl_reg <= cfg_i2c_scl;
			cfg_i2c_sda_reg <= cfg_i2c_sda;
			i2c_mode_reg <= (others => '0');
			reverse_i2c_reg <= '0';
			sc_rply_error <= (others => '0');
			sc_rply_data  <= (others => '0');
			state <= stIdle;
			i2c_cs <= '0';
			i2c_addr <= (others => '0');
			i2c_data <= (others => '0');
			sc_ack <= '0';
		elsif clk'event and clk = '1' then
			case state is
				when stIdle =>
					i2c_cs <= '0';
					i2c_addr <= (others => '0');
					i2c_data <= (others => '0');
					sc_ack <= '0';
					sc_rply_error <= (others => '0');
					sc_rply_data  <= (others => '0');
--					if ((sc_frame and sc_op) = '1') and (sc_port = PORT_CCARD_I2C) then
					if (sc_op = '1') and (sc_port = PORT_CCARD_I2C) then
						if sc_addr(31 downto 8) = x"000000" then
							state <= stI2C0;
						else
							state <= stREG;
						end if;
					end if;
				when stREG =>
					state <= stAck0;
					sc_ack <= '1';
					sc_rply_error <= x"00000100";
					if sc_wr = '1' then
						case sc_addr is
--							when x"00000100" => ccardaddr <= sc_data(7 downto 4);
							when x"0000010E" => reverse_i2c_reg <= sc_data(0);
							when x"0000010F" => 	i2c_mode_reg <= sc_data(23 downto 17);
														cfg_i2c_scl_reg <= sc_data(15 downto 8);
														cfg_i2c_sda_reg <= sc_data(7 downto 0);
							when others =>
						end case;
						sc_rply_data <= sc_data;
					else
						sc_rply_data <= x"00000000";
						case sc_addr is
--							when x"00000100" => sc_rply_data(7 downto 4) <= ccardaddr;
							when x"0000010E" => sc_rply_data(0) <= reverse_i2c_reg;
							when x"0000010F" => 	sc_rply_data(23 downto 17) <= i2c_mode_reg;
														sc_rply_data(15 downto 8) <= cfg_i2c_scl_reg;
														sc_rply_data(7 downto 0) <= cfg_i2c_sda_reg;
							when others =>
						end case;
					end if;
				when stI2C0 =>
					i2c_cs <= '1';
					i2c_addr <= ccardaddr & sc_addr_mapped(2 downto 0) & (not sc_wr);
					if sc_wr = '1' then
--						i2c_data <=  sc_data(7 downto 0) & x"FF";
						i2c_data <=  i2c_data_i;
					else
						i2c_data <= x"FFFF";
					end if;
					if i2c_busy = '1' then
						state <= stI2C1;
					end if;
				when stI2C1 => 
					i2c_cs <= '0';
					sc_ack <= '0';
					if i2c_busy = '0' then
						state <= stAck0;
						sc_rply_error <= sc_rply_error_i2c;
						sc_rply_data <= sc_rply_data_i2c;
						sc_ack <= '1';
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
						if sc_addr(31 downto 8) = x"000000" then
							state <= stI2C0;
						else
							state <= stREG;
						end if;
					end if;
				when others =>
					state <= stIdle;
			end case;
		end if;
	end process;

	
	gen_adc_3: if (G_ADC_COUNT = 3) generate
		i2c_mode <= i2c_mode_reg & '1';
		i2c_data_i <= sc_data_mapped(7 downto 0) & sc_data_mapped(15 downto 8);
		-- register mapping for ATCA M-ADC
		process(sc_data, sc_addr)
		begin
			sc_data_mapped <= (others => '0');
			sc_addr_mapped <= sc_addr(7 downto 0);
			reverse_i2c_auto <= '0';
			case sc_addr is 
				when x"00000000" =>
					-- RESET
					sc_data_mapped(0) <= sc_data(11);
					sc_data_mapped(1) <= sc_data(10);
					sc_data_mapped(2) <= sc_data(9);
					sc_data_mapped(3) <= sc_data(8);
					sc_data_mapped(6) <= sc_data(7);
					sc_data_mapped(7) <= sc_data(6);
					sc_data_mapped(8) <= sc_data(5);
					sc_data_mapped(11) <= sc_data(4);
					sc_data_mapped(12) <= sc_data(3);
					sc_data_mapped(13) <= sc_data(2);
					sc_data_mapped(14) <= sc_data(1);
					sc_data_mapped(15) <= sc_data(0);
					reverse_i2c_auto <= '1';
				when x"00000003" =>
					-- EQ0/1 A
					sc_addr_mapped <= x"01";
					sc_data_mapped(0) <= sc_data(3);
					sc_data_mapped(1) <= sc_data(11);
					sc_data_mapped(2) <= sc_data(13);
					sc_data_mapped(3) <= sc_data(5);
					sc_data_mapped(4) <= sc_data(12);
					sc_data_mapped(5) <= sc_data(4);
					sc_data_mapped(6) <= sc_data(2);
					sc_data_mapped(7) <= sc_data(10);
					
					sc_data_mapped(9) <= sc_data(1);
					sc_data_mapped(10) <= sc_data(9);
					sc_data_mapped(14) <= sc_data(8);
					sc_data_mapped(15) <= sc_data(0);
				when x"00000004" =>
					-- EQ0/1 B
					sc_addr_mapped <= x"02";
					sc_data_mapped(0) <= sc_data(5);
					sc_data_mapped(1) <= sc_data(13);
					sc_data_mapped(2) <= sc_data(12);
					sc_data_mapped(3) <= sc_data(4);
					sc_data_mapped(4) <= sc_data(11);
					sc_data_mapped(5) <= sc_data(3);
					sc_data_mapped(6) <= sc_data(2);
					sc_data_mapped(7) <= sc_data(10);
					
					sc_data_mapped(8) <= sc_data(1);
					sc_data_mapped(9) <= sc_data(9);
					sc_data_mapped(10) <= sc_data(0);
					sc_data_mapped(11) <= sc_data(8);
				when x"00000001" =>
					-- PD A/B 0
					sc_addr_mapped <= x"04";
					sc_data_mapped(0) <= sc_data(13);
					sc_data_mapped(1) <= sc_data(5);
					sc_data_mapped(2) <= sc_data(12);
					sc_data_mapped(3) <= sc_data(4);
					sc_data_mapped(4) <= sc_data(11);
					sc_data_mapped(5) <= sc_data(3);
					sc_data_mapped(6) <= sc_data(10);
					sc_data_mapped(7) <= sc_data(2);
					
					sc_data_mapped(11) <= sc_data(9);
					sc_data_mapped(12) <= sc_data(1);
					sc_data_mapped(13) <= sc_data(8);
					sc_data_mapped(14) <= sc_data(0);
				when x"00000002" =>
					-- PD A/B 0
					sc_addr_mapped <= x"03";
					sc_data_mapped(0) <= sc_data(0);
					sc_data_mapped(1) <= sc_data(1);
					sc_data_mapped(2) <= sc_data(2);
					sc_data_mapped(3) <= sc_data(10);
					sc_data_mapped(4) <= sc_data(3);
					sc_data_mapped(5) <= sc_data(4);
					
					sc_data_mapped(10) <= sc_data(13);
					sc_data_mapped(11) <= sc_data(5);
					sc_data_mapped(12) <= sc_data(12);
					sc_data_mapped(13) <= sc_data(11);
					sc_data_mapped(14) <= sc_data(9);
					sc_data_mapped(15) <= sc_data(8);
				when others =>
					sc_data_mapped <= sc_data(15 downto 0);
			end case;
		end process;
	end generate;
	
	gen_adc_2: if (G_ADC_COUNT < 3) generate
		i2c_mode <= i2c_mode_reg & '0';
		i2c_data_i <= sc_data(7 downto 0) & x"FF";
		sc_addr_mapped <= sc_addr(7 downto 0);
	end generate;
	
	sc_rply_error_i2c <= x"000000" & i2c_error;
	sc_rply_data_i2c <= x"0000" & i2c_rxdata;
	
	reverse_i2c <= reverse_i2c_auto xor reverse_i2c_reg;
	
	Inst_i2c_2byte_core_v2: i2c_2byte_core_v2 PORT MAP(
		clk => clk,
		rst_n => rstn,
		scl => scl,
		sda => sda,
		mode => i2c_mode,
		reverse_i2c => reverse_i2c,
		clkdiv_reg => cfg_i2c_scl_reg,
		sda_delay => cfg_i2c_sda_reg,
		addr_rw => i2c_addr,
		tx_data => i2c_data,
		rx_data => i2c_rxdata,
		cs => i2c_cs,
		busy => i2c_busy,
		error => i2c_error
	);
					

end Behavioral;

