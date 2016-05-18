`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		UPV
// Engineer: 		Raúl Esteve Bosch	
// 
// Create Date:   15:17:48 05/21/2007 
// Design Name: 
// Module Name:   DCMrst_Ctrl 
// Project Name: 
// Target Devices: 
// Description: 	FSM encargada de generar las señales de rst y final de reset
//						para los DCMs
//
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module DCMrst_Ctrl(init,
						 locked,
						 rstb,clk,
						 rst_dcm,
						 rst_end,
						 rst_iserdes,
						 rst_run);
					
    input 	init;
	 input 	locked;
	 input 	rstb;
    input 	clk;
	 output	rst_dcm;
    output 	rst_end;
	 output	rst_iserdes;
	 output	rst_run;
    
reg			rst_end, rst_dcm, rst_iserdes, rst_run;
reg [2:0]	st, next_st;

//FSM control de ejecución de acciones
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
	
	always @(st or init or locked)
	begin
		case (st)
			3'b000:	//000   // Espera a que empiecen a almacenarse los datos en la FIFO
			begin
				rst_end 		= 0;
				rst_dcm 		= 0;
				rst_iserdes = 0;
				rst_run		= 0;
															
				if (init)
					next_st = 3'b001;
				else
					next_st = 3'b000;
			end
			
			3'b001:	//001			// Inicio reset DCM (reloj DCO)
			begin
				rst_end 		= 0;
				rst_dcm 		= 1;
				rst_iserdes = 0;
				rst_run		= 1;
															
				next_st = 3'b011;
			end
			
			3'b011:	//011											
			begin
				rst_end 		= 0;
				rst_dcm 		= 1;
				rst_iserdes = 0;
				rst_run		= 1;
															
				next_st = 3'b010;
			end

			3'b010: //010												
			begin
				rst_end 		= 0;
				rst_dcm 		= 1;
				rst_iserdes = 0;
				rst_run		= 1;
						
				next_st = 3'b110;
			end

			3'b110: //110				// Fin reset DCM (reloj DCO)											
			begin
				rst_end 		= 0;
				rst_dcm 		= 0;
				rst_iserdes = 0;
				rst_run		= 1;
											
				if (locked)
					next_st = 3'b111;
				else
					next_st = 3'b110;
			end

			3'b111: //111				// Inicio reset ISERDES											
			begin
				rst_end 		= 0;
				rst_dcm 		= 0;
				rst_iserdes = 1;
				rst_run		= 1;
											
				next_st = 3'b101;
			end

			3'b101: //101															
			begin
				rst_end 		= 0;
				rst_dcm 		= 0;
				rst_iserdes = 1;
				rst_run		= 1;
											
				next_st = 3'b100;
			end
			
			3'b100:	//100											
			begin
				rst_end 		= 1;
				rst_dcm 		= 0;
				rst_iserdes = 1;
				rst_run		= 1;
						
				next_st = 3'b000;
			end

			default:
			begin
				rst_end 		= 0;
				rst_dcm 		= 0;
				rst_iserdes = 0;
				rst_run		= 0;
								
				next_st= 3'b000;
			end

		endcase
	end


endmodule



