----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:37:07 03/25/2015 
-- Design Name: 
-- Module Name:    sysClkMgrCTFv6 - Behavioral 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity sysClkMgrCTFv6 is
    Port ( clk200_p, clk200_n : in  STD_LOGIC;
           rstn, dtcctf_resetn : in  STD_LOGIC;
           clk200_out, clk40_out, clk10_out : out  STD_LOGIC;
           clk_locked : out  STD_LOGIC);
end sysClkMgrCTFv6;

architecture Behavioral of sysClkMgrCTFv6 is

	COMPONENT clock_unit
	Generic ( G_DEVICE : string := "VIRTEX5" );
	PORT(
		clk_osc_N : IN std_logic;
		clk_osc_P : IN std_logic;
		rstn : IN std_logic;          
		clk : OUT std_logic;
		clk10M : OUT std_logic;
		clk_refiod : OUT std_logic;
		clk_locked : OUT std_logic
		);
	END COMPONENT;
	COMPONENT dtcctf_unit
	PORT(
		clk0 : IN std_logic;
		rstn : IN std_logic;
		cfg : IN std_logic_vector(15 downto 0);
		DTCIN_P : IN std_logic_vector(1 downto 0);
		DTCIN_N : IN std_logic_vector(1 downto 0);
		DTC2IN_P : IN std_logic_vector(1 downto 0);
		DTC2IN_N : IN std_logic_vector(1 downto 0);
		trgin : IN std_logic;
		clkin : IN std_logic;          
		DTCOUT_P : OUT std_logic_vector(1 downto 0);
		DTCOUT_N : OUT std_logic_vector(1 downto 0);
		DTC2OUT_P : OUT std_logic_vector(1 downto 0);
		DTC2OUT_N : OUT std_logic_vector(1 downto 0);
		dtcclk_ok : OUT std_logic;
		dtcclk_out : OUT std_logic;
		dtctrg_out : OUT std_logic;
		dtcclk_locked : OUT std_logic;
		dtcclk_measure_val : OUT std_logic_vector(15 downto 0);
		dtcclk_status : OUT std_logic_vector(5 downto 0);
		dtcclk_measure_dv : OUT std_logic
		);
	END COMPONENT;

	signal	dtcclk_locked_out : std_logic;
	signal	dtcclk_measure_out : std_logic_vector(15 downto 0);
	signal	dtcclk_status_out : std_logic_vector(5 downto 0);
	
	signal clk40, clk10, clk200, clk_locked_i: std_logic;

begin

	Inst_clock_unit: clock_unit 
	GENERIC MAP( G_DEVICE => "VIRTEX6" )
	PORT MAP(
		clk_osc_N => clk200_n,
		clk_osc_P => clk200_p,
		rstn => rstn,
		clk => clk40,
		clk10M => clk10,
		clk_refiod => clk200,
		clk_locked => clk_locked_i
	);
	
	clk_locked <= clk_locked_i;
	clk200_out <= clk200;
	clk40_out  <= clk40;
	clk10_out  <= clk10;
	
	ctf_blk: block
		signal dtcctf_resetn, dtcclk_locked, dtcclk_measure_dv: std_logic;
		signal dtcctf_cfg: std_logic_vector(15 downto 0);
		signal dtcclk_measure_val: std_logic_vector(15 downto 0);
		signal dtcclk_status: std_logic_vector(5 downto 0);
	begin


		Inst_dtcctf_unit: dtcctf_unit PORT MAP(
			clk0 => clk40,
			rstn => dtcctf_resetn,
			cfg => dtcctf_cfg,
			DTCIN_P => DTC_CLK_P,
			DTCIN_N => DTC_CLK_N,
			DTC2IN_P => DTC_CMD_P,
			DTC2IN_N => DTC_CMD_N,
			DTCOUT_P => DTC_DATA0_P,
			DTCOUT_N => DTC_DATA0_N,
			DTC2OUT_P => DTC_DATA1_P,
			DTC2OUT_N => DTC_DATA1_N,
			trgin => nim_trgin,
			clkin => clk40,
			dtcclk_ok => open,
			dtcclk_out => open,
			dtctrg_out => open,
			dtcclk_locked => dtcclk_locked,
			dtcclk_measure_val => dtcclk_measure_val,
			dtcclk_status => dtcclk_status,
			dtcclk_measure_dv => dtcclk_measure_dv
		);
		
		process(clk10, rstn)
		begin
			if rstn = '0' then
				dtcclk_measure_out <= (others=> '0');
				dtcclk_status_out <= (others=> '0');
				dtcclk_measure_dv10 <= '0';
			elsif clk10'event and clk10 = '1' then
				dtcclk_measure_dv10 <= dtcclk_measure_dv;
				if dtcclk_measure_dv10 = '1' then
					dtcclk_measure_out <= dtcclk_measure_val;
					dtcclk_status_out <= dtcclk_status;
				end if;
			end if;
		end process;
	
	end block;

end Behavioral;

