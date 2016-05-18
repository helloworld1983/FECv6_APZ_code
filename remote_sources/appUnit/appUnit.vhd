----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:49:21 04/05/2012 
-- Design Name: 
-- Module Name:    appUnit_vhd - Behavioral 
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
--! @file

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;
use work.vhdl_functions_sc.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity appUnit_adc is
	generic ( BCLK_INVERT: boolean := false );
	port (
		
		clk, clk125, clk10M, clk_refiod: IN std_logic;				--! [SYS INTERNAL] clock signals
		rstn_init, rstn_global, rstn : IN std_logic;					--! [SYS INTERNAL] reset signals
		dcm_locked : IN std_logic;											--! [SYS INTERNAL] clock signals
		
		trgin : IN std_logic;          									--! [SYS INTERNAL] trigger from System Unit
		trgout : OUT std_logic;          								--! [SYS INTERNAL] trigger to System Unit
		
		-- sc bus
		sc_port : IN std_logic_vector(15 downto 0);									--! [SYS INTERNAL] SC bus
		sc_data, sc_addr, sc_subaddr : IN std_logic_vector(31 downto 0);		--! [SYS INTERNAL] SC bus
		sc_frame, sc_op, sc_wr : IN std_logic;											--! [SYS INTERNAL] SC bus
		sc_ack : OUT std_logic;																--! [SYS INTERNAL] SC bus
		sc_rply_data, sc_rply_error : OUT std_logic_vector(31 downto 0);		--! [SYS INTERNAL] SC bus
		
		-- ADC interface
		DCO1_P, DCO1_N : IN std_logic;																				--! [APP IO] ADC LVDS interface
		DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N : IN std_logic;				--! [APP IO] ADC LVDS interface
		DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N : IN std_logic;				--! [APP IO] ADC LVDS interface
		DCO2_P, DCO2_N : IN std_logic;																				--! [APP IO] ADC LVDS interface
		DCH9_P, DCH9_N, DCH10_P, DCH10_N, DCH11_P, DCH11_N, DCH12_P, DCH12_N : IN std_logic;		--! [APP IO] ADC LVDS interface
		DCH13_P, DCH13_N, DCH14_P, DCH14_N, DCH15_P, DCH15_N, DCH16_P, DCH16_N : IN std_logic;		--! [APP IO] ADC LVDS interface
		csb1, pwb1 : OUT std_logic;																					--! [APP IO] ADC control
		csb2, pwb2 : OUT std_logic;																					--! [APP IO] ADC control
		sclk, sdata, resetb : OUT std_logic;																		--! [APP IO] ADC SPI
		ADCLK_P, ADCLK_N : OUT std_logic;																			--! [APP IO] ADC LVDS clock
		-- clock & trigger output
		bclk_p, bclk_n: OUT std_logic;													--! [APP IO] Clock & Trigger output for hybrids
		btrg_p, btrg_n: OUT std_logic;													--! [APP IO] Clock & Trigger output for hybrids
		-- i2c channels
		i2c0_scl, i2c0_sda : INOUT std_logic;											--! [APP IO] I2C bus 0 (hybrid I2C)
		i2c0_rst : OUT std_logic;															--! [APP IO] I2C bus 0 (hybrid I2C)
		i2c1_scl, i2c1_sda : INOUT std_logic;											--! [APP IO] I2C bus 1 (ADC Card registers)

		-- TX UDP interface
		txack, txdstrdy, txendframe : IN std_logic;									--! [SYS INTERNAL] TX UDP interface
		txreq, txdone, txstart, txstop : OUT std_logic;								--! [SYS INTERNAL] TX UDP interface
		txdata : OUT std_logic_vector(7 downto 0);									--! [SYS INTERNAL] TX UDP interface
		txlength : OUT std_logic_vector(15 downto 0);								--! [SYS INTERNAL] TX UDP interface
		ro_NumFramesEvent :  out std_logic_vector( 6  downto 0  )				--! [SYS INTERNAL] TX UDP interface
);	

end appUnit_adc;

architecture Behavioral of appUnit_adc is

