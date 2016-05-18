----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:49:21 04/05/2012 
-- Design Name: 
-- Module Name:    appUnit_apz - Behavioral 
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

entity appUnit_apz is
	generic ( BCLK_INVERT: boolean := false );
	port (
		
		clk, clk125, clk10M, clk_refiod: IN std_logic;
		rstn_init, rstn_global, rstn : IN std_logic;
		dcm_locked : IN std_logic;
		
		trgin : IN std_logic;          
		trgout : OUT std_logic;
		
		trgIDin: in std_logic_vector(63 downto 0) := x"0000000000000000";
		trgIDin_val : in std_logic := '0';
		
		-- sc bus
		sc_port : IN std_logic_vector(15 downto 0);
		sc_data, sc_addr, sc_subaddr : IN std_logic_vector(31 downto 0);
		sc_frame, sc_op, sc_wr : IN std_logic;
		sc_ack : OUT std_logic;
		sc_rply_data, sc_rply_error : OUT std_logic_vector(31 downto 0);
		
		-- ADC interface
		FCO1_P, FCO1_N : IN std_logic;		--! New in V6
		DCO1_P, DCO1_N : IN std_logic;
		DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N : IN std_logic;
		DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N : IN std_logic;
		FCO2_P, FCO2_N : IN std_logic;		--! New in V6
		DCO2_P, DCO2_N : IN std_logic;
		DCH9_P, DCH9_N, DCH10_P, DCH10_N, DCH11_P, DCH11_N, DCH12_P, DCH12_N : IN std_logic;
		DCH13_P, DCH13_N, DCH14_P, DCH14_N, DCH15_P, DCH15_N, DCH16_P, DCH16_N : IN std_logic;
		csb1, pwb1 : OUT std_logic;
		csb2, pwb2 : OUT std_logic;
		sclk, sdata, resetb : OUT std_logic;
		ADCLK_P, ADCLK_N : OUT std_logic;
		-- clock & trigger output
		bclk_p : OUT std_logic;
		bclk_n : OUT std_logic;
		btrg_p, btrg_n: OUT std_logic;		--! New in V6
		-- i2c channels
		i2c0_scl, i2c0_sda : INOUT std_logic;
		i2c0_rst : OUT std_logic;
		i2c1_scl, i2c1_sda : INOUT std_logic;

		-- TX UDP interface
		txack, txdstrdy, txendframe : IN std_logic;
		txreq, txdone, txstart, txstop : OUT std_logic;
		txdata : OUT std_logic_vector(7 downto 0);
		txlength : OUT std_logic_vector(15 downto 0);
		ro_NumFramesEvent :  out std_logic_vector( 6  downto 0  )
);	

end appUnit_apz;

architecture Behavioral of appUnit_apz is
	COMPONENT sc_master_apz
	PORT(
		clk : IN std_logic;
		clk10M : IN std_logic;
		rstn : IN std_logic;
		--
		sc_port : IN std_logic_vector(15 downto 0);
		sc_data : IN std_logic_vector(31 downto 0);
		sc_addr : IN std_logic_vector(31 downto 0);
		sc_subaddr : IN std_logic_vector(31 downto 0);
		sc_frame : IN std_logic;
		sc_op : IN std_logic;
		sc_wr : IN std_logic;
		sc_ack : OUT std_logic;
		sc_rply_data : OUT std_logic_vector(31 downto 0);
		--
		sc_ack_o : IN std_logic;
		sc_rply_data_o : IN std_logic_vector(31 downto 0);
		sc_rply_error_o : IN std_logic_vector(31 downto 0);
		sc_rply_error : OUT std_logic_vector(31 downto 0);
		sc_port_o : OUT std_logic_vector(15 downto 0);
		sc_data_o : OUT std_logic_vector(31 downto 0);
		sc_addr_o : OUT std_logic_vector(31 downto 0);
		sc_subaddr_o : OUT std_logic_vector(31 downto 0);
		sc_frame_o : OUT std_logic;
		sc_op_o : OUT std_logic;
		sc_wr_o : OUT std_logic;
		--
		api_i2c_request : IN std_logic;
		api_i2c_ctr2 : IN std_logic_vector(4 downto 0);
		api_apv_select : IN std_logic_vector(3 downto 0);          
		api_i2c_done : OUT std_logic
		);
	END COMPONENT;
