----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Sorin Martoiu
-- 
-- Create Date:    21:12:59 01/24/2012 
-- Design Name: 
-- Module Name:    clock_measure - Behavioral 
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
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
--library work;
--use work.fec_dtc_pkg.all;

entity clock_measure is
	Generic ( 	SIMULATION : boolean := false;
					clk_present_hold : integer := 10;
					measure_hold : integer := 10);
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           clkin : in  STD_LOGIC;
           cfg : in  STD_LOGIC_VECTOR (7 downto 0);
			  clock_measure: out  STD_LOGIC_VECTOR (15 downto 0);
			  clock_measure_dv : out STD_LOGIC;
           clock_status : out  STD_LOGIC_VECTOR (5 downto 0));
end clock_measure;

architecture Behavioral of clock_measure is

type state_type is (stIdle, stMeasure, stSettle, stStop);
signal state : state_type;

signal clkin_present, count_en, count_reset, d, rst2 : std_logic;
signal t: std_logic_vector(3 downto 0) := "1000";

signal counter_ref, counter_in, counter_in_i: std_logic_vector(15 downto 0);

signal ref_count_max: integer := 10000;

function OR_reduce (A : std_logic_vector) 
return std_logic is
	variable temp : std_logic;
begin
	temp := '0';
	L1: for i in A'range loop
	temp := temp or A(i);
	end loop L1;
	return temp;
end function OR_reduce; 

signal count_reset_sr, count_en_sr : std_logic_vector(3 downto 0);
signal count_en_s, count_reset_s, count_reset_q: std_logic;

begin

	sim: if (SIMULATION) generate
		ref_count_max <= 100;
		counter_in <= conv_std_logic_vector(conv_integer(counter_in_i) * 100, 16);
	end generate;
	
	synthesis: if (not SIMULATION) generate
		counter_in <= counter_in_i;
	end generate;

	process(clk, rst)
	variable tmp : integer := 0;
	begin
		if rst = '1' then
			state <= stIdle;
			tmp := 0;
			clock_measure_dv <= '0';
			clock_measure <= (others => '0');
			clock_status <= (0 => '1', others => '0');
			count_reset_q <= '0';
		elsif clk'event and clk = '1' then
			count_reset_q <= count_reset;
			if state = stIdle then
				clock_status <= (0 => '1', others => '0');
				clock_measure_dv <= '0';
				if clkin_present = '1' then
					tmp := tmp + 1;
					if tmp > clk_present_hold then
						tmp := 0;
						state <= stMeasure;
					end if;
				else
					tmp := 0;
				end if;
			elsif state = stMeasure then
				clock_status <= (1 => '1', others => '0');
				clock_measure_dv <= '0';
				tmp := 0;
				if counter_ref = ref_count_max - 1 then
					state <= stSettle;
				end if;
			elsif state = stSettle then
				clock_status <= (1 => '1', others => '0');
				if tmp > measure_hold then
					tmp := 0;
--					state <= stStop;
					state <= stIdle;
					clock_status <= (others => '0');
					if (counter_in > 9900) and (counter_in <10100) then
						clock_status(2) <= '1';
					elsif (counter_in > 19800) and (counter_in <20200) then
						clock_status(3) <= '1';
					elsif (counter_in > 29700) and (counter_in <30300) then
						clock_status(4) <= '1';
					elsif (counter_in > 39600) and (counter_in <40400) then
						clock_status(5) <= '1';
					else
						state <= stIdle;
						clock_status(0) <= '1';
					end if;
					clock_measure <= counter_in;
					clock_measure_dv <= '1';
				else
					tmp := tmp + 1;
					clock_measure_dv <= '0';
				end if;
--			elsif state = stStop then
--				tmp := 0;
--				if clkin_present = '0' then
--					state <= stIdle;
--					clock_status <= (1 => '1', others => '0');
--				end if;
			end if;
		end if;
	end process;
	
	count_reset <= '1' when state = stIdle else '0';
	count_en <= '1' when state = stMeasure else '0';
	
	process(clk, rst)
	begin
		if rst = '1' then
			counter_ref <= (others => '0');
		elsif clk'event and clk = '1' then
			if count_reset = '1' then
				counter_ref <= (others => '0');
			elsif count_en = '1' then
				counter_ref <= counter_ref + 1;
			end if;
		end if;
	end process;
	
--	process(clkin, rst)
	process(clkin, rst, count_reset_q)
	begin
--		if rst = '1' then
		if rst = '1' or count_reset_q = '1' then
			counter_in_i <= (others => '0');
--			count_reset_sr <= (others => '0');
			count_en_sr <= (others => '0');
		elsif clkin'event and clkin = '1' then
--			count_reset_sr <= count_reset_sr(count_reset_sr'left -1 downto 0) & count_reset;
			count_en_sr <= count_en_sr(count_en_sr'left -1 downto 0) & count_en;
--			if count_reset_s = '1' then
--				counter_in_i <= (others => '0');
--			elsif count_en_s = '1' then
			if count_en_s = '1' then
				counter_in_i <= counter_in_i + 1;
			end if;
		end if;
	end process;
	
--	count_reset_s <= or_reduce(count_reset_sr);
	count_en_s <= or_reduce(count_en_sr);
	
	clkin_present <= '1';
	
--	process(clkin, rst2, rst)
--	begin 
--		if (rst2 or rst) = '1' then
--			d <= '0';
--		elsif clkin'event and clkin = '1' then
--			d <= '1';
--		end if;
--	end process;
--	process(clk, rst)
--	begin
--		if rst = '1' then
--			clkin_present <= '0';
--			t <= "1000";
--		elsif clk'event and clk = '1' then
--			t <= t(0) & t(3 downto 1);
--			if t(0) = '1' then	
--				clkin_present <= d;
--			end if;
--		end if;
--	end process;
--	rst2 <= t(3);
		
--	rst2 <= clkin_present after 1ns;
	

end Behavioral;

