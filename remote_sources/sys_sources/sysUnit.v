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

module sysUnit(
// IO PORTS
	// CLK Inputs
	input	clk_osc_P,	clk_osc_N,	// 200 MHz local oscillator
	// nim
	input 	nim_in,
	output 	nim_out,
	// 
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
	 input trg_in
);

// power enable signals linked to card present inputs
	assign PW_EN_A = ~ A_PRSNT_B;
	assign PW_EN_B = ~ B_PRSNT_B;
// generate initial reset
	Reset_Unit Reset_Unit (    .clk(clk125),     .rstb(rstn)    );
// local clock generation unit (200MHz, 40MHz and 10MHz)
	clock_unit clock_unit (   	.clk_osc_N(clk_osc_N),     .clk_osc_P(clk_osc_P), 
										.clk(clk), .clk_refiod(clk_refiod),    .clk10M(clk10M), 
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
	wire [15:0] cfg_udptxSrcPort, cfg_udptxDstPort, cfg_udptx_frameDly;
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

v5_emac_v1_7_top ethernet (
    .TXP_0(TXP_0),     		.TXN_0(TXN_0), 
    .RXP_0(RXP_0),     		.RXN_0(RXN_0), 
    .MGTCLK_P(MGTCLK_P),   .MGTCLK_N(MGTCLK_N), 
    .RESET(eth_rst), 
	 .clk_out(clk125),
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
	 .udprx_portAckIn(udprx_portAck),
		//config
	 .fpga_mac(cfg_fpga_mac),
	 .fpga_ip(cfg_fpga_ip),
    .udptx_numFramesEvent(ro_NumFramesEvent), 
	 .udptx_frameDly(cfg_udptx_frameDly),
	 .udptx_daqtotFrames(cfg_udptx_daqtotFrames),
    .udptx_srcPort(cfg_udptxSrcPort), 
    .udptx_dstPort(cfg_udptxDstPort), 
    .udptx_dstIP(cfg_udptxDstIP)
    );
	 
// signals for slow control UDP TX path 
	(* KEEP="TRUE" *) wire sctx_req, sctx_start, sctx_stop, sctx_ack, sctx_dstrdy, sctx_done;
	(* KEEP="TRUE" *) wire [7:0] sctx_data;
	(* KEEP="TRUE" *) wire [15:0] sctx_dstPort, sctx_srcPort, sctx_length;
	(* KEEP="TRUE" *) wire [31:0] sctx_dstIP;

//////////////////////////////////// TX ARBITER ///////////////////////////////////
   parameter stTXIDLE = 3'b00001;
   parameter stTXDAQ = 3'b00010;
   parameter stTXSC = 3'b00100;

   (* FSM_ENCODING="ONE-HOT", SAFE_IMPLEMENTATION="YES", SAFE_RECOVERY_STATE="5'b00001" *) reg [2:0] state = stTXIDLE;

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
	
	assign ro_txack = state[1];
	assign sctx_ack = state[2];
	
	assign ro_txdata_rdy = state[1] ? txdata_rdy : 1'b0;

	assign cfg_udptxSrcPort = 	state[2] ? sctx_srcPort : 
										cfg_daqport;
	assign cfg_udptxDstPort = 	state[2] ? sctx_dstPort : 
										cfg_daqport;
	assign cfg_udptxDstIP = 	state[2] ? sctx_dstIP : 
										cfg_daq_ip;
	assign tx_length = 	state[2] ? sctx_length : 
								ro_txlength;
	assign txdata = 		state[2] ? sctx_data : 
								ro_txdata;
	assign tx_start = 	state[2] ? sctx_start : 
								ro_txstart;
	assign tx_stop = state[2] ? sctx_stop : ro_txstop;
	
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
	wire sys_warm_init;
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
    .rstn_app(rstn_app)
    );
// sc registers
wire [511:0] scregs;
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
    .regout(scregs)
    );

	 assign sys_warm_init = sysrstreg[0];
	 assign SWRST_n = ~sysrstreg[15];
	 
	 assign version = scregs[31: 0];
	 assign cfg_fpga_mac[47:24] = scregs[55: 32];
	 assign cfg_fpga_mac[23: 0] = scregs[87: 64];
	 assign cfg_fpga_ip = scregs[127:96];
	 assign cfg_daqport = scregs[143:128];
	 assign cfg_scport = scregs[175:160];
	 assign cfg_udptx_frameDly = scregs[207:192];
	 assign cfg_totFrames = scregs[239:224];
	 assign cfg_ethmode = scregs[271:256];
	 assign cfg_scmode = scregs[303:288];
	 assign cfg_daq_ip = scregs[351:320];
	 assign cfg_udptx_daqtotFrames = scregs[367:352];
	 
///////////// triggers ///////////////
	 
	 assign trg_out = nim_in;
	 assign nim_out = trg_in;

endmodule