signal		sc_port_1 :  std_logic_vector(15 downto 0);
signal		sc_data_1, sc_addr_1, sc_subaddr_1 :  std_logic_vector(31 downto 0);
signal		sc_frame_1, sc_op_1, sc_wr_1 :  std_logic;
signal		sc_ack_1 :  std_logic;
signal		sc_rply_data_1, sc_rply_error_1 :  std_logic_vector(31 downto 0);
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
		appregin : IN std_logic_vector(1023 downto 0);
		appregout : OUT std_logic_vector(1023 downto 0);
		-- interface to the sigma and pedestal memories
		api_pedestal_out, api_sigma_out : IN std_logic_vector(11 downto 0);
		api_sigped_apv : OUT std_logic_vector(3 downto 0);
		api_load_pedestal, api_load_sigma : OUT std_logic;
		api_pedestal_addr, api_sigma_addr : OUT std_logic_vector(6 downto 0);
		api_pedestal_in, api_sigma_in : OUT std_logic_vector(11 downto 0)
		);
	END COMPONENT;
signal		cspi_enable :  std_logic;
signal		cspi_sdata :  std_logic;
signal		cspi_cs_n :  std_logic_vector(31 downto 0);
signal		cspi_rstreg :  std_logic_vector(15 downto 0);
signal		apprstreg :  std_logic_vector(15 downto 0);
signal		appregs, appregs_return :  std_logic_vector(1023 downto 0);
		-- interface to the sigma and pedestal memories
