----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:42:38 08/09/2010 
-- Design Name: 
-- Module Name:    bclk_ctrl - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity bclk_ctrl is
	generic ( BCLK_INVERT: boolean := false );
    Port ( clk : in  STD_LOGIC;
           clk2x : in  STD_LOGIC;
           rstn : in  STD_LOGIC;
			  trgin, forceRst : in  STD_LOGIC;
           reg0 : in  STD_LOGIC_VECTOR (7 downto 0);		-- mode
																			--		[0] 	=> enable apv reset 
																			--		[1] 	=> enable test pulse 
																			--		[2] 	=> continous loop(0)/triggered by trgin(1)
																			--		[3] 	=> trgin polarity
																			--		[7:4] => reserved
           reg1d : in  STD_LOGIC_VECTOR (15 downto 0);	-- trg repetition
           reg2d : in  STD_LOGIC_VECTOR (15 downto 0);	-- trg delay after trgin/apv_rst
           reg3d : in  STD_LOGIC_VECTOR (15 downto 0);	-- tp delay after trgin/apv_rst
           reg4 : in  STD_LOGIC_VECTOR (7 downto 0);		-- length of trigger burst (number of consecutive triggers)
           bclkout : out  STD_LOGIC;
           btrgout : out  STD_LOGIC;
           trgout, syncPulse, syncPulse0 : out  STD_LOGIC;
           trgcounter : out  STD_LOGIC_VECTOR (15 downto 0));
end bclk_ctrl;

architecture Behavioral of bclk_ctrl is
	COMPONENT apvbclk
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
	end component;
signal sm_trg:std_logic;
signal sm_trg1:std_logic;
signal btrgout_d, bclk_oddr_d2:std_logic;
begin
	Inst_apvbclk: apvbclk PORT MAP(
		clk 			=> clk,
		rstn 			=> rstn,
		trgin 		=> trgin,
		forceRst 	=> forceRst,
		syncPulse 	=> syncPulse,
		syncPulse0 	=> syncPulse0,
		mode 			=> reg0,
		trg_reg 		=> reg1d,
		trg_pos 		=> reg2d,
		tp_pos 		=> reg3d,
		trg_count 	=> reg4(5 downto 0),
		trg 			=> sm_trg,
		trg_out 		=> trgout,
		trg_counter => trgcounter
	);
	
   ODDR_inst : ODDR
   generic map(
      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT => '1',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "ASYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => bclkout,   -- 1-bit DDR output
      C => clk,    -- 1-bit clock input
      CE => not reg0(7),  -- 1-bit clock enable input
      D1 => sm_trg1,  -- 1-bit data input (positive edge)
      D2 => bclk_oddr_d2,  -- 1-bit data input (negative edge)
      R => not rstn,    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	

   ODDR2_inst : ODDR
   generic map(
      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
      INIT => '1',   -- Initial value for Q port ('1' or '0')
      SRTYPE => "ASYNC") -- Reset Type ("ASYNC" or "SYNC")
   port map (
      Q => btrgout,   -- 1-bit DDR output
      C => clk,    -- 1-bit clock input
      CE => not reg0(7),  -- 1-bit clock enable input
      D1 => btrgout_d,  -- 1-bit data input (positive edge)
      D2 => btrgout_d,  -- 1-bit data input (negative edge)
      R => not rstn,    -- 1-bit reset input
      S => '0'     -- 1-bit set input
   );
	
	BCLK_INVERT_gen: if BCLK_INVERT generate
		btrgout_d <= not (not reg0(5) xor sm_trg);
		sm_trg1 <= not(sm_trg and not reg0(6));
		bclk_oddr_d2 <= '0';
	end generate;
	BCLK_gen: if (not BCLK_INVERT) generate
		btrgout_d <= not reg0(5) xor sm_trg;
		sm_trg1 <= sm_trg and not reg0(6);
		bclk_oddr_d2 <= '1';
	end generate;

	
--  Process(clk2x, rstn)
--  Begin
--    IF rstn = '0' THEN
--		bclkout <= '0';
--    ELSIF clk2x = '1' AND clk2x'event THEN	
--	   bclkout <= clk and not sm_trg;		-- needs timing constraint
--	 end if;
--  End Process;


end Behavioral;

