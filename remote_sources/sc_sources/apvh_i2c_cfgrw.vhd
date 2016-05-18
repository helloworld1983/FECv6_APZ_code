----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:48:42 02/24/2011 
-- Design Name: 
-- Module Name:    apvh_i2c_cfgrw - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 3.0 - Added ATCA support (G_ADC_COUNT generic)
--								APV addr bit 0 ctrl moved to sc_subaddr(7) from sc_subaddr(16) !!
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

entity apvh_i2c_cfgrw is
	 Generic( PORT_APVH_I2C :std_logic_vector(15 downto 0) := x"1877";
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
			  i2c_rst : out STD_LOGIC;
           cfg_i2c_scl : in  STD_LOGIC_VECTOR (7 downto 0);
           cfg_i2c_sda : in  STD_LOGIC_VECTOR (7 downto 0));
end apvh_i2c_cfgrw;

architecture Behavioral of apvh_i2c_cfgrw is


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

type state_type is (stIdle, stReg, stI2CBRST, stMux0, stMux1, stMux2, stMux3, stI2C0, stI2C1, stI2C3, stI2C4, stAck0, stAck1);
signal state: state_type;
signal i2crst_counter : std_logic_vector(9 downto 0);
signal i2c_mode, i2c_addr, i2c_error : std_logic_vector(7 downto 0);
signal i2c_data, i2c_rxdata: std_logic_vector(15 downto 0);
signal i2c_cs, i2c_len, i2c_busy : std_logic;

