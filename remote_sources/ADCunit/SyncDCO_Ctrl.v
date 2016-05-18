`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:			UPV 
// Engineer: 		Raul Esteve Bosch
// 
// Create Date:   16:05:47 04/26/2007 
// Design Name: 
// Module Name:   Sync_ctrl 
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
module SyncDCO_Ctrl
		#(
			parameter [7:0]	DCO_ADJ 	= 8'h1F,
			parameter [11:0] 	DCO_STABLE = 12'hFFF
		)
		(
			init,
			DCH_ok,
			psen,
			ps_end,
			// El rst del DCM se ha utilizado para retardar más las señales
			// de los canales, aunque no parece necesario
			clk,rstb,
		   adj,
			inc_dec,
			adj_dly,
			ps_cycles,
			adj_end,
			run
		   );

   input    		init;
   input    		DCH_ok;
	input				psen;
   input    		ps_end;
   input    		clk;
   input    		rstb;
	output			adj;
   output   		inc_dec;
	output			adj_dly;
	output [6:0] 	ps_cycles;
   output   		adj_end;
	output			run;
   

   parameter [4:0]
		initst   = 4'b0000,
		cmpinc	= 4'b0001,
		adjdly	= 4'b0011,
		adjdly2	= 4'b0010,
		adjdly3	= 4'b0110,
		adjdly4	= 4'b0111,
		adjdly5	= 4'b0101,			
		nookinc  = 4'b0100,
		wtpsinc	= 4'b1100,
		adjfine	= 4'b1101,
		wtpsdec	= 4'b1111,	 
		adjmid	= 4'b1110,
		wtpsincm	= 4'b1010,
//		rstdcm   = 4'b1011,
//		wtrstdcm = 4'b1001,
		adjend	= 4'b1000;
 
   // Estados
   reg [3:0] 	st, next_st;
	
   // Salidas
   reg			inc_dec, adj, adj_drun, adj_fmid, adj_dly, adj_fen, adj_end, /*dcm_rst,*/ run;
	reg			adj_fine;
	reg			tmp_en, tmp_rst;
	// Temporizador
	reg [11:0]	tmp;
	reg [7:0]	adj_cnt;
	
	reg [6:0]	ps_cyclesint, ps_cycles;
	
	wire			tmp_end;
	
	// Temporizador que determina cuanto tiempo va a ser la salida igual
	// al patrón para considerarse el ajuste correcto
	// clk=20MHz (50ns) -> tmp == 500us -> 10000d, 2710h  
	assign		tmp_end = (tmp==DCO_STABLE) ? 1'b1:1'b0;
	
	// 
	assign		adj_ok	 =	(adj_cnt > DCO_ADJ) ? 1'b1:1'b0;

// Registro para controlar el final del ajuste
always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
		begin
			adj_cnt 			<= 8'h00;
			
			adj_fine 		<= 1'b0;
			
			ps_cycles 		<= 7'h00;
			ps_cyclesint 	<= 7'h00;
		end	
		else
		begin
			if (adj_end)
			begin
				ps_cycles <= 7'h00;//DCO_ADJ[6:0];
				
				ps_cyclesint <= 7'h00;
			end	
			else
			begin
				if (adj & !adj_ok)
					adj_cnt <= adj_cnt + 1;
				
				if (adj_fen)
				begin
					adj_fine <= 1'b1;
					
					ps_cycles <= 7'h00;				
				end	
				
				if (adj_drun & psen)
					ps_cyclesint <= ps_cyclesint + 1; 
				
				if (adj_fmid)
					ps_cycles <= {1'b0,ps_cyclesint[6:1]};
					
			end		
				
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
always @(st or init or DCH_ok or adj_ok or adj_fine or tmp_end or ps_end)
   begin
		case (st) 
			initst: 
			begin
				adj		= 1'b0;
				inc_dec	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b0;
	       	       
				if (init)
					next_st = cmpinc;
				else
				   next_st = initst;
			end
			
			cmpinc: 
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b1;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	
				if (!adj_ok)
					if (DCH_ok)
						next_st = nookinc;
					else
						next_st = adjdly;
				else
					if (!DCH_ok)
						next_st = adjdly;
					else	
						if (tmp_end)
							if (adj_fine)
								next_st = adjend;
							else
								next_st = adjfine;
						else
							next_st = cmpinc;
			end
			
			adjdly: //011
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b1;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b1;
				run		= 1'b1;
	       	       
				next_st = adjdly2; //cmpinc;
			end
			
			adjdly2:
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = adjdly3;
			end
			
			adjdly3: //
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = adjdly4;
			end
			
			adjdly4: //
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = adjdly5;
			end
			
			adjdly5: //
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = cmpinc;
			end	
			
			nookinc:
			begin
				adj  		= 1'b1;
				inc_dec 	= 1'b1;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b1;
				run		= 1'b1;
	       	       
				next_st = wtpsinc;
			end
			
			wtpsinc:
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b1;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;  
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	       
				if (!ps_end)
					next_st = wtpsinc;
				else
					next_st = cmpinc;
			end
			
			adjfine:
			begin
				adj  		= 1'b1;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b1;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b1;
				run		= 1'b1;
	       	       
				next_st = wtpsdec;
			end
			
			wtpsdec:
			begin
				adj  		= 1'b1;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b1;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	       
				if (DCH_ok)
					next_st = wtpsdec;
				else
					if (ps_end)
						next_st = adjmid;
					else
						next_st = wtpsdec;
			end
			
			adjmid:
			begin
				adj  		= 1'b1;
				inc_dec 	= 1'b1;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b1;   // Se carga la mitad del valor de PS
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	       
				next_st = wtpsincm;
			end
			
			wtpsincm:
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b1;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				run		= 1'b1;
	       	       
				if (!ps_end)
					next_st = wtpsincm;
				else
					next_st = cmpinc;
			end
			
			adjend:
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;   
				adj_dly	= 1'b0;
				adj_end 	= 1'b1;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b1;
				run		= 1'b1;
	       	       
				next_st = initst;
			end
			
			default:
			begin
				adj  		= 1'b0;
				inc_dec 	= 1'b0;
				adj_fen	= 1'b0;
				adj_drun	= 1'b0;
				adj_fmid = 1'b0;   
				adj_dly	= 1'b0;
				adj_end 	= 1'b0;
				tmp_en  	= 1'b0;
				tmp_rst 	= 1'b0;
				//dcm_rst	= 1'b0;
				run		= 1'b0;
	       	       
				next_st = initst;
			end

		endcase
	  
  end
  
always @(posedge clk or negedge rstb)
	begin
		if (!rstb)
		begin
			tmp 		<= 0;
		end	
		else
			if (tmp_rst)
			begin
				tmp 		<= 0;
			end	
			else
			begin
				if (tmp_en & !tmp_end)
					tmp <= tmp + 1;
			end
   end  
	  
endmodule