--signal		sc_port_1 :  std_logic_vector(15 downto 0);
--signal		sc_data_1, sc_addr_1, sc_subaddr_1 :  std_logic_vector(31 downto 0);
--signal		sc_frame_1, sc_op_1, sc_wr_1 :  std_logic;
--signal		sc_ack_1 :  std_logic;
--signal		sc_rply_data_1, sc_rply_error_1 :  std_logic_vector(31 downto 0);

	COMPONENT scApplication
	PORT(
		clk, clk40M : IN std_logic;
		rstn : IN std_logic;
		-- sc bus
		sc_port : IN std_logic_vector(15 downto 0);
		sc_data, sc_addr, sc_subaddr : IN std_logic_vector(31 downto 0);
		sc_frame, sc_op, sc_wr : IN std_logic;
		sc_ack : OUT std_logic;
		sc_rply_data, sc_rply_error : OUT std_logic_vector(31 downto 0);
		
		i2c0_scl, i2c0_sda : INOUT std_logic;
		i2c0_rst : OUT std_logic;
		i2c1_scl, i2c1_sda : INOUT std_logic;
		
		cspi_enable : OUT std_logic;
		cspi_sdata : OUT std_logic;
		cspi_cs_n : OUT std_logic_vector(31 downto 0);
		
		apprstreg, cspi_rstreg : OUT std_logic_vector(15 downto 0);
		appregin : IN std_logic_vector(511 downto 0);
		appregout : OUT std_logic_vector(511 downto 0)--;
--		-- interface to the sigma and pedestal memories
--		api_pedestal_out, api_sigma_out : IN std_logic_vector(11 downto 0);
--		api_sigped_apv : OUT std_logic_vector(3 downto 0);
--		api_load_pedestal, api_load_sigma : OUT std_logic;
--		api_pedestal_addr, api_sigma_addr : OUT std_logic_vector(6 downto 0);
--		api_pedestal_in, api_sigma_in : OUT std_logic_vector(11 downto 0)
		);
	END COMPONENT;
signal		cspi_enable :  std_logic;
signal		cspi_sdata :  std_logic;
signal		cspi_cs_n :  std_logic_vector(31 downto 0);
signal		cspi_rstreg :  std_logic_vector(15 downto 0);
signal		apprstreg :  std_logic_vector(15 downto 0);
signal		appregs, appregs_return :  std_logic_vector(511 downto 0);
--		-- interface to the sigma and pedestal memories
--signal		api_pedestal_out, api_sigma_out, api_pedestal_in, api_sigma_in :  std_logic_vector(11 downto 0);
--signal		api_sigped_apv :  std_logic_vector(3 downto 0);
--signal		api_load_pedestal, api_load_sigma :  std_logic;
--signal		api_pedestal_addr, api_sigma_addr :  std_logic_vector(6 downto 0);
	COMPONENT ADCcore
	PORT(
		clk, clk10M, clk_refiod: IN std_logic;
		rstn_init, rstn : IN std_logic;
		dcm_locked : IN std_logic;
		-- ADC interface
		DCO1_P, DCO1_N : IN std_logic;
		DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N : IN std_logic;
		DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N : IN std_logic;
		DCO2_P, DCO2_N : IN std_logic;
		DCH9_P, DCH9_N, DCH10_P, DCH10_N, DCH11_P, DCH11_N, DCH12_P, DCH12_N : IN std_logic;
		DCH13_P, DCH13_N, DCH14_P, DCH14_N, DCH15_P, DCH15_N, DCH16_P, DCH16_N : IN std_logic;
		csb1, pwb1 : OUT std_logic;
		csb2, pwb2 : OUT std_logic;
		sclk, sdata, resetb : OUT std_logic;
		ADCLK_P, ADCLK_N : OUT std_logic;
		-- deserialized data
		CH0, CH1, CH2, CH3, CH4, CH5, CH6, CH7 : OUT std_logic_vector(11 downto 0);
		CH8, CH9, CH10, CH11, CH12, CH13, CH14, CH15 : OUT std_logic_vector(11 downto 0);
		-- control
		adcsclk_disable : IN std_logic; 
		-- status		
		conf_end, DES_run : OUT std_logic;
		DES_status : OUT std_logic_vector(15 downto 0);
		ADCDCM_status : OUT std_logic_vector(5 downto 0)
		);
	END COMPONENT;
