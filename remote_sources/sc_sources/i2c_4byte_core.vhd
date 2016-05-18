----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:21:34 11/18/2009 
-- Design Name: 
-- Module Name:    i2c_2byte_core - Behavioral 
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
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity i2c_4byte_core is
    Port ( clk : in  STD_LOGIC;
           rst_n : in  STD_LOGIC;
           scl : inout  STD_LOGIC;
           sda : inout  STD_LOGIC;
           mode : in  STD_LOGIC_VECTOR (7 downto 0);
			  -- 7: abort when no ack
			  -- 6: wait for cs = '0' after transaction
			  -- [5:2] scl/sda delay
			  -- acknowledge when read op
			  -- 0: [0] -> endian flip
			  clkdiv_reg: in std_logic_vector(7 downto 0);
			  -- default "11000111" = 199 (clk=10MHz => scl = 100kHz)
			  sda_delay: in std_logic_vector(7 downto 0);
			  len : in STD_LOGIC_VECTOR (1 downto 0);
			  wae : in std_logic;
           addr_rw : in  STD_LOGIC_VECTOR (7 downto 0);
			  waddr : in STD_LOGIC_VECTOR (7 downto 0);
           tx_data : in  STD_LOGIC_VECTOR (31 downto 0);
           rx_data : out  STD_LOGIC_VECTOR (31 downto 0);
           cs : in  STD_LOGIC;
           busy : out  STD_LOGIC;
           error : out  STD_LOGIC_VECTOR (7 downto 0));
end i2c_4byte_core;

architecture Behavioral of i2c_4byte_core is
  TYPE I2CState_type IS (
    SIdl,
    SSta,
    SD0,
    SD1,
	 SA0,
	 SA1,
--	 SError,
    SSto0,
	 SSto1,
	 SFin
    );
  SIGNAL TxSt, NSt : I2CState_type;
signal scl_out, scl_in: std_logic;
signal scl_out_q, sda_out_q: std_logic_vector(15 downto 0);
signal sda_out, sda_in, scl_out_x, sda_out_x: std_logic;
signal sclk_en, sr_load, sr_shift, cs_int : std_logic;
signal sr: std_logic_vector(47 downto 0);
signal dataCount: std_logic_vector(5 downto 0);
signal sclkCount: std_logic_vector(9 downto 0);
signal rx_data_int: std_logic_vector(31 downto 0);
signal sda_del_switch, sda_out_xx: std_logic;
signal error_i : std_logic_vector(7 downto 0);
--constant clkdiv_reg: std_logic_vector(7 downto 0) := "11000111"; -- 199

signal countend_pointer : std_logic_vector(2 downto 0);
signal endianflip_data, endianflip_rxdata, rxdata_i, tx_data_i: std_logic_vector(31 downto 0);
begin
	sclPAD : IOBUF     GENERIC MAP (
		DRIVE => 24,
      IOSTANDARD => "LVCMOS25")
	PORT MAP (
    T  => scl_out_x,                          
    I  => '0',
    O  => scl_in,
    IO => scl);
	 
	sdaPAD : IOBUF     GENERIC MAP (
		DRIVE => 24,
      IOSTANDARD => "LVCMOS25")
	PORT MAP (
    T  => sda_out_x,                          
    I  => '0',
    O  => sda_in,
    IO => sda);
	
	process(mode(5 downto 2),scl_out_q)
	begin
		if mode(5) = '0' then
			case mode(4 downto 2) is 
				when "000" =>
					scl_out_x <= scl_out_q(0);
				when "001" =>
					scl_out_x <= scl_out_q(1);
				when "010" =>
					scl_out_x <= scl_out_q(2);
				when "011" =>
					scl_out_x <= scl_out_q(3);
				when "100" =>
					scl_out_x <= scl_out_q(5);
				when "101" =>
					scl_out_x <= scl_out_q(7);
				when "110" =>
					scl_out_x <= scl_out_q(9);
				when "111" =>
					scl_out_x <= scl_out_q(11);
				when others =>
					scl_out_x <= scl_out_q(15);
			end case;
		else
				scl_out_x <= scl_out_q(0);
		end if;
	end process;
	process(mode(5 downto 2),sda_out_q)
	begin
		if mode(5) = '1' then
			case mode(4 downto 2) is 
				when "000" =>
					sda_out_x <= sda_out_q(0);
				when "001" =>
					sda_out_x <= sda_out_q(1);
				when "010" =>
					sda_out_x <= sda_out_q(2);
				when "011" =>
					sda_out_x <= sda_out_q(3);
				when "100" =>
					sda_out_x <= sda_out_q(5);
				when "101" =>
					sda_out_x <= sda_out_q(7);
				when "110" =>
					sda_out_x <= sda_out_q(9);
				when "111" =>
					sda_out_x <= sda_out_q(11);
				when others =>
					sda_out_x <= sda_out_q(15);
			end case;
		else
				sda_out_x <= sda_out_q(0);
		end if;
	end process;

