--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:45:34 03/02/2012
-- Design Name:   
-- Module Name:   C:/Documents/Local/FEC_firm_v2/sources/sc//tb_sc_spi.vhd
-- Project Name:  FEC_firm_v2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: sc_spi_tx
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
 
ENTITY tb_sc_spi IS
END tb_sc_spi;
 
ARCHITECTURE behavior OF tb_sc_spi IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT sc_spi_tx
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
         rstreg : OUT  std_logic_vector(15 downto 0);
         spi_enable : OUT  std_logic;
         spi_sdata : OUT  std_logic;
         spi_cs_n : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rstn : std_logic := '0';
   signal sc_port : std_logic_vector(15 downto 0) := x"1978";
   signal sc_data : std_logic_vector(31 downto 0) := (others => '0');
   signal sc_addr : std_logic_vector(31 downto 0) := (others => '0');
   signal sc_subaddr : std_logic_vector(31 downto 0) := (others => '0');
   signal sc_op : std_logic := '0';
   signal sc_frame : std_logic := '0';
   signal sc_wr : std_logic := '0';

 	--Outputs
   signal sc_ack : std_logic;
   signal sc_rply_data : std_logic_vector(31 downto 0);
   signal sc_rply_error : std_logic_vector(31 downto 0);
   signal rstreg : std_logic_vector(15 downto 0);
   signal spi_enable : std_logic;
   signal spi_sdata : std_logic;
   signal spi_cs_n : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	
	signal shiftreg: std_logic_vector(23 downto 0) := x"000000";
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: sc_spi_tx PORT MAP (
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
          rstreg => rstreg,
          spi_enable => spi_enable,
          spi_sdata => spi_sdata,
          spi_cs_n => spi_cs_n
        );

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

      wait for clk_period*10;
		
		sc_subaddr <= x"000000ff";
		sc_addr <= x"00000010";
		sc_data <= x"00005d7b";
		sc_op <= '1';
		sc_wr <= '1';
		sc_frame <= '1';
		
      wait for clk_period*40;
		sc_op <= '0';
		
      wait for clk_period*5;
		sc_addr <= x"00000025";
		sc_data <= x"00007340";
		sc_op <= '1';
		
      wait for clk_period*40;
		sc_op <= '0';
		sc_wr <= '0';
		sc_frame <= '0';

      -- insert stimulus here 

      wait;
   end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if spi_cs_n(0)  = '0' then
				shiftreg <= shiftreg(22 downto 0) & spi_sdata;
			else
				shiftreg <= (others => '0');
			end if;
		end if;
	end process;

END;