signal		api_pedestal_out, api_sigma_out, api_pedestal_in, api_sigma_in :  std_logic_vector(11 downto 0);
signal		api_sigped_apv :  std_logic_vector(3 downto 0);
signal		api_load_pedestal, api_load_sigma :  std_logic;
signal		api_pedestal_addr, api_sigma_addr :  std_logic_vector(6 downto 0);
	COMPONENT ADCcore
	PORT(
		clk, clk10M, clk_refiod: IN std_logic;
		rstn_init, rstn : IN std_logic;
		dcm_locked : IN std_logic;
		-- ADC interface
		FCO1_P, FCO1_N : IN std_logic;
		DCO1_P, DCO1_N : IN std_logic;
		DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N : IN std_logic;
		DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N : IN std_logic;
		FCO2_P, FCO2_N : IN std_logic;
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
--! This is from FECv6_ADC version, comment for now
--! attribute KEEP : string;
--! attribute KEEP of conf_end: signal is "TRUE";
--! attribute KEEP of DES_run: signal is "TRUE";
--! attribute KEEP of DES_status: signal is "TRUE";
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
	COMPONENT apz_wrapper
	PORT(
		clk : IN std_logic;
		clk10M : IN std_logic;
		clk125 : IN std_logic;
		rstn : IN std_logic;
		regs : IN std_logic_vector(1023 downto 0);
		trigger : IN std_logic;
		apv_data : IN std_logic_vector(191 downto 0);
		api_output_enable : IN std_logic_vector(15 downto 0);
		api_read_in : IN std_logic_vector(15 downto 0);
		api_sigped_apv : IN std_logic_vector(3 downto 0);
		api_load_pedestal : IN std_logic;
		api_load_sigma : IN std_logic;
		api_pedestal_addr : IN std_logic_vector(6 downto 0);
		api_sigma_addr : IN std_logic_vector(6 downto 0);
		api_pedestal_in : IN std_logic_vector(11 downto 0);
		api_sigma_in : IN std_logic_vector(11 downto 0);          
		api_data_out : OUT std_logic_vector(255 downto 0);
		api_wordcount_out : OUT std_logic_vector(255 downto 0);
		api_ready_out : OUT std_logic_vector(15 downto 0);
		api_I2C_done : IN std_logic;
		api_I2C_request : OUT std_logic;
		api_I2C_ctr2 : OUT std_logic_vector(4 downto 0);
		api_pedestal_out : OUT std_logic_vector(11 downto 0);
		api_sigma_out : OUT std_logic_vector(11 downto 0);
        apz_status          :  out std_logic_vector(15  downto 0  );
        apz_chstatus        :  out std_logic_vector(31  downto 0  );
		evbld_apz : OUT std_logic;
		api_reset : OUT std_logic;
		api_random_trigger : OUT std_logic;
		api_trigger_inhibit : OUT std_logic;
		api_busy_out : OUT std_logic;
		api_apv_select : OUT std_logic_vector(3 downto 0)
		);
	END COMPONENT;
signal		api_I2C_done, api_I2C_request :  std_logic;
signal		api_I2C_ctr2 :  std_logic_vector(4 downto 0);

signal	apv_data :  std_logic_vector(191 downto 0);
signal		cfgout_apz_status : std_logic_vector(15 downto 0);
signal		evbld_apz, api_reset, api_random_trigger, api_trigger_inhibit :  std_logic;
signal		api_apv_select :  std_logic_vector(3 downto 0);
signal        cfgout_apz_chstatus        :   std_logic_vector(31  downto 0  );

	COMPONENT appDAQ_APZ_vhd
	PORT(
		clk, clk125, clk10M : IN std_logic;
		rstn : IN std_logic;
		
		evbld_apz : IN std_logic;
		api_reset : IN std_logic;
		apv_select : IN std_logic_vector(3 downto 0);
		cfg_roenable : IN std_logic_vector(7 downto 0);
		ro_trigger : IN std_logic;
		trgID_FromSys : in std_logic_vector( 63  downto 0  );
		regs : IN std_logic_vector(1023 downto 0);          
		-- deserialized data from DC core
		CH0, CH1, CH2, CH3, CH4, CH5, CH6, CH7 : IN std_logic_vector(11 downto 0);
		CH8, CH9, CH10, CH11, CH12, CH13, CH14, CH15 : IN std_logic_vector(11 downto 0);
		-- data from APZ processor
		api_busy : IN std_logic;
		api_ready : IN std_logic_vector(15 downto 0);
		api_data, api_wordcount : IN std_logic_vector(255 downto 0);
		api_read_out, api_output_enable : OUT std_logic_vector(15 downto 0);
		-- TX UDP interface
		txack, txdstrdy, txendframe : IN std_logic;
		txreq, txdone, txstart, txstop : OUT std_logic;
		txdata : OUT std_logic_vector(7 downto 0);
		txlength : OUT std_logic_vector(15 downto 0);
		ro_NumFramesEvent :  out std_logic_vector( 6  downto 0  )
    
--    --! Moved here in V6 ADC version
--    forceBclkRst : IN std_logic; 
--		trgin : IN std_logic;
--		bclkout : OUT std_logic;
--		btrgout : OUT std_logic;
--		trgout : OUT std_logic;
--		trgout0 : OUT std_logic
		);
	END COMPONENT;
signal		api_busy : std_logic;
signal		api_ready, api_read :  std_logic_vector(15 downto 0);
signal		api_data, api_wordcount :  std_logic_vector(255 downto 0);
signal		api_output_enable :  std_logic_vector(15 downto 0);

	COMPONENT appTRG_APZ_vhd
	PORT(
		rstn : IN std_logic;
		clk : IN std_logic;
		api_trigger_inhibit : IN std_logic;
		api_random_trigger : IN std_logic;
		forceBclkRst : IN std_logic;
		regs : IN std_logic_vector(1023 downto 0);
		trgin : IN std_logic;          
		trgout : OUT std_logic;
		bclkout : OUT std_logic;
		ro_trigger : OUT std_logic;
		bclk_p : OUT std_logic;
		bclk_n : OUT std_logic
		);
	END COMPONENT;
signal		trgout_i, ro_trigger :  std_logic;
signal		forceBclkRst :  std_logic;
signal		trgID_FromSys :  std_logic_vector(63 downto 0);

signal cfg_roenable: std_logic_vector(7 downto 0);
signal cfg_evbld_chmask: std_logic_vector(15 downto 0);

signal rstn_init_adc, rstn_global_adc, csb1_adc, csb2_adc, sdata_adc, resetb_adc:std_logic;
signal bclkout:std_logic;
signal btrgout:std_logic;

begin
	sc_master: sc_master_apz PORT MAP(
		clk => clk,		clk10M => clk10M,		rstn => rstn,
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
		--
		sc_port_o 			=> sc_port_1,
		sc_data_o 			=> sc_data_1,
		sc_addr_o 			=> sc_addr_1,
		sc_subaddr_o 		=> sc_subaddr_1,
		sc_frame_o 			=> sc_frame_1,
		sc_op_o 				=> sc_op_1,
		sc_wr_o 				=> sc_wr_1,
		sc_ack_o 			=> sc_ack_1,
		sc_rply_data_o 	=> sc_rply_data_1,
		sc_rply_error_o 	=> sc_rply_error_1,
		--
		api_i2c_request 	=> api_i2c_request,
		api_i2c_done 		=> api_i2c_done,
		api_i2c_ctr2 		=> api_i2c_ctr2,
		api_apv_select 	=> api_apv_select
	);
	
	--! slow-control drivers for the application unit
	scApplication_inst: scApplication PORT MAP(
		clk => clk10M,		clk40M => clk,		rstn => rstn,
		
		sc_port 	     => sc_port_1,
		sc_data 	     => sc_data_1,
		sc_addr 	     => sc_addr_1,
		sc_subaddr 	  => sc_subaddr_1,
		sc_op 		  => sc_op_1,
		sc_frame 	  => sc_frame_1,
		sc_wr 		  => sc_wr_1,
		sc_ack 		  => sc_ack_1,
		sc_rply_data  => sc_rply_data_1,
		sc_rply_error => sc_rply_error_1,
		
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
		appregin    => appregs_return,
		
		api_sigped_apv 	  	=> api_sigped_apv,
		api_load_pedestal 	=> api_load_pedestal,
		api_load_sigma 	  	=> api_load_sigma,
		api_pedestal_addr 	=> api_pedestal_addr,
		api_sigma_addr 	  	=> api_sigma_addr,
		api_pedestal_in   	=> api_pedestal_in,
		api_sigma_in 	  		=> api_sigma_in,
		api_pedestal_out  	=> api_pedestal_out,
		api_sigma_out 	  		=> api_sigma_out
	);
	
	cfg_roenable <= ireg8( 15 , appregs );
	cfg_evbld_chmask 			<= ireg16( 8 , appregs );
	forceBclkRst <= apprstreg(0);
	
	adcsclk_disable <= '0';

   appregs_return( 6*32+31  downto 0 ) 		<= appregs( 6*32+31  downto 0 );
   appregs_return( 7*32+31  downto  7*32 ) 	<= x"00" & conf_end & DES_run & ADCDCM_status & DES_status;
   appregs_return(15*32+31  downto 8*32 ) 	<= appregs(15*32+31  downto 8*32 );
   appregs_return(16*32+31  downto 16*32 ) 	<= x"0000" & apv_sync;
   appregs_return(17*32+31  downto 17*32 ) 	<= cfgout_apz_chstatus(15 downto 0) & cfgout_apz_status;
   appregs_return(1023  downto 18*32 ) 		<= appregs(1023  downto 18*32 );
	
	appFE: ADCcore PORT MAP(
		clk 			  	      => clk, clk10M => clk10M,		clk_refiod => clk_refiod,
		rstn_init            => rstn_init_adc,		rstn => rstn_global_adc,
		dcm_locked           => dcm_locked,
		-- ADC interface 
		DCH1_N 		  	      => DCH1_N,   DCH1_P => DCH1_P,   DCH2_N => DCH2_N,   DCH2_P => DCH2_P,	 DCH3_N => DCH3_N,   DCH3_P => DCH3_P,   DCH4_N => DCH4_N,   DCH4_P => DCH4_P,
		 DCH5_N 		  	      => DCH5_N,   DCH5_P => DCH5_P,   DCH6_N => DCH6_N,   DCH6_P => DCH6_P,	 DCH7_N => DCH7_N,   DCH7_P => DCH7_P,   DCH8_N => DCH8_N,   DCH8_P => DCH8_P,
		 DCH9_N 		  	      => DCH9_N,   DCH9_P => DCH9_P,   DCH10_N => DCH10_N, DCH10_P => DCH10_P,	 DCH11_N => DCH11_N, DCH11_P => DCH11_P, DCH12_N => DCH12_N, DCH12_P => DCH12_P,
		 DCH13_N 		  	   => DCH13_N, DCH13_P => DCH13_P, DCH14_N => DCH14_N, DCH14_P => DCH14_P,	 DCH15_N => DCH15_N, DCH15_P => DCH15_P, DCH16_N => DCH16_N, DCH16_P => DCH16_P,
		FCO1_N 		  	      => FCO1_N,  FCO1_P => FCO1_P,
		 FCO2_N 		  	      => FCO2_N,  FCO2_P => FCO2_P,		 
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
	
	apv_data <= CH8 & CH9 & CH10 & CH11 & CH12 & CH13 & CH14 & CH15 & CH0 & CH1 & CH2 & CH3 & CH4 & CH5 & CH6 & CH7;

	cfg_apvdet_lowthr <= x"4B0" when ireg12(29, appregs) = 0 else ireg12(29, appregs);
	cfg_apvdet_highthr <= x"BB8" when ireg12(30, appregs) = 0 else ireg12(30, appregs);
	
	apvsdet_gen: for i in 0 to 15 generate
		Inst_apv_sdet: apv_sync_det PORT MAP(		clk => clk,		rst => not rstn,
			datain => apv_data((12*i + 11) downto 12*i),
			threshold_low => cfg_apvdet_lowthr,			threshold_high => cfg_apvdet_highthr,
			sync_out => apv_sync(i)
		);
	end generate;
	
	appAPZProc: apz_wrapper PORT MAP(
		clk                 => clk,		clk10M => clk10M,		clk125 => clk125,
		rstn                => rstn,
      -- registers and control
		regs                => appregs,
		trigger             => trgout_i,
      -- data from ADC core
		apv_data            => apv_data,
      -- data out interface
		api_data_out        => api_data,
		api_wordcount_out   => api_wordcount,
		api_ready_out       => api_ready,
		api_output_enable   => api_output_enable,
		api_read_in         => api_read,
      -- clock phase align signals
 		api_I2C_request     => api_I2C_request,
		api_I2C_done        => api_I2C_done,
		api_I2C_ctr2        => api_I2C_ctr2,
		-- sigma and pedestals memory access
		api_sigped_apv      => api_sigped_apv,
		api_load_pedestal   => api_load_pedestal,
		api_load_sigma      => api_load_sigma,
		api_pedestal_addr   => api_pedestal_addr,
		api_sigma_addr      => api_sigma_addr,
		api_pedestal_in     => api_pedestal_in,
		api_sigma_in        => api_sigma_in,
		api_pedestal_out    => api_pedestal_out,
		api_sigma_out       => api_sigma_out,
		-- status and ctrl out 
		apz_status          => cfgout_apz_status,
		apz_chstatus        => cfgout_apz_chstatus,
		evbld_apz           => evbld_apz,
		api_reset           => api_reset,
		api_random_trigger  => api_random_trigger,
		api_trigger_inhibit => api_trigger_inhibit,
		api_busy_out 		  => api_busy,
		api_apv_select      => api_apv_select
	);

	appDAQ: appDAQ_APZ_vhd PORT MAP(
		clk 					      => clk,	clk125 => clk125,	clk10M => clk10M,
		rstn 					      => rstn,		
		-- control
		evbld_apz 				   => evbld_apz,
		api_reset 				   => api_reset,
		cfg_roenable 			   => cfg_roenable,
		apv_select 				   => api_apv_select,
		ro_trigger 				   => ro_trigger,
		trgID_FromSys				=> trgID_FromSys,
		-- slow control registers
		regs 					      => appregs,
		-- deserialized data from ADC core
		 CH0 					      => CH0,  CH1 => CH1,  CH2 => CH2,  CH3 => CH3,  CH4 => CH4,  CH5 => CH5,  CH6 => CH6,  CH7 => CH7,
		 CH8 					      => CH8,  CH9 => CH9,  CH10 => CH10, CH11 => CH11, CH12 => CH12, CH13 => CH13, CH14 => CH14, CH15 => CH15,
		-- APZ processor daata connection 
		api_busy 				   => api_busy,
--		api_busy 				   => cfgout_apz_status(0),
		api_ready 				   => api_ready,
		api_data 				   => api_data,
		api_wordcount 			   => api_wordcount,
		api_read_out 			   => api_read,
		api_output_enable 		=> api_output_enable,
		-- UDP TX interface
		txreq 					   => txreq,
		txdone 					   => txdone,
		txstart 				      => txstart,
		txstop 					   => txstop,
		txack 					   => txack,
		txdstrdy 				   => txdstrdy,
		txendframe 				   => txendframe,
		txdata 					   => txdata,
		txlength 				   => txlength,
		ro_NumFramesEvent 		=> ro_NumFramesEvent
		
--		--! Moved here in V6 ADC version
--		forceBclkRst => forceBclkRst,
--		bclkout => bclkout,		
--		btrgout => btrgout,
--		trgin => trgin,
--		trgout => open,
--		trgout0 => trgout_i
	);

	appTRG: appTRG_APZ_vhd PORT MAP(
		rstn 					      => rstn,
		clk 					      => clk,
		api_trigger_inhibit 	   => api_trigger_inhibit,
		api_random_trigger 		=> api_random_trigger,
		forceBclkRst 			   => forceBclkRst,
		regs 					      => appregs,
		trgin 					   => trgin,
		trgout 					   => trgout_i,
		bclkout 				      => open,
		ro_trigger 				   => ro_trigger,
		bclk_p 					   => bclk_p,
		bclk_n 					   => bclk_n
	);
	process(clk, rstn)
	begin
		if rstn = '0' then
			trgID_FromSys <= (others => '0');
		elsif clk'event and clk = '1' then
			if trgIDin_val = '1' then
				trgID_FromSys <= trgIDin;
			end if;
		end if;
	end process;
	
	--! New here in V6 ADC version
--	chmask_bitsum: bitsum15 PORT MAP(	data => cfg_evbld_chmask,	result => ro_NumFramesEvent);

	trgout <= trgout_i;
  
  --! New here in V6 ADC version
--	OBUFDS_inst : OBUFDS   generic map ( IOSTANDARD => "LVDS_25")
--	port map (
--		O => bclk_p,     -- Diff_p output (connect directly to top-level port)
--		OB => bclk_n,   -- Diff_n output (connect directly to top-level port)
--		I => bclkout      -- Buffer input 
--	);
--	OBUFDS2_inst : OBUFDS   generic map ( IOSTANDARD => "LVDS_25")
--   port map (
--      O => btrg_p,     -- Diff_p output (connect directly to top-level port)
--      OB => btrg_n,   -- Diff_n output (connect directly to top-level port)
--      I => btrgout      -- Buffer input 
--   );

end Behavioral;


