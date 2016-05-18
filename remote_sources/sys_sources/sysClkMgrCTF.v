`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:59:01 03/31/2015 
// Design Name: 
// Module Name:    sysClkMgrCTF 
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
module sysClkMgrCTF(
	input	clk_osc_P,	clk_osc_N,							//% [SYSTEM IO] local clock oscillator (200 MHz)
	input clk125, ethrxclk,
	input rstn,
	
	input [1:0] DTCIN_P, DTCIN_N,							//% [SYSTEM IO] DTC LVDS pads
	input [1:0] DTC2IN_P, DTC2IN_N,						//% [SYSTEM IO] DTC LVDS pads
	output [1:0] DTCOUT_P, DTCOUT_N,						//% [SYSTEM IO] DTC LVDS pads
	output [1:0] DTC2OUT_P, DTC2OUT_N,					//% [SYSTEM IO] DTC LVDS pads

	output mclkmux_app_rst,
	input trgin, 
	output trgout, 
	
	input [15:0] sysrstreg,
	input [7:0] mclkmux_cfg,
	input [15:0] dtcctf_cfg,
	output [31:0] cfg_out,

	 output clk, clk10M, clk_refiod,						//% [APP INTERNAL] clock signals
	 output dcm_locked										//% [APP INTERNAL] clock signals
    );
	 
	parameter SIMULATION = 0;

	/*! DTC CTF unit signals*/ wire dtcctf_resetn, dtc_clk, dtc_trg, dtcclk_locked, dtcclk_ok;
	// 40MHz clock from ethernet RX CRU 
	wire ethrxclk_ok;
	wire ethrxclk_locked, ethrxclk_rst, clk40e;

	 assign dtcctf_resetn = (rstn) & (!sysrstreg[1]);
	 assign ethrxclk_rst = (~rstn) | sysrstreg[2];

	wire clk0;

	clock_unit #( .G_DEVICE("VIRTEX6") ) clock_unit  
								(   	.clk_osc_N(clk_osc_N),     .clk_osc_P(clk_osc_P), 
										.clk(clk0), .clk_refiod(clk_refiod),    .clk10M(clk10M), 
										.clk_locked(dcm_locked),     .rstn(rstn)
								  );

	/*! DTC CTF unit signals*/ wire [15:0] dtcclk_measure_val;
	/*! DTC CTF unit signals*/ wire [5:0]  dtcclk_status;
	/*! DTC CTF unit signals*/ wire dtcclk_measure_dv;

	//% DTCCTF unit. Retrieves clock and trigger from the DTC LVDS interface when connected to a CTF card.
	dtcctf_unit #( .SIMULATION(SIMULATION)) dtcctf_u (
		 .clk0(clk0),		 .rstn(dtcctf_resetn),		 .cfg(dtcctf_cfg), 
		 //
		 .DTCIN_P(DTCIN_P), 		 .DTCIN_N(DTCIN_N), 
		 .DTC2IN_P(DTC2IN_P),	 .DTC2IN_N(DTC2IN_N), 
		 .DTCOUT_P(DTCOUT_P),	 .DTCOUT_N(DTCOUT_N), 
		 .DTC2OUT_P(DTC2OUT_P),	 .DTC2OUT_N(DTC2OUT_N),
		//	 
		 .trgin(trgin),		 .clkin(clk),
		//
		 .dtcclk_ok(dtcclk_ok), 	 .dtcclk_locked(dtcclk_locked), 
		 .dtcclk_out(dtc_clk), 		 .dtctrg_out(trgout),
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
		
	//% PLL and clock detection circuitry for the clocked recovered from the Ethernet RX line
	ethmclk ethmclk_unit (
		 .ethrxclk(ethrxclk), .ethrxclk_rst(ethrxclk_rst), 
		 .clk40e(clk40e), 	 .ethrxclk_ok(ethrxclk_ok), 	 .ethrxclk_locked(ethrxclk_locked)
		 );
		 
	// Main CLOCK MUX
	wire [1:0] mclkmux_clksel;
	
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

	 assign cfg_out = {dtcclk_measure_out, 2'b00, dtcclk_status_out, 2'b00, mclkmux_clksel, 2'b00, ethrxclk_locked, dtcclk_locked};


endmodule
