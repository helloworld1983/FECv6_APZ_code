`timescale 1ns / 1ps

module Des_ADC
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
		sclk,
		//clk_refiod,
		rstb, rstb_dcm,
		
		// ADC configuración externa
		adc_init, adc_conf,
		
		// DCMs configuración externa
		dcm_init, dcm_conf,
		
		//trsf_conf,
		//fcoconf_en,
		// Configuracion en espera
		ADC_confwt,auto_runwt,
		
		// ADC1
		FCO,
		DCO,
		DCH1, DCH2, DCH3, DCH4, DCH5, DCH6, DCH7, DCH8,
				
		//Outputs
		des_DCH1, des_DCH2, des_DCH3, des_DCH4,
		des_DCH5, des_DCH6, des_DCH7, des_DCH8,
		
		FCO_out,
		
		// Señales de configuración del ADC
		csb, sdata, pwb, resetb,
		
		// Señales de control del ADC
		conf_end,
		
		// Señales de control de los DCMs
		//DCMs_locked,
		DES_run, DES_status,
		
		ADC_confrun, auto_run,
		
		//SOLO SIMULACION
		pttn_sel//, ADC_run
		);
		
	// Señal de control del ADC
	input				sclk;
	//input				clk_refiod;
	
	input				rstb;
	input				rstb_dcm;
	
	// Configuración externa
	input				adc_init;
	input [23:0]	adc_conf;
	input				dcm_init;
	input [7:0]		dcm_conf;
	
	// Configuración en espera
	input				ADC_confwt;
	input				auto_runwt;
	
	//input				trsf_conf;
	//input				fcoconf_en;
	
	//	ADC1
	input				FCO;
	input				DCO;
	input				DCH1;
	input				DCH2;
	input				DCH3;
	input				DCH4;
	input				DCH5;
	input				DCH6;
	input				DCH7;
	input				DCH8;

	//	Deserialized outputs
	output [11:0]	des_DCH1;
	output [11:0]	des_DCH2;
	output [11:0]	des_DCH3;
	output [11:0]	des_DCH4;
	output [11:0]	des_DCH5;
	output [11:0]	des_DCH6;
	output [11:0]	des_DCH7;
	output [11:0]	des_DCH8;
	
	output			FCO_out;
	
	// Señales de configuración del ADC
	output			csb;
	output			sdata;
	output			pwb;
	output			resetb;
	
	// Señales de control del ADC
	output			conf_end;
	
	// Señales de control de los DCMs
	//output		DCMs_locked;
	output			DES_run;
	output [10:0]	DES_status;
	
	// Bloque de la configuración de cada ADC
	output			ADC_confrun;
	output			auto_run;
	
	// Reset de toda la unidad
	//output			DES_rst;

	
	//SOLO SIMULACION
	output [3:0]	pttn_sel;
	//output			ADC_run;
	
	
//*************************************************************************************************************************************
// Declaración de señales
wire			DCH_ok, DCH1_ok, DCH2_ok, DCH3_ok, DCH4_ok,
				DCH5_ok, DCH6_ok, DCH7_ok, DCH8_ok;
				
wire			ramp_ok, ramp_ok1, ramp_ok2, ramp_ok3, ramp_ok4,
				ramp_ok5, ramp_ok6, ramp_ok7, ramp_ok8;					

wire			BS_confrun1,BS_confrun2,BS_confrun3,BS_confrun4,
				BS_confrun5,BS_confrun6,BS_confrun7,BS_confrun8;		
					
wire			DCO_locked;//,FCO_locked;

//Registro de estado del bloque deserializador
//	[0]		DCO_locked
//	[1]		FCO_locked
// [2]		DCMps_sat[0] - PS de DCM de DCO saturado
// [3]		DCMps_sat[1] - PS de DCM de FCO saturado
// [4:11]	DCH_adj 		 - Canal del 1 al 8 ajustado

wire			DES_run, ADC_confrun, ADC_confrunp, DCM_confrun, DCM_end, DES_rst, auto_block;
wire [7:0]	DCH_adj, DCH_adj1, DCH_adj2, pwdown_ch;
wire [10:0]	DES_status;
wire [1:0]	DCMps_sat;
//wire [1:0]	DCH_par;

wire			FCO_des, end_sync;


reg [7:0]	DCH_adjr1, DCH_adjr2;

assign 		DCH_adj1		= {DCH8_ok,DCH7_ok,DCH6_ok,DCH5_ok,
									DCH4_ok,DCH3_ok,DCH2_ok,DCH1_ok};
									
assign 		DCH_adj2		= {ramp_ok8,ramp_ok7,ramp_ok6,ramp_ok5,
									ramp_ok4,ramp_ok3,ramp_ok2,ramp_ok1};									

assign		DCH_adj		= DCH_adjr1 & DCH_adjr2;

assign		DES_status	= {DCH_adj,DCMps_sat,
									DCO_locked};
									
assign		DES_run		= ADC_confrunp | DCM_confrun;

assign		BS_confrun	= BS_confrun1 | BS_confrun2 | BS_confrun3 | BS_confrun4 |
								  BS_confrun5 | BS_confrun6 | BS_confrun7 | BS_confrun8;				

//assign		ADC_confrun = ADC_confrunp;// | auto_block;

// Almacenamiento en registro del estado de los ISERDES
always @(posedge FCO_des or negedge rstb)
	begin
		if (!rstb)
		begin
			DCH_adjr1 <= 8'h00;
			DCH_adjr2 <= 8'h00;
		end
		else
		begin
			if (DCM_end)
				DCH_adjr1 <= DCH_adj1;
				
			if (end_sync)
				DCH_adjr2 <= DCH_adj2;
		end
	end



//*************************************************************************************************************************************
// Asignación de señales

	assign 	FCO_out 	= FCO_des;
	
	wire		conf_end, ADC_confend, DCM_confend;
	
	assign	conf_end	= ADC_confend | DCM_confend;
	
//*************************************************************************************************************************************
//*************************************************************************************************************************************
// Instanciación de módulos

//**************************************************************************************************
// Control y configuración automática de ADCs 
//**************************************************************************************************
// Dominio de reloj: SCLK

	wire [11:0]	DCH_pttn;
	wire	[4:0]	ADC_confdes;
	wire	[4:0]	ADC_confdess;
	//wire [11:0]	pttn_test;

	
	ADC_interface
	//#(
	//	.ADJ_ADCRST(ADJ_ADCRST)
	//)	
	ADC_interface
	(
		.adc_init(adc_init),
		.adc_conf(adc_conf),
		.adc_confdes(ADC_confdess),	//Ajuste de patrones para la sincronización del Deserializador
		.DCMs_locked(DCMs_locked),
		.DCM_confrun(DCM_confrun),
		
		.ADC_confwt(ADC_confwt),.auto_runwt(auto_runwt),
		
		//.init_ADCconfTest(init_ADCconfTest),
		//.pttn_test(pttn_test),
		//.testpttn_run(testpttn_run),
		
		.rstb(rstb),
		.DES_rst(DES_rst), 
		.sclk(sclk), 					//Reloj de configuración del ADC - 20MHz max!
		.csb(csb), 
		.sdata(sdata), 
		.pwb(pwb), 
		.resetb(resetb),
		.end_conf(ADC_confend),
		.pttn(DCH_pttn),
		.end_autoconf(dcm_initauto),
		.adc_confrun(ADC_confrunp),
		//.ext_rst(ext_rst),
		
		.auto_run(auto_run),
		
		.pttn_sel(pttn_sel),
		.pwdown_ch(pwdown_ch)
		);
	 
//**************************************************************************************************
// Control y configuración automática de DCMs 
//**************************************************************************************************
// Unidad de adecuación y generación de las señales de reloj
// Control de desplazamiento de fase (PS) de los DCMs

// Dominio de reloj: DCO

// Señales a clk70!!!
assign			DCH_ok   	= (DCH1_ok | pwdown_ch[0]) & (DCH2_ok | pwdown_ch[1]) &
									  (DCH3_ok | pwdown_ch[2]) & (DCH4_ok | pwdown_ch[3]) &
									  (DCH5_ok | pwdown_ch[4]) & (DCH6_ok | pwdown_ch[5]) & 
									  (DCH7_ok | pwdown_ch[6]) & (DCH8_ok | pwdown_ch[7]);
								

assign			ramp_ok		= (ramp_ok1 | pwdown_ch[0]) & (ramp_ok2 | pwdown_ch[1]) & 
									  (ramp_ok3 | pwdown_ch[2]) & (ramp_ok4 | pwdown_ch[3]) &
									  (ramp_ok5 | pwdown_ch[4]) & (ramp_ok6 | pwdown_ch[5]) &
									  (ramp_ok7 | pwdown_ch[6]) & (ramp_ok8 | pwdown_ch[7]);						

DCM_ctrl 
	#(
		.DCO_ADJ(DCO_ADJ),
		.DCO_STABLE(DCO_STABLE),
		.FCO_STABLE(FCO_STABLE),
		.ADJ_TEST(ADJ_TEST)//,
		
		//.TEST(TEST)
	)
DCM_ctrl 
	(
		.FCO(FCO),
		.DCO(DCO),
		.DCH_ok(DCH_ok),
		.ramp_ok(ramp_ok),
		.end_ADCconf(ADC_confend),
		.dcm_initauto(dcm_initauto),
		.dcm_init(dcm_init),
		.dcm_conf(dcm_conf),
		
		.ADC_confwt(ADC_confwt),
		//.trsf_conf(trsf_conf),
		
		//.ext_rst(ext_rst),
		
		.sclk(sclk),
		.rstb(rstb), .rstb_dcm(rstb_dcm),
		.DCO_des(DCO_des),
		//.DCOn_des(DCOn_des),
		
		.FCO_des(FCO_des),
		.ADC_data(ADC_confdes), //Ajuste de patrones para la sincronización del Deserializador
		.DLY_adj(DLY_adj),
		.DCMs_locked(DCMs_locked),
		.locked_DCO(DCO_locked),
		//.locked_FCO(FCO_locked),
		.DCM_confrun(DCM_confrun),
		.DCM_confend(DCM_confend),
		.DCMps_sat(DCMps_sat),
		
		.rst_ISERDconf(rst_ISERDconf),
		.rst_ISERD(rst_ISERD),
		.DES_rst(DES_rst),
		
		.BS_init(BS_init),
		.BS_confrun(BS_confrun),
		.DCM_end(DCM_end),
		
		//.init_ADCconfTest(init_ADCconfTest),
		//.pttn_test(pttn_test),
		//.testpttn_run(testpttn_run),
		//.ADC_run(ADC_run),
		
		.end_sync(end_sync),
		
		.ADC_confrun(ADC_confrun)
    );


//**************************************************************************************************
// Deserializador 
//**************************************************************************************************
// ADC
//wire 		DLY_adjs;
	
	Des_DCH
			#(
			.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
			.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
			.IODELAY_GRP(IODELAY_GRP)
			)
			 Des_DCH1
			(
			.rstb(rstb),
			.FCO(FCO_des),
			.DCO(DCO_des),
			//.DCOn(DCOn_des),
			.DCH(DCH1),
			.rst_ISERDconf(rst_ISERDconf),
			.rst_ISERD(rst_ISERD),
			.DCH_pttn(DCH_pttn),	
			.DLY_adj(DLY_adj),
			.des_DCH(des_DCH1),
			.DCH_ok(DCH1_ok),
			.BS_init(BS_init),
			.BS_confrun(BS_confrun1),
			.ramp_ok(ramp_ok1)
			);
			
	Des_DCH
			#(
			.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
			.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
			.IODELAY_GRP(IODELAY_GRP)
			)
			Des_DCH2
			(
			.rstb(rstb), 
			.FCO(FCO_des),
			.DCO(DCO_des), 
			//.DCOn(DCOn_des),
			.DCH(DCH2),
			.rst_ISERDconf(rst_ISERDconf),
			.rst_ISERD(rst_ISERD),
			.DCH_pttn(DCH_pttn),
			.DLY_adj(DLY_adj),
			.des_DCH(des_DCH2),
			.DCH_ok(DCH2_ok),
			.BS_init(BS_init),
			.BS_confrun(BS_confrun2),
			.ramp_ok(ramp_ok2)
			);

	Des_DCH
			#(
			.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
			.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
			.IODELAY_GRP(IODELAY_GRP)
			)
			Des_DCH3
			(
			.rstb(rstb),
			.FCO(FCO_des),
			.DCO(DCO_des), 
			//.DCOn(DCOn_des),
			.DCH(DCH3),
			.rst_ISERDconf(rst_ISERDconf),
			.rst_ISERD(rst_ISERD),
			.DCH_pttn(DCH_pttn),	
			.DLY_adj(DLY_adj),
			.des_DCH(des_DCH3),
			.DCH_ok(DCH3_ok),
			.BS_init(BS_init),
			.BS_confrun(BS_confrun3),
			.ramp_ok(ramp_ok3)
			);

	Des_DCH
			#(
			.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
			.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
			.IODELAY_GRP(IODELAY_GRP)
			)
			Des_DCH4
			(
			.rstb(rstb), 
			.FCO(FCO_des),
			.DCO(DCO_des), 
			//.DCOn(DCOn_des),
			.DCH(DCH4),
			.rst_ISERDconf(rst_ISERDconf),
			.rst_ISERD(rst_ISERD),
			.DCH_pttn(DCH_pttn),	
			.DLY_adj(DLY_adj),
			.des_DCH(des_DCH4),
			.DCH_ok(DCH4_ok),
			.BS_init(BS_init),
			.BS_confrun(BS_confrun4),
			.ramp_ok(ramp_ok4)
			);

	Des_DCH
			#(
			.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
			.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
			.IODELAY_GRP(IODELAY_GRP)
			)
			Des_DCH5
			(
			.rstb(rstb), 
			.FCO(FCO_des),
			.DCO(DCO_des), 
			//.DCOn(DCOn_des),
			.DCH(DCH5),
			.rst_ISERDconf(rst_ISERDconf),
			.rst_ISERD(rst_ISERD),
			.DCH_pttn(DCH_pttn),	
			.DLY_adj(DLY_adj),
			.des_DCH(des_DCH5),
			.DCH_ok(DCH5_ok),
			.BS_init(BS_init),
			.BS_confrun(BS_confrun5),
			.ramp_ok(ramp_ok5)
			);
			
	Des_DCH
			#(
			.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
			.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
			.IODELAY_GRP(IODELAY_GRP)
			)
			Des_DCH6
			(
			.rstb(rstb), 
			.FCO(FCO_des),
			.DCO(DCO_des), 
			//.DCOn(DCOn_des),
			.DCH(DCH6),
			.rst_ISERDconf(rst_ISERDconf),
			.rst_ISERD(rst_ISERD),
			.DCH_pttn(DCH_pttn),	
			.DLY_adj(DLY_adj),
			.des_DCH(des_DCH6),
			.DCH_ok(DCH6_ok),
			.BS_init(BS_init),
			.BS_confrun(BS_confrun6),
			.ramp_ok(ramp_ok6)
			);

	Des_DCH
			#(
			.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
			.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
			.IODELAY_GRP(IODELAY_GRP)
			)
			Des_DCH7
			(
			.rstb(rstb), 
			.FCO(FCO_des),
			//.DCOn(DCOn_des),
			.DCO(DCO_des), 
			.DCH(DCH7),
			.rst_ISERDconf(rst_ISERDconf),
			.rst_ISERD(rst_ISERD),
			.DCH_pttn(DCH_pttn),	
			.DLY_adj(DLY_adj),
			.des_DCH(des_DCH7),
			.DCH_ok(DCH7_ok),
			.BS_init(BS_init),
			.BS_confrun(BS_confrun7),
			.ramp_ok(ramp_ok7)
			);

	Des_DCH
			#(
			.SIGNAL_LEVEL1(SIGNAL_LEVEL1),	//1975
			.SIGNAL_LEVEL2(SIGNAL_LEVEL2), 	//2025
			.IODELAY_GRP(IODELAY_GRP)
			)
			Des_DCH8
			(
			.rstb(rstb), 
			.FCO(FCO_des),
			.DCO(DCO_des), 
			//.DCOn(DCOn_des),
			.DCH(DCH8),
			.rst_ISERDconf(rst_ISERDconf),
			.rst_ISERD(rst_ISERD),
			.DCH_pttn(DCH_pttn),	
			.DLY_adj(DLY_adj),
			.des_DCH(des_DCH8),
			.DCH_ok(DCH8_ok),
			.BS_init(BS_init),
			.BS_confrun(BS_confrun8),
			.ramp_ok(ramp_ok8)
			);						


// Dominio 70 MHz al dominio SCLK (20 MHz)
Sync1a2b Sync_ADC2(
		.x(ADC_confdes[0]),
		.rstb(rstb),.clk2(sclk),
		.y(ADC_confdess[0]));
		
Sync1a2b Sync_ADC3(
		.x(ADC_confdes[1]),
		.rstb(rstb),.clk2(sclk),
		.y(ADC_confdess[1]));
		
Sync1a2b Sync_ADC4(
		.x(ADC_confdes[2]),
		.rstb(rstb),.clk2(sclk),
		.y(ADC_confdess[2]));
		
Sync1a2b Sync_ADC5(
		.x(ADC_confdes[3]),
		.rstb(rstb),.clk2(sclk),
		.y(ADC_confdess[3]));
		
Sync1a2 Sync_ADC6(
		.x(ADC_confdes[4]),
		.rstb(rstb),.clk1(FCO_des),.clk2(sclk),
		.y(ADC_confdess[4]));

//IDELAYCTRL IDELAYCTRL_refiod (
//      //.RDY(rdy),       							// 1-bit ready output
//      .REFCLK(clk_refiod), 					// 1-bit reference clock input
//      .RST(!rstb)        						// 1-bit reset input
//   );

	 
endmodule