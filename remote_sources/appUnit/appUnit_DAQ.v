`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:15:15 03/08/2011 
// Design Name: 
// Module Name:    appUnit 
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
module appUnit_DAQ(
    input clk,    clk125,    clk10M,    rstn,
	input forceBclkRst,
	// ctrl
	input evbld_apz,					// APZ/ADC switch
	input [7:0] cfg_roenable,
	input api_reset,
	input [3:0] apv_select,
	// trigger
	input ro_trigger,
	// ADC interface
	input [11:0]	CH0, CH1, CH2, CH3, CH4, CH5, CH6, CH7,
	input [11:0]	CH8, CH9, CH10, CH11, CH12, CH13, CH14, CH15,
	// APZ interface
	input api_busy, api_ready,
	input [255:0] api_data, api_wordcount,
	output [15:0] api_read_out,
	//
	output bclkout,
	output btrgout,
	input trgin,
	output trgout, trgout0,
	// tx interface
	output txreq, txdone, txstart, txstop,
	input txack, txdstrdy, txendframe,
	output [7:0] txdata,
	output [15:0] txlength,
	// cfg
//	input [511:0] regs
	input [1023:0] regs
    );

parameter 	BCLK_INVERT = 0;

`include "../sc_sources/verilog_functions_sc.vh"

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// eventbuild registers	declarations 
	wire [7:0]  cfg_evbld_mode, cfg_evbld_eventInfoType;
	wire [15:0] cfg_evbld_datalength, cfg_evbld_chmask;
	wire [31:0] frameCounterOut, cfg_evbld_eventInfoData;
// eventbuild registers
	assign cfg_evbld_chmask		   = ireg16( 8, regs);
	assign cfg_evbld_datalength	   = ireg16( 9, regs);
	assign cfg_evbld_mode		   = ireg8( 10, regs);
	assign cfg_evbld_eventInfoType = ireg8( 11, regs);
	assign cfg_evbld_eventInfoData = ireg32(12, regs);

///////////////////////////////// APZ data path ///////////////////////////////////

wire evbld_earlyStart, evbld_ren, evbld_nextchPointer_valid;
wire [3:0] evbld_chPointer, evbld_nextchPointer;
wire [15:0] apz_datalength, evbld_rReady_apz;
wire [7:0] apz_dataout;

apz_data_switch apz_data_switch (
    .clk(clk125),     .reset(api_reset), 
	 // eventbuild interface
    .chPointer(evbld_chPointer), 
    .nextchPointer(evbld_nextchPointer), 
    .nextchPointer_valid(evbld_nextchPointer_valid), 
    .earlyStart(evbld_earlyStart), 
    .data_out(apz_dataout), 
    .read_from_evbld(evbld_ren),
    .wordcount_out(apz_datalength), 
	 // APZ processor interface
    .data_in(api_data), 
    .wordcount_in(api_wordcount), 
    .read_to_apz(api_read_out)
    );
assign api_output_enable = 16'hFF;
// mask calibration activity
assign evbld_rReady_apz = api_busy ? 16'h0000 : api_ready | (~cfg_evbld_chmask);

/////////////////////////////// APZ bypass ////////////////////////////////////
wire [23:0] timestamp;
wire [12:0] evbld_rAddr;
wire [7:0] adc_dataout;
wire [15:0] adc_chmask, evbld_rReady_adc, adc_datalength;

adc_data_switch adc_data_switch (
    .rstn(rstn),     .clk(clk),     .eclk(clk125), 
	 // ctrl
		 .trgin(ro_trigger), 	 .enable(cfg_roenable[0]),
		 .chSelect(apv_select), 
		 .datalength(cfg_evbld_datalength), 
		 .eventInfoType(cfg_evbld_eventInfoType), 
	 // data from ADC
		 .data_in({CH8, CH9, CH10, CH11, CH12, CH13, CH14, CH15, CH0, CH1, CH2, CH3, CH4, CH5, CH6, CH7}), 
	 // eventbuild interface
		 // inputs
		 .rAddr(evbld_rAddr), 
		 .read_from_evbld(evbld_ren), 
		 .rDone_from_evbld(txstop), 
		 // outputs
		 .rReady_to_evbld(evbld_rReady_adc), 
		 .data_out(adc_dataout), 
		 .datalength_to_evbld(adc_datalength),
	 // trigger timestamp output
		 .timestamp(timestamp), 
	 // channel mask generated from chSelect
		 .chmask_out(adc_chmask)
    );

/////////////////////////// EVENTBUILD /////////////////////////////////

