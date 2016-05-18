`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:57:32 07/27/2012 
// Design Name: 
// Module Name:    dtcctf_unit 
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
module dtcctf_unit(
		// system clock and reset
		input clk0, rstn,
		input [15:0] cfg,
		// DTC IOs
		input [1:0] DTCIN_P, DTCIN_N,
		input [1:0] DTC2IN_P, DTC2IN_N,
		output [1:0] DTCOUT_P, DTCOUT_N,
		output [1:0] DTC2OUT_P, DTC2OUT_N,
		// main clock and trg for CTF emulation on the DTC outputs
		input trgin, clkin,
		// clock and trigger from CTF
		output dtcclk_ok, dtcclk_out, dtctrg_out, dtcclk_locked,
		// clock measure for sc
		output [15:0] dtcclk_measure_val,
		output [5:0]  dtcclk_status,
		output dtcclk_measure_dv
    );

parameter SIMULATION = 0;

wire dtc_trg, dtc_clk;
wire [3:0] dtcctf_phy_cfg;
wire [7:0] dtcctf_clkunit_cfg;
wire dtctrg_invert;

	assign dtcctf_phy_cfg = cfg[3:0];
	assign dtcctf_clkunit_cfg = cfg[15:8];
	assign dtctrg_invert = cfg[4];
	
	assign dtctrg_out = (dtc_trg ^ dtctrg_invert) & dtcclk_ok;
	
// Instantiate the module
dtcctf_phy0 dtcctf_phy0 (
    .DTCIN_P(DTCIN_P), 
    .DTCIN_N(DTCIN_N), 
    .DTC2IN_P(DTC2IN_P), 
    .DTC2IN_N(DTC2IN_N), 
    .DTCOUT_P(DTCOUT_P), 
    .DTCOUT_N(DTCOUT_N), 
    .DTC2OUT_P(DTC2OUT_P), 
    .DTC2OUT_N(DTC2OUT_N), 
    .trgin(trgin), 
    .clkin(clkin), 
    .dtc_trg(dtc_trg), 
    .dtc_clk(dtc_clk), 
    .cfg(dtcctf_phy_cfg)
    );
dtcctf_clkunit #( .SIMULATION(SIMULATION)) dtcctf_clkunit (
    .clk0(clk0), 
    .rstn(rstn), 
	 //
    .dtcclk(dtc_clk), 
    .dtcclk_ok(dtcclk_ok), 
    .dtcclk_out(dtcclk_out), 
    .dtcclk_locked(dtcclk_locked), 
	 //
    .dtcclk_measure_val(dtcclk_measure_val), 
    .dtcclk_status(dtcclk_status), 
    .dtcclk_measure_dv(dtcclk_measure_dv),
	 //	 
    .cfg(dtcctf_clkunit_cfg)
    );
	 
	 

endmodule
