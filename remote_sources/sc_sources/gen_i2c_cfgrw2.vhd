----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:48:42 02/24/2011 
-- Design Name: 
-- Module Name:    gen_i2c_cfgrw2 - Behavioral 
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

entity gen_i2c_cfgrw2 is
	Generic (PORT_GEN_I2C: std_logic_vector(15 downto 0) := x"1787");
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
--			  i2c_rst : out STD_LOGIC;
           cfg_i2c_scl : in  STD_LOGIC_VECTOR (7 downto 0);
           cfg_i2c_sda : in  STD_LOGIC_VECTOR (7 downto 0));
end gen_i2c_cfgrw2;

architecture Behavioral of gen_i2c_cfgrw2 is

--constant PORT_GEN_I2C: std_logic_vector(15 downto 0) := x"1787";

	COMPONENT i2c_4byte_core
	PORT(
		clk : IN std_logic;
		rst_n : IN std_logic;
		mode : IN std_logic_vector(7 downto 0);
		clkdiv_reg : IN std_logic_vector(7 downto 0);
		sda_delay : IN std_logic_vector(7 downto 0);
		len : IN std_logic_vector(1 downto 0);
		wae : IN std_logic;
		addr_rw : IN std_logic_vector(7 downto 0);
		waddr : IN std_logic_vector(7 downto 0);
		tx_data : IN std_logic_vector(31 downto 0);
		cs : IN std_logic;    
		scl : INOUT std_logic;
		sda : INOUT std_logic;      
		rx_data : OUT std_logic_vector(31 downto 0);
		busy : OUT std_logic;
		error : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

type state_type is (stIdle, stI2C0, stI2C1, stI2C3, stI2C4, stAck0, stAck1);
signal state: state_type;
signal i2crst_counter : std_logic_vector(9 downto 0);
signal i2c_mode, i2c_addr, i2c_error, i2c_waddr: std_logic_vector(7 downto 0);
signal i2c_data, i2c_rxdata: std_logic_vector(31 downto 0);
signal i2c_cs, i2c_busy, i2c_wae : std_logic;
signal i2c_len: std_logic_vector(1 downto 0);

signal pollcounter: std_logic_vector(4 downto 0);
signal regi2caddr, regi2cmode: std_logic_vector(7 downto 0);
begin
--------------------------------------------------
-- History:
-- * I2C address and mode controlled by either subaddress or addrress fields
-- * upto 4 byte data read/write
--------------------------------------------------
	regi2caddr <= sc_addr(31 downto 24) when sc_subaddr = x"FFFFFFFF" else sc_subaddr(31 downto 24);
	regi2cmode <= sc_addr(23 downto 16) when sc_subaddr = x"FFFFFFFF" else sc_subaddr(23 downto 16);
	
	-- regi2cmode(7) : double transfer mode (1) / single tranfer mode (0)
	-- regi2cmode(6) : repeat op 10 times until ack in single tranfer mode 
	-- regi2cmode(5) : acknowledge when read op 
	-- regi2cmode(4) : [0] -> endian flip 
	-- regi2cmode(3) : reserved 
	-- regi2cmode(2) : reserved 
	-- regi2cmode(1:0) : data length (1 / 4 bytes) 
	
	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stIdle;
			i2c_cs <= '0';
			i2c_addr <= (others => '1');
			i2c_waddr <= (others => '1');
			i2c_data <= (others => '1');
			i2c_len <= "00";
			i2c_wae <= '0';
			sc_ack <= '0';
			pollcounter <= (others => '0');
		elsif clk'event and clk = '1' then
			case state is
				when stIdle =>
					pollcounter <= (others => '0');
					i2c_cs <= '0';
					i2c_addr <= (others => '1');
					i2c_data <= (others => '1');
					i2c_waddr <= (others => '1');
					i2c_len <= "00";
					i2c_wae <= '0';
					sc_ack <= '0';
--					if ((sc_frame and sc_op) = '1') and (sc_port = PORT_GEN_I2C) then
					if (sc_op = '1') and (sc_port = PORT_GEN_I2C) then
						state <= stI2C0;
					end if;
				when stI2C0 =>
					i2c_cs <= '1'; 
					if regi2cmode(7) = '0' then
						i2c_addr <= regi2caddr(7 downto 1) & (not sc_wr);
						i2c_data <= sc_data;
						i2c_len <= regi2cmode(1 downto 0);
						i2c_wae <= '0';
					else
						-- I2C write or I2C read (transfer 1)
						i2c_addr <= regi2caddr(7 downto 1) & '0';
						if sc_wr = '1' then
							i2c_wae <= '1';
							i2c_data <= sc_data;
							i2c_waddr <= sc_addr(7 downto 0);
							i2c_len <= regi2cmode(1 downto 0);
						else
							i2c_wae <= '0';
							i2c_data <=  x"FFFFFF" & sc_addr(7 downto 0);
							i2c_waddr <= x"FF";
							i2c_len <= "00";
						end if;
					end if;	
					if i2c_busy = '1' then
						state <= stI2C1;
					end if;
				when stI2C1 =>
					i2c_cs <= '0';
					sc_ack <= '0';
					if i2c_busy = '0' then
						if (sc_wr = '0') and (regi2cmode(7)= '1') then
							state <= stI2C3;
						elsif (sc_wr = '1') and (regi2cmode(6) = '1') then
							if (i2c_error(1) = '1') and (pollcounter < 10) then
								pollcounter <= pollcounter + 1;
								state <= stI2C0;
							else
								state <= stAck0;
								sc_ack <= '1';
							end if;
						else
							state <= stAck0;
							sc_ack <= '1';
						end if;
					end if;
				when stI2C3 =>
					-- I2C read (transfer 2) 
					i2c_cs <= '1'; 
					i2c_data <= x"FFFFFFFF";
					i2c_len <= regi2cmode(1 downto 0);
					i2c_wae <= '0';
					i2c_addr <= regi2caddr(7 downto 1) & '1';
					if i2c_busy = '1' then
						state <= stI2C4;
					end if;
				when stI2C4 => 
					i2c_cs <= '0';
					sc_ack <= '0';
					if i2c_busy = '0' then
						state <= stAck0;
						sc_ack <= '1';
					end if;
				when stAck0 =>
					pollcounter <= (others => '0');
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

	i2c_mode <= "000000" & regi2cmode(5 downto 4);
	sc_rply_error <= x"000000" & i2c_error;
	sc_rply_data <= i2c_rxdata;
	
	Inst_i2c_4byte_core: i2c_4byte_core PORT MAP(
		clk => clk,
		rst_n => rstn,
		scl => scl,
		sda => sda,
		mode => i2c_mode,
		clkdiv_reg => cfg_i2c_scl,
		sda_delay => cfg_i2c_sda,
		len => i2c_len,
		wae => i2c_wae,
		addr_rw => i2c_addr,
		waddr => i2c_waddr,
		tx_data => i2c_data,
		rx_data => i2c_rxdata,
		cs => i2c_cs,
		busy => i2c_busy,
		error => i2c_error
	);
					

end Behavioral;

