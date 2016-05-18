`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 			UPV
// Engineer:			Raúl Esteve Bosch 
// 
// Create Date:    	19:30:12 04/25/2007 
// Module Name:    	DCM_control 
// Project Name: 		PET16DAQ
// Revision: 
// Revision 0.01 - File Created
// Description:
// 	Bloque que controla el desplazamiento de fase (PS) de un DCM
//
//		Interpreta un comando que puede venir dado desde el PC o desde el
//		circuito de control automático de PS
//
//		Configura los ADCs con el patrón adecuado
//		
//////////////////////////////////////////////////////////////////////////////////
module DCM_ctrl
				#(
					 parameter [7:0]	DCO_ADJ 	= 8'h1F,
					 parameter [11:0] DCO_STABLE = 12'hFFF,
					 parameter [11:0]	FCO_STABLE = 12'hFFF,
		 			 parameter [11:0]	ADJ_TEST = 12'hFFF//,
					 
					 //parameter			TEST = 1'b0
				)
				(
					 clkin,
					 DCO, //FCO,
					 DCH_ok,
					 ramp_ok,
					 //DCH_par,
					 // DCMs configuración externa
					 dcm_init, dcm_conf,
					 //trsf_conf,
					 //fcoconf_en,
					 //dcm_dataPC,
					 end_ADCconf,
					 ADC_confwt,
					 
					 dcm_initauto,
					 					 
					 //ext_rst,
					 
					 sclk,
					 rstb, rstb_dcm,
					 DCO_des, //DCOn_des,
					 FCO_des,// FCOn_des, 
					 ADC_data,
					 DLY_adj,//DLY_adjf,
					 //DCH_adjpn,
					 DCMs_locked,
					 locked_DCO,
					 //locked_FCO,
					 DCM_confrun,
					 DCM_confend,
					 DCMps_sat,
					 
					 rst_ISERDconf,
					 rst_ISERD,
					 DES_rst,
					 
					 BS_init,
					 BS_confrun,
					 DCM_end,
					 
					 //pttn_en,
					 //FCO_runfine,
					 
					 //init_ADCconfTest,
					 //pttn_test,
					 //testpttn_run,
					 //ADC_run,
					 
					 end_sync,
					 
					 ADC_confrun
					 );
					 
	// Señales de reloj de los PADs
	input				DCO;
//	input				FCO;
	input				clkin;
	
	// Clk de control de los ADCs
	input				sclk;
	
	// Control datos ISERDES y patrones ADC
	input				DCH_ok;
	input				ramp_ok;
	//input	[1:0]		DCH_par;
	
	// DCM configuración externa
	input				dcm_init;
	input [7:0]		dcm_conf; // [FCO_DCO,rst,conf_PS,inc_dec,cycles(4bits)]
	//input [7:0]		dcm_dataPC; 
	//input				trsf_conf;
	//input				fcoconf_en;
	
	// Control ADCs
	input				end_ADCconf;
	input				ADC_confwt;
	// Inicio configuración automática después de configurar los ADCs 
	input				dcm_initauto;
	
	//input				ext_rst;
	
	input				rstb;
	input				rstb_dcm;
	
	// Relojes deserializadores
	output 			DCO_des;
	//output			DCOn_des;
	output			FCO_des;
	//output			FCOn_des;
	
	// Control ADCs - Ajuste de patrones para la sincronización del Deserializador
	output [4:0]	ADC_data;	//[confADC_init, pttn_sel]
	
	// Control de configuración automática
	output			DCMs_locked;
	output			locked_DCO;
	//output			locked_FCO;
	
	// Control de configuración de los DLYs
	output			DLY_adj;
	//output			DLY_adjf;
	
	//output			DCH_adjpn;
	
	// Salida de control de la sincronización de los ADCs
	output			DCM_confrun;
	
	// Salida de control para la Unidad de Control
	output			DCM_confend;
	
	// Salida de control del Phase Shift de los DCMs
	output [1:0]	DCMps_sat;
	
	output			rst_ISERDconf;
	output			rst_ISERD;
	
	output			DES_rst;	
	
	// Ajuste BITSLEEP
	output			BS_init;
	input				BS_confrun;
	
	// Almacenamiento en registro
	output			DCM_end;
	
//	output			pttn_en;
//	output			FCO_runfine;
	
//	output			init_ADCconfTest;
//	output [11:0]	pttn_test;
//	output			testpttn_run;
//	output			ADC_run;
	
	output			end_sync;
	
	output			ADC_confrun;

	
// Parametros utilizados en los DCMs
parameter   	PS_DCO  = 0;//175; 						// -37(2)	5(1)

// Declaración de señales
	wire [6:0]	ps_cycles, pscycles_auto, DCOps_cycles/*FCOps_cycles*/;
	wire [3:0]	pscycles_ext;
	
	wire			psen, psen_DCO, /*psen_FCO,*/ psen_ext;
	wire			psdone, psdone_DCO /*, psdone_FCO*/;
	wire			locked_DCO, DCMs_locked;
	
	//wire			FCODCOb_int;
	wire			inc_dec, ps_adj;
	wire [2:0]	op_ADC;
	wire [1:0]	DCMps_sat;
	wire			init_ADCconf, end_DCMconf;
	
	wire			DCM_autorun, DCM_confrun, DCO_confrun, /*FCO_confrun,*/ ramp_run, rst_run, syncrst_run;
	wire			ps_end, end_sync, ps_endext, psincdec_ext;
	
	wire [15:0] DO_DCO;
	
	wire			dcmrst, dcmrst_DCO, rst_iserdes, DES_rstw;
	wire			rst_end; 
	
	//wire 			DCOadj_fine;
	wire			DCOps_adj;//, FCOps_adj;
	wire			DCOinc_dec;//, FCOinc_dec;
	wire			DCOend_conf;//, FCOend_conf, test_end;
	
	wire			/*init_FCOconf,*/ init_DCOconf, init_DCMconf;

// El rst de los ISERDES debe producirse cada vez que se modifica la fase de FCO
// En esta configuración se modifica la fase de DCO solamente
	assign		rst_ISERDconf	= init_DCOconf;
	assign		rst_ISERD		= rst_iserdes;

// Datos para modificar PS desde el PC
	assign		psadj_ext 		= dcm_init & !dcm_conf[6];
	assign		dcmconf_ext 	= dcm_init & dcm_conf[7] & !dcm_conf[6];
	assign		dcmrst_ext 		= dcm_init & dcm_conf[6]; // Al menos tres ciclos!
	//assign		FCODCOb_ext		= dcm_conf[5];
	assign		psincdec_ext	= dcm_conf[4];
	assign		pscycles_ext	= dcm_conf[3:0];

// Señales de control de PS
	// Paso para PS - Valor por defecto = 10	
	assign		pscycles_auto 	= (DCO_confrun) ? DCOps_cycles:7'h00;
	assign		ps_cycles   	= (DCM_autorun) ? pscycles_auto:{3'b000,pscycles_ext};
	
	// PS DCO signals
	assign		psen_DCO		 	= (psen | psen_ext);
	assign		psincdec_DCO	= (psen | psen_ext) & (inc_dec | psincdec_ext);

	// Salidas de los DCMs
	assign		psdone			= psdone_DCO; 
	
	assign		DCMs_locked		= locked_DCO;

	assign		DCMps_sat		= {1'b0,DO_DCO[0]};

	// Inicialización de PS control
	assign		ps_init			= ps_adj & DCMs_locked;
	
	assign		ps_initext		= psadj_ext & DCMs_locked;


// Inicialización del ajuste automático de DCO y FCO
	assign		sync_init 		= (dcm_initauto | dcmconf_ext) & DCMs_locked;
	
// Señales de control de patrones de los ADCs - Configuración automática
	// El patron por defecto es Deskew
	// Referencia valor registros de configuración del ADC
	//	((reg_sel == 4'b0001) ? sbits_pttn:
	//	((reg_sel == 4'b0010) ? dbits_pttn:
	//	((reg_sel == 4'b0011) ? deskew_pttn:
	//	((reg_sel == 4'b0100) ? sync_pttn:
	//	((reg_sel == 4'b0101) ? scustom_pttn:
	//	((reg_sel == 4'b0110) ? dcustom_pttn:
	//	((reg_sel == 4'b0111) ? ramp_pttn:
	//	((reg_sel == 4'b1000) ? pwrdown:
	//	((reg_sel == 4'b1001) ? del25:
	//	((reg_sel == 4'b1010) ? del45:
	
	assign		ADC_data[3:0] = (op_ADC==3'b000) ? 4'b0011: 			// Deskew_pttn 
								   	((op_ADC==3'b001) ? 4'b0100: 			// Sync_pttn
										((op_ADC==3'b010) ? 4'b0101: 			// scustom_pttn
										((op_ADC==3'b011) ? 4'b0111: 			// Ramp_pttn
										((op_ADC==3'b100) ? 4'b0000: 			// Normal operation
										((op_ADC==3'b101) ? 4'b1001: 			// Borrado registro 25
										((op_ADC==3'b110) ? 4'b1010: 			// Borrado registro 45
										 					     4'b0000))))));	// Normal operation
			
	assign		ADC_data[4]		= init_ADCconf;

	assign		DCM_confrun		= DCO_confrun |/* FCO_confrun |*/ DCM_autorun | ramp_run | rst_run | syncrst_run;
	
	// Esta señal indica a la Unidad de Control que el cmd ha sido ejecutado
	assign		DCM_confend		= (DCM_autorun) ? end_sync:(ps_end | ps_endext | rst_end);
	
	assign		init_DCOconf = init_DCMconf;//; & !FCODCOb_int;
	//assign		init_FCOconf = init_DCMconf & FCODCOb_int;
	
	assign		ps_adj  = DCOps_adj;// | FCOps_adj;
	assign		inc_dec = DCOinc_dec;// | FCOinc_dec;
	assign		end_DCMconf = DCOend_conf;// | test_end;

	//assign 		locked_FCO = 1'b1;
	
	
	wire			rstb_aux;
	
	assign		rstb_aux = rstb & DCMs_locked;
	
	assign		DES_rst	= DCMs_locked;
		

	Sync2a1 Sync_ADCl (
    .x(end_ADCconf), 
    .rstb(rstb_aux), 
    .clk1(FCO_des), 
    .y(end_ADCconfs));

// Control automático DCO y FCO
	SyncDCMs_Ctrl
//				#(
//				.TEST(TEST)
//				)
	SyncDCMs_Ctrl
				(
				.init(sync_init), 
				.ADC_confwt(ADC_confwt),.end_ADCconf(end_ADCconfs),
				.end_DCMconf(end_DCMconf),
				//.fcoconf_en(1'b1),//fcoconf_en),
				.end_ramp(end_ramp),
				.clk(FCO_des),.rstb(rstb_aux), 
				.init_ADCconf(init_ADCconf),.init_DCMconf(init_DCMconf),
				.init_ramp(init_ramp),	
				//.FCO_DCOb(FCODCOb_int),
				.op_ADC(op_ADC), 
				.end_sync(end_sync),.DCM_end(DCM_end),
				.BS_init(BS_init),.BS_confrun(BS_confrun),
				.run(DCM_autorun),
				.ADC_confrun(ADC_confrun)
				);
	

	SyncDCO_Ctrl 
				#(
				.DCO_ADJ(DCO_ADJ),
				.DCO_STABLE(DCO_STABLE)
	 			)
	SyncDCO_Ctrl			
				(
				.init(init_DCOconf), 
				.DCH_ok(DCH_ok),
				.ps_end(ps_end),
				.psen(psen),
				.rstb(rstb_aux),.clk(FCO_des), 
				.adj_dly(DLY_adj),
				.adj(DCOps_adj),
				.inc_dec(DCOinc_dec),
				.adj_end(DCOend_conf),
				.ps_cycles(DCOps_cycles),
				.run(DCO_confrun)
				);
	
				
	Ramp_Ctrl
				#(
				.DCO_STABLE(DCO_STABLE)
				)
	Ramp_Ctrl
				(
				.init(init_ramp), 
				.ramp_ok(ramp_ok), 
				.clk(FCO_des), 
				.rstb(rstb_aux), 
				.end_ramp(end_ramp), 
				.DES_rst(DES_rstw), 
				.run(ramp_run)
				);				

// Se intenta deserializar un número determinado de ciclos
// Esto impide que se bloquee el circuito de control
reg [3:0]	ramp_cnt;

assign		end_des = (ramp_cnt == 4'hF) ? 1'b1:1'b0;

assign		DES_rstaux = DES_rstw & !end_des;

	always @(posedge FCO_des or negedge rstb)
	begin
		if (!rstb)
		begin
			ramp_cnt <= 4'h0;
		end
		else
		begin
		if ((end_sync & end_des) | (!DES_rstw & end_ramp))
			ramp_cnt <= 4'h0;
		else
			if (init_ramp)
				ramp_cnt <= ramp_cnt + 1'b1;	
		end
	end				
				
// Phase Shift control	
	PS_ctrl PS_ctrl (.init(ps_init),.cycles(ps_cycles),.psdone(psdone),
						  .rstb(rstb_aux),.clk(FCO_des), 
    					  .psen(psen),.ps_end(ps_end));
						  
	PS_ctrl PS_ctrlext (.init(ps_initext),.cycles(ps_cycles),.psdone(psdone),
							  .rstb(rstb_aux),.clk(FCO_des), 
    					     .psen(psen_ext),.ps_end(ps_endext));										  
								  
// Acondicionamiento del reset de los DCMs
// El rst debe ser al menos 3 ciclos de la entrada de reloj
assign	dcmrst_DCO 	= dcmrst;// & !FCODCOb;

Sync1a2 Sync_ADC3(
		.x(DES_rstaux),
		.rstb(rstb),.clk1(FCO_des),.clk2(sclk),
		.y(DES_rsts),
		.run(syncrst_run));

DCMrst_Ctrl DCMrst_Ctrl (
    .init(dcmrst_ext | DES_rsts/* | ext_rst*/),  
    .locked(DCMs_locked), 
    .rstb(rstb), 
    .clk(sclk), 
    .rst_dcm(dcmrst),
	 .rst_iserdes(rst_iserdes),	
    .rst_end(rst_end),
	 .rst_run(rst_run)
    );




// Unidad de adecuación y generación de las señales de reloj DCO y FCO
// A partir de un DCM se genera DCO, y con el mismo DCM y un BUFR se genera FCO
// FCO es una versión de DCO, dividida por 6 y desplazada 270º
// De esta manera, FCO queda sincronicada con los datos
// Los datos son ajustados por SyncDCO_Ctrl
reg	buffco_en, FCOr, FCOrr;
wire	rstb_buf = rstb & locked_DCO; 

	always @(posedge DCO_des or negedge rstb_buf)
	begin
		if (!rstb_buf)
			buffco_en <= 1'b0;
		else
			if (locked_DCO & FCOr & !FCOrr)
				buffco_en <= 1'b1;
	end

	always @(posedge DCO_des or negedge rstb)
	begin
		if (!rstb)
		begin
			FCOr <= 1'b0;
			FCOrr <= 1'b0;
		end	
		else
		begin
//			FCOr <= FCO;
			FCOr <= clkin;
			FCOrr <= FCOr;
		end		
	end	


	BUFG bufg_DCO   (.O (DCO_des),.I (DCO_buf));
	
	BUFR #(
      .BUFR_DIVIDE("6"),		 					// "BYPASS", "1", "2", "3", "4", "5", "6", "7", "8" 
      .SIM_DEVICE("VIRTEX6")  					// Specify target device, "VIRTEX4" or "VIRTEX5" 
   ) BUFR_FCO (
		.O(FCO_deso),.I(DCO_des),
		.CE(buffco_en),.CLR(!rstb & locked_DCO));
	
//	BUFG bufg_FCO2  (.O (FCO_des),.I (FCO_deso));
	assign FCO_des = clkin;
	
	MMCM_ADV #(
      .BANDWIDTH("OPTIMIZED"),   // Jitter programming ("HIGH","LOW","OPTIMIZED")
      .CLKFBOUT_MULT_F(8.0),     // Multiply value for all CLKOUT (5.0-64.0).
      .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (0.00-360.00).
      .CLKIN1_PERIOD(4.160),     // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      .CLKOUT0_DIVIDE_F(4.0),    // Divide amount for CLKOUT0 (1.000-128.000).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(135.0),
      .CLKOUT1_DIVIDE(24),
      .CLKOUT4_CASCADE("FALSE"), // Cascase CLKOUT4 counter with CLKOUT6 (TRUE/FALSE)
      .CLOCK_HOLD("FALSE"),      // Hold VCO Frequency (TRUE/FALSE)
      .DIVCLK_DIVIDE(2),         // Master division value (1-80)
      .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
      .STARTUP_WAIT("FALSE"),     // Not supported. Must be set to FALSE.
		// USE_FINE_PS: Fine phase shift enable (TRUE/FALSE)
      .CLKFBOUT_USE_FINE_PS("FALSE"),
      .CLKOUT0_USE_FINE_PS("TRUE"),
      .CLKOUT1_USE_FINE_PS("TRUE"),
      .CLKOUT2_USE_FINE_PS("FALSE"),
      .CLKOUT3_USE_FINE_PS("FALSE"),
      .CLKOUT4_USE_FINE_PS("FALSE"),
      .CLKOUT5_USE_FINE_PS("FALSE"),
      .CLKOUT6_USE_FINE_PS("FALSE") 
		
   )
   MMCM_ADV_des (
      // Clock Outputs: 1-bit (each) User configurable clock outputs
      .CLKOUT0(DCO_buf),     		// 1-bit CLKOUT0 output
      //.CLKOUT1(FCO_buf),     		// 1-bit CLKOUT1 output
      // Feedback Clocks: 1-bit (each) Clock feedback ports
      .CLKFBOUT(DCO_fbout),   	// 1-bit Feedback clock output
      //.CLKFBOUTB(CLKFBOUTB), 	// 1-bit Inverted CLKFBOUT output
      // Status Port: 1-bit (each) MMCM status ports
      .LOCKED(locked_DCO),       // 1-bit LOCK output
      // Clock Input: 1-bit (each) Clock input
      .CLKIN1(DCO),
      // Control Ports: 1-bit (each) MMCM control ports
      .PWRDWN(1'b0),       		// 1-bit Power-down input
      .RST(!rstb_dcm | dcmrst_DCO),	
      // Feedback Clocks: 1-bit (each) Clock feedback ports
      .CLKFBIN(DCO_fbout),      	// 1-bit Feedback clock input
      // Dynamic Phase Shift Ports: 1-bit (each) Ports used for dynamic phase shifting of the outputs
      .PSCLK(FCO_des),               // 1-bit Phase shift clock input
      .PSEN(psen_DCO),                 // 1-bit Phase shift enable input
      .PSINCDEC(psincdec_DCO),         // 1-bit Phase shift increment/decrement input
      .PSDONE(psdone_DCO)     					// Dynamic phase adjust done output
   );



endmodule
