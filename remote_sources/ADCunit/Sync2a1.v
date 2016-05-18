`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		UPV
// Engineer: 		Raul Esteve
// 
// Create Date:   10:11:21 05/16/2007 
// Design Name: 
// Module Name:   Sync2a1 
// Project Name: 
// Description: 	
// 					Sincronizador para f (clk1) < f (clk2)
// 					Paso de una señal del dominio 1(clk1) al dominio 2(clk2)
//						Convierte una señal de menor f en otra de mayor f y 1 solo ciclo
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Sync2a1(x,rstb,clk1,y);
		input x;
		input rstb;
		input clk1;	  // Menor frecuencia
		output y;

		reg aux1, y;
		
		reg [1:0] st, next_st;

//FSM 
always @(posedge clk1 or negedge rstb)
	begin
		if (!rstb)
		begin
			st = 2'b00;
			
			aux1 <= 0;
		end
		else
		begin
			st = next_st;
			
			aux1 <= x;
		end
	end
	
always @(st or aux1)
	begin
		case (st)
			2'b00:													// Inicio
			begin
				y 			= 0;
																				
				if (aux1)						
					next_st = 2'b01;
				else
					next_st = 2'b00;
			end
			
			2'b01:													
			begin
				y 			= 1;
				
				if (aux1)
					next_st = 2'b11;
				else
					next_st = 2'b00;
			end

			2'b11:													
			begin
				y 			= 0;
									
				if (aux1)
					next_st = 2'b11;
				else
					next_st = 2'b00;
			end

			default:													
			begin
				y 			= 0;
								
				next_st = 2'b00;		
			end
			
		endcase
	end

endmodule






