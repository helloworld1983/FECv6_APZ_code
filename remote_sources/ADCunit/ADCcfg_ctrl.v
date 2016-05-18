`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		UPV
// Engineer: 		Raul Esteve Bosch
// 
// Create Date:   12:10:12 04/30/2007 
// Design Name: 
// Module Name:   ADCcfg_ctrl 
// Project Name: 
// Description: 	FSM que implementa el protocolo para enviar los registros
//						de configuración al ADC
//
//  
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ADCcfg_ctrl(init_conf,rstb,clk,load,csb,end_conf, conf_run);
    input 	init_conf;
    input 	rstb;
    input 	clk;
    output 	load;
    output 	csb;
	 output 	end_conf;
	 output 	conf_run;

reg			load,csb,end_conf,conf_run;
reg [1:0]	st, next_st;

// Contador que controla el estado de activación de CS
reg [4:0]	cnt_cs;

always @(posedge clk or negedge rstb)
begin
	if (!rstb)
		cnt_cs <= 5'b00000;
	else
		begin
			if (end_conf)
				cnt_cs <= 5'b00000;
			else
				if (!csb)
					cnt_cs <= cnt_cs + 5'b00001;
		end
end

wire			end_cs;
assign		end_cs = (cnt_cs == 5'd23) ? 1'b1:1'b0;

//FSM adc config interface
	always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
		begin
			st = 2'b00;
		end
		else
		begin
			st = next_st;
		end
	end
	
	always @(st or init_conf or end_cs)
	begin
		case (st)
			2'b00:
			begin
				load 		= 0;
				csb 		= 1;
				end_conf = 0;
				conf_run = 0;
															
				if (init_conf)
					next_st = 2'b01;
				else
					next_st = 2'b00;
			end
			// Carga de los datos en el registro de desplazamiento
			2'b01:											
			begin
				load 		= 1;
				csb 		= 1;
				end_conf = 0;
				conf_run = 1;
												
				next_st = 2'b11;
			end
			// Desplazamiento de los datos
			2'b11:	 // 0
			begin
				load 		= 0;
				csb 		= 0;
				end_conf = 0;
				conf_run = 1;
				
				if (end_cs)
					next_st = 2'b10;
				else
					next_st = 2'b11;
			end

			2'b10:	 // Fin										
			begin
				load 		= 0;
				csb 		= 1;
				end_conf = 1;
				conf_run = 1;
				
				next_st = 2'b00;
			end

			default:
			begin
				load 		= 0;
				csb 		= 1;
				end_conf = 0;
				conf_run = 0;
									
				next_st = 2'b00;
			end
		endcase
	end

endmodule


