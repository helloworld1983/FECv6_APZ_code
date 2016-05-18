`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:58:14 02/11/2011 
// Design Name: 
// Module Name:    eth_standalone 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module eth_standalone(

		// CLK Inputs
	input	clk_osc_P,
	input	clk_osc_N,	// 200 MHz
	
	input 	nim_in,
	output 	nim_out,

	output	SWRST_n,
	output PW_EN_A, PW_EN_B,
	input  A_PRSNT_B, B_PRSNT_B,

		// ethernet
		
	output	TXP_0, TXN_0, 
	input		RXP_0, RXN_0,
	input		MGTCLK_P, MGTCLK_N,
	output	linkStatus,
	input		SFP_LOS,

	output	i2c0_rst, 
	inout	scl0, sda0, 
	inout	scl1, sda1,
	inout	B_I2C_SCL, B_I2C_SDA,
	inout	A_I2C_SCL, A_I2C_SDA,
	
	// DTC
	input [1:0] DTCIN_P,
	input [1:0] DTCIN_N,
	output [1:0] DTCOUT_P,
	output [1:0] DTCOUT_N,
	// DTC2
	input [1:0] DTC2IN_P,
	input [1:0] DTC2IN_N,
	output [1:0] DTC2OUT_P,
	output [1:0] DTC2OUT_N,
	
	///////////////
	output		bclk_p, bclk_n,


		// ADCs Input/Outputs
		// Inputs
		// ADC1
		//FCO1_P, FCO1_N,
	input	DCO1_P, DCO1_N,
	input	DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N,
	input	DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N,
		// ADC2
		//FCO2_P, FCO2_N,
	input	DCO2_P, DCO2_N,
	input	DCH9_P, DCH9_N, DCH10_P, DCH10_N, DCH11_P, DCH11_N, DCH12_P, DCH12_N,
	input	DCH13_P, DCH13_N, DCH14_P, DCH14_N, DCH15_P, DCH15_N, DCH16_P, DCH16_N,
				
		// Outputs
		// ADC1
	output	csb1, pwb1,
		// ADC2
	output	csb2, pwb2,
		// Both
	output	resetb, sclk, sdata,
		// ADCLK
	output	ADCLK_P,ADCLK_N

    );

////////////////////////// GLOBAL PARAMETERS ///////////////////////////////////

	parameter [15:0] FEC_FW_VERSION = 15'h0208;
	
////////////////////////////////////////////////////////////////////////////////	

//assign SWRST_n = 1'b1;
assign PW_EN_A = ~ A_PRSNT_B;
assign PW_EN_B = ~ B_PRSNT_B;

wire clk125, clk, clk10M, clk_refiod, eth_rst, rstn;
wire forceEthCanSend, tx_start, tx_stop, txdata_rdy, frameEndEvent;
wire [7:0] txdata;
wire [15:0] tx_length;

(* KEEP="TRUE" *) wire udprx_datavalid, udprx_portAck, eth_tx_busy;
(* KEEP="TRUE" *) wire [7:0] udprx_data;
(* KEEP="TRUE" *) wire [15:0] udprx_dstPort, udprx_checksum;
(* KEEP="TRUE" *) wire [31:0] udprx_srcIP;
wire [15:0] cfg_udptxSrcPort, cfg_udptxDstPort, cfg_udptx_frameDly;
wire [6:0] cfg_udptxNumFramesEvent;
wire [31:0] cfg_udptxDstIP;

	
	wire clk0, trg0;
	
	// DTC CTF unit
	wire dtcctf_resetn, dtc_clk, dtc_trg, dtcclk_locked, dtcclk_ok;
	wire [15:0] dtcctf_cfg;
	wire [15:0] dtcclk_measure_val;
	wire [5:0]  dtcclk_status;
	wire dtcclk_measure_dv;
	dtcctf_unit dtcctf_unit (
		 .clk0(clk0), 
		 .rstn(dtcctf_resetn), 
		 .cfg(dtcctf_cfg), 
		 //
		 .DTCIN_P(DTCIN_P), 
		 .DTCIN_N(DTCIN_N), 
		 .DTC2IN_P(DTC2IN_P), 
		 .DTC2IN_N(DTC2IN_N), 
		 .DTCOUT_P(DTCOUT_P), 
		 .DTCOUT_N(DTCOUT_N), 
		 .DTC2OUT_P(DTC2OUT_P), 
		 .DTC2OUT_N(DTC2OUT_N),
		//	 
		 .trgin(trg0), 
		 .clkin(clk),
		//
		 .dtcclk_ok(dtcclk_ok), 
		 .dtcclk_locked(dtcclk_locked), 
		 .dtcclk_out(dtc_clk), 
		 .dtctrg_out(dtc_trg),
		 //
		 .dtcclk_measure_val(dtcclk_measure_val), 
		 .dtcclk_status(dtcclk_status), 
		 .dtcclk_measure_dv(dtcclk_measure_dv)
		 );
	
	// 40MHz clock from ethernet RX clock
	wire ethrxclk_ok;
	wire ethrxclk, ethrxclk_locked, ethrxclk_rst, clk40e;
	ethmclk ethmclk_unit (
		 .ethrxclk(ethrxclk), 
		 .ethrxclk_rst(ethrxclk_rst), 
		 .clk40e(clk40e), 
		 .ethrxclk_ok(ethrxclk_ok), 
		 .ethrxclk_locked(ethrxclk_locked)
		 );
		 
	// Main CLOCK MUX
	wire [1:0] mclkmux_clksel;
	wire [7:0] mclkmux_cfg;
	wire mclkmux_app_rst;
	mclk_unit mclk_unit (
		 .clk0(clk0), 
		 .rstn(rstn), 
		 .dtc_clk(dtc_clk), 
		 .dtcclk_locked(dtcclk_locked), 
		 .dtcclk_ok(dtcclk_ok), 
		 .clk40e(clk40e), 
		 .ethrxclk_ok(ethrxclk_ok), 
		 .ethrxclk_locked(ethrxclk_locked), 
		 .clk(clk), 
		 .mclkmux_cfg(mclkmux_cfg), 
		 .mclkmux_clksel(mclkmux_clksel), 
		 .mclkmux_app_rst(mclkmux_app_rst)
		 );

// SYSTEM RESET
Reset_Unit Reset_Unit (
    .clk(clk125), 
    .rstb(rstn)
    );
// SYSTEM CLOCK
wire dcm_locked;
clock_unit clock_unit (
    .clk_osc_N(clk_osc_N), 
    .clk_osc_P(clk_osc_P), 
    .clk(clk0), .clk_refiod(clk_refiod),
    .clk10M(clk10M), 
    .clk_locked(dcm_locked), 
    .rstn(rstn)
    );
	 
assign forceEthCanSend = 1'b1;

	 wire [15:0] version, cfg_daqport, cfg_scport, cfg_framedly, cfg_totFrames, cfg_ethmode, cfg_scmode, cfg_udptx_daqtotFrames;
	 wire [31:0] cfg_fpga_ip, cfg_daq_ip;
	 wire [47:0] cfg_fpga_mac;
	 wire rstn_eth, rstn_rxtx, rstn_app, rstn_sc, rstn_init, rstn_adc, force_adcrst;
	 assign rstn_init = (dcm_locked) & rstn;
	 assign rstn_adc  = (dcm_locked) & rstn & (!force_adcrst) & (!mclkmux_app_rst);
	 assign rstn_adcdcm  = rstn & (!force_adcrst) & (!mclkmux_app_rst);
	
assign eth_rst = ~rstn_eth;

v5_emac_v1_7_top ethernet (
    .TXP_0(TXP_0), 
    .TXN_0(TXN_0), 
    .RXP_0(RXP_0), 
    .RXN_0(RXN_0), 
    .MGTCLK_P(MGTCLK_P), 
    .MGTCLK_N(MGTCLK_N),
	 .RXRECCLK0_OUT(ethrxclk),
	 .clk_out(clk125),
    .linkStatus(linkStatus), 
    .RESET(eth_rst), 
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
    .udptx_numFramesEvent(cfg_udptxNumFramesEvent), 
	 .udptx_frameDly(cfg_udptx_frameDly),
	 .udptx_daqtotFrames(cfg_udptx_daqtotFrames),
    .udptx_srcPort(cfg_udptxSrcPort), 
    .udptx_dstPort(cfg_udptxDstPort), 
    .udptx_dstIP(cfg_udptxDstIP)
    );
	 
 
(* KEEP="TRUE" *) wire sctx_req, sctx_start, sctx_stop, sctx_ack, sctx_dstrdy, sctx_done;
(* KEEP="TRUE" *) wire [7:0] sctx_data;
(* KEEP="TRUE" *) wire [15:0] sctx_dstPort, sctx_srcPort, sctx_length;
(* KEEP="TRUE" *) wire [31:0] sctx_dstIP;
(* KEEP="TRUE" *) wire ro_txreq, ro_txdone;

	////////////////////////////////// TX ARBITER ///////////////////////////////////
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
	
	wire [15:0] ro_txlength;
	wire [7:0] ro_txdata;
	(* KEEP="TRUE" *) wire ro_txack, ro_txstart, ro_txstop;
	
	assign ro_txack = state[1];
	assign sctx_ack = state[2];
	
	wire ro_txdata_rdy;
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


(* KEEP="TRUE" *) wire [15:0] sc_port, sc_port_out;
(* KEEP="TRUE" *) wire [31:0] sc_data, sc_data_out, sc_addr, sc_addr_out, sc_subaddr, sc_subaddr_out, sc_rply_error, sc_rply_data;
(* KEEP="TRUE" *) wire sc_wr, sc_wr_out, sc_op, sc_op_out, sc_frame, sc_frame_out;
(* KEEP="TRUE" *) wire sc_ack, sc_ack_out;
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
wire sys_warm_init, rstn_app0, force_apprst;
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
    .rstn_app(rstn_app0)
    );
	
assign rstn_app = rstn_app0 & (!force_apprst) & (!mclkmux_app_rst);

wire [511:0] scregs, appregs, scregsin, appregsin;
wire [15:0] apprstreg, cspi_rstreg;
wire [15:0] sysrstreg;
wire forceBclkRst;
wire cspi_enable, cspi_sdata;
wire [31:0] cspi_cs_n;

scApplication scApplication (
    .clk(clk10M),     .rstn(rstn_sc), 
	 //////
    .sc_port(sc_port_out), 
    .sc_data(sc_data_out), 
    .sc_addr(sc_addr_out), 
    .sc_subaddr(sc_subaddr_out), 
    .sc_op(sc_op_out), 
    .sc_frame(sc_frame_out), 
    .sc_wr(sc_wr_out), 
    .sc_ack(sc_ack_out), 
	 //////
    .sc_rply_data(sc_rply_data), 
    .sc_rply_error(sc_rply_error), 
	 //////
    .i2c0_scl(scl0),     .i2c0_sda(sda0),     .i2c0_rst(i2c0_rst),
	 //
    .i2c1_scl(scl1),     .i2c1_sda(sda1),
	 //
	 .b_scl(B_I2C_SCL),	 .b_sda(B_I2C_SDA),
	 //
    .a_scl(A_I2C_SCL),     .a_sda(A_I2C_SDA), 
	 //
    .cspi_enable(cspi_enable), 
    .cspi_sdata(cspi_sdata), 
    .cspi_cs_n(cspi_cs_n), 
    .cspi_rstreg(cspi_rstreg), 
	 //
	 .rstreg(sysrstreg),
	 .apprstreg(apprstreg),
	 .regout(scregs),
	 .regin(scregsin),
	 .appregout(appregs),
	 .appregin(appregsin)
    );

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
		
	 wire dtctrg_invert;
	 
	 assign forceBclkRst = apprstreg[0];
	 assign sys_warm_init = sysrstreg[0];
	 assign SWRST_n = ~sysrstreg[15];
	 
	 assign dtcctf_resetn = (rstn) & (!sysrstreg[1]);
	 assign ethrxclk_rst = (~rstn) | sysrstreg[2];
//	 assign force_adcrst = sysrstreg[3];
//	 assign force_apprst = sysrstreg[4];
	 assign force_adcrst = cspi_rstreg[15];
	 assign force_apprst = cspi_rstreg[14];
	 
	 assign version = scregs[31: 0];
	 //assign version = FEC_FW_VERSION;
	 assign cfg_fpga_mac[47:24] 		= scregs[( 1 * 32)+: 24];
	 assign cfg_fpga_mac[23: 0] 		= scregs[( 2 * 32)+: 24];
	 assign cfg_fpga_ip 					= scregs[( 3 * 32)+: 32];
	 assign cfg_daqport 					= scregs[( 4 * 32)+: 16];
	 assign cfg_scport 					= scregs[( 5 * 32)+: 16];
	 assign cfg_udptx_frameDly 		= scregs[( 6 * 32)+: 16];
	 assign cfg_totFrames 				= scregs[( 7 * 32)+: 16];
	 assign cfg_ethmode 					= scregs[( 8 * 32)+: 16];
	 assign cfg_scmode 					= scregs[( 9 * 32)+: 16];
	 assign cfg_daq_ip 					= scregs[(10 * 32)+: 32];
	 assign cfg_udptx_daqtotFrames 	= scregs[(11 * 32)+: 15];
	 
//	 assign dtcclk_inh 			= scregs[(12 * 32) +  0];
//	 assign ethrxclk_sel 		= scregs[(12 * 32) +  1];
	 assign mclkmux_cfg 				= scregs[(12 * 32)+:8];
	 assign dtcctf_cfg[7:0] 		= scregs[(12 * 32)+:8];
	 assign dtcctf_cfg[15:8] 		= 8'h00;
	 
	 assign scregsin[415:0] = scregs[415:0];
	 
//	 assign scregsin[(13 * 32) +  0] = DTC0CLK_LOCKED;
//	 assign scregsin[(13 * 32) +  1] = ethrxclk_locked;
	 assign scregsin[(13 * 32)+:32] = {dtcclk_measure_out, 2'b00, dtcclk_status_out, 2'b00, mclkmux_clksel, 2'b00, ethrxclk_locked, dtcclk_locked};
	 
//	 assign scregsin[479:418] = 0;
	 assign scregsin[479:448] = 0;
	 
	 assign scregsin[(15 * 32)+:32] = {15'h0000, FEC_FW_VERSION};

	wire [15:0] cfg_chmask;
	assign cfg_chmask = appregs[271:256];
	assign cfg_udptxNumFramesEvent = 	cfg_chmask[0] + cfg_chmask[1] + cfg_chmask[2] + cfg_chmask[3] + 
								cfg_chmask[4] + cfg_chmask[5] + cfg_chmask[6] + cfg_chmask[7] + 
								cfg_chmask[8] + cfg_chmask[9] + cfg_chmask[10] + cfg_chmask[11] + 
								cfg_chmask[12] + cfg_chmask[13] + cfg_chmask[14] + cfg_chmask[15];
								

								
////////////////////// APPLICATION PARAMETERS ASSIGNEMENT /////////////////////////
wire			DES_run, conf_end;//, DCH_adj;//, DCM_lock;
wire [15:0]	DES_status;
wire [5:0]	ADCDCM_status;
wire adc_init;
wire [24:0] adc_conf;

//	assign adc_init = appregs[( 6 * 32)+ 31];
//	assign adc_conf = appregs[( 6 * 32)+:25];
								
	assign appregsin[( 7 * 32)+:32] = {8'h00, conf_end, DES_run, ADCDCM_status, DES_status};
	
	// default loopback assignement
	assign appregsin[( 7 * 32 - 1): 0] = appregs[(( 7 * 32) - 1): 0];
	
	assign appregsin[511: ( 8 * 32)] = appregs[511: ( 8 * 32)];

////////////////////////////// ADC Core /////////////////////////////////////
wire [11:0]	CH0,CH1,CH2,CH3,CH4,CH5,CH6,CH7;
wire [11:0]	CH8,CH9,CH10,CH11,CH12,CH13,CH14,CH15;
wire adcu_csb1, adcu_csb2, adcu_sdata;
		// Parametros de configuración del circuito de Ajuste de los Deserializadores
		parameter [7:0]	DCO_ADJ 	= 8'hFE;
		parameter [11:0] 	DCO_STABLE = 12'hFFF;
		parameter [11:0]	FCO_STABLE = 12'hFFF;
		parameter [11:0]	ADJ_TEST = 12'hFFF;
		parameter [10:0]	ADJ_ADCRST = 11'h3FF;
		
		parameter [25:0]	RST_ADJ = 10000000; //67108863
		
		parameter [11:0]	SIGNAL_LEVEL1 = 12'h7B7;	//1975
	   parameter [11:0]	SIGNAL_LEVEL2 = 12'h81B; 	//2075

ADCs_Unit 
#(
	.DCO_ADJ(DCO_ADJ),
	.DCO_STABLE(DCO_STABLE),
	.FCO_STABLE(FCO_STABLE),
	.ADJ_TEST(ADJ_TEST),
	.ADJ_ADCRST(ADJ_ADCRST),
	.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
	.SIGNAL_LEVEL2(SIGNAL_LEVEL2) //2025
)
ADCs_Unit (
	 // Relojes y reset
	 .clk(clk),						// Reloj principal
    .sclk(clk10M), 					// Reloj de control de los ADCs: 	 20 MHz
    .clk_refiod(clk_refiod), 	// Reloj de control de los IODELAYs: 200 MHz
    .rstb(rstn_adc),.rstb_dcm(rstn_adcdcm), 
	 
	 // Señales de control internas
    // Entradas
	 .adc_init(0), .adc_conf(0), 
//	 .adc_init(adc_init), .adc_conf(adc_conf), 
    .dcm_init(0),//dcm_init), 
    .dcm_conf(0),//dcm_conf),
	 //.trsf_conf(trsf_conf[5]),
	 // Salidas
	 .conf_end(conf_end), 
    .DES_run(DES_run), .DES_status(DES_status), .DCM_status(ADCDCM_status), 

	 // Señales de entrada de los ADCs
	 // ADC1
	 // Relojes	
    .DCO1_P(DCO1_P),     .DCO1_N(DCO1_N),
	 // Datos
    .DCH1_P(DCH1_P),     .DCH1_N(DCH1_N), 
    .DCH2_P(DCH2_P),     .DCH2_N(DCH2_N), 
    .DCH3_P(DCH3_P),     .DCH3_N(DCH3_N), 
    .DCH4_P(DCH4_P),	    .DCH4_N(DCH4_N), 
    .DCH5_P(DCH5_P),	    .DCH5_N(DCH5_N), 
    .DCH6_P(DCH6_P),     .DCH6_N(DCH6_N), 
    .DCH7_P(DCH7_P),	    .DCH7_N(DCH7_N), 
    .DCH8_P(DCH8_P),	    .DCH8_N(DCH8_N),
	 
	 // ADC2
	 // Relojes		 
    .DCO2_P(DCO2_P),     .DCO2_N(DCO2_N),
	 // Datos	
    .DCH9_P(DCH9_P),     .DCH9_N(DCH9_N), 
    .DCH10_P(DCH10_P),    .DCH10_N(DCH10_N), 
    .DCH11_P(DCH11_P),    .DCH11_N(DCH11_N), 
    .DCH12_P(DCH12_P),    .DCH12_N(DCH12_N), 
    .DCH13_P(DCH13_P),    .DCH13_N(DCH13_N), 
    .DCH14_P(DCH14_P),    .DCH14_N(DCH14_N), 
    .DCH15_P(DCH15_P),    .DCH15_N(DCH15_N), 
    .DCH16_P(DCH16_P),    .DCH16_N(DCH16_N),

	 // Datos de salida de los ADCs
    .CH0(CH0), .CH1(CH1), .CH2(CH2), .CH3(CH3), .CH4(CH4), .CH5(CH5), .CH6(CH6), .CH7(CH7), 
    .CH8(CH8), .CH9(CH9), .CH10(CH10), .CH11(CH11), .CH12(CH12), .CH13(CH13), .CH14(CH14), .CH15(CH15), 
	 
	 // Señales de control de los ADCs
	 // ADC1
    .csb1(adcu_csb1), 
    .pwb1(pwb1), 
	 // ADC2	
    .csb2(adcu_csb2), 
    .pwb2(pwb2),
	 // Both	
    .sdata(adcu_sdata), 
    .resetb(resetb_aux)
	 );
	assign resetb = resetb_aux & dcm_locked;
	
	assign sdata 	= cspi_enable ? cspi_sdata : adcu_sdata;
	assign csb1 	= cspi_enable ? cspi_cs_n[0] : adcu_csb1;
	assign csb2 	= cspi_enable ? cspi_cs_n[1] : adcu_csb2;
	
	ADC_clks ADC_clks (
		 .clk(clk), 
		 .clk10M(clk10M), 
		 .rstn(rstn), 
		 .adcsclk_disable(1'b0), 
		 .ADCLK_P(ADCLK_P), 
		 .ADCLK_N(ADCLK_N), 
		 .sclk(sclk)
		 );
		 
	
///////////////////////////////////////////////////////////////////////////////////////
wire bclkout, app_trgin;
assign app_trgin = nim_in | dtc_trg;
appUnit appUnit (
    .clk(clk),     .clk125(clk125),     .rstn(rstn_app),
	 .forceBclkRst(forceBclkRst),
	 ///////////////////////
    .CH0(CH0), .CH1(CH1), .CH2(CH2), .CH3(CH3), .CH4(CH4), .CH5(CH5), .CH6(CH6), .CH7(CH7), 
    .CH8(CH8), .CH9(CH9), .CH10(CH10), .CH11(CH11), .CH12(CH12), .CH13(CH13), .CH14(CH14), .CH15(CH15), 
	 ///////////////////////
	 .bclkout(bclkout),
	 .trgin(app_trgin),
	 .trgout(nim_out),
	 .trgout0(trg0),
	 ///////////////////////
    .txreq(ro_txreq), 
    .txdone(ro_txdone), 
    .txack(ro_txack), 
    .txdata(ro_txdata), 
    .txlength(ro_txlength), 
    .txstart(ro_txstart), 
    .txstop(ro_txstop), 
    .txdstrdy(ro_txdata_rdy), 
    .txendframe(frameEndEvent), 
    .regs(appregs)
    );


OBUFDS #(
      .IOSTANDARD("LVDS_25") 	// Specify the output I/O standard
   ) OBUFDS_bclock (
      .O(bclk_p),   			// Diff_p output (connect directly to top-level port)
      .OB(bclk_n),  			// Diff_n output (connect directly to top-level port)
      .I(bclkout)      				// Buffer input 
   );
	 
	 
endmodule
