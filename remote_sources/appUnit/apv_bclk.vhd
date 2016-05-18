----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:58:55 02/22/2010 
-- Design Name: 
-- Module Name:    apvbclk - Behavioral 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity apvbclk is
    Port ( clk : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
			  trgin: in std_logic;
			  forceRst: in std_logic;
			  mode: in std_logic_vector(7 downto 0);
			  trg_reg, trg_pos, tp_pos: in STD_LOGIC_VECTOR(15 downto 0);
			  trg_count: in STD_LOGIC_VECTOR(5 downto 0);
           trg : out  STD_LOGIC;
			  trg_out: out  STD_LOGIC;
			  syncPulse, syncPulse0 : out  STD_LOGIC;
			  trg_counter: out STD_LOGIC_VECTOR(15 downto 0));
end apvbclk;

architecture Behavioral of apvbclk is
signal apv_trg, apv_trg_reset, rstn_i, firstRst, apv_testpulse, trigger_gen, trgin_0, trgin_1, trgin_d, trigger, forceRst_d, syncPulse_i: std_logic;
signal apvmode_trg, vfatmode_trg, vfat_trg_reset, vfat_testpulse: std_logic;
signal syncCounter : std_logic_vector(5 downto 0);
signal syncCounter2 : std_logic_vector(2 downto 0);

signal sm_trg_val, trg_reg_i, trg_pos_i, tp_pos_i: STD_LOGIC_VECTOR(21 downto 0);
begin

	trg_reg_i <= trg_reg & "111111";
	trg_pos_i <= "000000" & trg_pos;
	tp_pos_i <= "000000" & tp_pos;
	
	apv_trg_reset <= '1' when (sm_trg_val = 1) or (sm_trg_val = 3) else '0';
	apv_testpulse <= '1' when (sm_trg_val = tp_pos_i) or (sm_trg_val = tp_pos_i + 1) else '0';
	
	vfat_trg_reset <= '1' when (sm_trg_val = 1) or (sm_trg_val = 2) else '0';
	vfat_testpulse <= '1' when (sm_trg_val = tp_pos_i) or (sm_trg_val = tp_pos_i + 1) or (sm_trg_val = tp_pos_i + 2) else '0';
	
	trigger_gen <= '1' when (sm_trg_val = trg_pos_i) else '0';

	trigger <= '1' when (mode(2) = '0') else trgin_1;

	trgin_1 <= (trgin_d and not trgin_0) when (mode(3) = '0') else (not trgin_d and trgin_0);
	
	rstn_i <= rstn and not forceRst;

  PROCESS (clk, rstn_i)
  BEGIN
    IF rstn_i = '0' THEN
      sm_trg_val <= (OTHERS => '0');
		trgin_0 <= '0';
		trgin_d <= '0';
		firstRst <= '1';
    ELSIF clk = '0' AND clk'event THEN	-- negative transition
		trgin_d <= trgin;
		trgin_0 <= trgin_d;
      if sm_trg_val = trg_reg_i then
			firstRst <= '0';
			if trigger = '1' then
				sm_trg_val <= (OTHERS => '0');
			end if;
		else
			sm_trg_val <= sm_trg_val + 1;
		end if;
    END IF;
  END PROCESS;
	process(clk, rstn_i)
	begin
		if rstn_i = '0' then
			syncCounter <= (others => '0');
		elsif clk'event and clk = '0' then -- negative transition
			if ((sm_trg_val = 3) and ((mode(0) or firstRst) = '1')) or (syncCounter = 34) then
				syncCounter <= (others => '0');
			else 
				syncCounter <= syncCounter + 1;
			end if;
		end if;
	end process;
	process(clk, rstn_i)
	begin
		if rstn_i = '0' then
			syncPulse_i <= '0';
			syncPulse <= '0';
			syncPulse0 <= '0';
			syncCounter2 <= (others => '0');
		elsif clk'event and clk = '1' then -- positive transition
			syncPulse <= '0';
			if syncCounter = 34 then
				syncPulse0 <= '1';
			else
				syncPulse0 <= '0';
			end if;	
			if ((syncPulse_i = '0') and (sm_trg_val = trg_pos_i - 4)) then
				syncPulse_i <= '1';
				syncCounter2 <= (others => '0');
			end if;
			if ((syncPulse_i = '1') and (syncCounter = 34)) then
				if syncCounter2 = "100" then
					syncPulse <= '1';
					syncPulse_i <= '0';
				else
					syncCounter2 <= syncCounter2 + 1;
				end if;
			end if;
		end if;
	end process;	
	process(clk, rstn_i)
	variable counter1: integer range 0 to 63;
	variable counter2: integer range 0 to 3;
	begin
    IF rstn_i = '0' THEN
		apv_trg <= '0';
		counter1 := 0;
		counter2 := 0;
    ELSIF clk = '0' AND clk'event THEN	-- negative transition
		apv_trg <= '0';
		if trigger_gen = '1' then
			apv_trg <= '1';
			counter1 := counter1 + 1;
			counter2 := 0;
		elsif counter1 > 0 then
			if counter2 >= 2 then
				if trg_count /= 0 then
					apv_trg <= '1';
				end if;
				counter2 := 0;
				if counter1 >= trg_count then
					counter1 := 0;
				else
					counter1 := counter1 + 1;
				end if;
			else
				counter2 := counter2 + 1;
			end if;
		end if;
	 end if;
	end process;

	apvmode_trg <= (apv_trg_reset AND (mode(0) or firstRst)) OR (apv_testpulse AND mode(1)) OR apv_trg;
	vfatmode_trg <= (vfat_trg_reset AND (mode(0) or firstRst)) OR (vfat_testpulse AND mode(1)) OR apv_trg;
	
	trg <= vfatmode_trg when mode(4) = '1' else apvmode_trg;
	
	trg_counter <= sm_trg_val(15 downto 0) when (sm_trg_val(21 downto 16) = 0) and firstRst = '0' else x"FFFF";
	
	trg_out <= trigger_gen;
	
end Behavioral;

