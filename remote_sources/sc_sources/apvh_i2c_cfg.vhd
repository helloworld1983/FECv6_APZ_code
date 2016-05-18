----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:48:42 02/24/2011 
-- Design Name: 
-- Module Name:    apvh_i2c_cfg - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity apvh_i2c_cfg is
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
			  i2c_rst : out STD_LOGIC;
           cfg_i2c_scl : in  STD_LOGIC_VECTOR (7 downto 0);
           cfg_i2c_sda : in  STD_LOGIC_VECTOR (7 downto 0));
end apvh_i2c_cfg;

architecture Behavioral of apvh_i2c_cfg is

constant PORT_APVH_I2C: std_logic_vector(15 downto 0) := x"1877";

	COMPONENT i2c_2byte_core_v2
	PORT(
		clk : IN std_logic;
		rst_n : IN std_logic;
		mode : IN std_logic_vector(7 downto 0);
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

type state_type is (stIdle, stI2CBRST, stMux0, stMux1, stI2C0, stI2C1, stAck0, stAck1);
signal state: state_type;
signal i2crst_counter : std_logic_vector(9 downto 0);
signal i2c_mode, i2c_addr, i2c_error : std_logic_vector(7 downto 0);
signal i2c_data, i2c_rxdata: std_logic_vector(15 downto 0);
signal i2c_cs, i2c_len, i2c_busy : std_logic;

signal muxaddr, bcstaddr, masteraddr, slaveaddr: std_logic_vector(6 downto 0);
signal plladdr : std_logic_vector(4 downto 0);

begin
	plladdr <= "11000";
	muxaddr <= "1110000";
	bcstaddr <= "0111111";
	masteraddr <= "0111111";
	slaveaddr <= "0111111";
	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stIdle;
			i2crst_counter <= (others => '0');
			i2c_rst <= '0';
			i2c_cs <= '0';
			i2c_addr <= (others => '0');
			i2c_data <= (others => '0');
			i2c_len <= '0';
			sc_ack <= '0';
		elsif clk'event and clk = '1' then
			case state is
				when stIdle =>
					i2crst_counter <= (others => '0');
					i2c_rst <= '0';
					i2c_cs <= '0';
					i2c_addr <= (others => '0');
					i2c_data <= (others => '0');
					i2c_len <= '0';
					sc_ack <= '0';
					if ((sc_frame and sc_op) = '1') and (sc_port = PORT_APVH_I2C) then
						state <= stI2CBRST;
					end if;
				when stI2CBRST =>
					i2crst_counter <= i2crst_counter + 1;
					if i2crst_counter < 100 then
						i2c_rst <= '1';
					else
						i2c_rst <= '0';
					end if;
					if i2crst_counter > 200 then
						state <= stMux0;
					end if;
				when stMux0 => 
					i2c_rst <= '0';
					i2c_cs <= '1';
					i2c_addr <= muxaddr & '0';
					i2c_len <= '0';
					i2c_data <= sc_subaddr(15 downto 8) & x"FF";
					if i2c_busy = '1' then
						state <= stMux1;
					end if;
				when stMux1 =>
					i2c_cs <= '0';
					if i2c_busy = '0' then
						state <= stI2C0;
					end if;
				when stI2C0 =>
					i2c_cs <= '1';
					case sc_subaddr(1 downto 0) is
						when "00" =>
							i2c_addr <= plladdr & sc_addr(1 downto 0) & (not sc_wr);
							i2c_data <=  sc_data(7 downto 0) & x"FF";
							i2c_len <= '0';
						when "01" =>
							i2c_addr <= masteraddr & (not sc_wr);
							i2c_data <= sc_addr(7 downto 0) & sc_data(7 downto 0);
							i2c_len <= '1';
						when "10" =>
							i2c_addr <= slaveaddr & (not sc_wr);
							i2c_data <= sc_addr(7 downto 0) & sc_data(7 downto 0);
							i2c_len <= '1';
						when "11" =>
							i2c_addr <= bcstaddr & (not sc_wr);
							i2c_data <= sc_addr(7 downto 0) & sc_data(7 downto 0);
							i2c_len <= '1';
						when others => 
							i2c_addr <= masteraddr & (not sc_wr);
							i2c_data <= sc_addr(7 downto 0) & sc_data(7 downto 0);
							i2c_len <= '1';
					end case;
					if i2c_busy = '1' then
						state <= stI2C1;
					end if;
				when stI2C1 => 
					sc_ack <= '0';
					if i2c_busy = '0' then
						state <= stAck0;
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
						state <= stI2C0;
					end if;
				when others =>
					state <= stIdle;
			end case;
		end if;
	end process;

	i2c_mode <= "0000000" & i2c_len;
	sc_rply_error <= x"000000" & i2c_error;
	sc_rply_data <= x"0000" & i2c_rxdata;
	
	Inst_i2c_2byte_core_v2: i2c_2byte_core_v2 PORT MAP(
		clk => clk,
		rst_n => rstn,
		scl => scl,
		sda => sda,
		mode => i2c_mode,
		clkdiv_reg => cfg_i2c_scl,
		sda_delay => cfg_i2c_sda,
		addr_rw => i2c_addr,
		tx_data => i2c_data,
		rx_data => i2c_rxdata,
		cs => i2c_cs,
		busy => i2c_busy,
		error => i2c_error
	);
					

end Behavioral;

