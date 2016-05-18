`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sorin Martoiu
// 
// Create Date:    00:37:13 04/03/2012 
// Design Name: 
// Module Name:    scSystem 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: system slow-control units
//
// Dependencies: common\sc_sources
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module scSystem(
    input clk, clk40M,
    input rstn,
	 // sc bus //
    input [15:0] sc_port,
    input [31:0] sc_data,
    input [31:0] sc_addr,
    input [31:0] sc_subaddr,
    input sc_op,
    input sc_frame,
    input sc_wr,
    output sc_ack,
    output [31:0] sc_rply_data,
    output [31:0] sc_rply_error,
	 // sc bus in //
    input sc_ack_in,
    input [31:0] sc_rply_data_in,
    input [31:0] sc_rply_error_in,
	 // a_i2c //
    inout a_scl,
    inout a_sda,
	 // b_i2c //
    inout b_scl,
    inout b_sda,
	 // registers
	 output [15:0] rstreg, 
	 output [511:0] regout,
	 input [511:0] regin
    );
wire [31:0] gen_rply_data, gen_rply_error;
wire [31:0] b_rply_data, b_rply_error;
wire [31:0] a_rply_data, a_rply_error;
wire gensys_ack, b_ack, a_ack;

assign sc_rply_data = 	(sc_port == 16'h1787) ? b_rply_data :
								(sc_port == 16'h1788) ? a_rply_data :
								(sc_port == 16'h1777) ? gen_rply_data : 
								 sc_rply_data_in;
assign sc_rply_error = 	(sc_port == 16'h1787) ? b_rply_error :
								(sc_port == 16'h1788) ? a_rply_error :
								(sc_port == 16'h1777) ? gen_rply_error : 
								 sc_rply_error_in;

assign sc_ack = 	(sc_port == 16'h1787) ? b_ack :
						(sc_port == 16'h1788) ? a_ack :
						(sc_port == 16'h1777) ? gensys_ack : 
						 sc_ack_in;
						 

gen_reg_cfg2  #(	 .gen_port(16'h1777),
						 .nr_registers(16),
						 .rstval_00(32'h00000000),
						 .rstval_01(32'h00000A35),
						 .rstval_02(32'h0001E321),
						 .rstval_03(32'h0A000002),
						 .rstval_04(32'h00001776),
						 .rstval_05(32'h00001777),
						 .rstval_06(32'h00000000),
						 .rstval_07(32'h00000000),
						 .rstval_08(32'h0000FFFF),
						 .rstval_09(32'h0000FFFF),
						 .rstval_0A(32'h0A000003),		
						 .rstval_0B(32'hDDAA4200)		//DTC control register
	) gen_reg_syscfg (
	 .clk(clk), 
	 .rstn(rstn), 
	 .sc_port(sc_port), 
	 .sc_data(sc_data), 
	 .sc_addr(sc_addr), 
	 .sc_subaddr(sc_subaddr), 
	 .sc_op(sc_op), 
	 .sc_frame(sc_frame), 
	 .sc_wr(sc_wr), 
	 .sc_ack(gensys_ack), 
	 .sc_rply_data(gen_rply_data), 
	 .sc_rply_error(gen_rply_error),
	 .rstreg(rstreg),
	 .regout(regout),
	 .regin(regin)
	 );

gen_i2c_cfgrw2  b_i2c_cfg (
    .clk(clk), 
    .rstn(rstn), 
    .sc_port(sc_port), 
    .sc_data(sc_data), 
    .sc_addr(sc_addr), 
    .sc_subaddr(sc_subaddr), 
    .sc_op(sc_op), 
    .sc_frame(sc_frame), 
    .sc_wr(sc_wr), 
    .sc_ack(b_ack), 
    .sc_rply_data(b_rply_data), 
    .sc_rply_error(b_rply_error), 
    .scl(b_scl), 
    .sda(b_sda), 
    .cfg_i2c_scl(8'h64), 
    .cfg_i2c_sda(8'h32)
    );
gen_i2c_cfgrw2 #(.PORT_GEN_I2C(16'h1788))  a_i2c_cfg (
    .clk(clk), 
    .rstn(rstn), 
    .sc_port(sc_port), 
    .sc_data(sc_data), 
    .sc_addr(sc_addr), 
    .sc_subaddr(sc_subaddr), 
    .sc_op(sc_op), 
    .sc_frame(sc_frame), 
    .sc_wr(sc_wr), 
    .sc_ack(a_ack), 
    .sc_rply_data(a_rply_data), 
    .sc_rply_error(a_rply_error), 
    .scl(a_scl), 
    .sda(a_sda), 
    .cfg_i2c_scl(8'h64), 
    .cfg_i2c_sda(8'h32)
    );

endmodule
