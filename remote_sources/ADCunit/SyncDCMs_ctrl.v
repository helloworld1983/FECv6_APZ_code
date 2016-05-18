`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:			UPV 
// Engineer: 		Raul Esteve Bosch
// 
// Create Date:   16:05:47 04/26/2007 
// Design Name: 
// Module Name:   SyncDCMs_ctrl 
// Project Name: 
// Description:	FSM que controla el ajuste automático de DCO y FCO 
//						respecto a DCH
//						
//						Carga patrones y ajusta PS para DCO y luego para FCO
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module SyncDCMs_Ctrl
//		 #(
//			parameter			TEST = 1'b0
//			)
			(
			init,
			end_ADCconf,
			end_DCMconf,
			end_ramp,
			ADC_confwt,
			//fcoconf_en,
			clk,rstb,
			init_ADCconf,
			init_DCMconf,
			init_ramp,
			//FCO_DCOb,
			op_ADC,
			end_sync,
			BS_init,
			BS_confrun,
			DCM_end,
			ADC_confrun,
			run
		   );

   input    		init;
   input    		end_ADCconf;
   input    		end_DCMconf;
	input				end_ramp;
	input				ADC_confwt;
	//input				fcoconf_en;
   input    		clk;
   input    		rstb;
	output			init_ADCconf;
   output   		init_DCMconf;
	output			init_ramp;
   //output   		FCO_DCOb;
	output [2:0]	op_ADC ;
	output			end_sync;
	output			DCM_end;
	output			run;
	
	output			BS_init;
	input				BS_confrun;
	
	output			ADC_confrun;

   

   parameter [4:0]
		initst   	= 5'b00000,
		dcoinit		= 5'b00001,
		dcowt  		= 5'b00011,
		dcopttn		= 5'b00010,
		dcopttnwt	= 5'b00110,
		dcoinit2		= 5'b00111,
		dcowt2  		= 5'b00101,
		fcopttn 		= 5'b00100,
		fcopttnwt	= 5'b01100,
		ramppttn		= 5'b01101,
		ramppttnwt	= 5'b01111,
		endst			= 5'b01110,
		bsinit		= 5'b01010,
		bswt			= 5'b01011,
		rampinit		= 5'b01001,
		rampwt		= 5'b01000,
		normalop		= 5'b11000,
		normalopwt	= 5'b11001,
		dcmend		= 5'b11011,
		dcoconfwt	= 5'b11010,
		fcoconfwt	= 5'b11110,
		rampconfwt	= 5'b11111,
		normconfwt 	= 5'b11101,
		del1			= 5'b11100,
		pttndel1		= 5'b10100,
		delconfwt1	= 5'b10101,
		del2			= 5'b10111,
		pttndel2		= 5'b10110,
		delconfwt2 	= 5'b10010,
		del3			= 5'b10011,
		pttndel3		= 5'b10001,
		delconfwt3 	= 5'b10000
		;
 
   // Estados
   reg [4:0] 	st, next_st;
	
   // Salidas
   reg			init_ADCconf,init_DCMconf,/*FCO_DCOb,*/end_sync,BS_init,DCM_end,init_ramp,ADC_confrun,run;
	reg [2:0]	op_ADC;
	
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
always @(st or init or end_ADCconf or end_DCMconf or BS_confrun or end_ramp or ADC_confwt)// or TEST)
   begin
		case (st) 
			initst:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b0;
	       	       
				if (init)
					//if (TEST)
					//	next_st = normalop;
					//else
						next_st = dcoinit;
				else
				   next_st = initst;
			end
			
			dcoinit:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b1;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		 	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				next_st = dcowt;
			end
			
			dcowt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (end_DCMconf)
					if (ADC_confwt)
						next_st = dcoconfwt;
					else
						next_st = del1;//dcopttn;
				else
					next_st = dcowt;
			end
			
			dcoconfwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (ADC_confwt)
					next_st = dcoconfwt;
				else
					next_st = del1;//dcopttn;
			end
			
			del1:
			begin
				init_ADCconf	= 1'b1;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b110;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				next_st = pttndel1;
			end
			
			pttndel1:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b110;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				if (end_ADCconf)
					if (ADC_confwt)
						next_st = delconfwt1;//dcoinit2;
					else
						next_st = dcopttn;
				else
					next_st = pttndel1;
			end
			
			delconfwt1:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (ADC_confwt)
					next_st = delconfwt1;
				else
					next_st = dcopttn;
			end
			
			dcopttn:
			begin
				init_ADCconf	= 1'b1;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b010;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				next_st = dcopttnwt;
			end
			
			dcopttnwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b010;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				if (end_ADCconf)
					next_st = dcoinit2;
				else
					next_st = dcopttnwt;
			end
			
			dcoinit2:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b1;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		 	= 3'b010;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				next_st = dcowt2;
			end
			
			dcowt2:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b010;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (end_DCMconf)
					if (ADC_confwt)
						next_st = fcoconfwt;
					else
						next_st = del2;//fcopttn;
				else
					next_st = dcowt2;
			end
			
			fcoconfwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (ADC_confwt)
					next_st = fcoconfwt;
				else
					next_st = del2;//fcopttn;
			end

			del2:
			begin
				init_ADCconf	= 1'b1;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b101;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				next_st = pttndel2;
			end
			
			pttndel2:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b101;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				if (end_ADCconf)
					if (ADC_confwt)
						next_st = delconfwt2;//dcoinit2;
					else
						next_st = fcopttn;
				else
					next_st = pttndel2;
			end
			
			delconfwt2:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (ADC_confwt)
					next_st = delconfwt2;
				else
					next_st = fcopttn;
			end
			
			fcopttn:
			begin
				init_ADCconf	= 1'b1;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b001;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				next_st = fcopttnwt;
			end

			fcopttnwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b001;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				if (end_ADCconf)
					next_st = bsinit;//fcoinit;
				else
					next_st = fcopttnwt;
			end

			bsinit:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b001;
				end_sync		 	= 1'b0;
				BS_init			= 1'b1;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				next_st = bswt;
			end

			bswt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b001;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (BS_confrun)
					next_st = bswt;
				else
					next_st = dcmend;
			end
			
			dcmend:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b001;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b1;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (ADC_confwt)
					next_st = rampconfwt;
				else
					next_st = del3;
			end
			
			rampconfwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (ADC_confwt)
					next_st = rampconfwt;
				else
					next_st = del3;//ramppttn;
			end
			
			del3:
			begin
				init_ADCconf	= 1'b1;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b110;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				next_st = pttndel3;
			end
			
			pttndel3:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b110;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				if (end_ADCconf)
					if (ADC_confwt)
						next_st = delconfwt3;//dcoinit2;
					else
						next_st = ramppttn;
				else
					next_st = pttndel3;
			end
			
			delconfwt3:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (ADC_confwt)
					next_st = delconfwt2;
				else
					next_st = ramppttn;
			end
			
			ramppttn:
			begin
				init_ADCconf	= 1'b1;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b011;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				next_st = ramppttnwt;
			end
			
			ramppttnwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b011;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				if (end_ADCconf)
					next_st = rampinit;
				else
					next_st = ramppttnwt;
			end
			
			rampinit:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b1;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b011;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				next_st = rampwt;
			end
			
			rampwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b011;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (end_ramp)
					if (ADC_confwt)
						next_st = normconfwt;
					else
						next_st = normalop;
				else
					next_st = rampwt;
			end
			
			normconfwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC 		  	= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				if (ADC_confwt)
					next_st = normconfwt;
				else
					next_st = normalop;
			end
			
			normalop:
			begin
				init_ADCconf	= 1'b1;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b101;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				next_st = normalopwt;
			end
			
			normalopwt:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b1;
				op_ADC 		  	= 3'b101;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b1;
				run				= 1'b1;
	       	       
				if (end_ADCconf)
					next_st = endst;
				else
					next_st = normalopwt;
			end
			
			endst:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC   		= 3'b100;
				end_sync		 	= 1'b1;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b1;
	       	       
				next_st = initst;
			end
			
			default:
			begin
				init_ADCconf	= 1'b0;
				init_DCMconf	= 1'b0;
				init_ramp		= 1'b0;
				//FCO_DCOb		 	= 1'b0;
				op_ADC   		= 3'b000;
				end_sync		 	= 1'b0;
				BS_init			= 1'b0;
				DCM_end			= 1'b0;
				ADC_confrun		= 1'b0;
				run				= 1'b0;
	       	       
				next_st = initst;
			end

		endcase
	  
  end
  
endmodule