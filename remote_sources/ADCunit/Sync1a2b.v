`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		UPV
// Engineer: 		Raul Esteve
// 
// Create Date:   10:11:21 05/16/2007 
// Design Name: 
// Module Name:   Sync1a2 
// Project Name: 
// Description: 	
// 					Sincronizador para f (clk1) > f (clk2)
// 					Paso de una señal del dominio 1(clk1) al dominio 2(clk2)
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Sync1a2b(x,rstb,/*clk1,*/clk2,y);
    input x;
    input rstb;
    //input clk1;
    input clk2;
    output y;

reg	aux1, y;


always @(posedge clk2 or negedge rstb)
begin
	if (!rstb)
		begin
			aux1 <= 0;
			y <= 0;
		end
	else
		begin
			aux1 <= x;
			y <= aux1;
		end
end

endmodule



