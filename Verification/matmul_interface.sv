`include "headers.vh"
`include "matmul_pkg.sv"
interface matmul_interface(input logic clk_i, input logic rst_ni);
	import matmul_pkg::*;
	//logic  					clk_i, rst_ni;
	logic					penable_i, psel_i, pwrite_i, busy_o, pslverr_o, pready_o;
	logic [BUS_WIDTH-1:0] 	pwdata_i,prdata_o;
	logic [ADDR_WIDTH-1:0]	paddr_i;
	logic [MAX_DIM-1:0] 	pstrb_i;


	modport matmul(input  clk_i, paddr_i, penable_i, psel_i,pstrb_i, pwdata_i, pwrite_i, rst_ni, 
			output busy_o, prdata_o, pready_o, pslverr_o);
	modport matmul_stimulus(input busy_o, prdata_o, pready_o, pslverr_o, clk_i, rst_ni,
				output paddr_i, penable_i, psel_i,pstrb_i, pwdata_i, pwrite_i);
	modport matmul_checkcoverage(input  clk_i, paddr_i, penable_i, psel_i,pstrb_i, pwdata_i, pwrite_i, rst_ni,busy_o, prdata_o, pready_o, pslverr_o);

endinterface
