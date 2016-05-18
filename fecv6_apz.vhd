----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:47:41 03/12/2014 
-- Design Name: 
-- Module Name:    fecv6_adc_top - Behavioral 
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

Library UNISIM;
use UNISIM.vcomponents.all;

entity fecv6_apz is
    Port ( 
		-- DTC PORT 0
		DTC0_CLK_P : in  STD_LOGIC;
		DTC0_CLK_N : in  STD_LOGIC;
		DTC0_CMD_P : in  STD_LOGIC;
		DTC0_CMD_N : in  STD_LOGIC;
		DTC0_DATA0_P : out  STD_LOGIC;
		DTC0_DATA0_N : out  STD_LOGIC;
		DTC0_DATA1_P : out  STD_LOGIC;
		DTC0_DATA1_N : out  STD_LOGIC;
		-- DTC PORT 1
		DTC1_CLK_P : in  STD_LOGIC;
		DTC1_CLK_N : in  STD_LOGIC;
		DTC1_CMD_P : in  STD_LOGIC;
		DTC1_CMD_N : in  STD_LOGIC;
		DTC1_DATA0_P : out  STD_LOGIC;
		DTC1_DATA0_N : out  STD_LOGIC;
		DTC1_DATA1_P : out  STD_LOGIC;
		DTC1_DATA1_N : out  STD_LOGIC;
		-- JITTER CLEANER CLOCKS
--		JITCLN_OUT_P : out  STD_LOGIC;
--		JITCLN_OUT_N : out  STD_LOGIC;
		JITCLN_IN_P : in  STD_LOGIC;
		JITCLN_IN_N : in  STD_LOGIC;
		-- JITTER CLEANER CONTROLS
		GOE : out  STD_LOGIC;
		CLKUWIRE : out  STD_LOGIC;
		LEUWIRE : out  STD_LOGIC;
		PLL_SYNC : out  STD_LOGIC;
		DATAUWIRE : out  STD_LOGIC;
		PLL_LOCK : in  STD_LOGIC;
		
		-- 
		-- SELF REBOOT PIN (TIE to '1' if not used)
		SELF_RSTN : out  STD_LOGIC;
		-- ON BOARD CLOCK
		CLK200_P : in  STD_LOGIC;
		CLK200_N : in  STD_LOGIC;
		-- GBT SWITCH (B CONNECTOR)
		GBTSW : out  STD_LOGIC;
		--
		--EXTENSION CONNECTOR
		EXP : inout  STD_LOGIC_VECTOR(11 downto 0);
	
		-- NIMS $ LEDS
		NIM_TO_TTL : in  STD_LOGIC;
		TTL_TO_NIM : out  STD_LOGIC;
		LED_0 : out  STD_LOGIC;
		LED_1 : out  STD_LOGIC;
		LEMODIFF_P : in  STD_LOGIC;
		LEMODIFF_N : in  STD_LOGIC;
		-- SFP CONTROLS
		SFP0_RX_LOS : in  STD_LOGIC;
		SFP0_TX_FAULT : in  STD_LOGIC;
		SFP_SCL0 : out  STD_LOGIC;
		SFP_SDA0 : inout  STD_LOGIC;
		
		SFP1_RX_LOS : in  STD_LOGIC;
		SFP1_TX_FAULT : in  STD_LOGIC;
		SFP_SCL1 : out  STD_LOGIC;
		SFP_SDA1 : inout  STD_LOGIC;
		
		-- ETH0
		SFP_CLK_P, SFP_CLK_N : in std_logic;
		SFP0_RX_P, SFP0_RX_N : in std_logic;
		SFP0_TX_P, SFP0_TX_N : out std_logic;
		
		-- A PCIE CONNECTOR
		A_PRSNT_N : in  STD_LOGIC;
		A_PWGOOD_N : in  STD_LOGIC;
		A_I2C_SCL : inout  STD_LOGIC;
		A_I2C_SDA : inout  STD_LOGIC;
		A_IO : inout  STD_LOGIC_VECTOR(32 downto 1);
		A_DIFF_P : inout  STD_LOGIC_VECTOR(20 downto 1);
		A_DIFF_N : inout  STD_LOGIC_VECTOR(20 downto 1);
		
		-- B PCIE CONNECTOR
		B_PRSNT_N : in  STD_LOGIC;
		B_PWGOOD_N : in  STD_LOGIC;
		B_I2C_SCL : inout  STD_LOGIC;
		B_I2C_SDA : inout  STD_LOGIC;
		B_IO : inout  STD_LOGIC_VECTOR(18 downto 1);
		B_DIFF_P : in  STD_LOGIC_VECTOR(5 downto 0);
		B_DIFF_N : in  STD_LOGIC_VECTOR(5 downto 0)
		
	 );
