`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:			UPV 
// Engineer: 		Raul Esteve Bosch
// 
// Create Date:   16:05:47 04/26/2007 
// Design Name: 
// Module Name:   Ramp_Ctrl 
// Project Name: 
// Description:	FSM que controla el ajuste automático de DCO y FCO 
//						respecto a DCH
//						Chequea la salida cuando está a 0 y si se sale de unos márgenes
// 					hace un reset del sistema 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Ramp_Ctrl
		#(
			parameter [11:0] 	DCO_STABLE = 12'hFFF
		)
		(
			init,
			ramp_ok,
			clk,rstb,
		   end_ramp,
			DES_rst,
			run
		   );

   input    		init;
   input    		ramp_ok;
   input    		clk;
   input    		rstb;
	output			DES_rst;
   output   		end_ramp;
	output			run;
   

   parameter [2:0]
		initst   = 3'b000,
		wtst1		= 3'b001,
		wtst2		= 3'b011,
		wtst3		= 3'b010,
		wtst4		= 3'b110,
		cntinit	= 3'b111,
		endok		= 3'b101,
		endrst	= 3'b100;
 
   // Estados
   reg [2:0] 	st, next_st;
	
   // Salidas
   reg			DES_rst, run, cnt_en;

	// Temporizador
	reg [12:0]	tmp;
	reg [4:0]	cnt;
	reg			tmp_en, tmp_rst;
	
	wire			end_ramp, cnt_end;
	
	wire [11:0]	tmp_half;
	// Temporizador que determina cuanto tiempo va a chequearse la rampa
	// al margen para considerarse el ajuste correcto
	assign		tmp_half = DCO_STABLE;
	assign		tmp_end = (tmp=={tmp_half,1'b0}) ? 1'b1:1'b0;
	
	assign		end_ramp = tmp_rst;
	
	assign		cnt_end = (cnt==32'h1F) ? 1'b1:1'b0;

// Registro para controlar el final del ajuste
always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
		begin
			tmp 		<= 13'h0;
			
			cnt		<= 5'h0;
		end	
		else
			if (tmp_rst)
			begin
				tmp 		<= 13'h0;
				cnt		<= 5'h0;
			end	
			else
			begin
				if (tmp_en)
					tmp <= tmp + 1;
					
				if (cnt_en)
					cnt <= cnt + 5'h1;
	
			end
   end 

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
always @(st or init or ramp_ok or tmp_end or cnt_end)
   begin
		case (st) 
			initst: //00
			begin
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				DES_rst	= 1'b0;
				cnt_en	= 1'b0;
				run		= 1'b0;
	       	       
				if (init)
					next_st = wtst1;
				else
				   next_st = initst;
			end
			
			wtst1: //11
			begin
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				DES_rst	= 1'b0;
				cnt_en	= 1'b1;
				run		= 1'b1;
	       	       
				if (cnt_end)		 
					next_st = cntinit;//wtst2;
				else
					next_st = wtst1;//wtst2;	
			end
			/*
			wtst2: //11
			begin
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				DES_rst	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = wtst3;
			end
			
			wtst3: //11
			begin
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				DES_rst	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = wtst4;
			end
			
			wtst4: //11
			begin
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				DES_rst	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = cntinit;
			end
			*/
			cntinit: //01
			begin
				tmp_en  	= 1'b1;
				tmp_rst 	= 1'b0;
				DES_rst	= 1'b0;
				cnt_en	= 1'b0;
				run		= 1'b1;
	       	
				if (!ramp_ok)
					next_st = endrst;
				else
					if (tmp_end)
						next_st = endok;
					else	
						next_st = cntinit;
			end
			
			endok: //11
			begin
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b1;
				DES_rst	= 1'b0;
				cnt_en	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = initst;
			end
			
			endrst:
			begin
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b1;
				DES_rst	= 1'b1;
				cnt_en	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = initst;
			end
			
			default:
			begin
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				DES_rst	= 1'b0;
				cnt_en	= 1'b0;
				run		= 1'b0;
	       	       
				next_st = initst;
			end

		endcase
	  
  end
  

	  
endmodule