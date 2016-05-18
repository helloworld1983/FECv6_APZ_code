// @file
`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: @author Sorin Martoiu
// 
// Create Date:   @date  23:58:44 04/02/2012 
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

//% @brief System Unit. Contains all system cores used for interfacing with DAQ or the on-board system peripherals, providing astandardized internal interface to the application core.
//% @note [SYSTEM IO] ports go to FPGA pads which are connected to system peripherals and connectors
//% @note [APP FIXED IO] ports go to FPGA pads which are connected to the PCIE extension connectors. This pins are standardized and are present for all extension cards
//% @note [APP INTERNAL] ports are FPGA internal nets connected to the application core

module sysUnit(


	input	clk_osc_P,	clk_osc_N,							//% [SYSTEM IO] local clock oscillator (200 MHz)

	input 	nim_in,											//% [SYSTEM IO] nim input
	output 	nim_out,											//% [SYSTEM IO] nim output

	input [1:0] DTCIN_P, DTCIN_N,							//% [SYSTEM IO] DTC LVDS pads
	input [1:0] DTC2IN_P, DTC2IN_N,						//% [SYSTEM IO] DTC LVDS pads
	output [1:0] DTCOUT_P, DTCOUT_N,						//% [SYSTEM IO] DTC LVDS pads
	output [1:0] DTC2OUT_P, DTC2OUT_N,					//% [SYSTEM IO] DTC LVDS pads

	output	SWRST_n,											//% [SYSTEM IO] force reboot 
	output PW_EN_A, PW_EN_B,								//% [APP FIXED] FRONT-END card controls
	input  A_PRSNT_B, B_PRSNT_B,							//% [APP FIXED] FRONT-END card controls

	output	TXP_0, TXN_0, 									//% [SYSTEM IO] ethernet TX (SFP)
	input		RXP_0, RXN_0,									//% [SYSTEM IO] ethernet RX (SFP)
	input		MGTCLK_P, MGTCLK_N,							//% [SYSTEM IO] ethernet clock (125 MHz)
	output	linkStatus,										//% [SYSTEM IO] ethernet link status led
	input		SFP_LOS,											//% [SYSTEM IO] ethernet LOS (SFP)

	inout	B_I2C_SCL, B_I2C_SDA,							//% [APP FIXED IO] System I2C ports
	inout	A_I2C_SCL, A_I2C_SDA,							//% [APP FIXED IO] System I2C ports

	 output rstn_app, rstn_sc, rstn_init, rstn,		//% [APP INTERNAL] reset signals
	 output clk125, clk, clk10M, clk_refiod,			//% [APP INTERNAL] clock signals
	 output dcm_locked,										//% [APP INTERNAL] clock signals

    output [15:0] 	sc_port_out,						//% [APP INTERNAL] SC bus
    output [31:0] 	sc_data_out,						//% [APP INTERNAL] SC bus
    output [31:0] 	sc_addr_out,						//% [APP INTERNAL] SC bus
    output [31:0] 	sc_subaddr_out,					//% [APP INTERNAL] SC bus
    output 				sc_op_out,							//% [APP INTERNAL] SC bus
    output 				sc_frame_out,						//% [APP INTERNAL] SC bus
    output 				sc_wr_out,							//% [APP INTERNAL] SC bus
    input 				sc_ack_in,							//% [APP INTERNAL] SC bus
    input [31:0] 		sc_rply_data_in,					//% [APP INTERNAL] SC bus
    input [31:0] 		sc_rply_error_in,					//% [APP INTERNAL] SC bus

    input ro_txreq, 											//% [APP INTERNAL] UDP channel interface (request access)
    input ro_txdone,											//% [APP INTERNAL] UDP channel interface (access done)
    output ro_txack,											//% [APP INTERNAL] UDP channel interface (grant access)
    input ro_txstart, ro_txstop,							//% [APP INTERNAL] UDP channel interface
    output ro_txdata_rdy, frameEndEvent,				//% [APP INTERNAL] UDP channel interface
    input [7:0] ro_txdata,									//% [APP INTERNAL] UDP channel interface (data byte)
    input [15:0] ro_txlength,								//% [APP INTERNAL] UDP channel interface (UDP frame length)
	 input [6:0] ro_NumFramesEvent,						//% [APP INTERNAL] UDP channel interface (number of (UDP) frames per event)

	 output trg_out,											//% [APP INTERNAL] trigger to application core
	 input trg_in												//% [APP INTERNAL] trigger from application core
);

	parameter gbe_rxram_depth = 14;

//% hardwired version, must be overwritten at top level
	parameter [15:0] FEC_FW_VERSION = 15'h0FFF;

//% @note power enable signals to application card are controlled by card present inputs
	assign PW_EN_A = ~ A_PRSNT_B;
	assign PW_EN_B = ~ B_PRSNT_B;

	wire clk0, trg0;
	
	/*! DTC CTF unit signals*/ wire dtcctf_resetn, dtc_clk, dtc_trg, dtcclk_locked, dtcclk_ok;
	/*! DTC CTF unit signals*/ wire [15:0] dtcctf_cfg;
	/*! DTC CTF unit signals*/ wire [15:0] dtcclk_measure_val;
	/*! DTC CTF unit signals*/ wire [5:0]  dtcclk_status;
	/*! DTC CTF unit signals*/ wire dtcclk_measure_dv;
	
	//% DTCCTF unit. Retrieves clock and trigger from the DTC LVDS interface when connected to a CTF card.
	dtcctf_unit dtcctf_u (
		 .clk0(clk0),		 .rstn(dtcctf_resetn),		 .cfg(dtcctf_cfg), 
		 //
		 .DTCIN_P(DTCIN_P), 		 .DTCIN_N(DTCIN_N), 
		 .DTC2IN_P(DTC2IN_P),	 .DTC2IN_N(DTC2IN_N), 
		 .DTCOUT_P(DTCOUT_P),	 .DTCOUT_N(DTCOUT_N), 
		 .DTC2OUT_P(DTC2OUT_P),	 .DTC2OUT_N(DTC2OUT_N),
		//	 
		 .trgin(trg0),		 .clkin(clk),
		//
		 .dtcclk_ok(dtcclk_ok), 	 .dtcclk_locked(dtcclk_locked), 
		 .dtcclk_out(dtc_clk), 		 .dtctrg_out(dtc_trg),
		 //
		 .dtcclk_measure_val(dtcclk_measure_val), 
		 .dtcclk_status(dtcclk_status), 
		 .dtcclk_measure_dv(dtcclk_measure_dv)
		 );
	
	// register for DTC clock measure in sc clock domain (10MHz)
	reg [15:0] dtcclk_measure_out;
	reg [5:0] dtcclk_status_out;
	reg dtcclk_measure_dv10;
   always @(posedge clk10M or negedge rstn)
      if (!rstn) begin
         dtcclk_measure_out <= 16'h0000;
         dtcclk_status_out <= 6'b000000;
			dtcclk_measure_dv10 <= 1'b0;
      end else begin
			dtcclk_measure_dv10 <= dtcclk_measure_dv;
			if (dtcclk_measure_dv10) begin
				dtcclk_measure_out <= dtcclk_measure_val;
				dtcclk_status_out <= dtcclk_status;
			end
      end
	
	// 40MHz clock from ethernet RX CRU 
	wire ethrxclk_ok;
	wire ethrxclk, ethrxclk_locked, ethrxclk_rst, clk40e;
	//% PLL and clock detection circuitry for the clocked recovered from the Ethernet RX line
	ethmclk ethmclk_unit (
		 .ethrxclk(ethrxclk), .ethrxclk_rst(ethrxclk_rst), 
		 .clk40e(clk40e), 	 .ethrxclk_ok(ethrxclk_ok), 	 .ethrxclk_locked(ethrxclk_locked)
		 );
		 
	// Main CLOCK MUX
	wire [1:0] mclkmux_clksel;
	wire [7:0] mclkmux_cfg;
	wire mclkmux_app_rst;
	
	//% Main clock multiplexer unit
	mclk_unit mclk_unit (
		 .clk0(clk0), 		 .rstn(rstn), 
		 .dtc_clk(dtc_clk), 	 .dtcclk_locked(dtcclk_locked), 	 .dtcclk_ok(dtcclk_ok), 
		 .clk40e(clk40e), 	 .ethrxclk_ok(ethrxclk_ok),		 .ethrxclk_locked(ethrxclk_locked), 
		 .clk(clk), 
		 .mclkmux_cfg(mclkmux_cfg), 
		 .mclkmux_clksel(mclkmux_clksel), 
		 .mclkmux_app_rst(mclkmux_app_rst)
		 );


//% generate initial reset
	Reset_Unit Reset_Unit (    .clk(clk125),     .rstb(rstn)    );
//% local clock generation unit (200MHz, 40MHz and 10MHz)
	clock_unit clock_unit (   	.clk_osc_N(clk_osc_N),     .clk_osc_P(clk_osc_P), 
										.clk(clk0), .clk_refiod(clk_refiod),    .clk10M(clk10M), 
										.clk_locked(dcm_locked),     .rstn(rstn)
								  );


/*! ethernet i/f signals */	wire eth_rst, forceEthCanSend, tx_start, tx_stop, txdata_rdy;
/*! ethernet i/f signals */	wire [7:0] txdata;
/*! ethernet i/f signals */	wire [15:0] tx_length;
/*! ethernet i/f signals */	(* KEEP="TRUE" *) wire udprx_datavalid, udprx_portAck, eth_tx_busy;
/*! ethernet i/f signals */	(* KEEP="TRUE" *) wire [7:0] udprx_data;
/*! ethernet i/f signals */	(* KEEP="TRUE" *) wire [15:0] udprx_dstPort, udprx_checksum;
/*! ethernet i/f signals */	(* KEEP="TRUE" *) wire [31:0] udprx_srcIP;
/*! ethernet cfg registers */	wire [15:0] cfg_udptxSrcPort, cfg_udptxDstPort, cfg_udptx_frameDly;
/*! ethernet cfg registers */	wire [31:0] cfg_udptxDstIP;

/*! system cfg registers */	wire [15:0] version, cfg_daqport, cfg_scport, cfg_framedly, cfg_totFrames, cfg_ethmode, cfg_scmode, cfg_udptx_daqtotFrames;
/*! system cfg registers */	wire [31:0] cfg_fpga_ip, cfg_daq_ip;
/*! system cfg registers */	wire [47:0] cfg_fpga_mac;

/*! internal reset signals */	wire rstn_eth, rstn_rxtx;

	assign rstn_init = (dcm_locked) & rstn;
	assign forceEthCanSend = 1'b1;
	assign eth_rst = ~rstn_eth;

//% Ethernet Unit
wire udprx_portAck_i;
v5_emac_v1_7_top #(.gbe_rxram_depth(gbe_rxram_depth)) ethernet (
    .TXP_0(TXP_0),     		.TXN_0(TXN_0), 
    .RXP_0(RXP_0),     		.RXN_0(RXN_0), 
    .MGTCLK_P(MGTCLK_P),   .MGTCLK_N(MGTCLK_N), 
    .RESET(eth_rst), 
	 .clk_out(clk125),
	 .RXRECCLK0_OUT(ethrxclk),
    .linkStatus(linkStatus), 
    .forceEthCanSend(forceEthCanSend), 
	 // TX
	 .tx_busy(eth_tx_busy),
    .txdata(txdata), 
    .tx_length(tx_length), 
    .tx_start(tx_start), 
    .tx_stop(tx_stop), 
    .txdata_rdy(txdata_rdy),
	 .frameEndEvent(frameEndEvent),	
	 // RX
	 .udprx_srcIP(udprx_srcIP),
	 .udprx_dataout(udprx_data),
	 .udprx_datavalid(udprx_datavalid),
	 .udprx_dstPortOut(udprx_dstPort),
	 .udprx_checksum(udprx_checksum),
	 .udprx_portAckIn(udprx_portAck_i),
		//config
	 .fpga_mac(cfg_fpga_mac),
	 .fpga_ip(cfg_fpga_ip),
    .udptx_numFramesEvent(ro_NumFramesEvent), 
	 .udptx_frameDly(cfg_udptx_frameDly),
//	 .udptx_daqtotFrames(cfg_udptx_daqtotFrames),
	 .udptx_daqtotFrames(16'h0000),
    .udptx_srcPort(cfg_udptxSrcPort), 
    .udptx_dstPort(cfg_udptxDstPort), 
    .udptx_dstIP(cfg_udptxDstIP)
    );
	 
wire roxoff_send, roxoff_evcr, udprx_portAck_xoff;
roxoff_catch_cmd roxoff_catch_cmd (
    .clk125(clk125), 
    .rstn(rstn_rxtx), 
    .cfg_daqport(cfg_daqport), 
    .cfg_daq_ip(cfg_daq_ip), 
    .cfg_xoffcmd(cfg_ethmode[15:12]), 
    .udprx_dstPort(udprx_dstPort), 
    .udprx_srcIP(udprx_srcIP), 
    .udprx_data(udprx_data), 
    .udprx_datavalid(udprx_datavalid), 
    .udprx_checksum(udprx_checksum), 
    .udprx_portAck(udprx_portAck_xoff), 
    .roxoff_send(roxoff_send), 
    .roxoff_evcr(roxoff_evcr)
    );

	assign udprx_portAck_i = udprx_portAck | udprx_portAck_xoff;

	(* KEEP="TRUE" *) wire sctx_req, sctx_start, sctx_stop, sctx_ack, sctx_dstrdy, sctx_done;		//% signals for slow control UDP TX path 
	(* KEEP="TRUE" *) wire [7:0] sctx_data;																		//% signals for slow control UDP TX path 
	(* KEEP="TRUE" *) wire [15:0] sctx_dstPort, sctx_srcPort, sctx_length;								//% signals for slow control UDP TX path
	(* KEEP="TRUE" *) wire [31:0] sctx_dstIP;																		//% signals for slow control UDP TX path

//////////////////////////////////// TX ARBITER ///////////////////////////////////
// Multiplexes between slow control and data 
txswitch txswitch (
    .clk125(clk125), 
    .rstn(rstn_rxtx), 
    .cfg(8'h00), 
    .daqtotframes(cfg_udptx_daqtotFrames), 
    .roxoff_send(roxoff_send), 
    .roxoff_evcr(roxoff_evcr), 
    .ro_txreq(ro_txreq), 
    .ro_txdone(ro_txdone), 
    .ro_txack(ro_txack), 
    .sc_txreq(sctx_req), 
    .sc_txdone(sctx_done), 
    .sc_txack(sctx_ack)
    );
//   parameter stTXIDLE = 3'b00001;
//   parameter stTXDAQ = 3'b00010;
//   parameter stTXSC = 3'b00100;
//
//   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="YES", SAFE_RECOVERY_STATE="5'b00001" *) reg [2:0] state = stTXIDLE;
//
//   always@(posedge clk125 or negedge rstn_rxtx)
//      if (!rstn_rxtx) begin
//         state <= stTXIDLE;
//      end
//      else
//         (* PARALLEL_CASE *) case (state)
//            stTXIDLE : begin
//               if (ro_txreq)
//                  state <= stTXDAQ;
//               else if (sctx_req)
//                  state <= stTXSC;
//               else
//                  state <= stTXIDLE;
//            end
//            stTXDAQ : begin
//               if (ro_txdone)
//                  state <= stTXIDLE;
//               else
//                  state <= stTXDAQ;
//            end
//            stTXSC : begin
//               if (sctx_done)
//                  state <= stTXIDLE;
//               else
//                  state <= stTXSC;
//            end
//            default : begin  // Fault Recovery
//               state <= stTXIDLE;
//            end   
//         endcase
//	
//	assign ro_txack = state[1];
//	assign sctx_ack = state[2];
	
	assign ro_txdata_rdy = ro_txack ? txdata_rdy : 1'b0;

	assign cfg_udptxSrcPort = 	sctx_ack ? sctx_srcPort : 
										cfg_daqport;
	assign cfg_udptxDstPort = 	sctx_ack ? sctx_dstPort : 
										cfg_daqport;
	assign cfg_udptxDstIP = 	sctx_ack ? sctx_dstIP : 
										cfg_daq_ip;
	assign tx_length = 	sctx_ack ? sctx_length : 
								ro_txlength;
	assign txdata = 		sctx_ack ? sctx_data : 
								ro_txdata;
	assign tx_start = 	sctx_ack ? sctx_start : 
								ro_txstart;
	assign tx_stop = sctx_ack ? sctx_stop : ro_txstop;
	
//////////////////////////////////// TX ARBITER (end) ///////////////////////////////////


/*! sc bus signals */	(* KEEP="TRUE" *) wire [15:0] sc_port;																	
/*! sc bus signals */	(* KEEP="TRUE" *) wire [31:0] sc_data, sc_addr, sc_subaddr, sc_rply_error, sc_rply_data;
/*! sc bus signals */	(* KEEP="TRUE" *) wire sc_wr, sc_op, sc_frame, sc_ack;
////////
//% Controller for the slow-control bus. Interfaces with the UDP i/f and ganerates the sc bus activity
scController scController_u (
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

//% System Initialization Core. Runs after reset or at Warn INIT. Takes over the sc bus reads data from the system EEPROM and writes values to peripheral registers
scInitSys scInitSys_u (
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

//% The drivers for the system slow-control peripherals (system I2C busses, system registers, )
scSystem scSystem_u (
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
	 assign SWRST_n = ~sysrstreg[15];
	 assign dtcctf_resetn = (rstn) & (!sysrstreg[1]);
	 assign ethrxclk_rst = (~rstn) | sysrstreg[2];
	 
	 assign version = scregs[31: 0];
	 assign cfg_fpga_mac[47:24] = scregs[55: 32];
	 assign cfg_fpga_mac[23: 0] = scregs[87: 64];
	 assign cfg_fpga_ip = scregs[127:96];
	 assign cfg_daqport = scregs[143:128];
	 assign cfg_scport = scregs[175:160];
	 assign cfg_udptx_frameDly = scregs[207:192];
//	 assign cfg_totFrames = scregs[239:224];
	 assign cfg_udptx_daqtotFrames = scregs[239:224];
	 assign cfg_ethmode = scregs[271:256];
	 assign cfg_scmode = scregs[303:288];
	 assign cfg_daq_ip = scregs[351:320];
//	 reserved for DTC control
//	 assign cfg_udptx_daqtotFrames = scregs[367:352];

	 assign mclkmux_cfg 				= scregs[(12 * 32)+:8];
	 assign dtcctf_cfg[7:0] 		= scregs[(12 * 32)+:8];
	 assign dtcctf_cfg[15:8] 		= 8'h00;
	 
	 assign scregsin[415:0] = scregs[415:0];
	 assign scregsin[(13 * 32)+:32] = {dtcclk_measure_out, 2'b00, dtcclk_status_out, 2'b00, mclkmux_clksel, 2'b00, ethrxclk_locked, dtcclk_locked};
	 assign scregsin[479:448] = 0;
	 assign scregsin[(15 * 32)+:32] = {15'h0000, FEC_FW_VERSION};
	 
///////////// triggers ///////////////
	 
	 assign trg_out = nim_in;
	 assign nim_out = trg_in;

endmodule
