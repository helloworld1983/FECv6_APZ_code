`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:			UPV 
// Engineer: 		Raul Esteve Bosch
// 
// Create Date:   16:05:47 04/26/2007 
// Design Name: 
// Module Name:   Bitsleep_ctrl 
// Project Name: 
// Description:	FSM que controla el ajuste automático de DCO y FCO 
//						respecto a DCH

//						Primero incrmenta PS y comprueba los resultados, después
//						ajusta de nuevo el PS inicial y luego decrementa PS 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Bitsleep_Ctrl(
			init,
			DCH_ok,
			clk,rstb,
		   bitsleep,
			run
		   );

   input    init;
   input    DCH_ok;
   input    clk;
   input    rstb;
	output	bitsleep;
	output	run;
   

   parameter [2:0]
		initst   = 3'b000,
		step		= 3'b001,
		wt1  		= 3'b011,
		wt2 		= 3'b010,
		wt3  		= 3'b110,
		wt4  		= 3'b111,
		wt5  		= 3'b101,
		wt6  		= 3'b100;


 
   // Estados
   reg [2:0] 	st, next_st;
	
   // Salidas
   reg			bitsleep, run;

// FSM
// Estados
always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
			st <= initst;
		else
			st <= next_st;
   end
	
// Circuito Combinacional Entrada 	
always @(st or init or DCH_ok)
   begin
		case (st) 
			initst:
			begin
				bitsleep	= 1'b0;
				run		= 1'b0;
	       	       
				if (init & !DCH_ok)
					next_st = step;
				else
				   next_st = initst;
			end
			
			step:
			begin
				bitsleep	= 1'b1;
				run		= 1'b1;
	       	       
				next_st = wt1;
			end
			
			wt1:
			begin
				bitsleep	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = wt2;
			end

			wt2:
			begin
				bitsleep	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = wt3;
			end

			wt3:
			begin
				bitsleep	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = wt4;
			end

			wt4:
			begin
				bitsleep	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = wt5;
			end
			
			wt5:
			begin
				bitsleep	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = wt6;
			end
			
			wt6:
			begin
				bitsleep	= 1'b0;
				run		= 1'b1;
	       	       
				if (DCH_ok)
					next_st = initst;
				else
					next_st = step;
				end

		endcase
	  
  end
  

endmodule