--	scl <= 'Z' when scl_out = '1' else '0';
--	scl_in <= scl;
--	sda <= 'Z' when sda_out = '1' else '0';
--	sda_in <= sda;
	sda_del_switch <= '1' when (not(sda_delay = 0) and (sda_delay < clkdiv_reg)) else '0';
	
	endianflip_data <= tx_data(7 downto 0) & tx_data(15 downto 8) & tx_data(23 downto 16) & tx_data(31 downto 24);
	endianflip_rxdata <= rx_data_int(7 downto 0) & rx_data_int(15 downto 8) & rx_data_int(23 downto 16) & rx_data_int(31 downto 24);

	process(mode(0), endianflip_data, tx_data, len)
	begin
		if mode(0) = '0' then
			tx_data_i <= endianflip_data;
		elsif len = 3 then
			tx_data_i <= tx_data;
		elsif len = 2 then 
			tx_data_i <= tx_data(23 downto 0) & x"FF";
		elsif len = 1 then 
			tx_data_i <= tx_data(15 downto 0) & x"FFFF";
		elsif len = 0 then 
			tx_data_i <= tx_data( 7 downto 0) & x"FFFFFF";
		end if;
	end process;
	process(mode(0), endianflip_rxdata, rx_data_int, len)
	begin
		if mode(0) = '0' then
			rxdata_i <= endianflip_rxdata;
		elsif len = 3 then
			rxdata_i <= rx_data_int;
		elsif len = 2 then 
			rxdata_i <= x"00" & rx_data_int(23 downto 0);
		elsif len = 1 then 
			rxdata_i <= x"0000" & rx_data_int(15 downto 0);
		elsif len = 0 then 
			rxdata_i <= x"000000" & rx_data_int( 7 downto 0);
		end if;
	end process;
			
	
	
	process (clk, rst_n)
	begin
		if rst_n = '0' then
			sclkCount <= (others => '0');
			dataCount <= (others => '0');
			TxSt <= SIdl;
			sr <= (others => '0');
			scl_out_q <= (others => '1');
			sda_out_q <= (others => '1');
			sda_out_xx <= '1';
		elsif clk'event and clk = '1' then
			if TxSt = SD0 then
				if sclkCount = sda_delay & "11" then
					sda_out_xx <= sda_out;
				end if;
			else
				sda_out_xx <= sda_out;
			end if;
			scl_out_q <= scl_out_q(14 downto 0) & scl_out;
			if sda_del_switch = '0' then									--????
				sda_out_q <= scl_out_q(14 downto 0) & sda_out;
			else
				sda_out_q <= scl_out_q(14 downto 0) & sda_out_xx;
			end if;
			if sr_load = '1' then				-- shift register
				sr(47 downto 40) <= addr_rw;
				if wae = '1' then
					sr(39 downto 32) <= waddr;
					sr(31 downto 0) <= tx_data_i;
				else
					sr(39 downto 8) <= tx_data_i;
					sr(7 downto 0) <= x"FF";
				end if;
				dataCount <= (others => '0');
			elsif (sr_shift and sclk_en) = '1' then
				sr <= sr(46 downto 0) & '1';
				dataCount <= dataCount + 1;
			end if;
			if sclk_en = '1' then				-- state register
				TxSt <= NSt;
			end if;
			if sclkCount = clkdiv_reg & "11" then	-- clock divider
				sclkCount <= (others => '0');
			else
				sclkCount <= sclkCount + 1;
			end if;
		end if;
	end process;
	
	sclk_en <= '1' when (sclkCount = (clkdiv_reg & "11")) else '0';
	
	countend_pointer <= ('0' & len) + "010" + ("00" & wae);
	
	process (TxSt, sda_in, cs, cs_int, sr(47), dataCount, countend_pointer, mode(7), mode(6), mode(1), addr_rw)
	begin
		case TxSt is
			when SIdl =>
				scl_out <= '1';
				sda_out <= '1';
				sr_load <= '1';
				sr_shift <= '0';
				if cs_int= '1' then
					NSt <= SSta;
				else
					NSt <= SIdl;
				end if;
			when SSta =>
				scl_out <= '1';
				sda_out <= '0';
				sr_load <= '0';
				sr_shift <= '0';
				NSt <= SD0;
			when SD0 =>
				scl_out <= '0';
				sda_out <= sr(47);
				sr_load <= '0';
				sr_shift <= '0';
				NSt <= SD1;
			when SD1 =>
				scl_out <= '1';
				sda_out <= sr(47);
				sr_load <= '0';
				sr_shift <= '1';
				if (dataCount(2 downto 0) = "111") then
					NSt <= SA0;
				else
					NSt <= SD0;
				end if;
			when SA0 =>
				scl_out <= '0';
				if ((addr_rw(0) and mode(1)) = '1') and 
					(dataCount(5 downto 3) > 0) and 
					(dataCount(5 downto 3) < countend_pointer) then
					sda_out <= '0';
				else
					sda_out <= '1';
				end if;
				sr_load <= '0';
				sr_shift <= '0';
				NSt <= SA1;
			when SA1 =>
				scl_out <= '1';
				if ((addr_rw(0) and mode(1)) = '1') and 
					(dataCount(5 downto 3) > 0) and 
					(dataCount(5 downto 3) < countend_pointer) then
					sda_out <= '0';
				else
					sda_out <= '1';
				end if;
				sr_load <= '0';
				sr_shift <= '0';
				if (sda_in and mode(7)) = '1' then
					NSt <= SSto0;
