`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		UPV
// Engineer: 		Raul Esteve Bosch
// 
// Create Date:   12:16:16 04/30/2007 
// Design Name: 
// Module Name:   ADCaut_ctrl 
// Project Name: 
// Description: 	FSM de control de la configuración automática
//						
//						Inicia la configuración automática del ADC
//							- Lee registros predefinidos
//  						- Llama a ADCcfg_ctrl que manda el dato al ADC
//
//						Se inicia automáticamente
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ADCaut_ctrl
		//#(
		//parameter [10:0]	ADJ_ADCRST = 11'h3FF
		//)
		(
		init,adc_rst,end_conf,end_auto,auto_runwt,
		rstb,clk,
		init_reg,incr_reg,init_auto,/*auto_run,*/run,end_autoconf);
    
	 input			init;			// DCMs en estado locked
	 input			adc_rst;
	 input			end_conf;
	 input			end_auto;
	 input			auto_runwt;
	 input 			rstb;
    input 			clk;
	 output			init_reg;
	 output			incr_reg;
    output 			init_auto;
	 output			end_autoconf;
	 //output			auto_run;
    output 			run;

reg			init_reg, incr_reg, init_auto, auto_run,end_autoconf;
reg [2:0]	st, next_st;

reg			init_aux = 1'b1;

// Contador 1s
//reg [10:0] 	cnt;
//wire			init_adc;

// La inicialización de la configuración debe ocurrir al menos 100ns después
// del reset de los ADCs según especifiaciones (t6, pag 14, ADS5282)
// Con el tiempo que tarda en activarse la configuración automática es suficiente
//assign init_adc = (cnt == ADJ_ADCRST) ? 1'b1:1'b0;

assign run = auto_run | init_aux;

always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
		begin
			//cnt <= 0;
			
			init_aux = 1'b1;	// Inicialización automática
		end
		else
		begin
			//if (adc_rst | init_auto)
			//	cnt <= 0;
			//else
			//	if (init_aux & !init_adc)
			//		cnt <= cnt+1;
				
			if (init_auto)
				init_aux = 1'b0;
			
			if (adc_rst)
				init_aux = 1'b1;
		end
	end							


//FSM command interface - Interrupt control
	always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
		begin
			st = 3'b000;
		end
		else
		begin
			st = next_st; 
		end
	end
	
	always @(st or init or init_aux /*or init_adc*/ or end_conf or end_auto or auto_runwt)
	begin
		case (st)
			3'b000:													// Inicio
			begin
				init_reg 	 = 1;
				incr_reg 	 = 0;
				init_auto 	 = 0;
				end_autoconf = 0;
				auto_run 	 = 0;
																
				if (init & init_aux & !auto_runwt)// & init_adc)						
					next_st = 3'b001;
				else
					next_st = 3'b000;
			end
			
			3'b001:													
			begin
				init_reg 	 = 0;
				incr_reg 	 = 0;
				init_auto 	 = 1;
				end_autoconf = 0;
				auto_run 	 = 1;
								
				next_st = 3'b011;
			end

			3'b011:													
			begin
				init_reg 	 = 0;
				incr_reg 	 = 0;
				init_auto 	 = 0;
				end_autoconf = 0;
				auto_run 	 = 1;
								
				if (end_conf)
					next_st = 3'b010;
				else
					next_st = 3'b011;
			end

			3'b010:													
			begin
				init_reg 	 = 0;
				incr_reg 	 = 1;
				init_auto 	 = 0;
				end_autoconf = 0;
				auto_run 	 = 1;
								
				if (end_auto)
					next_st = 3'b110;
				else
					next_st = 3'b001;			
			end
			
			3'b110:													
			begin
				init_reg 	 = 0;
				incr_reg 	 = 0;
				init_auto 	 = 0;
				end_autoconf = 1;
				auto_run 	 = 1;
								
				next_st = 3'b000;			
			end
			
			default:													
			begin
				init_reg 	 = 0;
				incr_reg 	 = 0;
				init_auto 	 = 0;
				end_autoconf = 0;
				auto_run 	 = 0;
								
				next_st = 3'b000;			
			end
			
		endcase
	end


endmodule

