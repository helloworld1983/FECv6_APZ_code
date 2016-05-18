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

--library work;
--use work.ethernet_pkg.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sc_spi_tx is
	 Generic (
			gen_port : std_logic_vector(15 downto 0) := x"1978"
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
			  -----------------
			  rstreg : out  STD_LOGIC_VECTOR (15 downto 0);
			  spi_enable: out std_logic;
			  spi_sdata: out std_logic;
			  spi_cs_n: out std_logic_vector(31 downto 0)
			  );
end sc_spi_tx;

architecture Behavioral of sc_spi_tx is
	COMPONENT adc_serial_tx
	PORT(
		RESET : IN std_logic;
		SCLK : IN std_logic;
		PDATA : IN std_logic_vector(15 downto 0);
		ADDR : IN std_logic_vector(7 downto 0);
		LOAD : IN std_logic;          
		SDATA : OUT std_logic;
		CS_n : OUT std_logic;
		READY : OUT std_logic
		);
	END COMPONENT;
	
	type state_type is (stIdle, stEx, stEx1, stAck0, stAck1);
	signal state: state_type;

	signal rst_delay_cnt, rst_width_cnt: std_logic_vector(7 downto 0);
	signal rst_reg_i, rst_reg_out : std_logic_vector(15 downto 0);

	signal rst, spi_load, spi_ready, spi_cs_n_i : std_logic;

	signal sc_subaddr_i: std_logic_vector(31 downto 0);

begin


	process(clk, rstn)
	begin
		if rstn = '0' then
			state <= stIdle;
			sc_ack <= '0';
			sc_rply_data <= (others => '0');
			sc_rply_error <= (others => '0');
			sc_subaddr_i <= (others => '0');
			spi_load <= '0';
			spi_enable <= '0';
		elsif clk'event and clk = '1' then
			spi_load <= '0';
			case state is
				when stIdle =>
					spi_enable <= '0';
					sc_ack <= '0';
					sc_rply_data <= (others => '0');
					sc_rply_error <= (others => '0');
					sc_subaddr_i <= (others => '0');
--					if ((sc_frame and sc_op) = '1') and (sc_port = gen_port) then
					if (sc_op = '1') and (sc_port = gen_port) then
						state <= stEx;
						spi_enable <= '1';
					end if;
				when stEx =>
					if sc_addr < 256 then
						if sc_wr = '1' then
							-- regarray(conv_integer(sc_addr)) <= sc_data;
							spi_load <= '1';
							sc_rply_data <= sc_data;
							sc_rply_error <= x"00000000";
							sc_subaddr_i <= sc_subaddr;
							if spi_ready = '0' then 
								state <= stEx1;
							end if;
							sc_ack <= '0';
						else
							sc_rply_data <= x"00000000";
							sc_rply_error <= x"00000001";
							sc_ack <= '1';
							state <= stAck0;
						end if;
					elsif sc_addr = x"FFFFFFFF" then
						sc_ack <= '1';
						state <= stAck0;
						if sc_wr = '1' then
							sc_rply_data <= sc_data;
							sc_rply_error <= x"00000000";
						else
							sc_rply_data <= rst_delay_cnt & rst_width_cnt & rst_reg_out;
							sc_rply_error <= x"00000000";
						end if;
					end if;
				when stEx1 =>
					sc_ack <= '0';
					if spi_ready = '1' then
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
						state <= stEx;
					end if;
				when others =>
					state <= stIdle;
			end case;
		end if;
	end process;
	
	rst <= not rstn;

	Inst_adc_serial_tx: adc_serial_tx PORT MAP(
		RESET => rst,
		SCLK => clk,
		SDATA => spi_sdata,
		CS_n => spi_cs_n_i,
		PDATA => sc_data(15 downto 0),
		ADDR => sc_addr(7 downto 0),
		LOAD => spi_load,
		READY => spi_ready
	);
	
	cs_n_gen: for i in 0 to 31 generate
		spi_cs_n(i) <= (not sc_subaddr_i(i)) or spi_cs_n_i;
	end generate;
	
	process(clk, rstn)			-- generate reset pulses
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

