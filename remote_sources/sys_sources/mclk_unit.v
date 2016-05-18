`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:11:54 07/27/2012 
// Design Name: 
// Module Name:    mclk_unit 
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
module mclk_unit(
	input clk0, rstn,
	// dtc clock
	input dtc_clk, dtcclk_locked, dtcclk_ok,
	// ethernet clock
	input clk40e,ethrxclk_ok, ethrxclk_locked,
	// output clock
	output clk,
	//
	input [7:0] mclkmux_cfg,
	output [1:0] mclkmux_clksel,
	output mclkmux_app_rst
    );

mclkmux_fsm mclkmux_fsm (
    .clk(clk0), 
    .rstn(rstn), 
    .cfg(mclkmux_cfg), 
    .dtcclk_ok(dtcclk_ok), 
    .dtcclk_locked(dtcclk_locked), 
    .ethclk_ok(ethrxclk_ok), 
    .ethclk_locked(ethrxclk_locked), 
    .clksel(mclkmux_clksel), 
    .app_rst(mclkmux_app_rst)
    );

wire clk00;	 
// using simple mux, without edge detection	 
  BUFGCTRL #(
      .INIT_OUT(0),  // Inital value of 0 or 1 after configuration
      .PRESELECT_I0("TRUE"), // "TRUE" or "FALSE" set the I0 input after configuration
      .PRESELECT_I1("FALSE")  // "TRUE" or "FALSE" set the I1 input after configuration
   ) BUFGMUX_CTRL_1 (
      .O(clk00),     // 1-bit output
      .CE0(1'b1), // 1-bit clock enable 0
      .CE1(1'b1), // 1-bit clock enable 1
      .I0(clk0),   // 1-bit clock 0 input
      .I1(dtc_clk),   // 1-bit clock 1 input
      .IGNORE0(1'b1), // 1-bit ignore 0 input
      .IGNORE1(1'b1), // 1-bit ignore 1 input
      .S0(!mclkmux_clksel[0]),   // 1-bit select 0 input
      .S1(mclkmux_clksel[0])    // 1-bit select 1 input
   );
//	assign dtcclk_sel = DTC0CLK_LOCKED & (!dtcclk_inh);
//   BUFGMUX_CTRL BUFGMUX_CTRL_1 (
//      .O(clk00),    // Clock MUX output
//      .I0(clk0),  // Clock0 input
//      .I1(DTC0CLK_CLK),  // Clock1 input
////      .S(dtcclk_sel)     // Clock select input
//      .S(mclkmux_clksel[0])     // Clock select input
//   );
   BUFGMUX_CTRL BUFGMUX_CTRL_0 (
      .O(clk),    // Clock MUX output
      .I0(clk00),  // Clock0 input
      .I1(clk40e),  // Clock1 input
      .S(mclkmux_clksel[1])     // Clock select input
   );


endmodule
