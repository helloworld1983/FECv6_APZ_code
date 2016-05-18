`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		UPV
// Engineer: 		Raul Esteve Bosch						
// 
// Create Date:   12:19:48 04/30/2007 
// Design Name: 
// Module Name:   ADCreg_unit 
// Project Name: 
// Description:   Circuito que contiene registros para la configuración automática
//					
// 					Ver Data Sheet ADS5273
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ADCreg_unit(init_reg,incr_reg,auto_run,pwdown_ch,pttn_sel,
						 //pttn_test,
						 rstb,clk,
						 reg_out,end_auto);
						 
	 input			init_reg;
	 input			incr_reg;
	 input			auto_run;
	 input [7:0]	pwdown_ch;
	 input [3:0]	pttn_sel;
	 
//	 input [11:0]	pttn_test;
	 
    input 			rstb;
    input 			clk;
    output [23:0]	reg_out;
	 output			end_auto;


// Operación normal (3.5 mA) - Todas las salidas digitales a LVDS 4.5 mA
//wire [23:0]	lvds45		 = 24'h11_0777; No exite en el ADS5292
// Patrones de test	
wire [23:0]	deskew_pttn  = 24'h45_0001;	// Deskew pattern - 010101010101
wire [23:0]	sync_pttn 	 = 24'h45_0002;	// Sync pattern   - 111111000000
wire [23:0]	scustom_pttn = 24'h25_0012;	// Single custom pattern
wire [23:0]	sbits_pttn   = 24'h26_AA80;	// Custom1 pattern - 101010101010
wire [23:0]	dcustom_pttn = 24'h25_0026;	// Dual custom pattern (patterns 1/2)
wire [23:0]	dbits_pttn   = 24'h27_5540;	// Custom2 pattern - 010101010101
wire [23:0]	ramp_pttn    = 24'h25_0040;	// Ramp
// Borrado de patrones
wire [23:0]	del25   	 	 = 24'h25_0000;	// Borrado Single Custom/Rampa
wire [23:0]	del45    	 = 24'h45_0000;	// Borrado Deskew y sync pattern


// Modos de power down - Complete
reg [7:0]	pwrdown; 	//= {16'h0F_02,pwdown_ch[7:0]}; // Modos de power down
reg [2:0] 	cnt_out;
wire [3:0]	reg_sel;

// La configuración automática termina con el deskew_pttn
// Este patrón es el primero para el ajuste de los DCMs
assign		end_auto = (reg_sel == 4'b0011) ? 1'b1:1'b0;

// El valor para configurar el ADC se selecciona automaticamente o 
// a partir de un valor dado por el bloque DCM_ctrl
assign 		reg_sel[3:0]  = (auto_run == 1'b1) ? {1'b0,cnt_out[2:0]}:pttn_sel;

assign		cnt_rst  = init_reg;
assign 		cnt_en   = incr_reg;

// Multiplexor de salida;
assign reg_out = //Bloque de configuración automática por defecto  
					 //((reg_sel == 4'b0000) ? lvds45:
					 ((reg_sel == 4'b0001) ? sbits_pttn:
					 ((reg_sel == 4'b0010) ? dbits_pttn:
					 //// Otros registros de configuración
					 ((reg_sel == 4'b0011) ? deskew_pttn:
					 ((reg_sel == 4'b0100) ? sync_pttn:
					 ((reg_sel == 4'b0101) ? scustom_pttn:
					 ((reg_sel == 4'b0110) ? dcustom_pttn:
					 ((reg_sel == 4'b0111) ? ramp_pttn:
					 ((reg_sel == 4'b1000) ? pwrdown:
					 ((reg_sel == 4'b1001) ? del25:
					 ((reg_sel == 4'b1010) ? del45:
													 24'h00_0000))))))))));


always @(posedge clk or negedge rstb)
begin
	if (!rstb)
	begin
		pwrdown <= 24'h0F_0200;
	end
	else
		begin
			pwrdown <= {16'h0F_02,pwdown_ch[7:0]};
		end
end


always @(posedge clk or negedge rstb)
begin
	if (!rstb)
		cnt_out <= 3'b001;
	else
		begin
			if (cnt_rst)
				cnt_out <= 3'b001;
			else
				if (cnt_en)
					cnt_out <= cnt_out + 3'b001;
		end
end

endmodule



