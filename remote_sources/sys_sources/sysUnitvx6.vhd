----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:40:41 03/14/2014 
-- Design Name: 
-- Module Name:    sysUnitvx6 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: `
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

entity sysUnitvx6 is
    port ( 
			  clk200_p, clk200_n 	: in  std_logic;
			  sfp_clk_p : in  std_logic;
           sfp_clk_n : in  std_logic;
           sfp_rx_p 	: in  std_logic;
           sfp_rx_n 	: in  std_logic;
           sfp_tx_p 	: out std_logic;
           sfp_tx_n 	: out std_logic;
			  
				-- DTC PORT 0, 1
				DTC_CLK_P : in  STD_LOGIC_VECTOR(1 downto 0);
				DTC_CLK_N : in  STD_LOGIC_VECTOR(1 downto 0);
				DTC_CMD_P : in  STD_LOGIC_VECTOR(1 downto 0);
				DTC_CMD_N : in  STD_LOGIC_VECTOR(1 downto 0);
				DTC_DATA0_P : out  STD_LOGIC_VECTOR(1 downto 0);
				DTC_DATA0_N : out  STD_LOGIC_VECTOR(1 downto 0);
				DTC_DATA1_P : out  STD_LOGIC_VECTOR(1 downto 0);
				DTC_DATA1_N : out  STD_LOGIC_VECTOR(1 downto 0);

			  A_I2C_SCL, A_I2C_SDA : inout std_logic;
			  B_I2C_SCL, B_I2C_SDA : inout std_logic;
			  SWRST_n : out std_logic;
-- INTERNAL PORTS
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
end sysUnitvx6;

architecture Behavioral of sysUnitvx6 is

	component Reset_Unit
	port(
		clk : in std_logic;          
		rstb : out std_logic
		);
	end component;
	
	component v6_emac_v1_5_top
	port(
		clientemactxifgdelay : in std_logic_vector(7 downto 0);
		clientemacpausereq : in std_logic;
		clientemacpauseval : in std_logic_vector(15 downto 0);
		rxp : in std_logic;
		rxn : in std_logic;
		phyad : in std_logic_vector(4 downto 0);
		mgtclk_p : in std_logic;
		mgtclk_n : in std_logic;
		reset : in std_logic;
		rx_ll_dst_rdy_n : in std_logic;
		tx_ll_data : in std_logic_vector(7 downto 0);
		tx_ll_sof_n : in std_logic;
		tx_ll_eof_n : in std_logic;
		tx_ll_src_rdy_n : in std_logic;          
		emacclientrxdvld : out std_logic;
		emacclientrxframedrop : out std_logic;
		emacclientrxstats : out std_logic_vector(6 downto 0);
		emacclientrxstatsvld : out std_logic;
		emacclientrxstatsbytevld : out std_logic;
		emacclienttxstats : out std_logic;
		emacclienttxstatsvld : out std_logic;
		emacclienttxstatsbytevld : out std_logic;
		emacclientsyncacqstatus : out std_logic;
		emacaninterrupt : out std_logic;
		txp : out std_logic;
		txn : out std_logic;
		rx_ll_data : out std_logic_vector(7 downto 0);
		rx_ll_sof_n : out std_logic;
		rx_ll_eof_n : out std_logic;
		rx_ll_src_rdy_n : out std_logic;
		tx_ll_dst_rdy_n : out std_logic;
		clk125_out : out std_logic;
		RXRECCLK_OUT : out std_logic;
		rst_out : out std_logic
		);
	end component;
	
	
	component gbe_top
	port(
		clk 						: in std_logic;
		rst 						: in std_logic;
		data_in 					: in std_logic_vector(7 downto 0);
		sof_in_n 				: in std_logic;
		eof_in_n 				: in std_logic;
		src_rdy_in_n 			: in std_logic;
		dst_rdy_in_n 			: in std_logic;
		fpga_mac 				: in std_logic_vector(47 downto 0);
		fpga_ip 					: in std_logic_vector(31 downto 0);
		forceethcansend 		: in std_logic;
		txdata 					: in std_logic_vector(7 downto 0);
		tx_length 				: in std_logic_vector(15 downto 0);
		tx_start 				: in std_logic;
		tx_stop 					: in std_logic;
		udptx_numframesevent	: in std_logic_vector(6 downto 0);
		udptx_srcport 			: in std_logic_vector(15 downto 0);
		udptx_dstport 			: in std_logic_vector(15 downto 0);
		udptx_framedly 		: in std_logic_vector(15 downto 0);
		udptx_daqtotframes 	: in std_logic_vector(15 downto 0);
		udptx_dstip 			: in std_logic_vector(31 downto 0);
		udprx_portackin 		: in std_logic;          
		dst_rdy_out_n 			: out std_logic;
		data_out 				: out std_logic_vector(7 downto 0);
		sof_out_n 				: out std_logic;
		eof_out_n 				: out std_logic;
		src_rdy_out_n 			: out std_logic;
		tx_busy 					: out std_logic;
		txdata_rdy 				: out std_logic;
		frameendevent 			: out std_logic;
		udprx_srcip 			: out std_logic_vector(31 downto 0);
		udprx_dstportout 		: out std_logic_vector(15 downto 0);
		udprx_checksum 		: out std_logic_vector(15 downto 0);
		udprx_dataout 			: out std_logic_vector(7 downto 0);
		udprx_datavalid 		: out std_logic
		);
	end component;
	
	COMPONENT txswitch
	PORT(
		clk125 : IN std_logic;
		rstn : IN std_logic;
		cfg : IN std_logic_vector(7 downto 0);
		daqtotframes : IN std_logic_vector(15 downto 0);
		roxoff_send : IN std_logic;
		roxoff_evcr : IN std_logic;
		ro_txreq : IN std_logic;
		ro_txdone : IN std_logic;
		sc_txreq : IN std_logic;
		sc_txdone : IN std_logic;          
		ro_txack : OUT std_logic;
		sc_txack : OUT std_logic
		);
	END COMPONENT;
	
	component scController
	port(
		clk 						: in std_logic;
		clk125 					: in std_logic;
		clk10m 					: in std_logic;
		rstn 						: in std_logic;
		cfg_scport 				: in std_logic_vector(15 downto 0);
		cfg_scmode 				: in std_logic_vector(15 downto 0);
		udprx_data 				: in std_logic_vector(7 downto 0);
		udprx_checksum 		: in std_logic_vector(15 downto 0);
		udprx_dstport 			: in std_logic_vector(15 downto 0);
		udprx_srcip 			: in std_logic_vector(31 downto 0);
		udprx_datavalid 		: in std_logic;
		portack_in 				: in std_logic;
		sc_ack 					: in std_logic;
		sc_rply_error 			: in std_logic_vector(31 downto 0);
		sc_rply_data 			: in std_logic_vector(31 downto 0);
		sctx_ack 				: in std_logic;
		sctx_txdatardy 		: in std_logic;          
		udprx_portack 			: out std_logic;
		sc_port 					: out std_logic_vector(15 downto 0);
		sc_data 					: out std_logic_vector(31 downto 0);
		sc_addr 					: out std_logic_vector(31 downto 0);
		sc_subaddr 				: out std_logic_vector(31 downto 0);
		sc_wr 					: out std_logic;
		sc_op 					: out std_logic;
		sc_frame 				: out std_logic;
		sctx_udptxsrcport 	: out std_logic_vector(15 downto 0);
		sctx_udptxdstport 	: out std_logic_vector(15 downto 0);
		sctx_length 			: out std_logic_vector(15 downto 0);
		sctx_udptxdstip 		: out std_logic_vector(31 downto 0);
		sctx_data 				: out std_logic_vector(7 downto 0);
		sctx_start 				: out std_logic;
		sctx_stop 				: out std_logic;
		sctx_req 				: out std_logic;
		sctx_done 				: out std_logic
		);
	end component;
	
	component scInitSys
	port(
		clk 						: in std_logic;
		rstn 						: in std_logic;
		sc_port_in 				: in std_logic_vector(15 downto 0);
		sc_data_in 				: in std_logic_vector(31 downto 0);
		sc_addr_in 				: in std_logic_vector(31 downto 0);
		sc_subaddr_in 			: in std_logic_vector(31 downto 0);
		sc_frame_in 			: in std_logic;
		sc_op_in 				: in std_logic;
		sc_wr_in 				: in std_logic;
		sc_ack_out 				: in std_logic;
		sc_rply_data 			: in std_logic_vector(31 downto 0);
		warm_init 				: in std_logic;          
		sc_ack_in 				: out std_logic;
		sc_port_out 			: out std_logic_vector(15 downto 0);
		sc_data_out 			: out std_logic_vector(31 downto 0);
		sc_addr_out 			: out std_logic_vector(31 downto 0);
		sc_subaddr_out 		: out std_logic_vector(31 downto 0);
		sc_frame_out 			: out std_logic;
		sc_op_out 				: out std_logic;
		sc_wr_out 				: out std_logic;
		rstn_eth 				: out std_logic;
		rstn_rxtx 				: out std_logic;
		rstn_sc 					: out std_logic;
		rstn_app 				: out std_logic
		);
	end component;
	
	
	component scSystem
	port(
		clk : in std_logic;
		clk40m : in std_logic;
		rstn : in std_logic;
		sc_port : in std_logic_vector(15 downto 0);
		sc_data : in std_logic_vector(31 downto 0);
		sc_addr : in std_logic_vector(31 downto 0);
		sc_subaddr : in std_logic_vector(31 downto 0);
		sc_op : in std_logic;
		sc_frame : in std_logic;
		sc_wr : in std_logic;
		sc_ack_in : in std_logic;
		sc_rply_data_in : in std_logic_vector(31 downto 0);
		sc_rply_error_in : in std_logic_vector(31 downto 0);
		regin : in std_logic_vector(511 downto 0);    
		a_scl : inout std_logic;
		a_sda : inout std_logic;
		b_scl : inout std_logic;
		b_sda : inout std_logic;      
		sc_ack : out std_logic;
		sc_rply_data : out std_logic_vector(31 downto 0);
		sc_rply_error : out std_logic_vector(31 downto 0);
		rstreg : out std_logic_vector(15 downto 0);
		regout : out std_logic_vector(511 downto 0)
		);
	end component;
	
	signal clk200			: std_logic; 
	signal clk125				: std_logic;
	signal ETH_RXRECCLK				: std_logic;
	signal clk10				: std_logic;
	signal clk40, clk40_bufr			: std_logic;

	signal rstn, dtcctf_resetn					: std_logic;
	signal data_router		: std_logic_vector(7 downto 0);
	signal sof_n_router		: std_logic;
	signal eof_n_router		: std_logic;
	signal src_rdy_n_router	: std_logic;
	signal dst_rdy_n_emac	: std_logic;
	signal data_emac			: std_logic_vector(7 downto 0);
	signal sof_n_emac			: std_logic;
	signal eof_n_emac			: std_logic;
	signal src_rdy_n_emac	: std_logic;
	signal dst_rdy_n_arbiter: std_logic;
	
	signal ll_reset_i			: std_logic;
	
	
	signal udprx_srcIP		: std_logic_vector(31 downto 0);
	signal udprx_dstPortOut	: std_logic_vector(15 downto 0);
	signal udprx_checksum	: std_logic_vector(15 downto 0);
	signal udprx_dataout		: std_logic_vector(7 downto 0);
	signal udprx_datavalid	: std_logic;
	signal udprx_portAck		: std_logic;
	
	signal sc_udptx_dstIP		: std_logic_vector(31 downto 0);
	signal sc_udptx_srcPort		: std_logic_vector(15 downto 0);
	signal sc_udptx_dstPort		: std_logic_vector(15 downto 0);
	signal sc_txdata 				: std_logic_vector(7 downto 0);
	signal sc_tx_length 			: std_logic_vector(15 downto 0);
	signal sc_tx_start 			: std_logic;
	signal sc_tx_stop 			: std_logic;

	
	signal udptx_dstIP		: std_logic_vector(31 downto 0);
	signal udptx_srcPort		: std_logic_vector(15 downto 0);
	signal udptx_dstPort		: std_logic_vector(15 downto 0);
	signal txdata 				: std_logic_vector(7 downto 0);
	signal tx_length 			: std_logic_vector(15 downto 0);
	signal tx_start 			: std_logic;
	signal tx_stop 			: std_logic;
	
	signal txdata_rdy 		: std_logic;
	signal frameEndEvent 	: std_logic;
	
	signal ro_txack, sc_txack 	: std_logic;
	signal sc_txreq, sc_txdone 	: std_logic;
	
  -- sc bus
	signal sig_sc_port_in 		: std_logic_vector (15 downto 0);
	signal sig_sc_data_in 		: std_logic_vector (31 downto 0);
	signal sig_sc_addr_in 		: std_logic_vector (31 downto 0);
	signal sig_sc_subaddr_in 	: std_logic_vector (31 downto 0);
	signal sig_sc_frame_in 		: std_logic;
	signal sig_sc_op_in 			: std_logic;
	signal sig_sc_wr_in 			: std_logic;
	signal sig_sc_ack_in			: std_logic;
	
	signal sig_sc_port_out 		: std_logic_vector (15 downto 0);
	signal sig_sc_data_out 		: std_logic_vector (31 downto 0);
	signal sig_sc_addr_out 		: std_logic_vector (31 downto 0);
	signal sig_sc_subaddr_out 	: std_logic_vector (31 downto 0);
	signal sig_sc_frame_out 	: std_logic;
	signal sig_sc_op_out 		: std_logic;
	signal sig_sc_wr_out 		: std_logic;
	signal sig_sc_ack_out		: std_logic;
	
	signal sig_sc_rply_data 		: std_logic_vector(31 downto 0);
	signal sig_sc_rply_error 		: std_logic_vector(31 downto 0);
	
	signal sig_reg_in					: std_logic_vector (511 downto 0);
	
	signal sig_sc_ack_app: std_logic;
	signal sig_sc_rply_data_app, sig_sc_rply_error_app: std_logic_vector(31 downto 0);

	signal sys_warm_init, rstn_eth, rstn_rxtx, rstn_sc, rstn_app, rstn_init, dcm_locked_i : std_logic;
	
	signal cfg_udptx_frameDly, cfg_daqport, cfg_scport, cfg_framedly, cfg_totFrames, cfg_ethmode, cfg_scmode, cfg_udptx_daqtotFrames : std_logic_vector(15 downto 0);
	signal version, cfg_fpga_ip, cfg_daq_ip : std_logic_vector(31 downto 0);
	signal cfg_fpga_mac : std_logic_vector(47 downto 0);
	
	signal scregs: std_logic_vector(511 downto 0);
	signal scregs_return: std_logic_vector(511 downto 0);
	signal sysrstreg: std_logic_vector(15 downto 0);

	
	attribute keep : boolean;
	attribute keep of udprx_srcIP: 			signal is true;
	attribute keep of udprx_dstPortOut: 	signal is true;
	attribute keep of udprx_checksum: 		signal is true;
	attribute keep of udprx_dataout: 		signal is true;
	attribute keep of udprx_datavalid: 		signal is true;
	
	attribute keep of sc_txack: 		signal is true;
	attribute keep of sc_txreq: 		signal is true;
	attribute keep of sc_txdone: 		signal is true;
	attribute keep of sc_txdata: 		signal is true;
	attribute keep of sc_tx_length: 		signal is true;
	attribute keep of sc_tx_start: 		signal is true;
	attribute keep of sc_tx_stop: 		signal is true;
	attribute keep of sc_udptx_dstIP: 		signal is true;

	COMPONENT sysClkMgrCTF
	PORT(
		clk_osc_P : IN std_logic;
		clk_osc_N : IN std_logic;
		clk125 : IN std_logic;
		ethrxclk : IN std_logic;
		rstn : IN std_logic;
		DTCIN_P : IN std_logic_vector(1 downto 0);
		DTCIN_N : IN std_logic_vector(1 downto 0);
		DTC2IN_P : IN std_logic_vector(1 downto 0);
		DTC2IN_N : IN std_logic_vector(1 downto 0);
		trgin : IN std_logic;
		sysrstreg : IN std_logic_vector(15 downto 0);
		mclkmux_cfg : IN std_logic_vector(7 downto 0);
		dtcctf_cfg : IN std_logic_vector(15 downto 0);          
		DTCOUT_P : OUT std_logic_vector(1 downto 0);
		DTCOUT_N : OUT std_logic_vector(1 downto 0);
		DTC2OUT_P : OUT std_logic_vector(1 downto 0);
		DTC2OUT_N : OUT std_logic_vector(1 downto 0);
		mclkmux_app_rst : OUT std_logic;
		trgout : OUT std_logic;
		cfg_out : OUT std_logic_vector(31 downto 0);
		clk : OUT std_logic;
		clk10M : OUT std_logic;
		clk_refiod : OUT std_logic;
		dcm_locked : OUT std_logic
		);
	END COMPONENT;

	
	
--	constant default_fpga_mac:			std_logic_vector(47 downto 0) := x"0A350001E321"; 
--	constant default_fpga_ip:			std_logic_vector(31 downto 0) := x"0A000002"; 
--	constant default_fpga_port:		std_logic_vector(15 downto 0) := x"1F90";
--	constant default_remote_ip:		std_logic_vector(31 downto 0) := x"0A000003"; 
--	constant default_remote_port:		std_logic_vector(15 downto 0) := x"1F91";

	signal clkMgr_cfg_out: std_logic_vector(31 downto 0);
	signal	cfg_clkmgr_dtcctf : std_logic_vector(15 downto 0);          
	signal	cfg_clkmgr_mclkmux : std_logic_vector(7 downto 0);
	signal	mclkmux_app_rst : std_logic;
	signal	ctf_trg : std_logic;
	
	signal DTCIN_P, DTCIN_N, DTCOUT_P, DTCOUT_N : std_logic_vector(1 downto 0);
	signal DTC2IN_P, DTC2IN_N, DTC2OUT_P, DTC2OUT_N : std_logic_vector(1 downto 0);

begin

	-- damned mapping....
	DTCIN_P <= DTC_CMD_P(0) & DTC_CLK_P(0);
	DTCIN_N <= DTC_CMD_N(0) & DTC_CLK_N(0);
	DTC2IN_P <= DTC_CMD_P(1) & DTC_CLK_P(1);
	DTC2IN_N <= DTC_CMD_N(1) & DTC_CLK_N(1);
	DTC_DATA0_P <= DTC2OUT_P(0) & DTCOUT_P(0);
	DTC_DATA0_N <= DTC2OUT_N(0) & DTCOUT_N(0);
	DTC_DATA1_P <= DTC2OUT_P(1) & DTCOUT_P(1);
	DTC_DATA1_N <= DTC2OUT_N(1) & DTCOUT_N(1);

	Inst_sysClkMgrCTF: sysClkMgrCTF PORT MAP(
		clk_osc_P => CLK200_P,
		clk_osc_N => CLK200_N,
		rstn => rstn,
		clk125 => clk125,
		ethrxclk => ETH_RXRECCLK,
			DTCIN_P => DTCIN_P,
			DTCIN_N => DTCIN_N,
			DTC2IN_P => DTC2IN_P,
			DTC2IN_N => DTC2IN_N,
			DTCOUT_P => DTCOUT_P,
			DTCOUT_N => DTCOUT_N,
			DTC2OUT_P => DTC2OUT_P,
			DTC2OUT_N => DTC2OUT_N,
		mclkmux_app_rst => mclkmux_app_rst,
		trgin => nim_trgin,
		trgout => ctf_trg,
		sysrstreg => sysrstreg,
		
		mclkmux_cfg => cfg_clkmgr_mclkmux,
		dtcctf_cfg => cfg_clkmgr_dtcctf,
		cfg_out => clkMgr_cfg_out,
		clk => clk40,
		clk10M => clk10,
		clk_refiod => clk200,
		dcm_locked => dcm_locked_i
	);
	-- Convert CLK200 diff to normal
--   IBUFGDS_inst : IBUFGDS
--   generic map (DIFF_TERM => true, IBUF_LOW_PWR => TRUE, IOSTANDARD => "DEFAULT")
--   port map (O => CLK200, I  => CLK200_P, IB => CLK200_N);


	Inst_Reset_Unit: Reset_Unit PORT MAP(
--		clk => clk200,
		clk => clk125,
		rstb => rstn
	);
	
	rstn_init <= rstn and dcm_locked_i;
--	dcm_locked_i <= '1';
	
	dcm_locked <= dcm_locked_i;
	
--   BUFR_clk40_inst : BUFR
--   generic map (
--      BUFR_DIVIDE => "5",   -- "BYPASS", "1", "2", "3", "4", "5", "6", "7", "8" 
--      SIM_DEVICE => "VIRTEX6")   -- Must be set to "VIRTEX6" 
--   port map (
--      O => clk40_bufr,     -- 1-bit output: Clock output port
--      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
--      CLR => not rstn, -- 1-bit input: Active high, asynchronous clear (Divided mode only)
--      I => clk200      -- 1-bit input: Clock buffer input driven by an IBUFG, MMCM or local interconnect
--   );
--   BUFR_clk10_inst : BUFR
--   generic map (
--      BUFR_DIVIDE => "4",   -- "BYPASS", "1", "2", "3", "4", "5", "6", "7", "8" 
--      SIM_DEVICE => "VIRTEX6")   -- Must be set to "VIRTEX6" 
--   port map (
--      O => clk10,     -- 1-bit output: Clock output port
--      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
--      CLR => not rstn, -- 1-bit input: Active high, asynchronous clear (Divided mode only)
--      I => clk40      -- 1-bit input: Clock buffer input driven by an IBUFG, MMCM or local interconnect
--   );
--	
--   BUFG40_inst : BUFG   port map (      O => clk40,       I => clk40_bufr     );

	clk200_out <= clk200;
	clk125_out <= clk125;
	clk40_out  <= clk40;
	clk10_out  <= clk10;

	trgout <= ctf_trg when clkMgr_cfg_out(5 downto 4) = "01" else nim_trgin;
	
	nim_trgout <= trgin;
	
-- ethernet MAC
	Inst_v6_emac_v1_5_top: v6_emac_v1_5_top port map(
		emacclientrxdvld => open,
		emacclientrxframedrop => open,
		emacclientrxstats => open,
		emacclientrxstatsvld => open,
		emacclientrxstatsbytevld => open,
		clientemactxifgdelay => x"00",
		emacclienttxstats => open,
		emacclienttxstatsvld => open,
		emacclienttxstatsbytevld => open,
		clientemacpausereq => '0',
		clientemacpauseval => x"0000",
		emacclientsyncacqstatus => open,
		emacaninterrupt => open,
		txp => sfp_tx_p,
		txn => sfp_tx_n,
		rxp => sfp_rx_p,
		rxn => sfp_rx_n,
		phyad => "00000",
		mgtclk_p => sfp_clk_p,
		mgtclk_n => sfp_clk_n,
		reset => rstn,
		-- RX signals
		rx_ll_data      => data_router,
		rx_ll_sof_n     => sof_n_router,
		rx_ll_eof_n     => eof_n_router,
		rx_ll_src_rdy_n => src_rdy_n_router,
		rx_ll_dst_rdy_n => dst_rdy_n_emac,
		-- TX signals
		tx_ll_data      => data_emac,
		tx_ll_sof_n     => sof_n_emac,
		tx_ll_eof_n     => eof_n_emac,
		tx_ll_src_rdy_n => src_rdy_n_emac,
		tx_ll_dst_rdy_n => dst_rdy_n_arbiter,
		
		clk125_out      => clk125,
		RXRECCLK_OUT      => ETH_RXRECCLK,
		rst_out         => ll_reset_i
	);
	
	Inst_gbe_top: gbe_top port map(
		clk 					=> clk125,
		rst 					=> ll_reset_i,
		
		data_in 				=> data_router,
		sof_in_n 			=> sof_n_router,
		eof_in_n 			=> eof_n_router,
		src_rdy_in_n 		=> src_rdy_n_router,
		dst_rdy_out_n 		=> dst_rdy_n_emac,
		
		data_out 			=> data_emac,
		sof_out_n 			=> sof_n_emac,
		eof_out_n 			=> eof_n_emac,
		src_rdy_out_n 		=> src_rdy_n_emac,
		dst_rdy_in_n 		=> dst_rdy_n_arbiter,
		
		fpga_mac				=> cfg_fpga_mac,
		fpga_ip 				=> cfg_fpga_ip,
		
		tx_busy 				=> open,
		forceEthCanSend 	=> '1',
		
		txdata 				=> txdata,
		tx_length 			=> tx_length,
		tx_start 			=> tx_start,
		tx_stop 				=> tx_stop,
		txdata_rdy 			=> txdata_rdy,
		frameEndEvent 		=> frameEndEvent,
		
		udptx_numFramesEvent	=> ro_NumFramesEvent,
		udptx_srcPort 			=> udptx_srcPort,
		udptx_dstPort 			=> udptx_dstPort,
		udptx_frameDly 		=> cfg_udptx_frameDly,
		udptx_daqtotFrames 	=> cfg_udptx_daqtotFrames,
		udptx_dstIP 			=> udptx_dstIP,
		
		udprx_srcIP 		=> udprx_srcIP,
		udprx_dstPortOut 	=> udprx_dstPortOut,
		udprx_checksum 	=> udprx_checksum,
		udprx_portAckIn 	=> udprx_portAck,
		udprx_dataout 		=> udprx_dataout,
		udprx_datavalid 	=> udprx_datavalid
	);

	------------- TX ARBITRER ----------------------
	Inst_txswitch: txswitch PORT MAP(
		clk125 => clk125,
		rstn => rstn_rxtx,
		cfg => x"00",
		daqtotframes => x"0000",
		roxoff_send => '1',
		roxoff_evcr => '0',
		ro_txreq 	=> ro_txreq,
		ro_txdone 	=> ro_txdone,
		ro_txack 	=> ro_txack,
		sc_txreq 	=> sc_txreq,
		sc_txdone 	=> sc_txdone,
		sc_txack 	=> sc_txack
	);
	
	txdata 			<= sc_txdata 		when sc_txack = '1' else ro_txdata;
	tx_length 		<= sc_tx_length 	when sc_txack = '1' else ro_tx_length;
	tx_start 		<= sc_tx_start 	when sc_txack = '1' else ro_tx_start;
	tx_stop	 		<= sc_tx_stop	 	when sc_txack = '1' else ro_tx_stop;
	
	udptx_srcPort	<= sc_udptx_srcPort 	when sc_txack = '1' else cfg_daqport;
	udptx_dstPort	<= sc_udptx_dstPort 	when sc_txack = '1' else cfg_daqport;
	udptx_dstIP		<= sc_udptx_dstIP 	when sc_txack = '1' else cfg_daq_ip;

	ro_txdata_rdy 		<= txdata_rdy		when ro_txack = '1' else '0';
	ro_frameEndEvent 	<= frameEndEvent	when ro_txack = '1' else '0';
	
	ro_txack_out <= ro_txack;
	----------------------------------------------------------------
	
	Inst_scController: scController port map(
		clk 						=> clk40, 
		clk125 					=> clk125,
		clk10M 					=> clk10, 
		rstn 						=> rstn_rxtx,
		cfg_scport 				=> cfg_scport, 
		cfg_scmode 				=> cfg_scmode, 
		
		udprx_data 				=> udprx_dataout,
		udprx_checksum 		=> udprx_checksum,
		udprx_dstport 			=> udprx_dstPortOut,
		udprx_srcIP 			=> udprx_srcIP,
		udprx_datavalid 		=> udprx_datavalid,
		udprx_portAck 			=> udprx_portAck,
		portAck_in 				=> '1', 

		sc_port 					=> sig_sc_port_in,
		sc_data 					=> sig_sc_data_in,
		sc_addr 					=> sig_sc_addr_in,
		sc_subaddr 				=> sig_sc_subaddr_in,
		sc_wr 					=> sig_sc_wr_in,
		sc_op 					=> sig_sc_op_in,
		sc_frame 				=> sig_sc_frame_in,
		sc_ack 					=> sig_sc_ack_in, 
		sc_rply_error 			=> sig_sc_rply_error,
		sc_rply_data 			=> sig_sc_rply_data,
		
		sctx_req 				=> sc_txreq,
		sctx_done 				=> sc_txdone,
		sctx_ack 				=> sc_txack, 
		sctx_udptxSrcPort 	=> sc_udptx_srcPort,
		sctx_udptxDstPort 	=> sc_udptx_dstPort,
		sctx_length 			=>	sc_tx_length,		
		sctx_udptxDstIP 		=> sc_udptx_dstIP,
		sctx_data 				=> sc_txdata,
		sctx_start 				=> sc_tx_start,
		sctx_stop 				=> sc_tx_stop,
		sctx_txdatardy 		=> txdata_rdy
	);

	Inst_scInitSys: scInitSys port map(
		clk 						=> clk10,
		rstn 						=> rstn_init,
		
		sc_port_in 				=> sig_sc_port_in,
		sc_data_in 				=> sig_sc_data_in,
		sc_addr_in 				=> sig_sc_addr_in,
		sc_subaddr_in 			=> sig_sc_subaddr_in,
		sc_frame_in 			=> sig_sc_frame_in,
		sc_op_in 				=> sig_sc_op_in,
		sc_wr_in 				=> sig_sc_wr_in,
		sc_ack_in 				=> sig_sc_ack_in,
		
		sc_port_out 			=> sig_sc_port_out,
		sc_data_out 			=> sig_sc_data_out,
		sc_addr_out 			=> sig_sc_addr_out,
		sc_subaddr_out 		=> sig_sc_subaddr_out,
		sc_frame_out 			=> sig_sc_frame_out,
		sc_op_out 				=> sig_sc_op_out,
		sc_wr_out 				=> sig_sc_wr_out,
		sc_ack_out 				=> sig_sc_ack_out,
		
		sc_rply_data			=> sig_sc_rply_data,
		
		warm_init 				=> sys_warm_init, 
		rstn_eth 				=> rstn_eth,  
		rstn_rxtx				=> rstn_rxtx,  
		rstn_sc 					=> rstn_sc,  
		rstn_app 				=> rstn_app   
	);
	
	rstn_app_out 	<= rstn_app and (not mclkmux_app_rst);
	rstn_sc_out 	<= rstn_sc;
	rstn_init_out 	<= rstn_init;
	rstn_out 		<= rstn;
	
	Inst_scSystem: scSystem PORT MAP(
		clk 						=> clk10,
		clk40M					=> clk40,
		rstn 						=> rstn_sc,
		
		sc_port 					=> sig_sc_port_out,
		sc_data 					=> sig_sc_data_out,
		sc_addr 					=> sig_sc_addr_out,
		sc_subaddr 				=> sig_sc_subaddr_out,
		sc_op 					=> sig_sc_op_out,  
		sc_frame 				=> sig_sc_frame_out,
		sc_wr 					=> sig_sc_wr_out,  
		
		sc_ack 					=> sig_sc_ack_out,
		sc_rply_data			=> sig_sc_rply_data,  
		sc_rply_error 			=> sig_sc_rply_error, 
		
		-- sc bus replyes from application (to be implemented in the interface)
		sc_ack_in 				=> sig_sc_ack_app,
		sc_rply_data_in 		=> sig_sc_rply_data_app,	
		sc_rply_error_in 		=> sig_sc_rply_error_app,	

		a_scl 					=> A_I2C_SCL,  
		a_sda 					=> A_I2C_SDA,  
		b_scl 					=> B_I2C_SCL,  
		b_sda 					=> B_I2C_SDA,  
		
		rstreg 					=> sysrstreg,  
		regout 					=> scregs,  
		regin 					=> scregs_return   
	);
	
		sc_port_out 				<= sig_sc_port_out;
		sc_data_out 				<= sig_sc_data_out;
		sc_addr_out 				<= sig_sc_addr_out;
		sc_subaddr_out 			<= sig_sc_subaddr_out;
		sc_op_out 					<= sig_sc_op_out;  
		sc_frame_out 				<= sig_sc_frame_out;
		sc_wr_out 					<= sig_sc_wr_out;  
		
		sig_sc_ack_app				<= sc_ack_in;
		sig_sc_rply_data_app		<= sc_rply_data_in;
		sig_sc_rply_error_app	<= sc_rply_error_in;

	--------- CONFIGURATION REGISTERS ----------------------
	 sys_warm_init <= sysrstreg(0);
	 dtcctf_resetn <= rstn and not sysrstreg(1);
	 SWRST_n <= not sysrstreg(15);
	 
	 version <= scregs(31 downto  0);
	 cfg_fpga_mac(47 downto 24) <= scregs(55 downto  32);
	 cfg_fpga_mac(23 downto  0) <= scregs(87 downto  64);
	 cfg_fpga_ip <= scregs(127 downto 96);
	 cfg_daqport <= scregs(143 downto 128);
	 cfg_scport <= scregs(175 downto 160);
	 cfg_udptx_frameDly <= scregs(207 downto 192);
	 cfg_udptx_daqtotFrames <= scregs(239 downto 224);
	 cfg_ethmode <= scregs(271 downto 256);
	 cfg_scmode <= scregs(303 downto 288);
	 cfg_daq_ip <= scregs(351 downto 320);
--	 cfg_udptx_daqtotFrames <= scregs(367 downto 352);
	
	 cfg_clkmgr_dtcctf(7 downto 0) <= scregs( (12 * 32) + 7 downto (12 * 32) );
	 cfg_clkmgr_dtcctf(15 downto 8) <= (others => '0');
	 cfg_clkmgr_mclkmux(7 downto 0) <= scregs( (12 * 32) + 7 downto (12 * 32) );
	 
	 scregs_return( (12 * 32) + 31 downto 0) <= scregs( (12 * 32) + 31 downto 0);
	 scregs_return( (13 * 32) + 31 downto (13 * 32) ) <= clkMgr_cfg_out;
	 scregs_return( (15 * 32) + 31 downto (14 * 32) ) <= scregs( (15 * 32) + 31 downto (14 * 32) );
	 


end Behavioral;

