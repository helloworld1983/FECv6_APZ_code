`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:15:25 04/03/2012 
// Design Name: 
// Module Name:    ADCcore 
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
module ADCcore
	#(
		parameter [7:0]	DCO_ADJ 	= 8'hFE,
		parameter [11:0] 	DCO_STABLE = 12'hFFF,
		parameter [11:0]	FCO_STABLE = 12'hFFF,
		parameter [11:0]	ADJ_TEST = 12'hFFF,
		parameter [10:0]	ADJ_ADCRST = 11'h3FF,
		
		parameter [11:0]	SIGNAL_LEVEL1 = 12'h7B7,	//1975
	   parameter [11:0]	SIGNAL_LEVEL2 = 12'h81B, 	//2075
		parameter IODELAY_GRP = "IODELAY_ADC"
	)
	(
		// Inputs
		input clk, clk10M, clk_refiod,
		//input rstb, rstb_dcm, dcm_locked
		input rstn_init, rstn, dcm_locked,
//		// ADCs configuracin externa
//		input adc_init, 
//		input [24:0] adc_conf,
//		// DCMs configuracin externa
//		input dcm_init, 
//		input [9:0] dcm_conf,
		
		// ADC1
		input FCO1_P, FCO1_N,
		input DCO1_P, DCO1_N,
		input DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N,
		input DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N,
		// ADC2
		input FCO2_P, FCO2_N,
		input DCO2_P, DCO2_N,
		input DCH9_P, DCH9_N, DCH10_P, DCH10_N, DCH11_P, DCH11_N, DCH12_P, DCH12_N,
		input DCH13_P, DCH13_N, DCH14_P, DCH14_N, DCH15_P, DCH15_N, DCH16_P, DCH16_N,
			
		//Outputs
		output [11:0] CH0, CH1, CH2, CH3, CH4, CH5, CH6, CH7,
		output [11:0] CH8, CH9, CH10, CH11, CH12, CH13, CH14, CH15,

		// ADC1
		output csb1, pwb1,
		// ADC2
		output csb2, pwb2,
		// Both
		output sdata, resetb,
		
		// clocks
		input adcsclk_disable,
		output ADCLK_P, ADCLK_N, sclk,
		
		// Seales de control
		output conf_end,
		
		output DES_run, 
		output [15:0] DES_status, 
		output [5:0] ADCDCM_status
    );
wire resetb_aux;

	 (* IODELAY_GROUP = IODELAY_GRP *)
	 IDELAYCTRL IDELAYCTRL_refiod (
      //.RDY(rdy),       							// 1-bit ready output
      .REFCLK(clk_refiod), 					// 1-bit reference clock input
      .RST(!rstn_init)        						// 1-bit reset input
   );

ADCs_Unit 
#(
	.DCO_ADJ(DCO_ADJ),
	.DCO_STABLE(DCO_STABLE),
	.FCO_STABLE(FCO_STABLE),
	.ADJ_TEST(ADJ_TEST),
	.ADJ_ADCRST(ADJ_ADCRST),
	.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
	.SIGNAL_LEVEL2(SIGNAL_LEVEL2), //2025
	.IODELAY_GRP(IODELAY_GRP)
) ADCs_Unit (
	 // Relojes y reset
	 .clk(clk),						// Reloj principal
    .sclk(clk10M), 					// Reloj de control de los ADCs: 	 20 MHz
    //.clk_refiod(clk_refiod), 	// Reloj de control de los IODELAYs: 200 MHz
    .rstb(rstn_init),.rstb_dcm(rstn), 
	 
	 // Seales de control internas
    // Entradas
	 .adc_init(0), .adc_conf(0), 
    .dcm_init(0),//dcm_init), 
    .dcm_conf(0),//dcm_conf),
	 //.trsf_conf(trsf_conf[5]),
	 // Salidas
	 .conf_end(conf_end), 
    .DES_run(DES_run), .DES_status(DES_status), .DCM_status(ADCDCM_status), 

	 // Seales de entrada de los ADCs
	 // ADC1
	 // Relojes	
	 .FCO1_P(FCO1_P),     .FCO1_N(FCO1_N),
    .DCO1_P(DCO1_P),     .DCO1_N(DCO1_N),
	 // Datos
    .DCH1_P(DCH1_P),     .DCH1_N(DCH1_N), 
    .DCH2_P(DCH2_P),     .DCH2_N(DCH2_N), 
    .DCH3_P(DCH3_P),     .DCH3_N(DCH3_N), 
    .DCH4_P(DCH4_P),	    .DCH4_N(DCH4_N), 
    .DCH5_P(DCH5_P),	    .DCH5_N(DCH5_N), 
    .DCH6_P(DCH6_P),     .DCH6_N(DCH6_N), 
    .DCH7_P(DCH7_P),	    .DCH7_N(DCH7_N), 
    .DCH8_P(DCH8_P),	    .DCH8_N(DCH8_N),
	 
	 // ADC2
	 // Relojes		 
	 .FCO2_P(FCO2_P),     .FCO2_N(FCO2_N),	
    .DCO2_P(DCO2_P),     .DCO2_N(DCO2_N),
	 // Datos	
    .DCH9_P(DCH9_P),     .DCH9_N(DCH9_N), 
    .DCH10_P(DCH10_P),    .DCH10_N(DCH10_N), 
    .DCH11_P(DCH11_P),    .DCH11_N(DCH11_N), 
    .DCH12_P(DCH12_P),    .DCH12_N(DCH12_N), 
    .DCH13_P(DCH13_P),    .DCH13_N(DCH13_N), 
    .DCH14_P(DCH14_P),    .DCH14_N(DCH14_N), 
    .DCH15_P(DCH15_P),    .DCH15_N(DCH15_N), 
    .DCH16_P(DCH16_P),    .DCH16_N(DCH16_N),

	 // Datos de salida de los ADCs
    .CH0(CH0), .CH1(CH1), .CH2(CH2), .CH3(CH3), .CH4(CH4), .CH5(CH5), .CH6(CH6), .CH7(CH7), 
    .CH8(CH8), .CH9(CH9), .CH10(CH10), .CH11(CH11), .CH12(CH12), .CH13(CH13), .CH14(CH14), .CH15(CH15), 
	 
	 // Seales de control de los ADCs
	 // ADC1
    .csb1(csb1), 
//    .pwb1(pwb1), 
    .pwb1(pwb1), 
	 // ADC2	
    .csb2(csb2), 
//    .pwb2(pwb2),
    .pwb2(pwb2),
	 // Both	
    .sdata(sdata), 
//    .resetb(resetb_aux)
    .resetb(resetb_aux),
	 
	 .ch_pol(16'hFFFF)
	 );
	assign resetb = resetb_aux & dcm_locked;
	
	ADC_clks ADC_clks (
		 .clk(clk), 
		 .clk10M(clk10M), 
		 .rstn(rstn), 
		 .adcsclk_disable(1'b0), 
		 .ADCLK_P(ADCLK_P), 
		 .ADCLK_N(ADCLK_N), 
		 .sclk(sclk)
		 );

endmodule
