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
module Sync1a2(x,rstb,clk1,clk2,y,run);
    input x;
    input rstb;
    input clk1;
    input clk2;
    output y;
	 output run;

reg	aux2, aux3, aux4, y;
wire 	out2, out3, out4, out5;

assign out2 = !(!aux2 || aux3);
assign out3 = aux4 || out2;
assign out4 = out3 && (!y);
assign out5 = aux4 && (!y);

assign run 	= x | out3 | y;

always @(posedge clk1 or negedge rstb)
begin
	if (!rstb)
		begin
			aux2 <= 0;
			aux3 <= 0;
			aux4 <= 0;
		end
	else
		begin
			aux2 <= x;
			aux3 <= aux2;
			aux4 <= out4;
		end
end

always @(posedge clk2 or negedge rstb)
begin
	if (!rstb)
		begin
			y <= 0;
		end
	else
		begin
			y <= out5;
		end
end

endmodule



