`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:09:17 03/01/2011 
// Design Name: 
// Module Name:    scApplication 
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
module scApplication(
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
	 // i2c0 //
    inout i2c0_scl,
    inout i2c0_sda,
    output i2c0_rst,
	 // i2c1 //
    inout i2c1_scl,
    inout i2c1_sda,
	 // adc spi //
	 output cspi_enable,
	 output cspi_sdata,
	 output [31:0] cspi_cs_n,
	 // registers
	 output [15:0] apprstreg,	cspi_rstreg,
	 output [511:0] appregout,
	 input [511:0] appregin//,
//	 // ped & sigma
//	 output [3:0] api_sigped_apv,
//	output api_load_pedestal, api_load_sigma,
//	output [6:0] api_pedestal_addr, api_sigma_addr,
//	output [11:0] api_pedestal_in, api_sigma_in, 
//	input [11:0] api_pedestal_out, api_sigma_out
	 
    );
//(* KEEP=TRUE *) wire [511:0] regout;

wire [31:0] apvh_rply_data, apvh_rply_error;
wire [31:0] ccard_rply_data, ccard_rply_error;
//wire [31:0] gen_rply_data, gen_rply_error;
wire [31:0] genapp_rply_data, genapp_rply_error;
//wire [31:0] sigped_rply_data, sigped_rply_error;
//wire [31:0] b_rply_data, b_rply_error;
wire [31:0] cspi_rply_data, cspi_rply_error;

wire apvh_ack, ccard_ack, gensys_ack, genapp_ack, b_ack, sigped_ack, cspi_ack;

assign sc_rply_data = 	(sc_port == 16'h1877) ? apvh_rply_data : 
								(sc_port == 16'h1977) ? ccard_rply_data :
								(sc_port == 16'h1978) ? cspi_rply_data :
//								(sc_port == 16'h1787) ? b_rply_data :
//								(sc_port == 16'h1777) ? gen_rply_data : 
								(sc_port == 16'h1797) ? genapp_rply_data : 
//								(sc_port == 16'h1798) ? sigped_rply_data : 
								 32'h00000000;
assign sc_rply_error = 	(sc_port == 16'h1877) ? apvh_rply_error : 
								(sc_port == 16'h1977) ? ccard_rply_error :
								(sc_port == 16'h1978) ? cspi_rply_error :
//								(sc_port == 16'h1787) ? b_rply_error :
//								(sc_port == 16'h1777) ? gen_rply_error : 
								(sc_port == 16'h1797) ? genapp_rply_error : 
//								(sc_port == 16'h1798) ? sigped_rply_error : 
								 32'hFFFFFFFF;

assign sc_ack = 	(sc_port == 16'h1877) ? apvh_ack : 
						(sc_port == 16'h1977) ? ccard_ack :
						(sc_port == 16'h1978) ? cspi_ack :
//						(sc_port == 16'h1787) ? b_ack :
//						(sc_port == 16'h1777) ? gensys_ack : 
						(sc_port == 16'h1797) ? genapp_ack : 
//						(sc_port == 16'h1798) ? sigped_ack : 
						 sc_frame;

apvh_i2c_cfgrw apvh_i2c_cfg (
    .clk(clk), 
    .rstn(rstn), 
    .sc_port(sc_port), 
    .sc_data(sc_data), 
    .sc_addr(sc_addr), 
    .sc_subaddr(sc_subaddr), 
    .sc_op(sc_op), 
    .sc_frame(sc_frame), 
    .sc_wr(sc_wr), 
    .sc_ack(apvh_ack), 
    .sc_rply_data(apvh_rply_data), 
    .sc_rply_error(apvh_rply_error), 
    .scl(i2c0_scl), 
    .sda(i2c0_sda), 
    .i2c_rst(i2c0_rst), 
    .cfg_i2c_scl(8'h64), 
    .cfg_i2c_sda(8'h32)
    );
ccard_i2c_cfg ccard_i2c_cfg (
    .clk(clk), 
    .rstn(rstn), 
    .sc_port(sc_port), 
    .sc_data(sc_data), 
    .sc_addr(sc_addr), 
    .sc_subaddr(sc_subaddr), 
    .sc_op(sc_op), 
    .sc_frame(sc_frame), 
    .sc_wr(sc_wr), 
    .sc_ack(ccard_ack), 
    .sc_rply_data(ccard_rply_data), 
    .sc_rply_error(ccard_rply_error), 
    .scl(i2c1_scl), 
    .sda(i2c1_sda), 
    .cfg_i2c_scl(8'h64), 
    .cfg_i2c_sda(8'h32)
    );
sc_spi_tx  # ( .gen_port(16'h1978)	)	ccard_spi_cfg	(
    .clk(clk), 
    .rstn(rstn), 
    .sc_port(sc_port), 
    .sc_data(sc_data), 
    .sc_addr(sc_addr), 
    .sc_subaddr(sc_subaddr), 
    .sc_op(sc_op), 
    .sc_frame(sc_frame), 
    .sc_wr(sc_wr), 
    .sc_ack(cspi_ack), 
    .sc_rply_data(cspi_rply_data), 
    .sc_rply_error(cspi_rply_error), 
    .rstreg(cspi_rstreg), 
    .spi_enable(cspi_enable), 
    .spi_sdata(cspi_sdata), 
    .spi_cs_n(cspi_cs_n)
    );
gen_reg_cfg2  #(	 .gen_port(16'h1797),
						 .nr_registers(16),
						 .rstval_00(32'h00000004),
						 .rstval_01(32'h00000003),
						 .rstval_02(32'h00009C40),
						 .rstval_03(32'h00000100),
						 .rstval_04(32'h00000080),
						 .rstval_05(32'h0000012C),
						 .rstval_08(32'h0000FFFF),
						 .rstval_09(32'h000009C4)) gen_reg_appcfg (
	 .clk(clk), 
	 .rstn(rstn), 
	 .sc_port(sc_port), 
	 .sc_data(sc_data), 
	 .sc_addr(sc_addr), 
	 .sc_subaddr(sc_subaddr), 
	 .sc_op(sc_op), 
	 .sc_frame(sc_frame), 
	 .sc_wr(sc_wr), 
	 .sc_ack(genapp_ack), 
	 .sc_rply_data(genapp_rply_data), 
	 .sc_rply_error(genapp_rply_error), 
	 .rstreg(apprstreg),
	 .regout(appregout),
	 .regin(appregin)
	 );




endmodule
