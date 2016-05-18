`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:24:42 04/06/2012 
// Design Name: 
// Module Name:    bitsum15 
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
module bitsum15(
    input [15:0] data,
    output [6:0] result
    );

	assign result = 	data[0] + data[1] + data[2] + data[3] + 
								data[4] + data[5] + data[6] + data[7] + 
								data[8] + data[9] + data[10] + data[11] + 
								data[12] + data[13] + data[14] + data[15];


endmodule
