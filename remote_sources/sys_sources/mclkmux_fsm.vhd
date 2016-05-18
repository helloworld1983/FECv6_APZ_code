----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:36:57 07/25/2012 
-- Design Name: 
-- Module Name:    mclkmux_fsm - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mclkmux_fsm is
    Port ( clk : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
           cfg : in  STD_LOGIC_VECTOR (7 downto 0); -- overlaps with dtcctf cfg
           dtcclk_ok, dtcclk_locked : in  STD_LOGIC;
           ethclk_ok, ethclk_locked: in  STD_LOGIC;
           clksel : out  STD_LOGIC_VECTOR (1 downto 0);
           app_rst : out  STD_LOGIC);
end mclkmux_fsm;


architecture Behavioral of mclkmux_fsm is
--type state_type is (stIDLE, stLOCK, stRST, stDTC, stETH);
type state_type is (stIDLE, stRST, stDTC, stETH);
signal state, next_state: state_type;

alias dtcclk_inh: std_logic is cfg(0);
alias ethclk_sel: std_logic is cfg(7);

signal counter : std_logic_vector(7 downto 0);
constant count_max : std_logic_vector(7 downto 0) := x"C8";		-- 200
--signal lock_counter : std_logic_vector(15 downto 0);
--constant lock_timeout : std_logic_vector(15 downto 0) := x"03E8";		-- 1000

signal clk_locked, clk_ok: std_logic;

signal dtcclk_locked_i, ethclk_locked_i: std_logic;

signal idle_counter : std_logic_vector(31 downto 0);
constant idle_count_max : std_logic_vector(31 downto 0) := x"00989680";		-- 10000 = 250ms
begin

	clk_ok 	<= 	dtcclk_ok when next_state = stDTC else
						ethclk_ok when next_state = stETH else
						'1';
	clk_locked <= 	dtcclk_locked when next_state = stDTC else
						ethclk_locked when next_state = stETH else
						'1';
						
	-- dtcclk_locked debouncer: lock signal should be stable for at least 1000 clks
	dtcclk_locked_filter: block
		signal dtclock_counter: std_logic_vector(15 downto 0);
		constant dtclock_max : std_logic_vector(15 downto 0) := x"03E8";		-- 1000
	begin
		process(clk, rstn)
		begin
			if rstn = '0' then					
					dtclock_counter <= (others => '0');
					dtcclk_locked_i <= '0';
			elsif clk'event and clk = '1' then
				if dtcclk_locked = '0' then
					dtclock_counter <= (others => '0');
					dtcclk_locked_i <= '0';
				elsif dtclock_counter < dtclock_max then
					dtclock_counter <= dtclock_counter + 1;
				else
					dtcclk_locked_i <= '1';
				end if;
			end if;
		end process;
	end block;
	
	-- ethclk_locked debouncer: lock signal should be stable for at least 1000 clks
	ethclk_locked_filter: block
		signal ethlock_counter: std_logic_vector(15 downto 0);
		constant ethlock_max : std_logic_vector(15 downto 0) := x"03E8";		-- 1000
	begin
		process(clk, rstn)
		begin
			if rstn = '0' then					
				ethlock_counter <= (others => '0');
				ethclk_locked_i <= '0';
			elsif clk'event and clk = '1' then
				if ethclk_locked = '0' then
					ethlock_counter <= (others => '0');
					ethclk_locked_i <= '0';
				elsif ethlock_counter < ethlock_max then
					ethlock_counter <= ethlock_counter + 1;
				else
					ethclk_locked_i <= '1';
				end if;
			end if;
		end process;
	end block;

	process(clk, rstn)
	begin
		if rstn = '0' then					counter <= (others => '0');
		elsif clk'event and clk = '1' then
			if state = stRST then
				if counter < count_max then 	counter <= counter + 1;		end if;
			else										counter <= (others => '0');
			end if;
		end if;
	end process;
	process(clk, rstn)
	begin
		if rstn = '0' then					idle_counter <= (others => '0');
		elsif clk'event and clk = '1' then
			if state = stIDLE then
				if idle_counter < idle_count_max then 	idle_counter <= idle_counter + 1;		end if;
			else										idle_counter <= (others => '0');
			end if;
		end if;
	end process;
--	process(clk)
--	begin
--		if clk'event and clk = '1' then
--			if rstn = '0' then					lock_counter <= (others => '0');
--			elsif state = stLOCK then
--				if lock_counter < lock_timeout then 	lock_counter <= lock_counter + 1;		end if;
--			else										lock_counter <= (others => '0');
--			end if;
--		end if;
--	end process;

	process(clk, rstn)
	begin
		if rstn = '0' then
			clksel <= "00";
			state <= stIDLE;
			next_state <= stIDLE;
			app_rst <= '1';
		elsif clk'event and clk = '1' then
				case state is
					when stIDLE => 
						clksel <= "00";
						app_rst <= '0';
						next_state <= stIDLE;
						if idle_counter >= idle_count_max then
							if ethclk_ok = '1' and ethclk_sel = '1' and ethclk_locked_i = '1' then
	--							state <= stLOCK;
								state <= stRST;
								next_state <= stETH;
							elsif dtcclk_ok = '1' and dtcclk_inh = '0' and dtcclk_locked_i = '1' then
	--							state <= stLOCK;
								state <= stRST;
								next_state <= stDTC;
							end if;
						end if;
--					when stLOCK =>
--						app_rst <= '0';
--						clksel <= "00";
--						if clk_ok = '0' or lock_counter >= lock_timeout then
--							state <= stIdle;
--						elsif clk_locked = '1' then
--							state <= stRST;
--						end if;
					when stRST =>
						app_rst <= '1';
						if next_state = stDTC then
							clksel <= "01";
						elsif next_state = stETH then
							clksel <= "10";
						else
							clksel <= "00";
						end if;
						if clk_ok = '0' or clk_locked = '0' then
							state <= stIdle;
							clksel <= "00";
						elsif counter >= count_max then
							state <= next_state;
							app_rst <= '0';
						end if;
					when stDTC =>
						clksel <= "01";
						app_rst <= '0';
						if dtcclk_ok = '0' or dtcclk_inh = '1' or dtcclk_locked = '0' then
							clksel <= "00";
							state <= stRST;
							next_state <= stIDLE;
						end if;
					when stETH =>
						clksel <= "10";
						app_rst <= '0';
						if ethclk_ok = '0' or ethclk_sel = '0' or ethclk_locked = '0' then
							clksel <= "00";
							state <= stRST;
							next_state <= stIDLE;
						end if;
					when others =>
						state <= stIDLE;
						next_state <= stIDLE;
				end case;
					
		end if;
	end process;
	
end Behavioral;