end fecv6_apz;

architecture Behavioral of fecv6_apz is
	COMPONENT sysUnitvx6
	PORT(
		clk200_p, clk200_n : IN std_logic;
		SFP_CLK_P : IN std_logic;
		SFP_CLK_N : IN std_logic;
		SFP_RX_P : IN std_logic;
		SFP_RX_N : IN std_logic;          
		SFP_TX_P : OUT std_logic;
		SFP_TX_N : OUT std_logic;
	  A_I2C_SCL, A_I2C_SDA : inout std_logic;
	  B_I2C_SCL, B_I2C_SDA : inout std_logic;
	  SWRST_n : out std_logic;
				-- DTC PORT 0, 1
				DTC_CLK_P : in  STD_LOGIC_VECTOR(1 downto 0);
				DTC_CLK_N : in  STD_LOGIC_VECTOR(1 downto 0);
				DTC_CMD_P : in  STD_LOGIC_VECTOR(1 downto 0);
				DTC_CMD_N : in  STD_LOGIC_VECTOR(1 downto 0);
				DTC_DATA0_P : out  STD_LOGIC_VECTOR(1 downto 0);
				DTC_DATA0_N : out  STD_LOGIC_VECTOR(1 downto 0);
				DTC_DATA1_P : out  STD_LOGIC_VECTOR(1 downto 0);
				DTC_DATA1_N : out  STD_LOGIC_VECTOR(1 downto 0);
	-- CLOCKS
		clk200_out, clk125_out, clk40_out, clk10_out: out std_logic;
		dcm_locked: out std_logic;
	-- RESETS
		rstn_app_out, rstn_sc_out, rstn_init_out, rstn_out: out std_logic;
	-- EXTERNAL (NIM) TRIGGERS
		nim_trgin: in std_logic;
		nim_trgout: out std_logic;
	-- INTERNAL TRIGGER SIGNALS
		trgout: out std_logic;
		trgin: in std_logic;
	-- SLOW CONTROL BUS (SC)
     	sc_port_out 	:out std_logic_vector(15 downto 0);						--% [APP INTERNAL] SC bus
     	sc_data_out 	:out std_logic_vector(31 downto 0);						--% [APP INTERNAL] SC bus
     	sc_addr_out 	:out std_logic_vector(31 downto 0);						--% [APP INTERNAL] SC bus
     	sc_subaddr_out :out std_logic_vector(31 downto 0);						--% [APP INTERNAL] SC bus
     	sc_op_out 		:out std_logic;												--% [APP INTERNAL] SC bus
     	sc_frame_out 	:out std_logic;												--% [APP INTERNAL] SC bus
    	sc_wr_out 		:out std_logic;												--% [APP INTERNAL] SC bus
   	sc_ack_in 		:in std_logic;													--% [APP INTERNAL] SC bus
    	sc_rply_data_in 	:in std_logic_vector(31 downto 0);					--% [APP INTERNAL] SC bus
    	sc_rply_error_in 	:in std_logic_vector(31 downto 0);					--% [APP INTERNAL] SC bus
	-- TX DAQ PORT		  
		ro_txreq, ro_txdone: in std_logic;
		ro_txack_out : out std_logic;
		ro_txdata: in std_logic_vector(7 downto 0);
		ro_tx_length: in std_logic_vector(15 downto 0);
		ro_NumFramesEvent: in std_logic_vector(6 downto 0);
		ro_tx_start, ro_tx_stop: in std_logic;
		ro_txdata_rdy, ro_frameEndEvent: out std_logic
		);
	END COMPONENT;
	signal	clk200, clk125, clk40, clk10:  std_logic;
	signal	rstn_app, rstn_sc, rstn_init, rstn:  std_logic;
	signal 	trg_to_sys, trg_from_sys, dcm_locked: std_logic;
   signal  	sc_port 	: std_logic_vector(15 downto 0);						--% [APP INTERNAL] SC bus
   signal  	sc_data 	: std_logic_vector(31 downto 0);						--% [APP INTERNAL] SC bus
   signal  	sc_addr 	: std_logic_vector(31 downto 0);						--% [APP INTERNAL] SC bus
   signal  	sc_subaddr : std_logic_vector(31 downto 0);						--% [APP INTERNAL] SC bus
   signal  	sc_op 		: std_logic;												--% [APP INTERNAL] SC bus
   signal  	sc_frame 	: std_logic;												--% [APP INTERNAL] SC bus
   signal 	sc_wr 		: std_logic;												--% [APP INTERNAL] SC bus
   signal	sc_ack 		: std_logic;													--% [APP INTERNAL] SC bus
   signal 	sc_rply_data 	: std_logic_vector(31 downto 0);					--% [APP INTERNAL] SC bus
   signal 	sc_rply_error 	: std_logic_vector(31 downto 0);					--% [APP INTERNAL] SC bus

	signal	ro_txreq, ro_txdone:  std_logic;
	signal	ro_txack :  std_logic;
	signal	ro_txdata:  std_logic_vector(7 downto 0);
	signal	ro_tx_length:  std_logic_vector(15 downto 0);
	signal	ro_NumFramesEvent: std_logic_vector(6 downto 0);
	signal	ro_tx_start, ro_tx_stop:  std_logic;
	signal	ro_txdata_rdy, ro_frameEndEvent:  std_logic;


