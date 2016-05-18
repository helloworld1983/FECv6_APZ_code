--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:20:51 08/05/2014
-- Design Name:   
-- Module Name:   /home/smartoiu/designs/xilinx/SRSFW/FECv6_ADC/sim/tb_adccore.vhd
-- Project Name:  FECv6_ADC
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ADCcore
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
 
ENTITY tb_adccore IS
END tb_adccore;
 
ARCHITECTURE behavior OF tb_adccore IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ADCcore
    PORT(
         clk : IN  std_logic;
         clk10M : IN  std_logic;
         clk_refiod : IN  std_logic;
         rstn_init : IN  std_logic;
         rstn : IN  std_logic;
         dcm_locked : IN  std_logic;
         FCO1_P : IN  std_logic;
         FCO1_N : IN  std_logic;
         DCO1_P : IN  std_logic;
         DCO1_N : IN  std_logic;
         DCH1_P : IN  std_logic;
         DCH1_N : IN  std_logic;
         DCH2_P : IN  std_logic;
         DCH2_N : IN  std_logic;
         DCH3_P : IN  std_logic;
         DCH3_N : IN  std_logic;
         DCH4_P : IN  std_logic;
         DCH4_N : IN  std_logic;
         DCH5_P : IN  std_logic;
         DCH5_N : IN  std_logic;
         DCH6_P : IN  std_logic;
         DCH6_N : IN  std_logic;
         DCH7_P : IN  std_logic;
         DCH7_N : IN  std_logic;
         DCH8_P : IN  std_logic;
         DCH8_N : IN  std_logic;
         FCO2_P : IN  std_logic;
         FCO2_N : IN  std_logic;
         DCO2_P : IN  std_logic;
         DCO2_N : IN  std_logic;
         DCH9_P : IN  std_logic;
         DCH9_N : IN  std_logic;
         DCH10_P : IN  std_logic;
         DCH10_N : IN  std_logic;
         DCH11_P : IN  std_logic;
         DCH11_N : IN  std_logic;
         DCH12_P : IN  std_logic;
         DCH12_N : IN  std_logic;
         DCH13_P : IN  std_logic;
         DCH13_N : IN  std_logic;
         DCH14_P : IN  std_logic;
         DCH14_N : IN  std_logic;
         DCH15_P : IN  std_logic;
         DCH15_N : IN  std_logic;
         DCH16_P : IN  std_logic;
         DCH16_N : IN  std_logic;
         CH0 : OUT  std_logic_vector(11 downto 0);
         CH1 : OUT  std_logic_vector(11 downto 0);
         CH2 : OUT  std_logic_vector(11 downto 0);
         CH3 : OUT  std_logic_vector(11 downto 0);
         CH4 : OUT  std_logic_vector(11 downto 0);
         CH5 : OUT  std_logic_vector(11 downto 0);
         CH6 : OUT  std_logic_vector(11 downto 0);
         CH7 : OUT  std_logic_vector(11 downto 0);
         CH8 : OUT  std_logic_vector(11 downto 0);
         CH9 : OUT  std_logic_vector(11 downto 0);
         CH10 : OUT  std_logic_vector(11 downto 0);
         CH11 : OUT  std_logic_vector(11 downto 0);
         CH12 : OUT  std_logic_vector(11 downto 0);
         CH13 : OUT  std_logic_vector(11 downto 0);
         CH14 : OUT  std_logic_vector(11 downto 0);
         CH15 : OUT  std_logic_vector(11 downto 0);
         csb1 : OUT  std_logic;
         pwb1 : OUT  std_logic;
         csb2 : OUT  std_logic;
         pwb2 : OUT  std_logic;
         sdata : OUT  std_logic;
         resetb : OUT  std_logic;
         adcsclk_disable : IN  std_logic;
         ADCLK_P : OUT  std_logic;
         ADCLK_N : OUT  std_logic;
         sclk : OUT  std_logic;
         conf_end : OUT  std_logic;
         DES_run : OUT  std_logic;
         DES_status : OUT  std_logic_vector(15 downto 0);
         ADCDCM_status : OUT  std_logic_vector(5 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal dch : std_logic := '0';
   signal clk : std_logic := '0';
   signal fclk : std_logic := '0';
   signal clk10M : std_logic := '0';
   signal clk_refiod : std_logic := '0';
   signal rstn_init : std_logic := '0';
   signal rstn : std_logic := '0';
   signal dcm_locked : std_logic := '1';
   signal FCO1_P : std_logic := '0';
   signal FCO1_N : std_logic := '1';
   signal DCO1_P : std_logic := '0';
   signal DCO1_N : std_logic := '1';
   signal DCH1_P : std_logic := '0';
   signal DCH1_N : std_logic := '1';
   signal DCH2_P : std_logic := '0';
   signal DCH2_N : std_logic := '1';
   signal DCH3_P : std_logic := '0';
   signal DCH3_N : std_logic := '1';
   signal DCH4_P : std_logic := '0';
   signal DCH4_N : std_logic := '1';
   signal DCH5_P : std_logic := '0';
   signal DCH5_N : std_logic := '1';
   signal DCH6_P : std_logic := '0';
   signal DCH6_N : std_logic := '1';
   signal DCH7_P : std_logic := '0';
   signal DCH7_N : std_logic := '1';
   signal DCH8_P : std_logic := '0';
   signal DCH8_N : std_logic := '1';
   signal FCO2_P : std_logic := '0';
   signal FCO2_N : std_logic := '1';
   signal DCO2_P : std_logic := '0';
   signal DCO2_N : std_logic := '1';
   signal DCH9_P : std_logic := '0';
   signal DCH9_N : std_logic := '1';
   signal DCH10_P : std_logic := '0';
   signal DCH10_N : std_logic := '1';
   signal DCH11_P : std_logic := '0';
   signal DCH11_N : std_logic := '1';
   signal DCH12_P : std_logic := '0';
   signal DCH12_N : std_logic := '1';
   signal DCH13_P : std_logic := '0';
   signal DCH13_N : std_logic := '1';
   signal DCH14_P : std_logic := '0';
   signal DCH14_N : std_logic := '1';
   signal DCH15_P : std_logic := '0';
   signal DCH15_N : std_logic := '1';
   signal DCH16_P : std_logic := '0';
   signal DCH16_N : std_logic := '1';
   signal adcsclk_disable : std_logic := '0';

 	--Outputs
   signal CH0 : std_logic_vector(11 downto 0);
   signal CH1 : std_logic_vector(11 downto 0);
   signal CH2 : std_logic_vector(11 downto 0);
   signal CH3 : std_logic_vector(11 downto 0);
   signal CH4 : std_logic_vector(11 downto 0);
   signal CH5 : std_logic_vector(11 downto 0);
   signal CH6 : std_logic_vector(11 downto 0);
   signal CH7 : std_logic_vector(11 downto 0);
   signal CH8 : std_logic_vector(11 downto 0);
   signal CH9 : std_logic_vector(11 downto 0);
   signal CH10 : std_logic_vector(11 downto 0);
   signal CH11 : std_logic_vector(11 downto 0);
   signal CH12 : std_logic_vector(11 downto 0);
   signal CH13 : std_logic_vector(11 downto 0);
   signal CH14 : std_logic_vector(11 downto 0);
   signal CH15 : std_logic_vector(11 downto 0);
   signal csb1 : std_logic;
   signal pwb1 : std_logic;
   signal csb2 : std_logic;
   signal pwb2 : std_logic;
   signal sdata : std_logic;
   signal resetb : std_logic;
   signal ADCLK_P : std_logic;
   signal ADCLK_N : std_logic;
   signal sclk : std_logic;
   signal conf_end : std_logic;
   signal DES_run : std_logic;
   signal DES_status : std_logic_vector(15 downto 0);
   signal ADCDCM_status : std_logic_vector(5 downto 0);

   -- Clock period definitions
   constant clk_period : time := 25 ns;
   constant clk10M_period : time := 100 ns;
   constant clk_refiod_period : time := 5 ns;
   constant sclk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ADCcore PORT MAP (
          clk => clk,
          clk10M => clk10M,
          clk_refiod => clk_refiod,
          rstn_init => rstn_init,
          rstn => rstn,
          dcm_locked => dcm_locked,
          FCO1_P => FCO1_P,
          FCO1_N => FCO1_N,
          DCO1_P => DCO1_P,
          DCO1_N => DCO1_N,
          DCH1_P => DCH1_P,
          DCH1_N => DCH1_N,
          DCH2_P => DCH2_P,
          DCH2_N => DCH2_N,
          DCH3_P => DCH3_P,
          DCH3_N => DCH3_N,
          DCH4_P => DCH4_P,
          DCH4_N => DCH4_N,
          DCH5_P => DCH5_P,
          DCH5_N => DCH5_N,
          DCH6_P => DCH6_P,
          DCH6_N => DCH6_N,
          DCH7_P => DCH7_P,
          DCH7_N => DCH7_N,
          DCH8_P => DCH8_P,
          DCH8_N => DCH8_N,
          FCO2_P => FCO2_P,
          FCO2_N => FCO2_N,
          DCO2_P => DCO2_P,
          DCO2_N => DCO2_N,
          DCH9_P => DCH9_P,
          DCH9_N => DCH9_N,
          DCH10_P => DCH10_P,
          DCH10_N => DCH10_N,
          DCH11_P => DCH11_P,
          DCH11_N => DCH11_N,
          DCH12_P => DCH12_P,
          DCH12_N => DCH12_N,
          DCH13_P => DCH13_P,
          DCH13_N => DCH13_N,
          DCH14_P => DCH14_P,
          DCH14_N => DCH14_N,
          DCH15_P => DCH15_P,
          DCH15_N => DCH15_N,
          DCH16_P => DCH16_P,
          DCH16_N => DCH16_N,
          CH0 => CH0,
          CH1 => CH1,
          CH2 => CH2,
          CH3 => CH3,
          CH4 => CH4,
          CH5 => CH5,
          CH6 => CH6,
          CH7 => CH7,
          CH8 => CH8,
          CH9 => CH9,
          CH10 => CH10,
          CH11 => CH11,
          CH12 => CH12,
          CH13 => CH13,
          CH14 => CH14,
          CH15 => CH15,
          csb1 => csb1,
          pwb1 => pwb1,
          csb2 => csb2,
          pwb2 => pwb2,
          sdata => sdata,
          resetb => resetb,
          adcsclk_disable => adcsclk_disable,
          ADCLK_P => ADCLK_P,
          ADCLK_N => ADCLK_N,
          sclk => sclk,
          conf_end => conf_end,
          DES_run => DES_run,
          DES_status => DES_status,
          ADCDCM_status => ADCDCM_status
        );
		  
		  DCO1_P <= transport fclk after 3 ns;
		  DCO1_N <= transport not fclk after 3 ns;
		  DCO2_P <= transport fclk after 3 ns;
		  DCO2_N <= transport not fclk after 3 ns;

		  FCO1_P <= transport clk after 3 ns;
		  FCO1_N <= transport not clk after 3 ns;
		  FCO2_P <= transport clk after 3 ns;
		  FCO2_N <= transport not clk after 3 ns;

		  DCH1_P <= transport dch after 3 ns;
		  DCH1_N <= transport not dch after 3 ns;
		  DCH2_P <= transport dch after 3 ns;
		  DCH2_N <= transport not dch after 3 ns;
		  
		  dch <= fclk;

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

   fclk_process :process
   begin
		fclk <= '0';
		wait for clk_period/12;
		fclk <= '1';
		wait for clk_period/12;
   end process;
 
   clk10M_process :process
   begin
		clk10M <= '0';
		wait for clk10M_period/2;
		clk10M <= '1';
		wait for clk10M_period/2;
   end process;
 
   clk_refiod_process :process
   begin
		clk_refiod <= '0';
		wait for clk_refiod_period/2;
		clk_refiod <= '1';
		wait for clk_refiod_period/2;
   end process;
 
--   sclk_process :process
--   begin
--		sclk <= '0';
--		wait for sclk_period/2;
--		sclk <= '1';
--		wait for sclk_period/2;
--   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
		rstn <= '1';
		rstn_init <= '1';

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
