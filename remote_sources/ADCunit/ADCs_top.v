`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 			UPV
// Engineer:			Ral Esteve Bosch 
// 
// Create Date:    	16:51:39 03/09/2007 
// Module Name:    	PET16DAQ_top 
// Project Name: 		PET16DAQ
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
// 	Versin del Firmware de la FPGA del Modulo de Adquisicin de
//		Datos
//		
//////////////////////////////////////////////////////////////////////////////////

module ADCs_top
		#(
		// Version del FIRMWARE
		// Version de debug 1. D001
		//parameter [15:0]  FPGA_VER = 16'hB001,
		
		// Parametros de configuracin del circuito de Ajuste de los Deserializadores
		parameter [7:0]	DCO_ADJ 	= 8'hFE,
		parameter [11:0] 	DCO_STABLE = 12'hFFF,
		parameter [11:0]	FCO_STABLE = 12'hFFF,
		parameter [11:0]	ADJ_TEST = 12'hFFF,
		parameter [10:0]	ADJ_ADCRST = 11'h3FF,
		
		parameter [25:0]	RST_ADJ = 10000000, //67108863
		
		parameter [11:0]	SIGNAL_LEVEL1 = 12'h7B7,	//1975
		parameter [11:0]	SIGNAL_LEVEL2 = 12'h81B,	//2075
		
		parameter IODELAY_GRP = "IODELAY_ADC"
		)
		(
		// CLK Inputs
		clk200_in,
		clk40,
		rstb_dcm,
		
		// ADCs Input/Outputs
		// Inputs
		// ADC1
		FCO1_P, FCO1_N,
		DCO1_P, DCO1_N,
		DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N,
		DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N,
		// ADC2
		FCO2_P, FCO2_N,
		DCO2_P, DCO2_N,
		DCH9_P, DCH9_N, DCH10_P, DCH10_N, DCH11_P, DCH11_N, DCH12_P, DCH12_N,
		DCH13_P, DCH13_N, DCH14_P, DCH14_N, DCH15_P, DCH15_N, DCH16_P, DCH16_N,
				
		// Outputs
		// ADC1
		csb1, pwb1,
		// ADC2
		csb2, pwb2,
		// Both
		resetb,
		sclk, sdata,
		// ADCLK
		//ADCLK_P,ADCLK_N,
		
		// Interfaz LVDSC
		//c_clk_P,
		//c_clk_N,
		//c_ctrl_P,
		//c_ctrl_N,
		//c_data1,
		//c_data2,
		
		CH0,CH1,CH2,CH3,CH4,CH5,CH6,CH7,
		CH8,CH9,CH10,CH11,CH12,CH13,CH14,CH15,
		
		conf_end, DES_run, DES_status, ADCDCM_status,

		i2c0_rst, 
		scl0, sda0, 
		scl1, sda1,
		
		trg_p, trg_n, 
		bclk_p, bclk_n,
		
		PW_EN_A, PW_EN_B, 
		CONVST_A_N, CONVST_B_N,
		A_PRSNT_B, B_PRSNT_B,
		
		ch_pol
		);

	input			clk200_in;
	input			clk40;
	
	input       rstb_dcm;
			
	// ADCs Input/Outputs
		
	// Inputs
	//	ADC1
	input				FCO1_P;
	input				FCO1_N;
	input				DCO1_P;
	input				DCO1_N;
	
	input				DCH1_P;
	input				DCH1_N;
	input				DCH2_P;
	input				DCH2_N;
	input				DCH3_P;
	input				DCH3_N;
	input				DCH4_P;
	input				DCH4_N;
	input				DCH5_P;
	input				DCH5_N;
	input				DCH6_P;
	input				DCH6_N;
	input				DCH7_P;
	input				DCH7_N;
	input				DCH8_P;
	input				DCH8_N;
	
	//	ADC2
	input				FCO2_P;
	input				FCO2_N;
	input				DCO2_P;
	input				DCO2_N;
	
	input				DCH9_P;
	input				DCH9_N;
	input				DCH10_P;
	input				DCH10_N;
	input				DCH11_P;
	input				DCH11_N;
	input				DCH12_P;
	input				DCH12_N;
	input				DCH13_P;
	input				DCH13_N;
	input				DCH14_P;
	input				DCH14_N;
	input				DCH15_P;
	input				DCH15_N;
	input				DCH16_P;
	input				DCH16_N;
	

	// Outputs
	// ADC1
	output			csb1;
	output			pwb1;
	// ADC2
	output			csb2;
	output			pwb2;
	// Both
	output			resetb;
	output			sclk;
	output			sdata;

	// ADCLK
	//output			ADCLK_P;
	//output			ADCLK_N;
	
	// Interfaz LVDSC
	//input	c_clk_P;
	//input	c_clk_N;
	//input	c_ctrl_P;
	//input	c_ctrl_N;
	//input	c_data1,
	//input	c_data2,
	
	output [11:0]	CH0,CH1,CH2,CH3,CH4,CH5,CH6,CH7;
	output [11:0]	CH8,CH9,CH10,CH11,CH12,CH13,CH14,CH15;
	
	output			conf_end;
	output			DES_run;
	output [15:0]	DES_status;
	output [5:0]	ADCDCM_status;
	
	// signals to control hybdrid chips (in general, ADC board)
	output 			i2c0_rst;
	inout 			scl0, sda0; 
	inout  			scl1, sda1;
		
	output 			trg_p, trg_n; 
	output 			bclk_p, bclk_n;
		
	output 			PW_EN_A, PW_EN_B;
	output 			CONVST_A_N, CONVST_B_N;
	input  			A_PRSNT_B, B_PRSNT_B;
	
	input [15:0]	ch_pol;

	
// Declaracin de seales
//wire clkosc_locked;

wire [15:0]	DES_status;
wire [5:0]	ADCDCM_status;

//wire [24:0]	adc_conf;
//wire [9:0]	dcm_conf;

wire [11:0]	CH0,CH1,CH2,CH3,CH4,CH5,CH6,CH7;
wire [11:0]	CH8,CH9,CH10,CH11,CH12,CH13,CH14,CH15;

wire			DES_run;//, DCH_adj;//, DCM_lock;

wire			pwb1, pwb2;

wire i2c0_rst;
wire scl0, sda0; 
wire scl1, sda1;
		
wire trg_p, trg_n; 
wire bclk_p, bclk_n;
		
wire PW_EN_A, PW_EN_B;
wire CONVST_A_N, CONVST_B_N;

wire clk10M;

//	OBUF #(.DRIVE(12), .IOSTANDARD("DEFAULT"), .SLEW("SLOW")) 
//	OBUF_inst (.O(PW_EN_A), .I(1'b1));

assign PW_EN_A = ~ A_PRSNT_B;
assign PW_EN_B = ~ B_PRSNT_B;
assign CONVST_A_N = 1'b1;
assign CONVST_B_N = 1'b1;

assign i2c0_rst = 1'b0;
assign scl0 = 1'bz;	
assign sda0 = 1'bz;

// Invertidos
OBUFDS #(
      .IOSTANDARD("LVDS_25") 	// Specify the output I/O standard
   ) OBUFDS_trigger (
      .O(trg_p),   			// Diff_p output (connect directly to top-level port)
      .OB(trg_n),  			// Diff_n output (connect directly to top-level port)
      .I(1'b1)      			// Buffer input 
   );

OBUFDS #(
      .IOSTANDARD("LVDS_25") 	// Specify the output I/O standard
   ) OBUFDS_bclock (
      .O(bclk_p),   			// Diff_p output (connect directly to top-level port)
      .OB(bclk_n),  			// Diff_n output (connect directly to top-level port)
      .I(1'b1)      		// Buffer input 
   );

	//BUFG bufg_clk10M(.O(clk10M),.I(sclk_bufr));
	wire rstn, resetb_aux, clk_locked;
	reg [11:0] cfgcounter;
	
	assign rstn = resetb_aux & clk_locked;
	
	
	always @ (posedge clk10M or negedge rstn)
	begin
		if (!rstn)
			cfgcounter <= 12'b000000000000;
		else
			if (cfgcounter != 12'b111111111111)
				cfgcounter <= cfgcounter + 1'b1;
	end
	
	assign ccardreg_writeall = (cfgcounter == 1000) ?  1'b1 : 1'b0;
	
	ccard_reg ccard_reg(
		.clk(clk10M),
		.rstn(rstn),
		.writeall(ccardreg_writeall),
		.reg0(8'b11111111),
		.reg1(8'b00000000),
		.reg2(8'b00000000),
		.reg3(8'b00000000),
		.reg4(8'b00000000),
		.reg5(8'b11111111),
		.reg6(8'b11111111),
		.i2c_clkdiv(8'b01100100), // 100
		.i2c_sdadel(8'b00110010), // 50      
		.scl(scl1),
		.sda(sda1)
	);

//////////////////////////////////////////////////////////////////////////
//wire			clk;

//************************************************************************
//**********************************************************************************************************************
// Reset interno - power up reset
// Activo a nivel bajo
wire			rstb;//lk_locked;

assign		rstb = rstb_dcm & clk_locked;
//**********************************************************************************************************************


//************************************************************************
// Seales de reloj
//************************************************************************
	// Bufers y MMCM para generar una señal de reloj 
	// La entrada de reloj est conectada a un PIN del tipo GC
	
	MMCM_BASE #(
      .BANDWIDTH("OPTIMIZED"),   	// Jitter programming ("HIGH","LOW","OPTIMIZED")
      .CLKFBOUT_MULT_F(5.0),     	// Multiply value for all CLKOUT (5.0-64.0).
      .CLKFBOUT_PHASE(0.0),      	// Phase offset in degrees of CLKFB (0.00-360.00).
      .CLKIN1_PERIOD(5.0),       	// Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      .CLKOUT0_DIVIDE_F(25.0),    	// Divide amount for CLKOUT0 (1.000-128.000).
      .CLKOUT0_DUTY_CYCLE(0.5),		// CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      .CLKOUT0_PHASE(0.0),				//CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
		.CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT1_DIVIDE(100),				//CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT2_DIVIDE(100),				//CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT4_CASCADE("FALSE"), 	// Cascase CLKOUT4 counter with CLKOUT6 (TRUE/FALSE)
      .CLOCK_HOLD("FALSE"),      	// Hold VCO Frequency (TRUE/FALSE)
      .DIVCLK_DIVIDE(1),         	// Master division value (1-80)
      .REF_JITTER1(0.0),         	// Reference input jitter in UI (0.000-0.999).
      .STARTUP_WAIT("FALSE")     	// Not supported. Must be set to FALSE.
   )
   MMCM_BASE_clk (
      // Clock Outputs: 1-bit (each) User configurable clock outputs
      .CLKOUT0(clk_buf),     		// 1-bit CLKOUT0 output
      .CLKOUT1(sclk_buf),     	// 1-bit CLKOUT1 output
		.CLKOUT2(clk10M),     		// 1-bit CLKOUT1 output
      // Feedback Clocks: 1-bit (each) Clock feedback ports
      .CLKFBOUT(clk_fbout),   	// 1-bit Feedback clock output
      // Status Port: 1-bit (each) MMCM status ports
      .LOCKED(clk_locked),       // 1-bit LOCK output
      // Clock Input: 1-bit (each) Clock input
      .CLKIN1(clk200_in),
      // Control Ports: 1-bit (each) MMCM control ports
      .PWRDWN(1'b0),       		// 1-bit Power-down input
      .RST(!rstb_dcm),       		// 1-bit Reset input
      // Feedback Clocks: 1-bit (each) Clock feedback ports
      .CLKFBIN(clk_fbout)      	// 1-bit Feedback clock input
   );



// Referencia IODELAYs - 200 MHz
	BUFG bufg_dcmiodelay (.O (clk_refiod),.I (clk200_in));
	
	
	 (* IODELAY_GROUP = IODELAY_GRP *)
	 IDELAYCTRL IDELAYCTRL_refiod (
      //.RDY(rdy),       							// 1-bit ready output
      .REFCLK(clk_refiod), 					// 1-bit reference clock input
      .RST(!rstb)        						// 1-bit reset input
   );

	
// ADCs clk
// SCLK es (clk200_in*5)/(1/100) = 10 MHz	(15 MHz maximo!)	
	BUFGCE_1 bufg_sclk(
		.O(sclk),
		.CE(DES_run),
		.I(sclk_buf));


//************************************************************************
//************************************************************************
//************************************************************************
// Deserializador (utiliza los bloques ISERDES)
//************************************************************************

ADCs_Unit 
#(
	.DCO_ADJ(DCO_ADJ),
	.DCO_STABLE(DCO_STABLE),
	.FCO_STABLE(FCO_STABLE),
	.ADJ_TEST(ADJ_TEST),
	.ADJ_ADCRST(ADJ_ADCRST),
	.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
	.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
	
	.IODELAY_GRP(IODELAY_GRP)
)
ADCs_Unit (
	 // Relojes y reset
	 .clk(clk40),						// Reloj principal
    .sclk(sclk_buf), 				// Reloj de control de los ADCs: 	 10 MHz
    //.clk_refiod(clk_refiod), 	// Reloj de control de los IODELAYs: 200 MHz
    .rstb(rstb),.rstb_dcm(rstb_dcm), 
	 
	 // Seales de control internas
    // Entradas
	 .adc_init(1'b0),//adc_init), 
    .adc_conf(25'b0),//adc_conf), 
    .dcm_init(1'b0),//dcm_init), 
    .dcm_conf(10'b0),//dcm_conf),
	 //.trsf_conf(trsf_conf[5]),
	 // Salidas
	 .conf_end(conf_end), 
    .DES_run(DES_run), 
    .DES_status(DES_status), 
    .DCM_status(ADCDCM_status), 

	 // Seales de entrada de los ADCs
	 // ADC1
	 // Relojes	
	 .FCO1_P(FCO1_P), 
    .FCO1_N(FCO1_N),
	 .DCO1_P(DCO1_P), 
    .DCO1_N(DCO1_N),
	 // Datos
    .DCH1_P(DCH1_P), 
    .DCH1_N(DCH1_N), 
    .DCH2_P(DCH2_P), 
    .DCH2_N(DCH2_N), 
    .DCH3_P(DCH3_P), 
    .DCH3_N(DCH3_N), 
    .DCH4_P(DCH4_P),				
    .DCH4_N(DCH4_N), 
    .DCH5_P(DCH5_P),				  
    .DCH5_N(DCH5_N), 
    .DCH6_P(DCH6_P), 
    .DCH6_N(DCH6_N), 
    .DCH7_P(DCH7_P),				  
    .DCH7_N(DCH7_N), 
    .DCH8_P(DCH8_P),				  
    .DCH8_N(DCH8_N),
	 
	 // ADC2
	 // Relojes
	 .FCO2_P(FCO2_P), 
    .FCO2_N(FCO2_N),	
    .DCO2_P(DCO2_P), 
    .DCO2_N(DCO2_N),
	 // Datos	
    .DCH9_P(DCH9_P), 
    .DCH9_N(DCH9_N), 
    .DCH10_P(DCH10_P),			  
    .DCH10_N(DCH10_N), 
    .DCH11_P(DCH11_P), 
    .DCH11_N(DCH11_N), 
    .DCH12_P(DCH12_P), 
    .DCH12_N(DCH12_N), 
    .DCH13_P(DCH13_P), 
    .DCH13_N(DCH13_N), 
    .DCH14_P(DCH14_P), 
    .DCH14_N(DCH14_N), 
    .DCH15_P(DCH15_P), 
    .DCH15_N(DCH15_N), 
    .DCH16_P(DCH16_P), 
    .DCH16_N(DCH16_N),

	 // Datos de salida de los ADCs
    .CH0(CH0), 
    .CH1(CH1), 
    .CH2(CH2), 
    .CH3(CH3), 
    .CH4(CH4), 
    .CH5(CH5),
	 .CH6(CH6), 
    .CH7(CH7), 
    .CH8(CH8), 
    .CH9(CH9), 
    .CH10(CH10), 
    .CH11(CH11),
	 .CH12(CH12), 
    .CH13(CH13), 
    .CH14(CH14), 
    .CH15(CH15), 
	 
	 // Seales de control de los ADCs
	 // ADC1
    .csb1(csb1), 
    .pwb1(pwb1), 
	 // ADC2	
    .csb2(csb2), 
    .pwb2(pwb2),
	 // Both	
    .sdata(sdata), 
    .resetb(resetb_aux),
	 
	 .ch_pol(ch_pol)
	 );
	
	assign resetb = resetb_aux & clk_locked;

endmodule