--				elsif dataCount(4 downto 3) = ('1' & mode(0)) then
				elsif dataCount(5 downto 3) = countend_pointer then
					NSt <= SSto0;
				else
					NSt <= SD0;
				end if;
			when SSto0 =>
				scl_out <= '0';
				sda_out <= '0';
				sr_load <= '0';
				sr_shift <= '0';
				NSt <= SSto1;
			when SSto1 =>
				scl_out <= '1';
				sda_out <= '0';
				sr_load <= '0';
				sr_shift <= '0';
				NSt <= SFin;
			when SFin =>
				scl_out <= '1';
				sda_out <= '1';
				sr_load <= '0';
				sr_shift <= '0';
				if (cs and mode(6)) = '1' then
					NSt <= SFin;
				else
					Nst <= SIdl;
				end if;
			when others =>
				scl_out <= '1';
				sda_out <= '1';
				sr_load <= '0';
				sr_shift <= '0';
				NSt <= SIdl;
		end case;
	end process;
	
	busy <= '0' when TxSt = SIdl else '1';
	
	process(clk, rst_n)		-- error
	begin
		if rst_n = '0' then
			error <= (others => '0');
			error_i <= (others => '0');
		elsif clk'event and clk = '1' then
			if sclk_en = '1' then
				if TxSt = SIdl then
					error <= (others => '0');
					error_i <= (others => '0');
				elsif (TxSt = SA1) then
					error_i <= error_i(6 downto 0) & sda_in;
					error <= error_i(6 downto 0) & sda_in;
--				elsif (TxSt = SA1) and (sda_in = '1') then
--					error(1 downto 0) <= dataCount(4 downto 3);
				end if;
			end if;
		end if;
	end process;
	process(clk, rst_n)		-- rx_data
	begin
		if rst_n = '0' then
			rx_data_int <= (others => '0');
		elsif clk'event and clk = '1' then
			if sclk_en = '1' then
				if (TxSt = SD1) then
					rx_data_int <= rx_data_int(30 downto 0) & sda_in;
				end if;
			end if;
		end if;
	end process;
	process (clk, rst_n)		-- cs monostable
	begin
		if rst_n = '0' then 
			cs_int <= '0';
		elsif clk'event and clk = '1' then
			if (TxSt = SIdl) then
				if (cs = '1') then
					cs_int <= '1';
				end if;
			else
				cs_int <= '0';
			end if;
		end if;
	end process;
--	rx_data <= rx_data_int;
	rx_data <= rxdata_i;
end Behavioral;

