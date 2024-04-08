package matmul_pkg;
	// DUT Params
	parameter int unsigned DATA_WIDTH = 8;// 8,16,32
    parameter int unsigned BUS_WIDTH = 32;// 16,32,64
    parameter int unsigned ADDR_WIDTH = 16;// 16,24,32
    parameter int unsigned SP_NTARGETS = 2;// 1,2,4
    localparam int unsigned MAX_DIM = BUS_WIDTH/DATA_WIDTH;// 2,3,4
	localparam time CLK_NS = 10ns;


endpackage
