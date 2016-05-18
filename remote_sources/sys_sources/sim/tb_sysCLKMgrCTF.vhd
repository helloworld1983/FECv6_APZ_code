--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:36:05 04/02/2015
-- Design Name:   
-- Module Name:   D:/Documents/SRSFW/FECv6_ADC/remote_sources/sys_sources/sim/tb_sysCLKMgrCTF.vhd
-- Project Name:  FECv6_ADC
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: sysClkMgrCTF
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_sysCLKMgrCTF IS
END tb_sysCLKMgrCTF;
 
ARCHITECTURE behavior OF tb_sysCLKMgrCTF IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT sysClkMgrCTF
	 GENERIC ( SIMULATION : integer := 0 );
    PORT(
         clk_osc_P : IN  std_logic;
         clk_osc_N : IN  std_logic;
         clk125 : IN  std_logic;
         ethrxclk : IN  std_logic;
         rstn : IN  std_logic;
         DTCIN_P : IN  std_logic_vector(1 downto 0);
         DTCIN_N : IN  std_logic_vector(1 downto 0);
         DTC2IN_P : IN  std_logic_vector(1 downto 0);
         DTC2IN_N : IN  std_logic_vector(1 downto 0);
         DTCOUT_P : OUT  std_logic_vector(1 downto 0);
         DTCOUT_N : OUT  std_logic_vector(1 downto 0);
         DTC2OUT_P : OUT  std_logic_vector(1 downto 0);
         DTC2OUT_N : OUT  std_logic_vector(1 downto 0);
         mclkmux_app_rst : OUT  std_logic;
         trgin : IN  std_logic;
         trgout : OUT  std_logic;
         sysrstreg : IN  std_logic_vector(15 downto 0);
         mclkmux_cfg : IN  std_logic_vector(7 downto 0);
         dtcctf_cfg : IN  std_logic_vector(15 downto 0);
         cfg_out : OUT  std_logic_vector(31 downto 0);
         clk : OUT  std_logic;
         clk10M : OUT  std_logic;
         clk_refiod : OUT  std_logic;
         dcm_locked : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_osc_P : std_logic := '0';
   signal clk_osc_N : std_logic := '0';
   signal clk125 : std_logic := '0';
   signal ethrxclk : std_logic := '0';
   signal rstn : std_logic := '0';
   signal DTCIN_P : std_logic_vector(1 downto 0) := (others => '0');
   signal DTCIN_N : std_logic_vector(1 downto 0) := (others => '1');
   signal DTC2IN_P : std_logic_vector(1 downto 0) := (others => '0');
   signal DTC2IN_N : std_logic_vector(1 downto 0) := (others => '1');
   signal trgin : std_logic := '0';
   signal sysrstreg : std_logic_vector(15 downto 0) := (others => '0');
   signal mclkmux_cfg : std_logic_vector(7 downto 0) := (others => '0');
   signal dtcctf_cfg : std_logic_vector(15 downto 0) := (others => '0');

 	--Outputs
   signal DTCOUT_P : std_logic_vector(1 downto 0);
   signal DTCOUT_N : std_logic_vector(1 downto 0);
   signal DTC2OUT_P : std_logic_vector(1 downto 0);
   signal DTC2OUT_N : std_logic_vector(1 downto 0);
   signal mclkmux_app_rst : std_logic;
   signal trgout : std_logic;
   signal cfg_out : std_logic_vector(31 downto 0);
   signal clk : std_logic;
   signal clk10M : std_logic;
   signal clk_refiod : std_logic;
   signal dcm_locked : std_logic;

   -- Clock period definitions
   constant clk_osc_P_period : time := 5 ns;
   constant clk125_period : time := 8 ns;
   constant ethrxclk_period : time := 8 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: sysClkMgrCTF 
	GENERIC MAP ( SIMULATION => 1 )
	PORT MAP (
          clk_osc_P => clk_osc_P,
          clk_osc_N => clk_osc_N,
          clk125 => clk125,
          ethrxclk => ethrxclk,
          rstn => rstn,
          DTCIN_P => DTCIN_P,
          DTCIN_N => DTCIN_N,
          DTC2IN_P => DTC2IN_P,
          DTC2IN_N => DTC2IN_N,
          DTCOUT_P => DTCOUT_P,
          DTCOUT_N => DTCOUT_N,
          DTC2OUT_P => DTC2OUT_P,
          DTC2OUT_N => DTC2OUT_N,
          mclkmux_app_rst => mclkmux_app_rst,
          trgin => trgin,
          trgout => trgout,
          sysrstreg => sysrstreg,
          mclkmux_cfg => mclkmux_cfg,
          dtcctf_cfg => dtcctf_cfg,
          cfg_out => cfg_out,
          clk => clk,
          clk10M => clk10M,
          clk_refiod => clk_refiod,
          dcm_locked => dcm_locked
        );

   -- Clock process definitions
   clk_osc_P_process :process
   begin
		clk_osc_P <= '0';
		wait for clk_osc_P_period/2;
		clk_osc_P <= '1';
		wait for clk_osc_P_period/2;
   end process;
	
	clk_osc_N <= not clk_osc_P;
 
   clk125_process :process
   begin
		clk125 <= '0';
		wait for clk125_period/2;
		clk125 <= '1';
		wait for clk125_period/2;
   end process;
 
   ethrxclk_process :process
   begin
		ethrxclk <= '0';
		wait for ethrxclk_period/2;
		ethrxclk <= '1';
		wait for ethrxclk_period/2;
   end process;
 
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
		rstn <= '1';

      wait for clk_osc_P_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
