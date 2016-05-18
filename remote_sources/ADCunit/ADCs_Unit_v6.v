`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:			UPV	 
// Engineer: 		Raúl Esteve
// 
// Create Date:    18:15:01 05/16/2007 
// Design Name: 
// Module Name:    ADCs_Unit 
// Project Name: 
// Target Devices: 
// Description: 	Unidad de Lectura de Datos de los ADCs
//							- Deserializadores 6x4 canales
//							- Configuración automática ADCs
//							- Sincronización automática de los Deserializadores y DCMs
//							- Bloque para la configuración de los relojes necesarios
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
	   parameter [11:0]	SIGNAL_LEVEL2 = 12'h81B 	//2075
	)
	(
		// Inputs
		clk,
		// Clk para el control de los ADCs
		sclk,
		// Clock de referencia para los bloques IODELAYS
		clk_refiod,		//
		rstb, rstb_dcm,
		// ADCs configuración externa
		adc_init, adc_conf,
		
		// DCMs configuración externa
		dcm_init, dcm_conf,
		
		// Envia de rampa digital (generada por el ADC) o datos
		//trsf_conf,
				
		// ADC1
		//FCO1_P, FCO1_N,
		DCO1_P, DCO1_N,
		DCH1_P, DCH1_N, DCH2_P, DCH2_N, DCH3_P, DCH3_N, DCH4_P, DCH4_N,
		DCH5_P, DCH5_N, DCH6_P, DCH6_N, DCH7_P, DCH7_N, DCH8_P, DCH8_N,
		// ADC2
		//FCO2_P, FCO2_N,
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
		sdata, resetb,
		
		
		// Señales de control
		conf_end,
		
		DES_run, DES_status, DCM_status
		);

	input				clk;
	input				sclk;
	input				clk_refiod;
	input				rstb;
	input				rstb_dcm;
	
	// Configuración externa
	input				adc_init;
	input [24:0]	adc_conf;
	input				dcm_init;
	input [9:0]		dcm_conf;
	//input				trsf_conf;
	
	//	ADC1
//	input				FCO1_P;
//	input				FCO1_N;
	input				DCO1_P;
	input				DCO1_N;
	
	input				DCH1_P;  //A_H1
	input				DCH1_N;
	input				DCH2_P;  //B_H1
	input				DCH2_N;
	input				DCH3_P;  //C_H1
	input				DCH3_N;
	input				DCH4_P;  //D_H1
	input				DCH4_N;
	input				DCH5_P;  //E_H1
	input				DCH5_N;
	input				DCH6_P;  //S_H1
	input				DCH6_N;
	input				DCH7_P;  //A_H2
	input				DCH7_N;
	input				DCH8_P;  //B_H2
	input				DCH8_N;
	
	//	ADC2
//	input				FCO2_P;
//	input				FCO2_N;
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
	
	
	// Señales de configuración de los ADCs
	// ADC1
	output			csb1;
	output			pwb1;
	// ADC2
	output			csb2;
	output			pwb2;
	// Both
	output			sdata;
	output			resetb;
	
	// Señales de control
	output			conf_end;
	
	output			DES_run;
	output [15:0]	DES_status;
	output [5:0]	DCM_status;

	
	//SOLO SIMULACION
	//output [3:0]	pttn_sel;

//*************************************************************************************************************************************
// Declaración de señales
wire	ADC_confrun1, ADC_confrun2;
wire	conf_end, conf_end1, conf_end2;
wire	adc_init1, adc_init2;
wire	dcm_init1, dcm_init2;
wire	FCO1, FCO2;  
//wire	DCMs_locked1, DCMs_locked2, DCMs_locked3;

wire [11:0]	CH0w,CH1w,CH2w,CH3w,CH4w,CH5w,CH6w,CH7w;
wire [11:0]	CH8w,CH9w,CH10w,CH11w,CH12w,CH13w,CH14w,CH15w;
//*************************************************************************************************************************************
// Asignación de señales

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

assign	DES_status	= {DES2_status[10:3],DES1_status[10:3]};
								
									
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

// Sincronización clk y FCO	
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
// Instancación de módulos

// Conversión de señales LVDS
// ADC1
	
//	IBUFGDS
//	#(.DIFF_TERM("TRUE"))
//	ibuf_fco1
//	(.I(FCO1_P),.IB(FCO1_N),.O(FCO1_dcm));	// ADCLK
	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dco1(.I(DCO1_N),.IB(DCO1_P),.O(DCO1_inv),.OB(DCO1_dcm));	// LCLK = ADCLK/12
//	INV 	 inv_dco1(.I(DCO1_inv),.O(DCO1_dcm));
	// synthesis attribute MAXDELAY of FCO1_dcm "1000ps"

	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch1(.I(DCH1_N),.IB(DCH1_P),.O(DCH1_inv),.OB(DCH1)); 		// Canal 1
//	INV 	 inv_dch1 (.I(DCH1_inv),.O(DCH1));

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch2(.I(DCH2_P),.IB(DCH2_N),.O(DCH2));				// Canal 2
	
	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch3(.I(DCH3_N),.IB(DCH3_P),.O(DCH3_inv), .OB(DCH3)); 		// Canal 3 
//	INV 	 inv_dch3 (.I(DCH3_inv),.O(DCH3));
	
	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch4(.I(DCH4_N),.IB(DCH4_P),.O(DCH4_inv),.OB(DCH4));	 		// Canal 4 
//	INV 	 inv_dch4 (.I(DCH4_inv),.O(DCH4));
	
	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch5(.I(DCH5_P),.IB(DCH5_N),.O(DCH5)); 				// Canal 5 

	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch6(.I(DCH6_N),.IB(DCH6_P),.O(DCH6_inv), .OB(DCH6)); 		// Canal 6 
//	INV 	 inv_dch6 (.I(DCH6_inv),.O(DCH6));
	
	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch7(.I(DCH7_N),.IB(DCH7_P),.O(DCH7_inv),.OB(DCH7)); 		// Canal 7 
//	INV 	 inv_dch7 (.I(DCH7_inv),.O(DCH7));

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
//	IBUFGDS
//	#(.DIFF_TERM("TRUE"))
//	ibuf_fco2(.I(FCO2_P),.IB(FCO2_N),.O(FCO2_dcm));	// ADCLK
	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dco2(.I(DCO2_N),.IB(DCO2_P),.O(DCO2_inv),.OB(DCO2_dcm));	// LCLK = ADCLK/12
//	INV 	 inv_dco2(.I(DCO2_inv),.O(DCO2_dcm));
	// synthesis attribute MAXDELAY of FCO2_dcm "1000ps"

	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch9(.I(DCH9_N),.IB(DCH9_P),.O(DCH9_inv),.OB(DCH9)); 				// Canal 9  
//	INV 	 inv_dch9(.I(DCH9_inv),.O(DCH9));
	
	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch10(.I(DCH10_N),.IB(DCH10_P),.O(DCH10_inv),.OB(DCH10));  			// Canal 10
//	INV 	 inv_dch10(.I(DCH10_inv),.O(DCH10));

	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch11(.I(DCH11_N),.IB(DCH11_P),.O(DCH11_inv),.OB(DCH11)); 			// Canal 11 
//	INV 	 inv_dch11(.I(DCH11_inv),.O(DCH11));
	
	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch12(.I(DCH12_P),.IB(DCH12_N),.O(DCH12));					// Canal 12	

	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch13(.I(DCH13_N),.IB(DCH13_P),.O(DCH13_inv),.OB(DCH13)); 			// Canal 13 
//	INV 	 inv_dch13 (.I(DCH13_inv),.O(DCH13));

	IBUFDS
	#(.DIFF_TERM("TRUE"))
	ibuf_dch14(.I(DCH14_P),.IB(DCH14_N),.O(DCH14)); 				// Canal 14 

	IBUFDS_DIFF_OUT
	#(.DIFF_TERM("TRUE"))
	ibuf_dch15(.I(DCH15_N),.IB(DCH15_P),.O(DCH15_inv),.OB(DCH15)); 		// Canal 15 
//	INV 	 inv_dch15 (.I(DCH15_inv),.O(DCH15));

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
	 .SIGNAL_LEVEL1(SIGNAL_LEVEL1),//1975
	 .SIGNAL_LEVEL2(SIGNAL_LEVEL2) //2075
	)
Des_ADC1 
	(
	 .clkin(clk),
	 .sclk(sclk),
	 //.clk_refiod(clk_refiod),
	 .rstb(rstb),.rstb_dcm(rstb_dcm),
	 .adc_init(adc_init1 & adc_conf[24]),
	 .adc_conf(adc_conf[23:0]),
	 .dcm_init(dcm_init1r),
	 .dcm_conf(dcm_conf1r[7:0]),
	 .ADC_confwt(ADC_confrun2),
 	 .auto_runwt(1'b0),
	 //.trsf_conf(trsf_conf),
	 //.fcoconf_en(1'b1),
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
	 
// ADC2
//(* IODELAY_GROUP = "DES_ADC2" *)
Des_ADC 
	#(
	 .DCO_ADJ(DCO_ADJ),
	 .DCO_STABLE(DCO_STABLE),
	 .FCO_STABLE(FCO_STABLE),
 	 .ADJ_TEST(ADJ_TEST),
	 .ADJ_ADCRST(ADJ_ADCRST),
	 .SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
	 .SIGNAL_LEVEL2(SIGNAL_LEVEL2) 	//2075
	)
Des_ADC2 
	(
	 .clkin(clk),
	 .sclk(sclk),
	 //.clk_refiod(clk_refiod),
	 .rstb(rstb),.rstb_dcm(rstb_dcm),
	 .adc_init(adc_init2 & !adc_conf[24]),
	 .adc_conf(adc_conf[23:0]),
	 .dcm_init(dcm_init2r),
	 .dcm_conf(dcm_conf2r[7:0]),
	 .ADC_confwt(ADC_confrun1),
	 .auto_runwt(auto_run1),
	 //.trsf_conf(trsf_conf),	 
	 //.fcoconf_en(1'b1),
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


assign	sdata  = (csb1==0 & csb2==0) ? sdata1:
					  ((csb1==0 & csb2==1) ? sdata1:
					  ((csb1==1 & csb2==0) ? sdata2:sdata1));
					 
assign	resetb = resetb1 & resetb2;
					 


	IDELAYCTRL IDELAYCTRL_refiod (
      //.RDY(rdy),       							// 1-bit ready output
      .REFCLK(clk_refiod), 					// 1-bit reference clock input
      .RST(!rstb)        						// 1-bit reset input
   );

//************************************************************************
// Registros provisionales de las señales del deserializador
//************************************************************************
//************************************************************************
// Sincronización de las señales del deserializador
//************************************************************************
// ADC1
/*
FIFO16x12 Adc1  (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),.din(CH0w),.wr_en(!DES1_run),.rd_en(!fempty1),.dout(CH0),.empty(fempty1));
FIFO16x12 Adc2  (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),.din(CH1w),.wr_en(!DES1_run),.rd_en(!fempty2),.dout(CH1),.empty(fempty2));
FIFO16x12 Adc3  (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),.din(CH2w),.wr_en(!DES1_run),.rd_en(!fempty3),.dout(CH2),.empty(fempty3));
FIFO16x12 Adc4  (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),.din(CH3w),.wr_en(!DES1_run),.rd_en(!fempty4),.dout(CH3),.empty(fempty4));
FIFO16x12 Adc5  (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),.din(CH4w),.wr_en(!DES1_run),.rd_en(!fempty5),.dout(CH4),.empty(fempty5));
FIFO16x12 Adc6  (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),.din(CH5w),.wr_en(!DES1_run),.rd_en(!fempty6),.dout(CH5),.empty(fempty6));
FIFO16x12 Adc7  (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),.din(CH6w),.wr_en(!DES1_run),.rd_en(!fempty7),.dout(CH6),.empty(fempty7));
FIFO16x12 Adc8  (.rst(!rstb),.wr_clk(FCO1),.rd_clk(clk),.din(CH7w),.wr_en(!DES1_run),.rd_en(!fempty8),.dout(CH7),.empty(fempty8));
// ADC2
FIFO16x12 Adc9  (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),.din(CH8w),.wr_en(!DES2_run),.rd_en(!fempty9),.dout(CH8),.empty(fempty9));
FIFO16x12 Adc10 (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),.din(CH9w),.wr_en(!DES2_run),.rd_en(!fempty10),.dout(CH9),.empty(fempty10));
FIFO16x12 Adc11 (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),.din(CH10w),.wr_en(!DES2_run),.rd_en(!fempty11),.dout(CH10),.empty(fempty11));
FIFO16x12 Adc12 (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),.din(CH11w),.wr_en(!DES2_run),.rd_en(!fempty12),.dout(CH11),.empty(fempty12));
FIFO16x12 Adc13 (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),.din(CH12w),.wr_en(!DES2_run),.rd_en(!fempty13),.dout(CH12),.empty(fempty13));
FIFO16x12 Adc14 (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),.din(CH13w),.wr_en(!DES2_run),.rd_en(!fempty14),.dout(CH13),.empty(fempty14));
FIFO16x12 Adc15 (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),.din(CH14w),.wr_en(!DES2_run),.rd_en(!fempty15),.dout(CH14),.empty(fempty15));
FIFO16x12 Adc16 (.rst(!rstb),.wr_clk(FCO2),.rd_clk(clk),.din(CH15w),.wr_en(!DES2_run),.rd_en(!fempty16),.dout(CH15),.empty(fempty16));
*/
//************************************************************************
//************************************************************************
assign CH0 = CH0w;
assign CH1 = CH1w;
assign CH2 = CH2w;
assign CH3 = CH3w;
assign CH4 = CH4w;
assign CH5 = CH5w;
assign CH6 = CH6w;
assign CH7 = CH7w;
assign CH8 = CH8w;
assign CH9 = CH9w;
assign CH10 = CH10w;
assign CH11 = CH11w;
assign CH12 = CH12w;
assign CH13 = CH13w;
assign CH14 = CH14w;
assign CH15 = CH15w;

endmodule