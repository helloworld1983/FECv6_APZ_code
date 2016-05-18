`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:02:09 07/27/2012 
// Design Name: 
// Module Name:    ethmclk 
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
module ethmclk(
	input ethrxclk, ethrxclk_rst,
	output clk40e, ethrxclk_ok, ethrxclk_locked
    );
// Ethernet recovered clock
wire ethrxfb, ethrxclk_bufg;
   PLL_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // "HIGH", "LOW" or "OPTIMIZED" 
      .CLKFBOUT_MULT(8),        // Multiplication factor for all output clocks
      .CLKFBOUT_PHASE(0.0),     // Phase shift (degrees) of all output clocks
      .CLKIN_PERIOD(8.000),     // Clock period (ns) of input clock on CLKIN
      .CLKOUT0_DIVIDE(25),       // Division factor for CLKOUT0 (1 to 128)
      .CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.01 to 0.99)
      .CLKOUT0_PHASE(0.0),      // Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
      .COMPENSATION("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", 
                                //   "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", 
                                //   "DCM2PLL", "PLL2DCM" 
      .DIVCLK_DIVIDE(1),        // Division factor for all clocks (1 to 52)
      .REF_JITTER(0.100)        // Input reference jitter (0.000 to 0.999 UI%)
   ) PLL_BASE_ethclk (
      .CLKFBOUT(ethrxfb),      // General output feedback signal
      .CLKOUT0(clk40e),        // One of six general clock output signals
      .LOCKED(ethrxclk_locked),          // Active high PLL lock signal
      .CLKFBIN(ethrxfb),        // Clock feedback input
      .CLKIN(ethrxclk_bufg),            // Clock input
      .RST(ethrxclk_rst)                 // Asynchronous PLL reset
   );
   BUFG BUFG_ethrxclk (     .O(ethrxclk_bufg),       .I(ethrxclk)  );


assign ethrxclk_ok = ethrxclk_locked;


endmodule
