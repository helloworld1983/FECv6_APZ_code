`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sorin Martoiu
// 
// Create Date:    23:58:44 04/02/2012 
// Design Name: 
// Module Name:    sysUnit 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: FEC system Unit
//
// Dependencies: Common\ethernet, Common\scController, Common\sc_sources
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	 +------------------------------------------------------------------+
//	 | +---------+                                               +---------> scregs, sysrstreg
//	 | | clk&rst |                                               | +-------> B_I2C (FEC EEPROM,...)
//	 | +---------+                            sc path            | |    |
//	 |                                                           | |    |   +------------------------+
//	 | +----------+    +---------------+    +---------+   +------+-+-+  |   |   +-------------+      |
//	 | |          |--->|  scController +--->| sysInit +-->| scSystem +--------->|scApplication+-------->
//	 | |          |    +-------+-------+    +---------+   +----------+  |   |   +-------------+      |
//	 | | ethernet |            |                                        |   |                        |
//	 | |          |            v                                        |   |                        |
//	 | |          |    +---------------+                                |   |   +-------------+      |
//	 | |          |<---+  TX arbiter   |<---------------------------------------+ EventBuilder|<-------+
//	 | +----------+    +---------------+                                |   |   |             |      |
//	 |                                        daq path                  |   |   +-------------+      |
//	 |                                                                  |   |                        |
//	 | sysUnit                                                          |   | appUnit                |
//	 +------------------------------------------------------------------+   +------------------------+
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////

module sysUnit_dtc(
// IO PORTS
	// CLK Inputs
	input	clk_osc_P,	clk_osc_N,	// 200 MHz local oscillator
	// nim
	input 	nim_in,
	output 	nim_out,
	// DTC LVDS pads
		input [1:0] DTCIN_P, DTCIN_N,
		input [1:0] DTC2IN_P, DTC2IN_N,
		output [1:0] DTCOUT_P, DTCOUT_N,
		output [1:0] DTC2OUT_P, DTC2OUT_N,
	// other system IOs
	output	SWRST_n,
	output PW_EN_A, PW_EN_B,
	input  A_PRSNT_B, B_PRSNT_B,
	// ethernet ports
	output	TXP_0, TXN_0, 
	input		RXP_0, RXN_0,
	input		MGTCLK_P, MGTCLK_N,
	output	linkStatus,
	input		SFP_LOS,
	// I2C
	inout	B_I2C_SCL, B_I2C_SDA,
	inout	A_I2C_SCL, A_I2C_SDA,
// Application interface	
	 // system signals (clk & rst)
	 output rstn_app, rstn_sc, rstn_init, rstn,
	 output clk125, clk, clk10M, clk_refiod,
	 output dcm_locked,
	 // sc bus //
    output [15:0] 	sc_port_out,
    output [31:0] 	sc_data_out,
    output [31:0] 	sc_addr_out,
    output [31:0] 	sc_subaddr_out,
    output 				sc_op_out,
    output 				sc_frame_out,
    output 				sc_wr_out,
    input 				sc_ack_in,
    input [31:0] 		sc_rply_data_in,
    input [31:0] 		sc_rply_error_in,
	 // daq (tx) interface
    input ro_txreq,
    input ro_txdone,
    output ro_txack,
    input [7:0] ro_txdata,
    input [15:0] ro_txlength,
    input ro_txstart,
    input ro_txstop,
    output ro_txdata_rdy, frameEndEvent,
	 input [6:0] ro_NumFramesEvent,
	 // trigger
	 output trg_out,
	 output [63:0] trgID,
	 output 			trgID_val,
	 input trg_in
);

// hardwired version, must be overwritten at top level
	parameter [15:0] FEC_FW_VERSION = 15'h0FFF;

// power enable signals linked to card present inputs
	assign PW_EN_A = ~ A_PRSNT_B;
	assign PW_EN_B = ~ B_PRSNT_B;

	wire clk0, trg0;
	
	
	wire dtc_SWRST_n, dtc_clk40_out, dtc_clk40_out_ok;
	wire dtc_validTrgFrame_in, dtc_validTrgFrame_out, dtc_trigger;
	wire [63:0] dtc_trgFrame_in, dtc_trgFrame_out;
	wire dtc_wrDataFIFO, dtc_fullDataFIFO;
	wire [7:0] dtc_dataToDataFIFO;
	wire dtc_eof_out_n, dtc_sof_out_n, dtc_src_rdy_out_n, dtc_sof_in_n, dtc_eof_in_n, dtc_src_rdy_in_n, dtc_dst_rdy_in_n;
	wire [7:0] dtc_data_out, dtc_data_in;
	wire [10:0] dtc_wrcntSCFIFO;
	
	wire [31:0] cfg_dtcCtrlReg;
	
	wire clk_gbe;
	wire rst_gbe;
	
	assign dtc_trgFrame_in = 64'h0000000000000000;
	assign dtc_validTrgFrame_in = 1'b0;
	
	DTCCL_BASIC_FEC dtccl_unit (
		 .clk_brd				(clk_refiod),  
		
		 .rj45_j2_1_p_i		(DTC2IN_P[0]), 
		 .rj45_j2_1_n_i		(DTC2IN_N[0]), 
		 .rj45_j2_2_p_i		(DTC2IN_P[1]), 
		 .rj45_j2_2_n_i		(DTC2IN_N[1]), 
		 .rj45_j2_3_p_o		(DTC2OUT_P[0]), 
		 .rj45_j2_3_n_o		(DTC2OUT_N[0]), 
		 .rj45_j2_4_p_o		(DTC2OUT_P[1]), 
		 .rj45_j2_4_n_o		(DTC2OUT_N[1]), 
		 
		 .clk40_o				(dtc_clk40_out),
       .clkDiv_o           (clk_gbe),
		 .rst_n_o         	(rstn),		 
		 .clk40_ok_o			(dtc_clk40_out_ok),
		 
		 .valid_trg_frame_i	(dtc_validTrgFrame_in), 
		 .trg_frame_i			(dtc_trgFrame_in), 
		 .trigger_o				(dtc_trigger), 
		 .valid_trg_frame_o	(dtc_validTrgFrame_out), 
		 .trg_frame_o			(dtc_trgFrame_out), 
		 
		 .clk_data				(clk125), 
		 .wr_data_fifo_i		(dtc_wrDataFIFO), 
		 .data_fifo_i			(dtc_dataToDataFIFO), 
		 .full_data_fifo_o	(dtc_fullDataFIFO), 
		 
		 .clk_gbe				(clk125),
       .rst_gbe            (rst_gbe),		 
		 .eof_n_dtccl_i		(dtc_eof_out_n), 
		 .sof_n_dtccl_i		(dtc_sof_out_n), 
		 .src_rdy_n_dtccl_i	(dtc_src_rdy_out_n), 
		 .data_dtccl_i			(dtc_data_out), 
		 .sof_n_stack_o		(dtc_sof_in_n), 
		 .eof_n_stack_o		(dtc_eof_in_n), 
		 .src_rdy_n_stack_o	(dtc_src_rdy_in_n), 
		 .data_stack_o			(dtc_data_in), 
		 
		 .wr_cnt_sc_fifo_o	(dtc_wrcntSCFIFO)
		);
	
	// 64 bit trigger id/info to app
	assign trgID 		= dtc_trgFrame_out;
	assign trgID_val 	= dtc_validTrgFrame_out;
	reg [63:0] trgID_i;
   always @(posedge dtc_clk40_out or negedge rstn)
      if (!rstn) begin
         trgID_i <= 64'h0000000000000000;
      end else if (dtc_validTrgFrame_out) begin
         trgID_i <= dtc_trgFrame_out;
      end
	
	
	wire dtc_dst_rdy_in_n_i;
	dtcSCFlowCtrl dtcSCFlowCtrl (
		 .clk(clk125), 		 .rstn(rstn), 
		 
		 .wrcntSCFIFO	(dtc_wrcntSCFIFO), 
		 .eof_n			(dtc_eof_out_n), 
		 .dst_rdy_n		(dtc_dst_rdy_in_n_i)
		 );
	assign dtc_dst_rdy_in_n = (~cfg_dtcCtrlReg[1]) ? dtc_dst_rdy_in_n_i : 1'b0;
		 
//	assign dtc_wrDataFIFO = 1'b0;
//	assign dtc_dataToDataFIFO = 8'hCA;

	wire dtc_txreq, dtc_txdone, dtc_txack, dtc_txdata_rdy, dtc_frameEndEvent;
	wire eth_txack, eth_txdata_rdy, eth_frameEndEvent;
	wire cfg_datatx_EthOverDTC;
	
	assign dtc_txreq 		= (cfg_datatx_EthOverDTC) ? 1'b0 : ro_txreq;
	assign dtc_txdone 	= (cfg_datatx_EthOverDTC) ? 1'b1 : ro_txdone;
	
	assign ro_txack 		= (cfg_datatx_EthOverDTC) ? eth_txack : dtc_txack;
	assign ro_txdata_rdy = (cfg_datatx_EthOverDTC) ? eth_txdata_rdy : dtc_txdata_rdy;
	assign frameEndEvent = (cfg_datatx_EthOverDTC) ? eth_frameEndEvent : dtc_frameEndEvent;
	
	dtcDataIF dataToDTCinterface (
		 .clk(clk125), 		 .rst(~rstn), 
		 .cfg(cfg_dtcCtrlReg),
		 .trgID(trgID_i),
		 // app interface
		 .txreq				(dtc_txreq), 
		 .txdone				(dtc_txdone), 
		 .txack				(dtc_txack), 
		 .txlength			(ro_txlength), 
		 .txdata				(ro_txdata), 
		 .txstart			(ro_txstart), 
		 .txstop				(ro_txstop), 
		 .txdata_rdy		(dtc_txdata_rdy), 
		 .frameEndEvent	(dtc_frameEndEvent), 
		 .numFramesEvent	(ro_NumFramesEvent), 
		 // dtc interface
		 .dtc_wrDataFIFO			(dtc_wrDataFIFO), 
		 .dtc_dataToDataFIFO		(dtc_dataToDataFIFO), 
		 .dtc_fullDataFIFO		(dtc_fullDataFIFO)
		 );		 
		 
//	// DTC CTF unit
	wire dtcctf_resetn, dtc_clk, dtc_trg, dtcclk_locked, dtcclk_ok;
	wire [15:0] dtcctf_cfg;
//	wire [15:0] dtcclk_measure_val;
//	wire [5:0]  dtcclk_status;
//	wire dtcclk_measure_dv;
//	dtcctf_unit dtcctf_unit (
//		 .clk0(clk0),		 .rstn(dtcctf_resetn),		 .cfg(dtcctf_cfg), 
//		 //
//		 .DTCIN_P(DTCIN_P), 		 .DTCIN_N(DTCIN_N), 
//		 .DTC2IN_P(DTC2IN_P),	 .DTC2IN_N(DTC2IN_N), 
//		 .DTCOUT_P(DTCOUT_P),	 .DTCOUT_N(DTCOUT_N), 
//		 .DTC2OUT_P(DTC2OUT_P),	 .DTC2OUT_N(DTC2OUT_N),
//		//	 
//		 .trgin(trg0),		 .clkin(clk),
//		//
//		 .dtcclk_ok(dtcclk_ok), 	 .dtcclk_locked(dtcclk_locked), 
//		 .dtcclk_out(dtc_clk), 		 .dtctrg_out(dtc_trg),
//		 //
//		 .dtcclk_measure_val(dtcclk_measure_val), 
//		 .dtcclk_status(dtcclk_status), 
//		 .dtcclk_measure_dv(dtcclk_measure_dv)
//		 );
//	reg [15:0] dtcclk_measure_out;
//	reg [5:0] dtcclk_status_out;
//	reg dtcclk_measure_dv10;
//   always @(posedge clk10M or negedge rstn)
//      if (!rstn) begin
//         dtcclk_measure_out <= 16'h0000;
//         dtcclk_status_out <= 6'b000000;
//			dtcclk_measure_dv10 <= 1'b0;
//      end else begin
//			dtcclk_measure_dv10 <= dtcclk_measure_dv;
//			if (dtcclk_measure_dv10) begin
//				dtcclk_measure_out <= dtcclk_measure_val;
//				dtcclk_status_out <= dtcclk_status;
//			end
//      end
	wire [15:0] dtcclk_measure_out = 15'h0000;
	wire [5:0] dtcclk_status_out = 5'b00000;
	
//	// 40MHz clock from ethernet RX clock
	wire ethrxclk_ok;
	wire ethrxclk, ethrxclk_locked, ethrxclk_rst, clk40e;
//	ethmclk ethmclk_unit (
//		 .ethrxclk(ethrxclk), .ethrxclk_rst(ethrxclk_rst), 
//		 .clk40e(clk40e), 	 .ethrxclk_ok(ethrxclk_ok), 	 .ethrxclk_locked(ethrxclk_locked)
//		 );
	assign  clk40e = clk0;
	assign ethrxclk_ok = 1'b0;
	assign ethrxclk_locked = 1'b0;
	
	assign dtc_clk = dtc_clk40_out;
	assign dtcclk_locked = dtc_clk40_out_ok;
	assign dtcclk_ok = dtc_clk40_out_ok;
	// Main CLOCK MUX
	wire [1:0] mclkmux_clksel;
	wire [7:0] mclkmux_cfg;
	wire mclkmux_app_rst;
	mclk_unit mclk_unit (
		 .clk0(clk0), 		 .rstn(rstn), 
		 .dtc_clk(dtc_clk), 	 .dtcclk_locked(dtcclk_locked), 	 .dtcclk_ok(dtcclk_ok), 
		 .clk40e(clk40e), 	 .ethrxclk_ok(ethrxclk_ok),		 .ethrxclk_locked(ethrxclk_locked), 
		 .clk(clk), 
		 .mclkmux_cfg(mclkmux_cfg), 
		 .mclkmux_clksel(mclkmux_clksel), 
		 .mclkmux_app_rst(mclkmux_app_rst)
		 );


// generate initial reset
//	Reset_Unit Reset_Unit (    .clk(clk125),     .rstb(rstn)    );
// local clock generation unit (200MHz, 40MHz and 10MHz)
	clock_unit clock_unit (   	.clk_osc_N(clk_osc_N),     .clk_osc_P(clk_osc_P), 
										.clk(clk0), .clk_refiod(clk_refiod),    .clk10M(clk10M), 
										.clk_locked(dcm_locked),     .rstn(rstn)
								  );

// ethernet interface signals
	wire eth_rst, forceEthCanSend, tx_start, tx_stop, txdata_rdy;
	wire [7:0] txdata;
	wire [15:0] tx_length;
	(* KEEP="TRUE" *) wire udprx_datavalid, udprx_portAck, eth_tx_busy;
	(* KEEP="TRUE" *) wire [7:0] udprx_data;
	(* KEEP="TRUE" *) wire [15:0] udprx_dstPort, udprx_checksum;
	(* KEEP="TRUE" *) wire [31:0] udprx_srcIP;
	wire [15:0] cfg_udptxSrcPort, cfg_udptxDstPort, cfg_udptx_frameDly, cfg_udptx_initframeDly;
	wire [31:0] cfg_udptxDstIP;
// slow control registers
	wire [15:0] version, cfg_daqport, cfg_scport, cfg_framedly, cfg_totFrames, cfg_ethmode, cfg_scmode, cfg_udptx_daqtotFrames;
	wire [31:0] cfg_fpga_ip, cfg_daq_ip;
	wire [47:0] cfg_fpga_mac;
// internal reset signals
	wire rstn_eth, rstn_rxtx;

	assign rstn_init = (dcm_locked) & rstn;
	assign forceEthCanSend = 1'b1;
	assign eth_rst = ~rstn_eth;

//v5_emac_v1_7_top ethernet (
//    .TXP_0(TXP_0),     		.TXN_0(TXN_0), 
//    .RXP_0(RXP_0),     		.RXN_0(RXN_0), 
//    .MGTCLK_P(MGTCLK_P),   .MGTCLK_N(MGTCLK_N), 
//    .RESET(eth_rst), 
//	 .clk_out(clk125),
//	 .RXRECCLK0_OUT(ethrxclk),
//    .linkStatus(linkStatus), 
//    .forceEthCanSend(forceEthCanSend), 
//	 // TX
//	 .tx_busy(eth_tx_busy),
//    .txdata(txdata), 
//    .tx_length(tx_length), 
//    .tx_start(tx_start), 
//    .tx_stop(tx_stop), 
//    .txdata_rdy(txdata_rdy),
//	 .frameEndEvent(frameEndEvent),	
//	 // RX
//	 .udprx_srcIP			(udprx_srcIP),
//	 .udprx_dataout		(udprx_data),
//	 .udprx_datavalid		(udprx_datavalid),
//	 .udprx_dstPortOut	(udprx_dstPort),
//	 .udprx_checksum		(udprx_checksum),
//	 .udprx_portAckIn		(udprx_portAck),
//		//config
//	 .fpga_mac(cfg_fpga_mac),
//	 .fpga_ip(cfg_fpga_ip),
//    .udptx_numFramesEvent(ro_NumFramesEvent), 
//	 .udptx_frameDly(cfg_udptx_frameDly),
//	 .udptx_daqtotFrames(cfg_udptx_daqtotFrames),
//    .udptx_srcPort(cfg_udptxSrcPort), 
//    .udptx_dstPort(cfg_udptxDstPort), 
//    .udptx_dstIP(cfg_udptxDstIP)
//    );
	 
assign linkStatus = 1'b0;
//  IBUFDS  IBUFDS_inst (
//      .O(clk125),  // Clock buffer output
//      .I(MGTCLK_P),  // Diff_p clock buffer input
//      .IB(MGTCLK_N) // Diff_n clock buffer input
//   );

  wire clk125_CLKFB;
	PLL_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // "HIGH", "LOW" or "OPTIMIZED" 
      .CLKFBOUT_MULT(10),        // Multiplication factor for all output clocks
      .CLKFBOUT_PHASE(0.0),     // Phase shift (degrees) of all output clocks
      .CLKIN_PERIOD(12.5000),     // Clock period (ns) of input clock on CLKIN
      .CLKOUT0_DIVIDE(5),       // Division factor for CLKOUT0 (1 to 128)
      .CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.01 to 0.99)
      .CLKOUT0_PHASE(0.0),      // Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
      .COMPENSATION("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", 
                                //   "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", 
                                //   "DCM2PLL", "PLL2DCM" 
      .DIVCLK_DIVIDE(2),        // Division factor for all clocks (1 to 52)
      .REF_JITTER(0.100)        // Input reference jitter (0.000 to 0.999 UI%)
   ) clk125_PLL_BASE_inst (
      .CLKFBOUT(clk125_CLKFB),      // General output feedback signal
      .CLKOUT0(clk125),        // One of six general clock output signals
      .LOCKED(),          // Active high PLL lock signal
      .CLKFBIN(clk125_CLKFB),        // Clock feedback input
      .CLKIN(clk_gbe),            // Clock input
      .RST(mclkmux_app_rst)                 // Asynchronous PLL reset
   );

	assign rst_gbe = eth_rst;



gbe_top ethernet (
    .clk(clk125),     .rst(eth_rst), 
	 // PHY TX
    .data_out			(dtc_data_out), 
    .sof_out_n			(dtc_sof_out_n), 
    .eof_out_n			(dtc_eof_out_n), 
    .src_rdy_out_n	(dtc_src_rdy_out_n), 
    .dst_rdy_in_n		(dtc_dst_rdy_in_n), 
	 // PHY RX
    .data_in			(dtc_data_in), 
    .sof_in_n			(dtc_sof_in_n), 
    .eof_in_n			(dtc_eof_in_n), 
    .src_rdy_in_n		(dtc_src_rdy_in_n), 
    .dst_rdy_out_n	(), 
	 // CFG
    .fpga_mac(cfg_fpga_mac), 
    .fpga_ip(cfg_fpga_ip), 
    .forceEthCanSend(forceEthCanSend), 
	 // TX
    .tx_busy		(eth_tx_busy), 
    .txdata			(txdata), 
    .tx_length		(tx_length), 
    .tx_start		(tx_start), 
    .tx_stop		(tx_stop), 
    .txdata_rdy	(txdata_rdy), 
    .frameEndEvent(eth_frameEndEvent), 
//    .frameEndEvent(), 
	 // TX config
    .udptx_numFramesEvent	(ro_NumFramesEvent), 
//    .udptx_numFramesEvent	(7'b0000001), 
    .udptx_frameDly			(cfg_udptx_frameDly), 
    .udptx_daqtotFrames		(cfg_udptx_daqtotFrames), 
    .udptx_srcPort			(cfg_udptxSrcPort), 
    .udptx_dstPort			(cfg_udptxDstPort), 
    .udptx_dstIP				(cfg_udptxDstIP), 
	 // RX
    .udprx_srcIP			(udprx_srcIP), 
    .udprx_dataout		(udprx_data), 
    .udprx_datavalid		(udprx_datavalid),
    .udprx_dstPortOut	(udprx_dstPort), 
    .udprx_checksum		(udprx_checksum), 
    .udprx_portAckIn		(udprx_portAck)
    );
	 
// signals for slow control UDP TX path 
	(* KEEP="TRUE" *) wire sctx_req, sctx_start, sctx_stop, sctx_ack, sctx_dstrdy, sctx_done;
	(* KEEP="TRUE" *) wire [7:0] sctx_data;
	(* KEEP="TRUE" *) wire [15:0] sctx_dstPort, sctx_srcPort, sctx_length;
	(* KEEP="TRUE" *) wire [31:0] sctx_dstIP;

////////////////////////////////// TX ARBITER ///////////////////////////////////
   parameter stTXIDLE = 3'b001;
   parameter stTXDAQ = 3'b010;
   parameter stTXSC = 3'b100;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="YES", SAFE_RECOVERY_STATE="5'b00001" *) reg [2:0] state = stTXIDLE;
//	reg [19:0] txInitDlyCnt;
	
   always@(posedge clk125 or negedge rstn_rxtx)
      if (!rstn_rxtx) begin
         state <= stTXIDLE;
      end
      else
         (* PARALLEL_CASE *) case (state)
            stTXIDLE : begin
               if (ro_txreq)
                  state <= stTXDAQ;
               else if (sctx_req)
                  state <= stTXSC;
               else
                  state <= stTXIDLE;
            end
            stTXDAQ : begin
               if (ro_txdone)
                  state <= stTXIDLE;
               else
                  state <= stTXDAQ;
            end
            stTXSC : begin
               if (sctx_done)
                  state <= stTXIDLE;
               else
                  state <= stTXSC;
            end
            default : begin  // Fault Recovery
               state <= stTXIDLE;
            end   
         endcase
	
	// tx arbitrer is kept to avoid sending of data and sc at the same time
	assign eth_txack = state[1];
	assign sctx_ack = state[2];
	
	assign eth_txdata_rdy = state[1] ? txdata_rdy : 1'b0;

	assign cfg_udptxSrcPort = 	(state[2] | ~cfg_datatx_EthOverDTC) ? sctx_srcPort : 
										cfg_daqport;
	assign cfg_udptxDstPort = 	(state[2] | ~cfg_datatx_EthOverDTC) ? sctx_dstPort : 
										cfg_daqport;
	assign cfg_udptxDstIP = 	(state[2] | ~cfg_datatx_EthOverDTC) ? sctx_dstIP : 
										cfg_daq_ip;
	assign tx_length = 	(state[2] | ~cfg_datatx_EthOverDTC) ? sctx_length : 
								ro_txlength;
	assign txdata = 		state[2] ? sctx_data : 
								ro_txdata;
	assign tx_start = 	state[2] ? sctx_start : 
								ro_txstart & cfg_datatx_EthOverDTC;
	assign tx_stop = state[2] ? sctx_stop : ro_txstop | ~cfg_datatx_EthOverDTC;

//	assign cfg_udptxSrcPort = 	sctx_srcPort;
//	assign cfg_udptxDstPort = 	sctx_dstPort;
//	assign cfg_udptxDstIP = 	sctx_dstIP;
//	assign tx_length = 			sctx_length;
//	assign txdata = 				sctx_data;
//	assign tx_start = 			sctx_start;
//	assign tx_stop = 				sctx_stop;
	
//////////////////////////////////// TX ARBITER (end) ///////////////////////////////////

// sc bus signals
	(* KEEP="TRUE" *) wire [15:0] sc_port;
	(* KEEP="TRUE" *) wire [31:0] sc_data, sc_addr, sc_subaddr, sc_rply_error, sc_rply_data;
	(* KEEP="TRUE" *) wire sc_wr, sc_op, sc_frame, sc_ack;
////////
scController scController (
    .clk(clk),     .clk125(clk125),     .clk10M(clk10M),     .rstn(rstn_rxtx), 
    .cfg_scport(cfg_scport), 
    .cfg_scmode(cfg_scmode), 
	 ///
    .udprx_data(udprx_data), 
	 .udprx_datavalid(udprx_datavalid),
    .udprx_checksum(udprx_checksum), 
    .udprx_dstport(udprx_dstPort), 
    .udprx_srcIP(udprx_srcIP), 
    .udprx_portAck(udprx_portAck), 
	 .portAck_in(1'b1),
	 ///
    .sc_port(sc_port), 
    .sc_data(sc_data), 
    .sc_addr(sc_addr), 
    .sc_subaddr(sc_subaddr), 
    .sc_wr(sc_wr), 
    .sc_op(sc_op), 
    .sc_frame(sc_frame), 
    .sc_ack(sc_ack), 
    .sc_rply_error(sc_rply_error), 
    .sc_rply_data(sc_rply_data), 
	 ///
    .sctx_udptxSrcPort(sctx_srcPort), 
    .sctx_udptxDstPort(sctx_dstPort), 
    .sctx_length(sctx_length), 
    .sctx_udptxDstIP(sctx_dstIP), 
    .sctx_data(sctx_data), 
    .sctx_start(sctx_start), 
    .sctx_stop(sctx_stop), 
    .sctx_req(sctx_req), 
    .sctx_ack(sctx_ack),
	 .sctx_done(sctx_done),
	 .sctx_txdatardy(txdata_rdy)
    );
// warm init signal triggered from the system sc registers
	wire sys_warm_init, rstn_app_i;
scInitSys scInitSys (
    .clk(clk10M),     .rstn(rstn_init), 
	 ////////
    .sc_port_in(sc_port), 
    .sc_data_in(sc_data), 
    .sc_addr_in(sc_addr), 
    .sc_subaddr_in(sc_subaddr), 
    .sc_frame_in(sc_frame), 
    .sc_op_in(sc_op), 
    .sc_wr_in(sc_wr), 
    .sc_ack_in(sc_ack), 
	 ///
    .sc_port_out(sc_port_out), 
    .sc_data_out(sc_data_out), 
    .sc_addr_out(sc_addr_out), 
    .sc_subaddr_out(sc_subaddr_out), 
    .sc_frame_out(sc_frame_out), 
    .sc_op_out(sc_op_out), 
    .sc_wr_out(sc_wr_out), 
    .sc_ack_out(sc_ack_out), 
	 ///
    .sc_rply_data(sc_rply_data), 
	 ///
    .warm_init(sys_warm_init), 
    .rstn_eth(rstn_eth), 
    .rstn_rxtx(rstn_rxtx), 
    .rstn_sc(rstn_sc), 
    .rstn_app(rstn_app_i)
    );
	 
	 assign rstn_app = rstn_app_i  & (!mclkmux_app_rst);
	 
// sc registers
wire [511:0] scregs, scregsin;
wire [15:0] sysrstreg;

scSystem scSystem (
    .clk(clk10M),     .clk40M(clk),    .rstn(rstn_sc), 
	 ////// sc bus inputs
    .sc_port(sc_port_out), 
    .sc_data(sc_data_out), 
    .sc_addr(sc_addr_out), 
    .sc_subaddr(sc_subaddr_out), 
    .sc_op(sc_op_out), 
    .sc_frame(sc_frame_out), 
    .sc_wr(sc_wr_out), 
	 ////// sc bus outputs
    .sc_ack(sc_ack_out), 
    .sc_rply_data(sc_rply_data), 
    .sc_rply_error(sc_rply_error), 
	 ////// sc bus outputs from application side
    .sc_ack_in(sc_ack_in), 
    .sc_rply_data_in(sc_rply_data_in), 
    .sc_rply_error_in(sc_rply_error_in),
	 ////	 
    .b_scl(B_I2C_SCL), 
    .b_sda(B_I2C_SDA), 
    .a_scl(A_I2C_SCL), 
    .a_sda(A_I2C_SDA), 
    .rstreg(sysrstreg), 
    .regout(scregs),
    .regin(scregsin)
    );

	 assign sys_warm_init = sysrstreg[0];
	 assign SWRST_n = (~sysrstreg[15]);
	 assign dtcctf_resetn = (rstn) & (!sysrstreg[1]);
	 assign ethrxclk_rst = (~rstn) | sysrstreg[2];
	 
	 assign version = scregs[31: 0];
	 assign cfg_fpga_mac[47:24] = scregs[55: 32];
	 assign cfg_fpga_mac[23: 0] = scregs[87: 64];
	 assign cfg_fpga_ip = scregs[127:96];
	 assign cfg_daqport = scregs[143:128];
	 assign cfg_scport = scregs[175:160];
	 assign cfg_udptx_frameDly = scregs[207:192];
	 assign cfg_udptx_initframeDly = scregs[223:208];
	 assign cfg_totFrames = scregs[239:224];
	 assign cfg_ethmode = scregs[271:256];
	 assign cfg_scmode = scregs[303:288];
	 assign cfg_daq_ip = scregs[351:320];
//	 assign cfg_udptx_daqtotFrames = scregs[367:352];
	 assign cfg_udptx_daqtotFrames = cfg_totFrames;
	 assign cfg_dtcCtrlReg = scregs[(11 * 32)+:32];

	 assign mclkmux_cfg 				= scregs[(12 * 32)+:8];
	 assign dtcctf_cfg[7:0] 		= scregs[(12 * 32)+:8];
	 assign dtcctf_cfg[15:8] 		= 8'h00;
	 
//	 assign cfg_dtcCtrlReg	= scregs[(14 * 32)+:32];
	 assign cfg_datatx_EthOverDTC	= cfg_dtcCtrlReg[0];
	 
	 assign scregsin[415:0] = scregs[415:0];
	 assign scregsin[(13 * 32)+:32] = {dtcclk_measure_out, 2'b00, dtcclk_status_out, 2'b00, mclkmux_clksel, 2'b00, ethrxclk_locked, dtcclk_locked};
	 assign scregsin[(14 * 32)+:32] = scregs[(14 * 32)+:32];
	 assign scregsin[(15 * 32)+:32] = {15'h0000, FEC_FW_VERSION};
	 
///////////// triggers ///////////////
	 
	 assign trg_out = nim_in | dtc_trigger;
	 assign nim_out = trg_in;

endmodule
