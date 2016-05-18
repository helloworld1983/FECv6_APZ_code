`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:18:33 03/15/2011 
// Design Name: 
// Module Name:    ADC_clks 
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
module ADC_clks(
	input clk, clk10M, rstn,
	input adcsclk_disable,
	output ADCLK_P, ADCLK_N, sclk
    );
	// ADCs input clk
	wire adcclk_out;
   ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_inst (
      .Q(adcclk_out),   // 1-bit DDR output
      .C(clk),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(1'b1), // 1-bit data input (positive edge)
      .D2(1'b0), // 1-bit data input (negative edge)
      .R(!rstn),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );
	
	OBUFDS #(
      .IOSTANDARD("LVDS_25") 	// Specify the output I/O standard
   ) OBUFDS_ADCLK (
      .O(ADCLK_P),   			// Diff_p output (connect directly to top-level port)
      .OB(ADCLK_N),  			// Diff_n output (connect directly to top-level port)
      .I(adcclk_out)      				// Buffer input 
   );

// ADCs clk
	// Control
//	wire sclk_i;
//	BUFG bufg_sclk(.O(sclk_i),.I(sclk_bufr));
   ODDR #(
      .DDR_CLK_EDGE("SAME_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_sclk_inst (
      .Q(sclk),   // 1-bit DDR output
      .C(clk10M),   // 1-bit clock input
      .CE(~adcsclk_disable), // 1-bit clock enable input
      .D1(1'b1), // 1-bit data input (positive edge)
      .D2(1'b0), // 1-bit data input (negative edge)
      .R(!rstn),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );

endmodule
