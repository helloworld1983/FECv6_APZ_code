`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:			UPV 
// Engineer: 		Raúl Esteve Bosch		
// 
// Create Date:   19:30:12 04/25/2007 
// Design Name: 
// Module Name:   PS_ctrl 
// Project Name: 	
// Tool versions: 
// Description: 	Máquina de estados que permite modificar el valor de PS
//						para un DCM dado
//						
//						Permite incrementar/decrementar dicho valor el número de
//						indicado en "cycles"
//
// Revision: 
// Revision 0.01 - File Created
//
//////////////////////////////////////////////////////////////////////////////////
module PS_ctrl(init,cycles,psdone,
					rstb,clk,
					psen,ps_end);
    
	 input			init;
	 input [6:0]	cycles;
	 input 			psdone;
	 input			rstb;
	 input 			clk;
	 output			psen;
    output 			ps_end;

reg			psen,ps_end,cnt_rst;
reg [1:0]	st, next_st;

reg [6:0]	cnt_cycles = 7'h7f;

wire			end_cycles;

assign		end_cycles = (cnt_cycles == cycles) ? 1'b1:1'b0; 

parameter [1:0]
	initst	= 2'b00,
   psenst   = 2'b01,
	waitst   = 2'b11,
	endst		= 2'b10;

//FSM para la modificacion de PS en un DCM
	always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
		begin
			st = initst;
		end
		else
		begin
			st = next_st;
		end
	end
	
	always @(st or init or end_cycles or psdone)
	begin
		case (st)
			initst://2'b00:													// Inicio
			begin
				psen 		= 0;
				cnt_rst	= 0;
				ps_end	= 0;
																
				if (init)						
					next_st = psenst;
				else
					next_st = initst;
			end
			
			psenst://2'b01:													
			begin
				psen 		= 1;
				cnt_rst	= 0;
				ps_end	= 0;
			
				next_st = waitst;
			end

			waitst://2'b11:													
			begin
				psen 		= 0;
				cnt_rst	= 0;
				ps_end	= 0;
								
									
				if (psdone)
					if (end_cycles)
						next_st = endst;
					else
						next_st = psenst;
				else
					next_st = waitst;
					
			end

			endst://2'b10:													
			begin
				psen 		= 0;
				cnt_rst	= 1;
				ps_end	= 1;
								
				next_st = initst;			
			end
			
			default://2'b10:													
			begin
				psen 		= 0;
				cnt_rst	= 0;
				ps_end	= 0;
								
				next_st = initst;			
			end
			
		endcase
	end

// Contador de ciclos

always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
		begin
			cnt_cycles = 7'h7f;
		end
		else
		begin
			if (cnt_rst)
				cnt_cycles = 7'h7f;
			else
				if (psen)
					cnt_cycles = cnt_cycles + 7'h1;
		end
	end

endmodule