// trigger ID counter
	reg [31:0] triggerID;
	always @(posedge clk or negedge rstn)
			if (!rstn) begin
				triggerID <= 32'h00000000;
			end else if (cfg_roenable[0] == 1'b0) begin
				triggerID <= 32'h00000000;
			end else if (ro_trigger == 1'b1) begin
				triggerID <= triggerID + 1;
			end 

wire [31:0] evbld_eventInfoData;
assign evbld_eventInfoData = 	(cfg_evbld_eventInfoData[15:8] == 8'h01) ? {triggerID[15:0], cfg_evbld_datalength} :
										(cfg_evbld_eventInfoData[15:8] == 8'h02) ? triggerID :
										{cfg_evbld_eventInfoData[31:16], cfg_evbld_datalength};
wire [7:0] cfg_evbld_eventInfoType_i;
assign cfg_evbld_eventInfoType_i = evbld_apz ? 8'h02 : 8'h00;

/////////////////////////// eventbuild mux /////////////////////////////////
wire [15:0] cfg_evbld_chmask_i, evbld_datalength, evbld_rReady;
wire [7:0] evbld_data_in;

assign evbld_rReady 			= evbld_apz ? evbld_rReady_apz 	: evbld_rReady_adc;
assign evbld_data_in 		= evbld_apz ? apz_dataout 			: adc_dataout;
assign evbld_datalength		= evbld_apz ? apz_datalength 		: adc_datalength;
assign cfg_evbld_chmask_i	= evbld_apz ? cfg_evbld_chmask	: adc_chmask;

////////////////////////////////////////////////////////////////////////////

wire udpPauseData;
assign udpPauseData = ~txdstrdy;

udpEventBuildAPZ udpEventBuildAPZ (
    .clk(clk125),     .rstn(rstn),
	 // frame info & config
    .mode(cfg_evbld_mode), 
    .timestamp(timestamp), 
    .frameCounterOut(frameCounterOut), 
    .eventInfoType(cfg_evbld_eventInfoType_i), 
    .eventInfoData(evbld_eventInfoData), 
    .chmask(cfg_evbld_chmask_i),
	 // FE interface
    .rReady(evbld_rReady),
	 .earlyStart(evbld_earlyStart),
    .ren(evbld_ren), 
    .data_in(evbld_data_in), 
    .datalength(evbld_datalength), 
    .chPointer_out(evbld_chPointer), 
    .nextchPointer_out(evbld_nextchPointer), 
    .nextchPointer_valid(evbld_nextchPointer_valid), 
    .rAddr(evbld_rAddr), 
	 // TX interface
    .txreq(txreq), 
    .txdone(txdone), 
    .txack(txack), 
    .dataout(txdata), 
    .udpLength(txlength), 
    .udpPauseData(udpPauseData), 
    .frameEndEvent(txendframe), 
    .udpStartTx(txstart), 
    .udpStopTx(txstop)
    );
















// 
	wire [7:0] cfg_bclk_mode, cfg_bclk_trgburst;
	wire [15:0] cfg_bclk_freq, cfg_bclk_trgdelay,  cfg_bclk_tpdelay , cfg_bclk_rosync;
//	wire [7:0] cfg_roenable;
//
	assign cfg_bclk_mode 		= ireg8( 0, regs);
	assign cfg_bclk_trgburst 	= ireg8( 1, regs);
	assign cfg_bclk_freq		= ireg16( 2, regs);
	assign cfg_bclk_trgdelay	= ireg16( 3, regs);
	assign cfg_bclk_tpdelay		= ireg16( 4, regs);
	assign cfg_bclk_rosync		= ireg16( 5, regs);
//	assign cfg_roenable			= ireg8( 15, regs);

wire [15:0] trgcounter;

//reg [7:0] data;
//   always @(posedge clk125 or negedge rstn)
//      if (!rstn) begin
//         data <= 8'h00;
//      end else 
//         data <= data + 1;


//wire udpPauseData, ro_trigger, ro_trigger_i;
//assign ro_trigger_i = (trgcounter == cfg_bclk_rosync) ? 1'b1 : 1'b0;
//assign ro_trigger = ro_trigger_i;
////assign ro_trigger = ro_trigger_i & cfg_roenable;
//assign udpPauseData = ~txdstrdy;


//roLayer_v2 roLayer (
//    .rstn(rstn), 
//    .clk(clk), 
//    .trgin(ro_trigger), 
//	 .enable(cfg_roenable[0]),
//    .data0({4'b0000, CH7}),     .data1({4'b0000, CH6}),     .data2({4'b0000, CH5}),     .data3({4'b0000, CH4}), 
//    .data4({4'b0000, CH3}),     .data5({4'b0000, CH2}),     .data6({4'b0000, CH1}),     .data7({4'b0000, CH0}), 
//    .data8({4'b0000, CH15}),     .data9({4'b0000, CH14}),     .data10({4'b0000, CH13}),     .data11({4'b0000, CH12}), 
//    .data12({4'b0000, CH11}),     .data13({4'b0000, CH10}),     .data14({4'b0000, CH9}),     .data15({4'b0000, CH8}), 
//    .frameCounterOut(frameCounterOut), 
//	 
//    .eclk				(clk125), 
//    .dataout			(txdata), 
//    .udpLength			(txlength), 
//    .udpPauseData		(udpPauseData), 
//    .frameEndEvent	(txendframe), 
//    .txreq				(txreq), 
//    .txdone				(txdone), 
//    .txack				(txack), 
//    .udpStartTx		(txstart), 
//    .udpStopTx			(txstop), 
//    .udpBuildMode		(cfg_evbld_mode), 
//    .datalength		(cfg_evbld_datalength), 
//    .eventInfoType	(cfg_evbld_eventInfoType), 
//    .eventInfoData	(evbld_eventInfoData), 
//    .chmask				(cfg_evbld_chmask)
//    );

bclk_ctrl #(.BCLK_INVERT(BCLK_INVERT) ) bclk_ctrl (
    .clk(clk),     .clk2x(clk), 
    .rstn(rstn), 
    .trgin			(trgin), 
    .forceRst		(forceBclkRst), 
    .reg0			(cfg_bclk_mode), 
    .reg1d			(cfg_bclk_freq), 
    .reg2d			(cfg_bclk_trgdelay), 
    .reg3d			( cfg_bclk_tpdelay ), 
    .reg4			(cfg_bclk_trgburst), 
    .bclkout		(bclkout), 
    .btrgout		(btrgout), 
    .trgout			(trgout), 
    .syncPulse(), 
    .syncPulse0(), 
    .trgcounter	(trgcounter)
    );

assign trgout0 = (trgcounter == 0) ? 1'b1 : 1'b0;

endmodule
