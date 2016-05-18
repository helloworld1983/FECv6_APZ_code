`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:			UPV	 
// Engineer: 		Ral Esteve
// 
// Create Date:    18:15:01 05/16/2007 
// Design Name: 
// Module Name:    ADCs_Unit 
// Project Name: 
// Target Devices: 
// Description: 	Unidad de Lectura de Datos de los ADCs
//							- Deserializadores 6x4 canales
//							- Configuracin automtica ADCs
//							- Sincronizacin automtica de los Deserializadores y DCMs
//							- Bloque para la configuracin de los relojes necesarios
//
// Revision: 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
module ADCs_Unit
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
		clk,
		// Clk para el control de los ADCs
		sclk,
		// Clock de referencia para los bloques IODELAYS
		//clk_refiod,		
		rstb, rstb_dcm,
		// ADCs configuracin externa
		adc_init, adc_conf,
		
		// DCMs configuracin externa
		dcm_init, dcm_conf,
		
		// Envia de rampa digital (generada por el ADC) o datos
		//trsf_conf,
				
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
		
			
		//Outputs
		CH0, CH1, CH2, CH3, CH4, CH5, CH6, CH7,
		CH8, CH9, CH10, CH11, CH12, CH13, CH14, CH15,

		// ADC1
		csb1, pwb1,
		// ADC2
		csb2, pwb2,
		// Both
		sdata,
		resetb,
		
		
		// Seales de control
		conf_end,
		
		DES_run, DES_status, DCM_status,
		
		ch_pol
		);

	input				clk;
	input				sclk;
	//input				clk_refiod;
	input				rstb;
	input				rstb_dcm;
	
	// Configuracin externa
	input				adc_init;
	input [24:0]	adc_conf;
	input				dcm_init;
	input [9:0]		dcm_conf;
	//input				trsf_conf;
	
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


	//	ADCs
	output [11:0]	CH0;
	output [11:0]	CH1;
	output [11:0]	CH2;
	output [11:0]	CH3;
	output [11:0]	CH4;
	output [11:0]	CH5;
	output [11:0]	CH6;
	output [11:0]	CH7;
	output [11:0]	CH8;
	output [11:0]	CH9;
	output [11:0]	CH10;
	output [11:0]	CH11;
	output [11:0]	CH12;
	output [11:0]	CH13;
	output [11:0]	CH14;
	output [11:0]	CH15;
	
	
	// Seales de configuracin de los ADCs
	// ADC1
	output			csb1;
	output			pwb1;
	// ADC2
	output			csb2;
	output			pwb2;
	// Both
	output			sdata;
	
	output			resetb;
	
	// Seales de control
	output			conf_end;
	
	output			DES_run;
	output [15:0]	DES_status;
	output [5:0]	DCM_status;
	
	// Control de la polaridad de la señal
	input [15:0]	ch_pol;

	
	//SOLO SIMULACION
	//output [3:0]	pttn_sel;

//*************************************************************************************************************************************
// Declaracin de seales
wire	ADC_confrun1, ADC_confrun2;
wire	conf_end, conf_end1, conf_end2;
wire	adc_init1, adc_init2;
wire	dcm_init1, dcm_init2;
wire	FCO1, FCO2;  
//wire	DCMs_locked1, DCMs_locked2, DCMs_locked3;

wire [11:0]	CH0w,CH1w,CH2w,CH3w,CH4w,CH5w,CH6w,CH7w;
wire [11:0]	CH8w,CH9w,CH10w,CH11w,CH12w,CH13w,CH14w,CH15w;

wire [11:0]	CH0pol,CH1pol,CH2pol,CH3pol,CH4pol,CH5pol,CH6pol,CH7pol;
wire [11:0]	CH8pol,CH9pol,CH10pol,CH11pol,CH12pol,CH13pol,CH14pol,CH15pol;

//*************************************************************************************************************************************
// Asignacin de seales

//Registro de estado de los DCMs del bloque deserializador
//	[0]	DCO_locked - ADC1
//	[1]	FCO_locked - ADC1
//	[2]	DCO_locked - ADC2
//	[3]	FCO_locked - ADC2
//	[4]	DCO_locked - ADC3
//	[5]	FCO_locked - ADC3

//Registro de estado del bloque deserializador
// [7:0]		DCH_adj 		- Canal del 1 al 8 ajustado
// [8:15]	DCH_adj 		- Canal del 9 al 16 ajustado
// [16:23]	DCH_adj 		- Canal del 17 al 24 ajustado

wire			DES_run,DES1_run,DES2_run;
wire [10:0]	DES1_status,DES2_status;
wire [15:0]	DES_status;
wire [5:0]	DCM_status;

assign	DCM_status 	= {DES2_status[2:1],DES1_status[2:1],
								DES2_status[0],DES1_status[0]};

assign	DES_status	= {DES2_status[10:3], DES1_status[10:3]};
								
									
assign	DES_run		= DES1_run | DES2_run; 									



assign	conf_end		= conf_end1 | conf_end2;


//assign	DCMs_locked	= DCMs_locked1 & DCMs_locked2 & DCMs_locked3;

assign	adc_init1 	= (adc_conf[24]==1'b0) ? adc_init:1'b0; 
assign	adc_init2 	= (adc_conf[24]==1'b1) ? adc_init:1'b0;

assign	dcm_init1 	= (dcm_conf[9:8]==2'b00 | dcm_conf[9:8]==2'b01) ? dcm_init:1'b0; 
assign	dcm_init2 	= (dcm_conf[9:8]==2'b00 | dcm_conf[9:8]==2'b10) ? dcm_init:1'b0;

// Datos para modificar PS desde el PC
reg [7:0]	dcm_conf1r,dcm_conf2r;
reg			dcm_init1r,dcm_init2r;

// Sincronizacin clk y FCO	

	always @(posedge FCO1 or negedge rstb)
	begin
		if (!rstb)
		begin
			dcm_init1r <= 1'b0;
			
			dcm_conf1r <= 8'h00;
		end	
		else
		begin
			dcm_init1r <= dcm_init1;
			
			dcm_conf1r <= dcm_conf;
		end	
   end
	
	always @(posedge FCO2 or negedge rstb)
	begin
		if (!rstb)
		begin
			dcm_init2r <= 1'b0;
			
			dcm_conf2r <= 8'h00;
		end	
		else
		begin
			dcm_init2r <= dcm_init2;
			
			dcm_conf2r <= dcm_conf;
		end	
   end

//*************************************************************************************************************************************
//*************************************************************************************************************************************
// Instancacin de mdulos

// Conversin de seales LVDS
// ADC1
	IBUFGDS
	#(.DIFF_TERM("TRUE"))
	ibuf_fco1
	(.I(FCO1_P),.IB(FCO1_N),.O(FCO1_dcm));	// ADCLK

	IBUFGDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dco1(.I(DCO1_P),.IB(DCO1_N),.O(DCO1_dcm));//_inv));	// LCLK = ADCLK/12
	// synthesis attribute MAXDELAY of DCO1_dcm "1000ps"

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch1(.I(DCH1_P),.IB(DCH1_N),.O(DCH1)); 		// Canal 1

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch2(.I(DCH2_P),.IB(DCH2_N),.O(DCH2));		// Canal 2
	
	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch3(.I(DCH3_P),.IB(DCH3_N),.O(DCH3)); 		// Canal 3 
	
	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch4(.I(DCH4_P),.IB(DCH4_N),.O(DCH4)); 		// Canal 4 
	
	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch5(.I(DCH5_P),.IB(DCH5_N),.O(DCH5));		// Canal 5 

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch6(.I(DCH6_P),.IB(DCH6_N),.O(DCH6)); 		// Canal 6 
	
	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch7(.I(DCH7_P),.IB(DCH7_N),.O(DCH7)); 		// Canal 7 

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch8(.I(DCH8_P),.IB(DCH8_N),.O(DCH8)); 		// Canal 8 
	
	// synthesis attribute MAXDELAY of DCH1 "500ps"	
	// synthesis attribute MAXDELAY of DCH2 "500ps"	
	// synthesis attribute MAXDELAY of DCH3 "500ps"	
	// synthesis attribute MAXDELAY of DCH4 "500ps"	
	// synthesis attribute MAXDELAY of DCH5 "500ps"	
	// synthesis attribute MAXDELAY of DCH6 "500ps"	
	// synthesis attribute MAXDELAY of DCH7 "500ps"	
	// synthesis attribute MAXDELAY of DCH8 "500ps"	
	
// ADC2
	IBUFGDS
	#(.DIFF_TERM("TRUE"))
	ibuf_fco2(.I(FCO2_P),.IB(FCO2_N),.O(FCO2_dcm));	// ADCLK

	IBUFGDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dco2(.I(DCO2_P),.IB(DCO2_N),.O(DCO2_dcm));	// LCLK = ADCLK/12
	// synthesis attribute MAXDELAY of DCO2_dcm "1025ps"

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch9(.I(DCH9_P),.IB(DCH9_N),.O(DCH9)); 			// Canal 9  
	
	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch10(.I(DCH10_P),.IB(DCH10_N),.O(DCH10)); 	// Canal 10

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch11(.I(DCH11_P),.IB(DCH11_N),.O(DCH11)); 	// Canal 11 
	
	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch12(.I(DCH12_P),.IB(DCH12_N),.O(DCH12));		// Canal 12	

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch13(.I(DCH13_P),.IB(DCH13_N),.O(DCH13)); 	// Canal 13 

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch14(.I(DCH14_P),.IB(DCH14_N),.O(DCH14)); 	// Canal 14 

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch15(.I(DCH15_P),.IB(DCH15_N),.O(DCH15)); 	// Canal 15 

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch16(.I(DCH16_P),.IB(DCH16_N),.O(DCH16)); 		// Canal 16
	
	// synthesis attribute MAXDELAY of DCH9 "500ps"	
	// synthesis attribute MAXDELAY of DCH10 "500ps"	
	// synthesis attribute MAXDELAY of DCH11 "500ps"	
	// synthesis attribute MAXDELAY of DCH12 "500ps"	
	// synthesis attribute MAXDELAY of DCH13 "500ps"	
	// synthesis attribute MAXDELAY of DCH14 "500ps"	
	// synthesis attribute MAXDELAY of DCH15 "500ps"	
	// synthesis attribute MAXDELAY of DCH16 "500ps"

// ADC1

Des_ADC 
	#(
	 .DCO_ADJ(DCO_ADJ),
	 .DCO_STABLE(DCO_STABLE),
	 .FCO_STABLE(FCO_STABLE),
	 .ADJ_TEST(ADJ_TEST),
	 .ADJ_ADCRST(ADJ_ADCRST),
	 .SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
	 .SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2075
	 
	 .IODELAY_GRP(IODELAY_GRP)
	)
Des_ADC1 
	(
	 .sclk(sclk),
	 //.clk_refiod(clk_refiod),
	 .rstb(rstb),.rstb_dcm(rstb_dcm),
	 .adc_init(adc_init1 & adc_conf[24]),
	 .adc_conf(adc_conf[23:0]),
	 .dcm_init(dcm_init1r),
	 .dcm_conf(dcm_conf1r[7:0]),
	 .ADC_confwt(ADC_confrun2),
 	 .auto_runwt(ADC_confrun2),
	 //.trsf_conf(trsf_conf),
	 //.fcoconf_en(1'b1),
    .FCO(FCO1_dcm),
	 .DCO(DCO1_dcm),
	 .DCH1(DCH1),
	 .DCH2(DCH2), 
    .DCH3(DCH3), 
    .DCH4(DCH4),
	 .DCH5(DCH5),
	 .DCH6(DCH6),
	 .DCH7(DCH7),
	 .DCH8(DCH8),
    .des_DCH1(CH0w), 
    .des_DCH2(CH1w), 
    .des_DCH3(CH2w), 
    .des_DCH4(CH3w),
	 .des_DCH5(CH4w),
	 .des_DCH6(CH5w),
	 .des_DCH7(CH6w),
	 .des_DCH8(CH7w),
	 .FCO_out(FCO1),
	 .csb(csb1),
	 .sdata(sdata1),
	 .pwb(pwb1),
	 .resetb(resetb1),
	 .conf_end(conf_end1),
	 .DES_run(DES1_run),
	 .DES_status(DES1_status),
	 .ADC_confrun(ADC_confrun1),
	 .auto_run(auto_run1)
    );
 

Des_ADC 
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
Des_ADC2 
	(
	 .sclk(sclk),
	 //.clk_refiod(clk_refiod),
	 .rstb(rstb),.rstb_dcm(rstb_dcm),
	 .adc_init(adc_init2 & !adc_conf[24]),
	 .adc_conf(adc_conf[23:0]),
	 .dcm_init(dcm_init2r),
	 .dcm_conf(dcm_conf2r[7:0]),
	 .ADC_confwt(auto_run1 | ADC_confrun1),
	 .auto_runwt(auto_run1 | ADC_confrun1),
	 //.trsf_conf(trsf_conf),	 
	 //.fcoconf_en(1'b1),
	 .FCO(FCO2_dcm),
    .DCO(DCO2_dcm), 
    .DCH1(DCH9), 
    .DCH2(DCH10), 
    .DCH3(DCH11), 
    .DCH4(DCH12),
	 .DCH5(DCH13),
	 .DCH6(DCH14),
	 .DCH7(DCH15),
	 .DCH8(DCH16),
    .des_DCH1(CH8w), 
    .des_DCH2(CH9w), 
    .des_DCH3(CH10w), 
    .des_DCH4(CH11w),
	 .des_DCH5(CH12w),
	 .des_DCH6(CH13w),
	 .des_DCH7(CH14w),
	 .des_DCH8(CH15w),
	 .FCO_out(FCO2),
	 .csb(csb2),
	 .sdata(sdata2),
	 .pwb(pwb2),
	 .resetb(resetb2),
	 .conf_end(conf_end2),
	 .DES_run(DES2_run),
	 .DES_status(DES2_status),
	 .ADC_confrun(ADC_confrun2),
 	 .auto_run()
    );


assign	sdata  = (csb1==0) 				? sdata1:
					  ((csb1==1 & csb2==0) 	? sdata2:sdata1);
					 
assign	resetb = resetb1 & resetb2;
					 

/*
	IDELAYCTRL IDELAYCTRL_refiod (
      //.RDY(rdy),       							// 1-bit ready output
      .REFCLK(clk_refiod), 					// 1-bit reference clock input
      .RST(!rstb)        						// 1-bit reset input
   );
*/

//************************************************************************
// Registros provisionales de las seales del deserializador
//************************************************************************
//************************************************************************
// Sincronizacin de las seales del deserializador
//************************************************************************
// ADC1
assign	CH0pol = (ch_pol[0]==1'b0) ? 12'd4095-CH0w:CH0w; 
assign	CH1pol = (ch_pol[1]==1'b0) ? 12'd4095-CH1w:CH1w; 
assign	CH2pol = (ch_pol[2]==1'b0) ? 12'd4095-CH2w:CH2w; 
assign	CH3pol = (ch_pol[3]==1'b0) ? 12'd4095-CH3w:CH3w; 
assign	CH4pol = (ch_pol[4]==1'b0) ? 12'd4095-CH4w:CH4w; 
assign	CH5pol = (ch_pol[5]==1'b0) ? 12'd4095-CH5w:CH5w; 
assign	CH6pol = (ch_pol[6]==1'b0) ? 12'd4095-CH6w:CH6w; 
assign	CH7pol = (ch_pol[7]==1'b0) ? 12'd4095-CH7w:CH7w; 

fifo16x96 FFADC1 (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),
					   // Inversión de señales
						.din({
						CH0pol,
						CH1pol,
						CH2pol,
						CH3pol,
						CH4pol,
						CH5pol,
						CH6pol,
						CH7pol}),
					   .wr_en(!DES1_run),.rd_en(!fempty1),
					   .dout({CH0,CH1,CH2,CH3,CH4,CH5,CH6,CH7}),
					   .almost_empty(fempty1));
// ADC2
assign	CH8pol = (ch_pol[8]==1'b0) ? 12'd4095-CH8w:CH8w; 
assign	CH9pol = (ch_pol[9]==1'b0) ? 12'd4095-CH9w:CH9w; 
assign	CH10pol = (ch_pol[10]==1'b0) ? 12'd4095-CH10w:CH10w; 
assign	CH11pol = (ch_pol[11]==1'b0) ? 12'd4095-CH11w:CH11w; 
assign	CH12pol = (ch_pol[12]==1'b0) ? 12'd4095-CH12w:CH12w; 
assign	CH13pol = (ch_pol[13]==1'b0) ? 12'd4095-CH13w:CH13w; 
assign	CH14pol = (ch_pol[14]==1'b0) ? 12'd4095-CH14w:CH14w; 
assign	CH15pol = (ch_pol[15]==1'b0) ? 12'd4095-CH15w:CH15w; 


fifo16x96 FFADC2 (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),
					   .din({
						// Inversión de señales
						CH8pol,
						CH9pol,
						CH10pol,
						CH11pol,
						CH12pol,
						CH13pol,
						CH14pol,
						CH15pol}),
					   .wr_en(!DES2_run),.rd_en(!fempty2),
					   .dout({CH8,CH9,CH10,CH11,CH12,CH13,CH14,CH15}),
					   .almost_empty(fempty2));


//************************************************************************
//************************************************************************


endmodule