--	signal CLK200: STD_LOGIC;
	attribute keep : boolean;
	attribute keep of ro_txack: 		signal is true;
	attribute keep of ro_txdone: 		signal is true;
	attribute keep of ro_txreq: 		signal is true;
	attribute keep of ro_txdata: 		signal is true;
	attribute keep of ro_tx_start: 		signal is true;
	attribute keep of ro_tx_stop: 		signal is true;
	attribute keep of ro_txdata_rdy: 		signal is true;
	attribute keep of ro_frameEndEvent: 		signal is true;
	
	signal s_DTC_DATA0_P, s_DTC_DATA0_N, s_DTC_DATA1_P, s_DTC_DATA1_N:  std_logic_vector(1 downto 0);

	
	signal TEMPORAL: STD_LOGIC;
	signal COUNTER : integer range 0 to 24999999 := 0;
	
	COMPONENT appUnit_apz
	generic ( BCLK_INVERT: boolean := false );
	PORT(
		clk, clk125, clk10M, clk_refiod : IN std_logic;
		rstn_init, rstn_global, rstn, dcm_locked : IN std_logic;
		
		-- ADC interface
		FCO1_P, FCO1_N : IN std_logic;																				--! [APP IO] ADC LVDS interface
		DCO1_P, DCO1_N : IN std_logic;																				--! [APP IO] ADC LVDS interface
		DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N : IN std_logic;				--! [APP IO] ADC LVDS interface
		DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N : IN std_logic;				--! [APP IO] ADC LVDS interface
		FCO2_P, FCO2_N : IN std_logic;																				--! [APP IO] ADC LVDS interface
		DCO2_P, DCO2_N : IN std_logic;																				--! [APP IO] ADC LVDS interface
		DCH9_P, DCH9_N, DCH10_P, DCH10_N, DCH11_P, DCH11_N, DCH12_P, DCH12_N : IN std_logic;		--! [APP IO] ADC LVDS interface
		DCH13_P, DCH13_N, DCH14_P, DCH14_N, DCH15_P, DCH15_N, DCH16_P, DCH16_N : IN std_logic;		--! [APP IO] ADC LVDS interface

		ADCLK_P : OUT std_logic;
		ADCLK_N : OUT std_logic;
		bclk_p : OUT std_logic;
		bclk_n : OUT std_logic;
		btrg_p : OUT std_logic;
		btrg_n : OUT std_logic;
		
		csb1, pwb1 : OUT std_logic;
		csb2, pwb2 : OUT std_logic;
		sclk, sdata, resetb : OUT std_logic;
		i2c0_scl, i2c0_sda : INOUT std_logic;
		i2c0_rst : OUT std_logic;
		i2c1_scl, i2c1_sda : INOUT std_logic;
		
		trgout : OUT std_logic;
		trgin : IN std_logic;
		
		sc_port : IN std_logic_vector(15 downto 0);
		sc_data : IN std_logic_vector(31 downto 0);
		sc_addr : IN std_logic_vector(31 downto 0);
		sc_subaddr : IN std_logic_vector(31 downto 0);
		sc_frame : IN std_logic;
		sc_op : IN std_logic;
		sc_wr : IN std_logic;
		sc_ack : OUT std_logic;
		sc_rply_data : OUT std_logic_vector(31 downto 0);
		sc_rply_error : OUT std_logic_vector(31 downto 0);
		
		txack : IN std_logic;
		txdstrdy : IN std_logic;
		txendframe : IN std_logic; 
		txreq : OUT std_logic;
		txdone : OUT std_logic;
		txstart : OUT std_logic;
		txstop : OUT std_logic;
		txdata : OUT std_logic_vector(7 downto 0);
		txlength : OUT std_logic_vector(15 downto 0);
		ro_NumFramesEvent : OUT std_logic_vector(6 downto 0)
		);
	END COMPONENT;
	
	
