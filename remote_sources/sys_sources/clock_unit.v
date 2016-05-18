`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:20:18 02/15/2011 
// Design Name: 
// Module Name:    clock_unit 
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
module clock_unit(
    input clk_osc_N,
    input clk_osc_P,
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
	

// CLK es de (clk_osc/2)*(2/5) = 40 MHz	
	BUFG bufg_dcm0 (.O (clk),.I (clkfx));

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