signal		CH0, CH1, CH2, CH3, CH4, CH5, CH6, CH7 :  std_logic_vector(11 downto 0);
signal		CH8, CH9, CH10, CH11, CH12, CH13, CH14, CH15 :  std_logic_vector(11 downto 0);
signal 		adcsclk_disable :  std_logic; 
signal		conf_end, DES_run :  std_logic;
signal		DES_status :  std_logic_vector(15 downto 0);
attribute KEEP : string;
attribute KEEP of conf_end: signal is "TRUE";
attribute KEEP of DES_run: signal is "TRUE";
attribute KEEP of DES_status: signal is "TRUE";
signal		ADCDCM_status :  std_logic_vector(5 downto 0);
	COMPONENT apv_sync_det
	PORT(
		clk : IN std_logic;
		rst : IN std_logic;
		datain : IN std_logic_vector(11 downto 0);
		threshold_low : IN std_logic_vector(11 downto 0);
		threshold_high : IN std_logic_vector(11 downto 0);          
		sync_out : OUT std_logic
		);
	END COMPONENT;
	COMPONENT bitsum15
	PORT(
		data : IN std_logic_vector(15 downto 0);          
		result : OUT std_logic_vector(6 downto 0)
		);
	END COMPONENT;
	signal apv_sync : std_logic_vector(15 downto 0);
	signal cfg_apvdet_lowthr, cfg_apvdet_highthr : std_logic_vector(11 downto 0);
--signal		api_I2C_done, api_I2C_request :  std_logic;
--signal		api_I2C_ctr2 :  std_logic_vector(4 downto 0);

signal	apv_data :  std_logic_vector(191 downto 0);
--signal		cfgout_apz_status : std_logic_vector(15 downto 0);
--signal		evbld_apz, api_reset, api_random_trigger, api_trigger_inhibit :  std_logic;
--signal		api_apv_select :  std_logic_vector(3 downto 0);
--signal        cfgout_apz_chstatus        :   std_logic_vector(31  downto 0  );

--signal		api_busy : std_logic;
--signal		api_ready, api_read :  std_logic_vector(15 downto 0);
--signal		api_data, api_wordcount :  std_logic_vector(255 downto 0);
--signal		api_output_enable :  std_logic_vector(15 downto 0);

	COMPONENT appUnit_DAQ
	generic ( BCLK_INVERT: boolean := false );
	PORT(
		clk : IN std_logic;
		clk125 : IN std_logic;
		rstn : IN std_logic;
		forceBclkRst : IN std_logic;
		CH0 : IN std_logic_vector(11 downto 0);
		CH1 : IN std_logic_vector(11 downto 0);
		CH2 : IN std_logic_vector(11 downto 0);
		CH3 : IN std_logic_vector(11 downto 0);
		CH4 : IN std_logic_vector(11 downto 0);
		CH5 : IN std_logic_vector(11 downto 0);
		CH6 : IN std_logic_vector(11 downto 0);
		CH7 : IN std_logic_vector(11 downto 0);
		CH8 : IN std_logic_vector(11 downto 0);
		CH9 : IN std_logic_vector(11 downto 0);
		CH10 : IN std_logic_vector(11 downto 0);
		CH11 : IN std_logic_vector(11 downto 0);
		CH12 : IN std_logic_vector(11 downto 0);
		CH13 : IN std_logic_vector(11 downto 0);
		CH14 : IN std_logic_vector(11 downto 0);
		CH15 : IN std_logic_vector(11 downto 0);
		trgin : IN std_logic;
		txack : IN std_logic;
		txdstrdy : IN std_logic;
		txendframe : IN std_logic;
		regs : IN std_logic_vector(511 downto 0);          
		bclkout : OUT std_logic;
		btrgout : OUT std_logic;
		trgout : OUT std_logic;
		trgout0 : OUT std_logic;
		txreq : OUT std_logic;
		txdone : OUT std_logic;
		txdata : OUT std_logic_vector(7 downto 0);
		txlength : OUT std_logic_vector(15 downto 0);
		txstart : OUT std_logic;
		txstop : OUT std_logic
		);
	END COMPONENT;
signal		trgout_i, ro_trigger :  std_logic;
signal		forceBclkRst :  std_logic;

signal cfg_roenable: std_logic_vector(7 downto 0);
signal cfg_evbld_chmask: std_logic_vector(15 downto 0);