begin

	SELF_RSTN 	<= '0';
	GBTSW 		<= '0';
	EXP 			<= "000000000000";

	SFP_SDA0 	<= '1';
	SFP_SDA1 	<= '1';
	SFP_SCL0		<= '1';
	SFP_SCL1		<= '1';
--	A_I2C_SDA 	<= '1';
--	A_I2C_SCL 	<= '1';
--	B_I2C_SDA 	<= '1';
--	B_I2C_SCL	<= '1';

	PLL_SYNC		<= '0';
	GOE			<= '0';
	CLKUWIRE			<= '0';
	DATAUWIRE		<= '0';
	LEUWIRE			<= '0';
--	TTL_TO_NIM		<= '0';

	DTC0_DATA0_P <= s_DTC_DATA0_P(0);
	DTC0_DATA0_N <= s_DTC_DATA0_N(0);
	DTC1_DATA0_P <= s_DTC_DATA0_P(1);
	DTC1_DATA0_N <= s_DTC_DATA0_N(1);
	DTC0_DATA1_P <= s_DTC_DATA1_P(0);
	DTC0_DATA1_N <= s_DTC_DATA1_N(0);
	DTC1_DATA1_P <= s_DTC_DATA1_P(1);
	DTC1_DATA1_N <= s_DTC_DATA1_N(1);
	
	sysUnit_i: sysUnitvx6 PORT MAP(
		clk200_p => CLK200_P,
		clk200_n => CLK200_N,
		SFP_CLK_P => SFP_CLK_P,
		SFP_CLK_N => SFP_CLK_N,
		SFP_RX_P => SFP0_RX_P,
		SFP_RX_N => SFP0_RX_N,
		SFP_TX_P => SFP0_TX_P,
		SFP_TX_N => SFP0_TX_N,
		
		DTC_CLK_P => DTC1_CLK_P & DTC0_CLK_P,
		DTC_CLK_N => DTC1_CLK_N & DTC0_CLK_N,
		DTC_CMD_P => DTC1_CMD_P & DTC0_CMD_P,
		DTC_CMD_N => DTC1_CMD_N & DTC0_CMD_N,
--		DTC_DATA0_P => DTC1_DATA0_P & DTC0_DATA0_P,
--		DTC_DATA0_N => DTC1_DATA0_N & DTC0_DATA0_N,
--		DTC_DATA1_P => DTC1_DATA1_P & DTC0_DATA1_P,
--		DTC_DATA1_N => DTC1_DATA1_N & DTC0_DATA1_N,
		DTC_DATA0_P => s_DTC_DATA0_P,
		DTC_DATA0_N => s_DTC_DATA0_N,
		DTC_DATA1_P => s_DTC_DATA1_P,
		DTC_DATA1_N => s_DTC_DATA1_N,
		
		A_I2C_SCL => A_I2C_SCL,
		A_I2C_SDA => A_I2C_SDA,
		B_I2C_SCL => B_I2C_SCL,
		B_I2C_SDA => B_I2C_SDA,
--		SWRST_n => SELF_RSTN
		SWRST_n => open,
		
		nim_trgin => NIM_TO_TTL,
		nim_trgout => TTL_TO_NIM,

		clk200_out => clk200,	clk125_out => clk125,	clk40_out => clk40,	clk10_out => clk10,
		rstn_app_out => rstn_app,		rstn_sc_out => rstn_sc,		rstn_init_out => rstn_init,	rstn_out => rstn,
		
		dcm_locked => dcm_locked,
		
		trgout => trg_from_sys,
		trgin => trg_to_sys,
		
		sc_port_out 		=> sc_port,
		sc_data_out 		=> sc_data,
		sc_addr_out 		=> sc_addr,
		sc_subaddr_out 	=> sc_subaddr,
		sc_op_out 			=> sc_op,
		sc_frame_out 		=> sc_frame,
		sc_wr_out 			=> sc_wr,
		sc_ack_in 			=> sc_ack,
		sc_rply_data_in 	=> sc_rply_data,
		sc_rply_error_in 	=> sc_rply_error,
		
		ro_txreq 			=> ro_txreq,
		ro_txdone 			=> ro_txdone,
		ro_txack_out 		=> ro_txack,
		ro_txdata 			=> ro_txdata,
		ro_tx_length 		=> ro_tx_length,
		ro_NumFramesEvent => ro_NumFramesEvent,
		ro_tx_start 		=> ro_tx_start,
		ro_tx_stop 			=> ro_tx_stop,
		ro_txdata_rdy 		=> ro_txdata_rdy,
		ro_frameEndEvent 	=> ro_frameEndEvent
		
	);
	
	appUnit_i: appUnit_apz 
	GENERIC MAP( 	BCLK_INVERT => false )
	PORT MAP(
		clk => clk40,	clk125 => clk125,		clk10M => clk10,	clk_refiod => clk200,
		rstn_init => rstn_init,	rstn_global => rstn,		rstn => rstn_app,
		-- TO BE REVISED
		dcm_locked => dcm_locked,
		-- TO BE REVISED
		trgin => trg_from_sys,
		trgout => trg_to_sys,
		
		sc_port => sc_port,
		sc_data => sc_data,
		sc_addr => sc_addr,
		sc_subaddr => sc_subaddr,
		sc_frame => sc_frame,
		sc_op => sc_op,
		sc_wr => sc_wr,
		sc_ack => sc_ack,
		sc_rply_data => sc_rply_data,
		sc_rply_error => sc_rply_error,
		
		FCO1_P => A_IO(17),
		FCO1_N => A_IO(18),
		
--		DCO1_P => A_IO(17),
--		DCO1_N => A_IO(18),
		DCO1_P => A_DIFF_P(12),
		DCO1_N => A_DIFF_N(12),
		
		DCH1_P => A_DIFF_P(13),
		DCH1_N => A_DIFF_N(13),
		DCH2_P => A_DIFF_P(14),
		DCH2_N => A_DIFF_N(14),
		DCH3_P => A_DIFF_P(15),
		DCH3_N => A_DIFF_N(15),
		DCH4_P => A_DIFF_P(16),
		DCH4_N => A_DIFF_N(16),
		DCH5_P => A_DIFF_P(17),
		DCH5_N => A_DIFF_N(17),
		DCH6_P => A_DIFF_P(18),
		DCH6_N => A_DIFF_N(18),
		DCH7_P => A_DIFF_P(19),
		DCH7_N => A_DIFF_N(19),
		DCH8_P => A_DIFF_P(20),
		DCH8_N => A_DIFF_N(20),
		
		FCO2_P => A_IO(1),
		FCO2_N => A_IO(2),
		
--		DCO2_P => A_IO(1),
--		DCO2_N => A_IO(2),
		DCO2_P => A_DIFF_P(2),
		DCO2_N => A_DIFF_N(2),
		
		DCH9_P => A_DIFF_P(3),
		DCH9_N => A_DIFF_N(3),
		DCH10_P => A_DIFF_P(4),
		DCH10_N => A_DIFF_N(4),
		DCH11_P => A_DIFF_P(5),
		DCH11_N => A_DIFF_N(5),
		DCH12_P => A_DIFF_P(6),
		DCH12_N => A_DIFF_N(6),
		DCH13_P => A_DIFF_P(7),
		DCH13_N => A_DIFF_N(7),
		DCH14_P => A_DIFF_P(8),
		DCH14_N => A_DIFF_N(8),
		DCH15_P => A_DIFF_P(9),
		DCH15_N => A_DIFF_N(9),
		DCH16_P => A_DIFF_P(10),
		DCH16_N => A_DIFF_N(10),
		csb1 => B_IO(14),
		pwb1 => B_IO(16),
		csb2 => B_IO(13),
		pwb2 => B_IO(15),
		sclk => B_IO(9),
		sdata => B_IO(10),
		resetb => B_IO(6),
		
		ADCLK_P => A_DIFF_P(11),
		ADCLK_N => A_DIFF_N(11),
		-- inverted at source
		bclk_p => A_DIFF_P(1),
		bclk_n => A_DIFF_N(1),
		
		-- inverted at source
		btrg_p => A_IO(16),
		btrg_n => A_IO(15),
		
		i2c0_scl => B_IO(11),
		i2c0_sda => B_IO(12),
		i2c0_rst => B_IO(8),
		i2c1_scl => B_IO(1),
		i2c1_sda => B_IO(2),
		
		txack => ro_txack,
		txdstrdy => ro_txdata_rdy,
		txendframe => ro_frameEndEvent,
		txreq => ro_txreq,
		txdone => ro_txdone,
		txstart => ro_tx_start,
		txstop => ro_tx_stop,
		txdata => ro_txdata,
		txlength => ro_tx_length,
		ro_NumFramesEvent => ro_NumFramesEvent
	);
	
	
	
	
	frequency_divider: process (CLK125) begin
		if rising_edge(CLK125) then
			if (COUNTER = 24999999) then
				 TEMPORAL <= NOT(TEMPORAL);
				 COUNTER <= 0;
			else
				 COUNTER <= COUNTER + 1;
			end if;
		end if;
	end process;

	LED_0 <= TEMPORAL;
	LED_1 <= NOT(TEMPORAL);
end Behavioral;

