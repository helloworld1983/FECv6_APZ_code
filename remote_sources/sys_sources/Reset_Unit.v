`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:22:51 02/16/2010 
// Design Name: 
// Module Name:    Reset_Unit 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Reset_Unit
	(	
		clk,
		rstb	
    );

input		clk;	 
output	rstb;	 

// Reset interno - power on reset
// aprox. 26 ciclos de clk principal - 200 MHz (130 ns)

reg			rstb  = 1'b0;
reg			rstb1 = 1'b0;
reg			rstb2 = 1'b0;
reg			rstb3 = 1'b0;
reg			rstb4 = 1'b0;
reg			rstb5 = 1'b0;
reg			rstb6 = 1'b0;
reg			rstb7 = 1'b0;
reg			rstb8 = 1'b0;
reg			rstb9 = 1'b0;
reg			rstb10= 1'b0;
reg			rstb11= 1'b0;
reg			rstb12= 1'b0;
reg			rstb13= 1'b0;
reg			rstb14= 1'b0;
reg			rstb15= 1'b0;
reg			rstb16= 1'b0;
reg			rstb17= 1'b0;
reg			rstb18= 1'b0;
reg			rstb19= 1'b0;
reg			rstb20= 1'b0;
reg			rstb21= 1'b0;
reg			rstb22= 1'b0;
reg			rstb23= 1'b0;
reg			rstb24= 1'b0;
reg			rstb25= 1'b0;

always @(posedge clk)
	begin
		rstb25<= 1'b1;
		rstb24<= rstb25;
		rstb23<= rstb24;
		rstb22<= rstb23;
		rstb21<= rstb22;
		rstb20<= rstb21;
		rstb19<= rstb20;
		rstb18<= rstb19;
		rstb17<= rstb18;
		rstb16<= rstb17;
		rstb15<= rstb16;
		rstb14<= rstb15;
		rstb13<= rstb14;
		rstb12<= rstb13;
		rstb11<= rstb12;
		rstb10<= rstb11;
		rstb9 <= rstb10;
		rstb8 <= rstb9;
		rstb7 <= rstb8;
		rstb6 <= rstb7;
		rstb5 <= rstb6;
		rstb4 <= rstb5;
		rstb3 <= rstb4;
		rstb2 <= rstb3;
		rstb1 <= rstb2;
		rstb	<= rstb1;	
	end							

//**********************************************************************************************************************



endmodule
