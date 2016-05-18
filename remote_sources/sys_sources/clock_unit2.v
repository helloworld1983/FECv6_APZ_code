`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:21:15 06/23/2011 
// Design Name: 
// Module Name:    clock_unit2 
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
module clock_unit2(
    input clk_osc_N,
    input clk_osc_P,
	 input sru_clkin,
    output clk,
    output clk10M, clk_refiod,
    output clk_locked,
    input rstn
    );

wire clk_osc, clk_dcmfb, clk0, clkfx, sclk_bufr;

	IBUFGDS #(
      .DIFF_TERM("TRUE"), 		// Differential Termination
      .IOSTANDARD("DEFAULT") 	// Specifies the I/O standard for this buffer
   ) IBUFGDS_clk (
      .O(clk_osc),  		// Clock buffer output
      .I(clk_osc_N),  	// Diff_p clock buffer input
      .IB(clk_osc_P) 	// Diff_n clock buffer input
   );

	BUFG bufg_dcmfb (.O (clk_dcmfb),.I (clk0));

   DCM_ADV #(
		.CLKDV_DIVIDE(5), 							// Divide by: 1.5,2.0,2.5,3.0,3.5...
		.CLKFX_DIVIDE(5),  							// Can be any integer from 1 to 32
      .CLKFX_MULTIPLY(2),	 						// Can be any integer from 2 to 32
      .CLKIN_PERIOD(5.00), 						// Specify period of input clock in ns from 1.25 to 1000.00
		.CLKIN_DIVIDE_BY_2("TRUE"), 				// TRUE/FALSE to enable CLKIN divide by two feature
      .CLKOUT_PHASE_SHIFT("NONE"), 				// Specify phase shift mode of NONE, FIXED, 
															// VARIABLE_POSITIVE, VARIABLE_CENTER or DIRECT
      .CLK_FEEDBACK("1X"),  						// Specify clock feedback of NONE, 1X or 2X
      .DCM_AUTOCALIBRATION("TRUE"), 			// DCM calibration circuitry "TRUE"/"FALSE" 
      .DCM_PERFORMANCE_MODE("MAX_SPEED"), 	// Can be MAX_SPEED or MAX_RANGE
      .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), 	// SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
															// an integer from 0 to 15
      .DFS_FREQUENCY_MODE("LOW"), 				// HIGH or LOW frequency mode for frequency synthesis
      .DLL_FREQUENCY_MODE("LOW"), 				// LOW, HIGH, or HIGH_SER frequency mode for DLL
      .DUTY_CYCLE_CORRECTION("TRUE"), 			// Duty cycle correction, "TRUE"/"FALSE" 
      .FACTORY_JF(16'hf0f0), 						// FACTORY JF value suggested to be set to 16'hf0f0
      .PHASE_SHIFT(0), 								// Amount of fixed phase shift from -255 to 1023
      .SIM_DEVICE("VIRTEX5"), 					// Set target device, "VIRTEX4" or "VIRTEX5" 
      .STARTUP_WAIT("FALSE")  					// Delay configuration DONE until DCM LOCK, "TRUE"/"FALSE" 
   ) DCM_ADV_clk (
		.CLK0(clk0),         						// 0 degree DCM CLK output
		.CLKFX(clkfx),
		//.CLKDV(clkfx),	
      .LOCKED(clk_locked),     					// DCM LOCK status output
      .CLKFB(clk_dcmfb),       					// DCM clock feedback
      .CLKIN(clk_osc),       						// Clock input (from IBUFG, BUFG or DCM)
      .RST(!rstn)            						// DCM asynchronous reset input
   );
	
wire sruCLKFBOUT, sruCLKOUT0, sruclk_LOCKED, RST_sruclk;

// CLK es de (clk_osc/2)*(2/5) = 40 MHz	
	BUFG bufg_dcm0 (.O (clk),.I (clkfx));

   PLL_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // "HIGH", "LOW" or "OPTIMIZED" 
      .CLKFBOUT_MULT(16),        // Multiplication factor for all output clocks
      .CLKFBOUT_PHASE(0.0),     // Phase shift (degrees) of all output clocks
      .CLKIN_PERIOD(25.000),     // Clock period (ns) of input clock on CLKIN
      .CLKOUT0_DIVIDE(16),       // Division factor for CLKOUT0 (1 to 128)
      .CLKOUT0_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT0 (0.01 to 0.99)
      .CLKOUT0_PHASE(0.0),      // Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
      .CLKOUT1_DIVIDE(2),       // Division factor for CLKOUT1 (1 to 128)
      .CLKOUT1_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT1 (0.01 to 0.99)
      .CLKOUT1_PHASE(0.0),      // Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
      .CLKOUT2_DIVIDE(2),       // Division factor for CLKOUT2 (1 to 128)
      .CLKOUT2_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT2 (0.01 to 0.99)
      .CLKOUT2_PHASE(0.0),      // Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
      .CLKOUT3_DIVIDE(2),       // Division factor for CLKOUT3 (1 to 128)
      .CLKOUT3_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT3 (0.01 to 0.99)
      .CLKOUT3_PHASE(0.0),      // Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
      .CLKOUT4_DIVIDE(2),       // Division factor for CLKOUT4 (1 to 128)
      .CLKOUT4_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT4 (0.01 to 0.99)
      .CLKOUT4_PHASE(0.0),      // Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
      .CLKOUT5_DIVIDE(2),       // Division factor for CLKOUT5 (1 to 128)
      .CLKOUT5_DUTY_CYCLE(0.5), // Duty cycle for CLKOUT5 (0.01 to 0.99)
      .CLKOUT5_PHASE(0.0),      // Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
      .COMPENSATION("SYSTEM_SYNCHRONOUS"), // "SYSTEM_SYNCHRONOUS", 
                                //   "SOURCE_SYNCHRONOUS", "INTERNAL", "EXTERNAL", 
                                //   "DCM2PLL", "PLL2DCM" 
      .DIVCLK_DIVIDE(1),        // Division factor for all clocks (1 to 52)
      .REF_JITTER(0.500)        // Input reference jitter (0.000 to 0.999 UI%)
   ) PLL_BASE_SRU (
      .CLKFBOUT(sruCLKFBOUT),      // General output feedback signal
      .CLKOUT0(sruCLKOUT0),        // One of six general clock output signals
      .CLKOUT1(),        // One of six general clock output signals
      .CLKOUT2(),        // One of six general clock output signals
      .CLKOUT3(),        // One of six general clock output signals
      .CLKOUT4(),        // One of six general clock output signals
      .CLKOUT5(),        // One of six general clock output signals
      .LOCKED(sruclk_LOCKED),          // Active high PLL lock signal
      .CLKFBIN(sruCLKFBOUT),        // Clock feedback input
      .CLKIN(sru_clkin),            // Clock input
      .RST(RST_sruclk)                 // Asynchronous PLL reset
   );

BUFR #(
	.BUFR_DIVIDE("4"), 		// "BYPASS", "1", "2", "3", "4", "5", "6", "7", "8" 
	.SIM_DEVICE("VIRTEX5")  // Specify target device, "VIRTEX4", "VIRTEX5", "VIRTEX6" 
) BUFR_sclk (
	.O(sclk_bufr),				// Clock buffer output
	.CE(clk_locked),   		// Clock enable input
	.CLR(!rstn), 				// Clock buffer reset input
	.I(clk)      				// Clock buffer input
);
BUFG bufg_clk10M(.O(clk10M),.I(sclk_bufr));
// Referencia IODELAYs - 200 MHz
	BUFG bufg_dcmiodelay (.O (clk_refiod),.I (clk_osc));


endmodule
