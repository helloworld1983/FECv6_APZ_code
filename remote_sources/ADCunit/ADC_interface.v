`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		UPV
// Engineer: 		Raúl Esteve Bosch
// 
// Create Date:   12:06:42 04/30/2007 
// Design Name: 
// Module Name:   ADC_interface 
// Project Name: 
// Description:	Interfaz de control de los ADCs de Texas Instruments ADS55251/2 
//			
// 					Modo automatico inicial y configuración registro a registro
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ADC_interface
		//#(
		//parameter [10:0]	ADJ_ADCRST = 11'h3FF
		//)
		(
		adc_init, adc_conf,
		adc_confdes,
		DCMs_locked,
		DCM_confrun,
		
		ADC_confwt,auto_runwt,
				
		//init_ADCconfTest,
		//pttn_test,
		//testpttn_run,

		rstb, DES_rst, sclk,
		csb,sdata,pwb,resetb,
		end_conf,
		end_autoconf,
		adc_confrun,
		//ext_rst,
		
		auto_run,
		
		pttn,
		pwdown_ch,
				
		pttn_sel);
	
	// Configuración externa o automática
	input				adc_init;
	input [23:0]	adc_conf;
	// Ajuste de patrones para la sincronización del Deserializador
	input [4:0]		adc_confdes;
	
	// Indicador
	input				DCMs_locked;
	input				DCM_confrun;
	
	input				ADC_confwt;
	input				auto_runwt;
	
	//input				init_ADCconfTest;
	//input [11:0]	pttn_test;
	//input				testpttn_run;
	
	input 			rstb;
	input				DES_rst;
	input				sclk;			// Este reloj debe ser de 20MHz máx.
	
	// Señales de configuración del ADC
	output			csb;
	output			sdata;
	output			pwb;
	output			resetb;
	
	// Señales de control
	output			end_conf;
	output			end_autoconf;
	output			adc_confrun;
	
	//output			ext_rst;
	
	output [7:0]	pwdown_ch;
	
	output			auto_run;
	
	// Solo para test
	output [11:0]	pttn;
	
	//SOLO SIMULACION
	output [3:0]	pttn_sel;

	reg	[23:0]	reg_desp;
	reg 	[7:0]		pwdown_ch;

	reg				sdata, csb;
	
	//reg				adc_rstb1p;

	wire	[23:0]	reg_out, reg_outaux;
	wire				adc_initauto, end_auto, end_autoconf, end_autoconfaux;
	wire				init_reg, incr_reg;
	wire				auto_run, adc_confrun, adc_confrunaux;//, ADCTest_run;
	wire				/*ext_rst,*/ adc_initext;

	wire				csb_aux;
	wire				end_conf, end_confaux;
	
	wire  [3:0]		pttn_sel;

	assign 			resetb 	= rstb;		// Activa a nivel bajo
	assign 			pwb 		= 1'b0;		// Activa a nivel bajo
	
	assign			adc_confrun = auto_run | (adc_confrunaux);// & !ADCTest_run
	
// Datos externos
	// Reset del ADC - Ahora mediante un registro - 00_0001h
	//assign		ext_rst 	= adc_init & adc_conf[7];
	
	// Inicia la configuración automática
	assign		adc_initdes = adc_confdes[4];

// Mux para seleccionar señales del modo automático o externas
	assign		adc_initext	= adc_init;
	
	assign		adc_initaux = adc_initauto | adc_initdes | adc_initext;// | adc_initTest;
	
// Mux para la eleccion del patron de test

	assign		pttn_sel 	= /*(ADCTest_run) ? pttn_selTest:*/adc_confdes[3:0];
	
	
	assign		pttn = (pttn_sel == 4'b0011) ? 12'b010101010101: // Deskew pttn
							((pttn_sel == 4'b0100) ? 12'b111111000000: // Sync pttn
							((pttn_sel == 4'b0101) ? 12'b101010101010: // Custom pttn
							//((pttn_sel == 4'b0111) ? pttn_test: 		 // Rampa pttn
																 12'h000));       // Normal Op.


// Inicio configuración DCM cuando se ha terminado la conf. auto. de los ADCs
// No se vuelven a configurar los DCMs si se ha enviado un cmd de reset de los ADCs
	assign 		end_autoconf = end_autoconfaux;
	
	assign		end_conf = (auto_run) ? (end_autoconfaux/* | end_ADCTestconf*/):end_confaux; 
	
	assign		rstb_aux	= rstb & DES_rst;

// Registros para la configuración automática
ADCreg_unit ADCreg_unit (
	.init_reg(init_reg), 
   .incr_reg(incr_reg),
	.auto_run(auto_run),
	.pwdown_ch(pwdown_ch),
	.pttn_sel(pttn_sel),
	
	//.pttn_test(pttn_test),
	
   .rstb(rstb_aux), 
   .clk(sclk), 
   .reg_out(reg_outaux),
	.end_auto(end_auto)
    );

// Control de la configuración automática
ADCaut_ctrl
	//#(
	//	.ADJ_ADCRST(ADJ_ADCRST)
	//)
	ADCaut_ctrl
	(
   .init(DCMs_locked),
	.adc_rst(1'b0),//ext_rst),
	.end_conf(end_confaux),  	// Fin de configuración de registro
   .end_auto(end_auto), 		//	Fin de configuración automática
	.auto_runwt(auto_runwt),
   .rstb(rstb_aux), 
   .clk(sclk), 
   .init_reg(init_reg), 
   .incr_reg(incr_reg), 
   .init_auto(adc_initauto), 
	//.auto_run(auto_block),
   .run(auto_run),
	.end_autoconf(end_autoconfaux)	
    );

// Implementa el protocolo para enviar los registros de configuración al ADC
ADCcfg_ctrl ADCcfg_ctrl (
   .init_conf(adc_initaux), 
   .rstb(rstb_aux), 
   .clk(sclk), 
   .load(load), 
   .csb(csb_aux),
	.end_conf(end_confaux),
	.conf_run(adc_confrunaux)
    );


// Detección de desactivación de canal
always @(negedge sclk or negedge rstb) 
begin
  	if (!rstb)
  		pwdown_ch <= 8'h00;
	else
  		begin
  			if (adc_init)
				if (adc_conf[23:8] == 16'h0F_02)
					pwdown_ch <= adc_conf[7:0]; 
		end
end

// Registro de desplazamiento serie, con carga paralelo
// Selección de registro automático o enviado desde el exterior
assign reg_out = (auto_run | DCM_confrun/* | ADCTest_run*/) ? reg_outaux:adc_conf;

always @(negedge sclk or negedge rstb_aux) 
begin
  	if (!rstb_aux)
	begin
  		reg_desp <= 24'h0000;
		csb 		<= 1'b1;
		sdata		<= 1'b0;
	end	
	else
  	begin
  		if (load)
		begin
   		reg_desp  	<= reg_out;
   		sdata 		<= reg_desp[0];
			csb 			<= 1'b1;
   	end
  		else
		begin
   		reg_desp  	<= {reg_desp[22:0],1'b0};
   		sdata 		<= reg_desp[23];
			csb 			<= csb_aux;
   	end
	end
end


endmodule