signal rstn_init_adc, rstn_global_adc, csb1_adc, csb2_adc, sdata_adc, resetb_adc:std_logic;
signal bclkout:std_logic;
signal btrgout:std_logic;

begin
	
	--! slow-control drivers for the application unit
	scApplication_inst: scApplication PORT MAP(
		clk => clk10M,		clk40M => clk,		rstn => rstn,
		
		sc_port 	     => sc_port,
		sc_data 	     => sc_data,
		sc_addr 	     => sc_addr,
		sc_subaddr 	  => sc_subaddr,
		sc_op 		  => sc_op,
		sc_frame 	  => sc_frame,
		sc_wr 		  => sc_wr,
		sc_ack 		  => sc_ack,
		sc_rply_data  => sc_rply_data,
		sc_rply_error => sc_rply_error,
		
		i2c0_scl    => i2c0_scl,
		i2c0_sda    => i2c0_sda,
		i2c0_rst    => i2c0_rst,
		
		i2c1_scl    => i2c1_scl,
		i2c1_sda    => i2c1_sda,
		
		cspi_enable => cspi_enable,
		cspi_sdata	=> cspi_sdata,
		cspi_cs_n	=> cspi_cs_n,
		cspi_rstreg	=> cspi_rstreg,
		
		apprstreg   => apprstreg,
		appregout   => appregs,
		appregin    => appregs_return--,
		
	);
	
	cfg_roenable <= ireg8( 15 , appregs );
   cfg_evbld_chmask 			<= ireg16( 8 , appregs );
	forceBclkRst <= apprstreg(0);
	
	adcsclk_disable <= '0';

   appregs_return( 6*32+31  downto 0 ) 		<= appregs( 6*32+31  downto 0 );
   appregs_return( 7*32+31  downto  7*32 ) 	<= x"00" & conf_end & DES_run & ADCDCM_status & DES_status;
   appregs_return(15*32+31  downto 8*32 ) 	<= appregs(15*32+31  downto 8*32 );
--   appregs_return(16*32+31  downto 16*32 ) 	<= x"0000" & apv_sync;
--   appregs_return(17*32+31  downto 17*32 ) 	<= cfgout_apz_chstatus(15 downto 0) & cfgout_apz_status;
--   appregs_return(1023  downto 18*32 ) 		<= appregs(1023  downto 18*32 );
	
	--! Front-end core: ADC deserializers
	appFE: ADCcore PORT MAP(
		clk 			  	      => clk, clk10M => clk10M,		clk_refiod => clk_refiod,
		rstn_init            => rstn_init_adc,		rstn => rstn_global_adc,
		dcm_locked           => dcm_locked,
		-- ADC interface
		 DCH1_N 		  	      => DCH1_N,   DCH1_P => DCH1_P,   DCH2_N => DCH2_N,   DCH2_P => DCH2_P,	 DCH3_N => DCH3_N,   DCH3_P => DCH3_P,   DCH4_N => DCH4_N,   DCH4_P => DCH4_P,
		 DCH5_N 		  	      => DCH5_N,   DCH5_P => DCH5_P,   DCH6_N => DCH6_N,   DCH6_P => DCH6_P,	 DCH7_N => DCH7_N,   DCH7_P => DCH7_P,   DCH8_N => DCH8_N,   DCH8_P => DCH8_P,
		 DCH9_N 		  	      => DCH9_N,   DCH9_P => DCH9_P,   DCH10_N => DCH10_N, DCH10_P => DCH10_P,	 DCH11_N => DCH11_N, DCH11_P => DCH11_P, DCH12_N => DCH12_N, DCH12_P => DCH12_P,
		 DCH13_N 		  	   => DCH13_N, DCH13_P => DCH13_P, DCH14_N => DCH14_N, DCH14_P => DCH14_P,	 DCH15_N => DCH15_N, DCH15_P => DCH15_P, DCH16_N => DCH16_N, DCH16_P => DCH16_P,
		 DCO1_N 		  	      => DCO1_N,  DCO1_P => DCO1_P,
		 DCO2_N 		  	      => DCO2_N,  DCO2_P => DCO2_P,
		csb1 			  	      => csb1_adc,		pwb1 => pwb1,
		csb2 			  	      => csb2_adc,		pwb2 => pwb2,
		sclk 			  	      => sclk,		sdata => sdata_adc,	resetb => resetb_adc,
		ADCLK_P 		  	      => ADCLK_P,	ADCLK_N => ADCLK_N,
		-- deserialized data
		 CH0 			  	      => CH0,  CH1 => CH1,  CH2 => CH2,  CH3 => CH3,  CH4 => CH4,  CH5 => CH5,  CH6 => CH6,  CH7 => CH7,
		 CH8 			  	      => CH8,  CH9 => CH9,  CH10 => CH10, CH11 => CH11, CH12 => CH12, CH13 => CH13, CH14 => CH14, CH15 => CH15,
		-- control
		adcsclk_disable   	=> adcsclk_disable,
		-- status		
		conf_end 		  	   => conf_end,
		DES_run 		  	      => DES_run,
		DES_status 		  	   => DES_status,
		ADCDCM_status 	  	   => ADCDCM_status
	);
	
	sdata <= cspi_sdata when cspi_enable = '1' else sdata_adc;
	csb1 <= cspi_cs_n(0) when cspi_enable = '1' else csb1_adc;
	csb2 <= cspi_cs_n(1) when cspi_enable = '1' else csb2_adc;
	
	resetb 				<= not ( (not resetb_adc) or cspi_rstreg(15));
	rstn_init_adc 		<= rstn_init 	and (not cspi_rstreg(14));
	rstn_global_adc 	<= rstn_global and (not cspi_rstreg(13));
	
