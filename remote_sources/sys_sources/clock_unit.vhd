----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:05:39 03/25/2015 
-- Design Name: 
-- Module Name:    clock_unit - Behavioral 
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

entity clock_unit is
	 Generic ( G_DEVICE : string := "VIRTEX5" );
    Port ( clk_osc_N, clk_osc_P : in  STD_LOGIC;
			  rstn: in  STD_LOGIC;
           clk, clk10M, clk_refiod, clk_locked : out  STD_LOGIC);
end clock_unit;

architecture Behavioral of clock_unit is
    signal clk_osc : std_logic;
    signal clk_dcmfb : std_logic;
    signal clk_locked_i : std_logic;
    signal clk0 : std_logic;
    signal clk_i : std_logic;
    signal clkfx : std_logic;
    signal sclk_bufr : std_logic;

begin

	  IBUFGDS_clk : IBUFGDS
			generic map (
				 DIFF_TERM => true,
				 IOSTANDARD => "LVDS_25")
			port map (
				 I => clk_osc_P,
				 IB => clk_osc_N,
				 O => clk_osc
				 );
	  bufg_dcmfb : BUFG
			port map (
				 I => clk0,
				 O => clk_dcmfb
				 );
				 
	v5gen: if G_DEVICE = "VIRTEX5" generate 
		  DCM_ADV_clk : DCM_ADV
				generic map (
					CLKDV_DIVIDE => 5.0,  -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
												 --   7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
					CLKFX_DIVIDE => 5,    -- Can be any integer from 1 to 32
					CLKFX_MULTIPLY => 2,  -- Can be any integer from 2 to 32
					CLKIN_DIVIDE_BY_2 => TRUE,    -- TRUE/FALSE to enable CLKIN divide by two feature
					CLKIN_PERIOD => 5.0,          -- Specify period of input clock in ns from 1.25 to 1000.00
					CLKOUT_PHASE_SHIFT => "NONE",  -- Specify phase shift mode of NONE, FIXED, 
															 -- VARIABLE_POSITIVE, VARIABLE_CENTER or DIRECT
					CLK_FEEDBACK => "1X",  -- Specify clock feedback of NONE or 1X
					DCM_PERFORMANCE_MODE => "MAX_SPEED",   -- Can be MAX_SPEED or MAX_RANGE
					DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
																		--   an integer from 0 to 15
					DFS_FREQUENCY_MODE => "LOW",    -- HIGH or LOW frequency mode for frequency synthesis
					DLL_FREQUENCY_MODE => "LOW",    -- LOW, HIGH, or HIGH_SER frequency mode for DLL
					DUTY_CYCLE_CORRECTION => TRUE,  -- Duty cycle correction, TRUE or FALSE
					FACTORY_JF => X"F0F0",          -- FACTORY JF Values Suggested to be set to X"F0F0" 
					PHASE_SHIFT => 0,  -- Amount of fixed phase shift from -255 to 1023
					SIM_DEVICE => "VIRTEX5",        -- Set target device, "VIRTEX4" or "VIRTEX5" 
					STARTUP_WAIT => FALSE)  -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
				port map (
					 CLK0 => clk0,
					 CLKFB => clk_dcmfb,
					 CLKFX => clkfx,
					 CLKIN => clk_osc,
					 LOCKED => clk_locked_i,
					 RST => (  not rstn ) 
					 );
	  end generate;

	 v6gen: if G_DEVICE = "VIRTEX6" generate
			mmcm_adv_inst : MMCM_ADV
			  generic map
				(BANDWIDTH            => "OPTIMIZED",
				 CLKOUT4_CASCADE      => FALSE,
				 CLOCK_HOLD           => FALSE,
				 COMPENSATION         => "ZHOLD",
				 STARTUP_WAIT         => FALSE,
				 DIVCLK_DIVIDE        => 1,
				 CLKFBOUT_MULT_F      => 5.000,
				 CLKFBOUT_PHASE       => 0.000,
				 CLKFBOUT_USE_FINE_PS => FALSE,
				 CLKOUT0_DIVIDE_F     => 25.000,
				 CLKOUT0_PHASE        => 0.000,
				 CLKOUT0_DUTY_CYCLE   => 0.500,
				 CLKOUT0_USE_FINE_PS  => FALSE,
				 CLKIN1_PERIOD        => 5.000,
				 REF_JITTER1          => 0.010)
			  port map
				 -- Output clocks
				(CLKFBOUT            => clk0,
				 CLKOUT0             => clkfx,
				 -- Input clock control
				 CLKFBIN             => clk_dcmfb,
				 CLKIN1              => clk_osc,
				 CLKIN2              => '0',
				 -- Tied to always select the primary input clock
				 CLKINSEL            => '1',
				 -- Other control and status signals
				 LOCKED              => clk_locked_i,
				 PWRDWN              => '0',
				 RST                 => (  not rstn ), 

			  -- DRP Ports: 7-bit (each) input: Dynamic reconfigration ports
				DADDR => "0000000",               -- 7-bit input: DRP adrress input
				DCLK => '0',                 -- 1-bit input: DRP clock input
				DEN => '0',                   -- 1-bit input: DRP enable input
				DI => x"0000",                     -- 16-bit input: DRP data input
				DWE => '0',                   -- 1-bit input: DRP write enable input
				-- Dynamic Phase Shift Ports: 1-bit (each) input: Ports used for dynamic phase shifting of the outputs
				PSCLK => '0',               -- 1-bit input: Phase shift clock input
				PSEN => '0',                 -- 1-bit input: Phase shift enable input
				PSINCDEC => '0'         -- 1-bit input: Phase shift increment/decrement input
				 
				 );

	  end generate;
	 
	  clk_locked <= clk_locked_i;
	  
	  bufg_dcm0 : BUFG
			port map (
				 I => clkfx,
				 O => clk_i
				 );
	  
	  clk <= clk_i;
	  
	  BUFR_sclk : BUFR
			generic map (
				 BUFR_DIVIDE => "4",
				 SIM_DEVICE => G_DEVICE )
			port map (
				 CE => clk_locked_i,
				 CLR => (  not rstn ) ,
				 I => clk_i,
				 O => sclk_bufr
				 );
	  bufg_clk10M : BUFG
			port map (
				 I => sclk_bufr,
				 O => clk10M
				 );
	  bufg_dcmiodelay : BUFG
			port map (
				 I => clk_osc,
				 O => clk_refiod
				 );


end Behavioral;

