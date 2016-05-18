`define REG_DATA_WIDTH 1023

function ireg1;
	input integer base;
	input integer pos;
	input [1023:0] registers;
	begin 
		ireg1 = registers[(base * 32)+ pos];
	end 
endfunction
function [7:0] ireg8;
	input integer base;
	input [1023:0] registers;
	begin 
		ireg8 = registers[(base * 32)+:8];
	end 
endfunction
function [7:0] ireg8_any;
	input integer base;
	input integer pos;
	input [1023:0] registers;
	begin 
		ireg8_any = registers[(base * 32 + pos * 8)+:8];
	end 
endfunction
function [15:0] ireg16;
	input integer base;
	input [1023:0] registers;
	begin 
		ireg16 = registers[(base * 32)+:16];
	end 
endfunction
function [31:0] ireg32;
	input integer base;
	input [1023:0] registers;
	begin 
		ireg32 = registers[(base * 32)+:32];
	end 
endfunction

