`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:07:54 07/27/2012 
// Design Name: 
// Module Name:    dtcctf_phy0 
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
module dtcctf_phy0(
		input [1:0] DTCIN_P, DTCIN_N,
		input [1:0] DTC2IN_P, DTC2IN_N,
		output [1:0] DTCOUT_P, DTCOUT_N,
		output [1:0] DTC2OUT_P, DTC2OUT_N,
		input trgin, clkin,
		output dtc_trg, dtc_clk,
		input [3:0] cfg
    );

	// DTC lvds buffers
	wire [1:0] dtcin, dtcout;
	wire [1:0] dtc2in, dtc2out;
	genvar x;
	generate
		for (x=0; x < 2; x=x+1) 
		begin: dtclinks
			IBUFDS #(      .DIFF_TERM("TRUE"),      .IOSTANDARD("LVDS_25")     
			) IBUFDS_dtc (      .O(dtcin[x]), .I(DTCIN_P[x]), .IB(DTCIN_N[x]) );
			OBUFDS #(      .IOSTANDARD("LVDS_25") 
			) OBUFDS_dtc (      .O(DTCOUT_P[x]), .OB(DTCOUT_N[x]), .I(dtcout[x])   );
			IBUFDS #(      .DIFF_TERM("TRUE"),      .IOSTANDARD("LVDS_25")     
			) IBUFDS_dtc2 (      .O(dtc2in[x]), .I(DTC2IN_P[x]), .IB(DTC2IN_N[x]) );
			OBUFDS #(      .IOSTANDARD("LVDS_25") 
			) OBUFDS_dtc2 (      .O(DTC2OUT_P[x]), .OB(DTC2OUT_N[x]), .I(dtc2out[x])   );
		end
	endgenerate

	assign dtcout[1] = trgin;
   ODDR #(
      .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_dtc0clkout (
      .Q(dtcout[0]),   // 1-bit DDR output
      .C(clkin),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(1'b1), // 1-bit data input (positive edge)
      .D2(1'b0), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );
	assign dtc2out[1] = ~trgin;
   ODDR #(
      .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE" 
      .INIT(1'b0),    // Initial value of Q: 1'b0 or 1'b1
      .SRTYPE("SYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) ODDR_dtc2clkout (
      .Q(dtc2out[0]),   // 1-bit DDR output
      .C(clkin),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D1(1'b1), // 1-bit data input (positive edge)
      .D2(1'b0), // 1-bit data input (negative edge)
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );

	wire dtcin_swaplanes, dtcin_swapports, dtctrg_inh, dtcclk_inh;

	wire dtc0trg, dtc0clk, dtc1trg, dtc1clk;
	wire dtc_trg_i, dtc_clk_i;
	assign dtc0trg = (dtcin_swaplanes) ? dtcin[0] : dtcin[1];
	assign dtc0clk = (dtcin_swaplanes) ? dtcin[1] : dtcin[0];
	assign dtc1trg = (dtcin_swaplanes) ? dtc2in[0] : dtc2in[1];
	assign dtc1clk = (dtcin_swaplanes) ? dtc2in[1] : dtc2in[0];

	assign dtc_trg_i = (dtcin_swapports) ? dtc0trg : dtc1trg;
	assign dtc_clk_i = (dtcin_swapports) ? dtc0clk : dtc1clk;
	
	assign dtc_trg = dtc_trg_i & (!dtctrg_inh);
	assign dtc_clk = dtc_clk_i & (!dtcclk_inh);
	
	assign dtcclk_inh = cfg[0];
	assign dtctrg_inh = cfg[1];
	assign dtcin_swapports = cfg[2];
	assign dtcin_swaplanes = cfg[3];

endmodule