signal muxaddr, muxaddr2, bcstaddr, masteraddr, slaveaddr: std_logic_vector(6 downto 0);
signal masteraddr_reg, slaveaddr_reg: std_logic_vector(5 downto 0);
signal plladdr : std_logic_vector(4 downto 0);
signal vfataddr : std_logic_vector(2 downto 0);
signal cfg_i2c_scl_reg, cfg_i2c_sda_reg: std_logic_vector(7 downto 0);
signal i2c_mode_reg: std_logic_vector(6 downto 0);
signal sc_rply_error_i2c, sc_rply_data_i2c: std_logic_vector(31 downto 0);

	function f_reverse_vector (a: in std_logic_vector)
	return std_logic_vector is
	  variable result: std_logic_vector(a'RANGE);
	  alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
	begin
	  for i in aa'RANGE loop
		 result(i) := aa(i);
	  end loop;
	  return result;
	end; -- function reverse_any_vector

begin
	muxaddr <= "1110000";
	muxaddr2 <= "1110001";
	
	masteraddr <= masteraddr_reg & not sc_subaddr(7);
	slaveaddr <= slaveaddr_reg & not sc_subaddr(7);
	process(clk, rstn)
	begin
		if rstn = '0' then
			masteraddr_reg <= "011010";
			slaveaddr_reg <= "011011";
			plladdr <= "11000";
			bcstaddr <= "0111111";
			vfataddr <= "101";
			cfg_i2c_scl_reg <= cfg_i2c_scl;
			cfg_i2c_sda_reg <= cfg_i2c_sda;
			i2c_mode_reg <= (others => '0');
			sc_rply_error <= (others => '0');
			sc_rply_data  <= (others => '0');
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
					sc_rply_error <= (others => '0');
					sc_rply_data  <= (others => '0');
--					if ((sc_frame and sc_op) = '1') and (sc_port = PORT_APVH_I2C) then
					if (sc_op = '1') and (sc_port = PORT_APVH_I2C) then
						if sc_addr(31 downto 8) /= x"000000" then
							state <= stREG;
						else
							state <= stI2CBRST;
						end if;
					end if;
				when stREG =>
					state <= stAck0;
					sc_ack <= '1';
					sc_rply_error <= x"00000100";
					if sc_wr = '1' then
						case sc_addr is
							when x"00000100" => plladdr <= sc_data(7 downto 3);
							when x"00000101" => masteraddr_reg <= sc_data(7 downto 2);
							when x"00000102" => slaveaddr_reg <= sc_data(7 downto 2);
							when x"00000103" => bcstaddr <= sc_data(7 downto 1);
							when x"00000104" => vfataddr <= sc_data(7 downto 5);
							when x"0000010F" => 	i2c_mode_reg <= sc_data(23 downto 17);
														cfg_i2c_scl_reg <= sc_data(15 downto 8);
														cfg_i2c_sda_reg <= sc_data(7 downto 0);
							when others =>
						end case;
						sc_rply_data <= sc_data;
					else
						sc_rply_data <= x"00000000";
						case sc_addr is
							when x"00000100" => sc_rply_data(7 downto 3) <= plladdr;
							when x"00000101" => sc_rply_data(7 downto 2) <= masteraddr_reg;
							when x"00000102" => sc_rply_data(7 downto 2) <= slaveaddr_reg;
							when x"00000103" => sc_rply_data(7 downto 1) <= bcstaddr;
							when x"00000104" => sc_rply_data(7 downto 5) <= vfataddr;
							when x"0000010F" => 	sc_rply_data(23 downto 17) <= i2c_mode_reg;
														sc_rply_data(15 downto 8) <= cfg_i2c_scl_reg;
														sc_rply_data(7 downto 0) <= cfg_i2c_sda_reg;
							when others =>
						end case;
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
						if (G_ADC_COUNT > 2) then
							state <= stMux2;
						else
							state <= stI2C0;
						end if;
					end if;
				when stMux2 => 
					i2c_rst <= '0';
					i2c_cs <= '1';
					i2c_addr <= muxaddr2 & '0';
					i2c_len <= '0';
					i2c_data <= x"0" & f_reverse_vector(sc_subaddr(19 downto 16)) & x"FF";
					if i2c_busy = '1' then
						state <= stMux3;
					end if;
				when stMux3 =>
					i2c_cs <= '0';
					if i2c_busy = '0' then
						state <= stI2C0;
					end if;
				when stI2C0 =>
					i2c_cs <= '1'; 
					if sc_subaddr(1 downto 0) = "00" or sc_subaddr(2 downto 0) = "100" then
						if sc_wr = '1' then
							i2c_data <=  sc_data(7 downto 0) & x"FF";
						else
							i2c_data <= x"FFFF";
						end if;
						i2c_len <= '0';
					else
						-- APV write or APV read (transfer 1)
						i2c_data <= sc_addr(6 downto 0) & (not sc_wr) & sc_data(7 downto 0);
						i2c_len <= sc_wr;
					end if;	
					case sc_subaddr(2 downto 0) is
						when "000" =>
							i2c_addr <= plladdr & sc_addr(1 downto 0) & (not sc_wr);
						when "001" =>
							i2c_addr <= masteraddr & '0';
						when "010" =>
							i2c_addr <= slaveaddr & '0';
--						when "011" =>
						when "011" | "111" =>
							i2c_addr <= bcstaddr & '0';
						when "100" =>
							i2c_addr <= vfataddr & sc_addr(3 downto 0) & (not sc_wr);
						when others => 
							i2c_addr <= x"FF";
					end case;
					if i2c_busy = '1' then
						state <= stI2C1;
					end if;
				when stI2C1 =>
					i2c_cs <= '0';
					sc_ack <= '0';
					if i2c_busy = '0' then
						if (sc_wr = '0') and (sc_subaddr(1 downto 0) /= "00" and sc_subaddr(2 downto 0) /= "100") then
							state <= stI2C3;
						else
							state <= stAck0;
							sc_rply_error <= sc_rply_error_i2c;
							sc_rply_data <= sc_rply_data_i2c;
							sc_ack <= '1';
						end if;
					end if;
				when stI2C3 =>
					-- APV read (transfer 2) 
					i2c_cs <= '1'; 
					i2c_data <= x"FFFF";
					i2c_len <= '0';
					case sc_subaddr(1 downto 0) is
						when "01" =>
							i2c_addr <= masteraddr & '1';
						when "10" =>
							i2c_addr <= slaveaddr & '1';
						when "11" =>
							i2c_addr <= bcstaddr & '1';
						when others => 
							i2c_addr <= x"FF";
					end case;
					if i2c_busy = '1' then
						state <= stI2C4;
					end if;
				when stI2C4 => 
					i2c_cs <= '0';
					sc_ack <= '0';
					if i2c_busy = '0' then
						state <= stAck0;
						sc_ack <= '1';
						sc_rply_error <= sc_rply_error_i2c;
						sc_rply_data <= sc_rply_data_i2c;
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

	i2c_mode <= i2c_mode_reg & i2c_len;
	sc_rply_error_i2c <= x"000000" & i2c_error;
	sc_rply_data_i2c <= x"0000" & i2c_rxdata;
	
	Inst_i2c_2byte_core_v2: i2c_2byte_core_v2 PORT MAP(
		clk => clk,
		rst_n => rstn,
		scl => scl,
		sda => sda,
		mode => i2c_mode,
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