--	apv_data <= CH8 & CH9 & CH10 & CH11 & CH12 & CH13 & CH14 & CH15 & CH0 & CH1 & CH2 & CH3 & CH4 & CH5 & CH6 & CH7;
--
--	cfg_apvdet_lowthr <= x"4B0" when ireg12(29, appregs) = 0 else ireg12(29, appregs);
--	cfg_apvdet_highthr <= x"BB8" when ireg12(30, appregs) = 0 else ireg12(30, appregs);
--	
--	apvsdet_gen: for i in 0 to 15 generate
--		Inst_apv_sdet: apv_sync_det PORT MAP(		clk => clk,		rst => not rstn,
--			datain => apv_data((12*i + 11) downto 12*i),
--			threshold_low => cfg_apvdet_lowthr,			threshold_high => cfg_apvdet_highthr,
--			sync_out => apv_sync(i)
--		);
--	end generate;
	
	--! DAQ core: trigger engine + event builder
	Inst_appUnit_DAQ: appUnit_DAQ 
	GENERIC MAP( BCLK_INVERT => BCLK_INVERT)
	PORT MAP(
		clk => clk,		clk125 => clk125,		rstn => rstn,
		forceBclkRst => forceBclkRst,
		CH0 => CH0,		CH1 => CH1,		CH2 => CH2,		CH3 => CH3,
		CH4 => CH4,		CH5 => CH5,		CH6 => CH6,		CH7 => CH7,
		CH8 => CH8,		CH9 => CH9,		CH10 => CH10,		CH11 => CH11,
		CH12 => CH12,		CH13 => CH13,		CH14 => CH14,		CH15 => CH15,
		bclkout => bclkout,
		btrgout => btrgout,
		trgin => trgin,
		trgout => open,
		trgout0 => trgout_i,
		txreq => txreq,
		txdone => txdone,
		txack => txack,
		txdata => txdata,
		txlength => txlength,
		txstart => txstart,
		txstop => txstop,
		txdstrdy => txdstrdy,
		txendframe => txendframe,
		regs => appregs
	);
	
	chmask_bitsum: bitsum15 PORT MAP(	data => cfg_evbld_chmask,	result => ro_NumFramesEvent);
	
	trgout <= trgout_i;
	
	OBUFDS_inst : OBUFDS   generic map ( IOSTANDARD => "LVDS_25")
	port map (
		O => bclk_p,     -- Diff_p output (connect directly to top-level port)
		OB => bclk_n,   -- Diff_n output (connect directly to top-level port)
		I => bclkout      -- Buffer input 
	);
	OBUFDS2_inst : OBUFDS   generic map ( IOSTANDARD => "LVDS_25")
   port map (
      O => btrg_p,     -- Diff_p output (connect directly to top-level port)
      OB => btrg_n,   -- Diff_n output (connect directly to top-level port)
      I => btrgout      -- Buffer input 
   );

end Behavioral;

