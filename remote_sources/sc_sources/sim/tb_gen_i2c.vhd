--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:50:05 12/05/2014
-- Design Name:   
-- Module Name:   D:/Documents/SRSFW/FEC_VMM2/remote_sources/sc_sources/sim/tb_gen_i2c.vhd
-- Project Name:  FEC_VMM2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: gen_i2c_cfgrw2
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
 
ENTITY tb_gen_i2c IS
END tb_gen_i2c;
 
ARCHITECTURE behavior OF tb_gen_i2c IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dcard_i2c_sc
    PORT(
         clk : IN  std_logic;
         rstn : IN  std_logic;
         sc_port : IN  std_logic_vector(15 downto 0);
         sc_data : IN  std_logic_vector(31 downto 0);
         sc_addr : IN  std_logic_vector(31 downto 0);
         sc_subaddr : IN  std_logic_vector(31 downto 0);
         sc_op : IN  std_logic;
         sc_frame : IN  std_logic;
         sc_wr : IN  std_logic;
         sc_ack : OUT  std_logic;
         sc_rply_data : OUT  std_logic_vector(31 downto 0);
         sc_rply_error : OUT  std_logic_vector(31 downto 0);
         scl : INOUT  std_logic;
         sda : INOUT  std_logic;
         cfg_i2c_scl : IN  std_logic_vector(7 downto 0);
         cfg_i2c_sda : IN  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rstn : std_logic := '0';
   signal sc_port : std_logic_vector(15 downto 0) := (others => '0');
   signal sc_data : std_logic_vector(31 downto 0) := (others => '0');
   signal sc_addr : std_logic_vector(31 downto 0) := (others => '0');
   signal sc_subaddr : std_logic_vector(31 downto 0) := (others => '0');
   signal sc_op : std_logic := '0';
   signal sc_frame : std_logic := '0';
   signal sc_wr : std_logic := '0';
   signal cfg_i2c_scl : std_logic_vector(7 downto 0) := (others => '0');
   signal cfg_i2c_sda : std_logic_vector(7 downto 0) := (others => '0');

	--BiDirs
   signal scl : std_logic;
   signal sda : std_logic;

 	--Outputs
   signal sc_ack : std_logic;
   signal sc_rply_data : std_logic_vector(31 downto 0);
   signal sc_rply_error : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dcard_i2c_sc PORT MAP (
          clk => clk,
          rstn => rstn,
          sc_port => sc_port,
          sc_data => sc_data,
          sc_addr => sc_addr,
          sc_subaddr => sc_subaddr,
          sc_op => sc_op,
          sc_frame => sc_frame,
          sc_wr => sc_wr,
          sc_ack => sc_ack,
          sc_rply_data => sc_rply_data,
          sc_rply_error => sc_rply_error,
          scl => scl,
          sda => sda,
          cfg_i2c_scl => cfg_i2c_scl,
          cfg_i2c_sda => cfg_i2c_sda
        );
		  
	scl <= 'H';
	sda <= 'H';

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		rstn <= '1';

      wait for clk_period*200;
		
		sc_port <= x"1787";
		sc_subaddr <= x"FFFFFFFF";
		sc_addr <= x"00000202";
		sc_data <= x"000000FF";
		sc_op <= '1';
		sc_wr <= '1';
		sc_frame <= '1';
		
--      wait for clk_period;
		
		wait until sc_ack = '1';
      wait for clk_period;
		sc_op <= '0';
		wait until sc_ack = '0';
      wait for clk_period;
		
		sc_addr <= x"00000203";
		sc_data <= x"000000FF";
		sc_op <= '1';
		sc_wr <= '1';
		
		wait until sc_ack = '1';
      wait for clk_period;
		sc_op <= '0';
		wait until sc_ack = '0';
      wait for clk_period;
		
		sc_addr <= x"00000200";
		sc_data <= x"00000000";
		sc_op <= '1';
		sc_wr <= '0';
		
		wait until sc_ack = '1';
      wait for clk_period;
		sc_op <= '0';
		sc_frame <= '0';
		wait until sc_ack = '0';
      wait for clk_period;

      -- insert stimulus here 

      wait;
   end process;

END;
