`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:29:22 07/27/2012 
// Design Name: 
// Module Name:    dtcctf_clkunit 
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
module dtcctf_clkunit(
	clk0, rstn,
	// dtc clock
	dtcclk,
	dtcclk_ok, dtcclk_locked, dtcclk_out,
	// slow control outputs
	dtcclk_measure_val,
	dtcclk_status,
	dtcclk_measure_dv,
	cfg	// not yet used
    );
	input clk0, rstn;
	// dtc clock
	input dtcclk;
	output dtcclk_ok, dtcclk_out, dtcclk_locked;
	output [15:0] dtcclk_measure_val;
	output [5:0]  dtcclk_status;
	output dtcclk_measure_dv;
	reg [15:0] dtcclk_measure_val;
	reg [5:0]  dtcclk_status;
	input [7:0] cfg;
	
	parameter SIMULATION = 0;
	 
	//DTC clk PLL
	wire DTC0CLK_CLKFB, DTC0CLK_CLKOUT0, DTC0CLK_CLKIN, DTC0CLK_RST;
   PLL_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // "HIGH", "LOW" or "OPTIMIZED" 
      .CLKFBOUT_MULT(20),        // Multiplication factor for all output clocks
      .CLKFBOUT_PHASE(0.0),     // Phase shift (degrees) of all output clocks
      .CLKIN_PERIOD(25.000),     // Clock period (ns) of input clock on CLKIN
      .CLKOUT0_DIVIDE(20),       // Division factor for CLKOUT0 (1 to 128)
      .CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.01 to 0.99)
      .CLKOUT0_PHASE(0.0),      // Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
      .COMPENSATION("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", 
                                //   "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", 
                                //   "DCM2PLL", "PLL2DCM" 
      .DIVCLK_DIVIDE(1),        // Division factor for all clocks (1 to 52)
      .REF_JITTER(0.100)        // Input reference jitter (0.000 to 0.999 UI%)
   ) PLL_BASE_inst (
      .CLKFBOUT(DTC0CLK_CLKFB),      // General output feedback signal
      .CLKOUT0(DTC0CLK_CLKOUT0),        // One of six general clock output signals
      .LOCKED(dtcclk_locked),          // Active high PLL lock signal
      .CLKFBIN(DTC0CLK_CLKFB),        // Clock feedback input
      .CLKIN(DTC0CLK_CLKIN),            // Clock input
      .RST(DTC0CLK_RST)                 // Asynchronous PLL reset
   );

   BUFG BUFG_DTC0CLK (     .O(DTC0CLK_CLKIN),       .I(dtcclk)  );
//   BUFG BUFG_DTC0CLKout (     .O(dtcclk_out),       .I(DTC0CLK_CLKOUT0)  );
	assign dtcclk_out = DTC0CLK_CLKOUT0;
	
	reg dtcclk_ok_r;
	wire 	dtcclk_measure_reset;
	wire [15:0] dtcclk_measure_val_i, sysrstreg;
	wire [5:0]  dtcclk_status_i;
	wire [7:0]  dtcclk_measure_cfg;
	wire dtcclk_measure_dv_;

	assign dtcclk_measure_reset = (~ rstn);
//	assign dtcclk_measure_cfg = 8'h00;
	assign dtcclk_measure_cfg = cfg;

	clock_measure #( .SIMULATION(SIMULATION)) dtcclk_measure (
		 .rst(dtcclk_measure_reset), 
		 .clk(clk0), 
		 .clkin(DTC0CLK_CLKIN), 
		 .cfg(dtcclk_measure_cfg), 
		 .clock_measure(dtcclk_measure_val_i), 
		 .clock_measure_dv(dtcclk_measure_dv_i), 
		 .clock_status(dtcclk_status_i)
		 );

	wire dtcclk_ok_i;
	reg [5:0] dtcclk_measure_dvq;
	reg [15:0] dtcclk_count;
	
	assign dtcclk_ok_i = dtcclk_status_i[2];
	
   always @(posedge clk0 or posedge dtcclk_measure_reset)
      if (dtcclk_measure_reset) begin
         dtcclk_status <= 6'b000000;
         dtcclk_measure_dvq <= 5'b00000;
         dtcclk_measure_val <= 15'h0000;
			dtcclk_count <= 16'h0000;
			dtcclk_ok_r <= 1'b0;
      end else begin
			dtcclk_measure_dvq <= {dtcclk_measure_dvq[3:0], dtcclk_measure_dv_i};
			if (dtcclk_measure_dv_i) begin
				if (!dtcclk_ok_i) begin
					dtcclk_count <= 16'h0000;
					dtcclk_ok_r <= 1'b0;
				end 
				else if (dtcclk_count < 2000) begin		// ~ 500 ms
					dtcclk_count  <= dtcclk_count + 1;
					dtcclk_ok_r <= 1'b0;
				end 
				else begin
					dtcclk_ok_r <= 1'b1;
				end 
			end
			if (dtcclk_measure_dv_i) begin
				dtcclk_status <= dtcclk_status_i;
				dtcclk_measure_val <= dtcclk_measure_val_i;
			end
      end

	assign dtcclk_measure_dv = dtcclk_measure_dvq[4] | dtcclk_measure_dvq[3] | dtcclk_measure_dvq[2] | dtcclk_measure_dvq[1] | dtcclk_measure_dvq[0];
	assign dtcclk_ok = dtcclk_ok_r;

	assign DTC0CLK_RST = (~rstn) | (~dtcclk_ok_r);

endmodule
