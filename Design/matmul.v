`include "headers.vh"
`include "mem.v"
`include "matmul_calc.v"
`include "apb_slave.v"
module matmul (clk_i,paddr_i, penable_i, psel_i,pstrb_i, pwdata_i,pwrite_i,rst_ni,busy_o, prdata_o,  pready_o, pslverr_o);

  parameter DATA_WIDTH = 8;//8,16,32  Data width in bits
  parameter BUS_WIDTH = 32;// 16,32,64     Bus width in bits
  parameter ADDR_WIDTH = 16;//16,24,32  Address width in bits
  parameter SP_NTARGETS = 2; // 1,2,4  Number of SP targets
  localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH;// 2,4
   // Port Declarations
   input   wire              		   clk_i;
   input   wire    [ADDR_WIDTH-1:0] paddr_i; 
   input   wire              		   penable_i; 
   input   wire              		   psel_i;
   input   wire    [MAX_DIM-1:0]   	pstrb_i;
   input   wire    [BUS_WIDTH-1:0]  pwdata_i;
   input   wire             		   pwrite_i;
   input   wire              		   rst_ni;
   output  wire             		   busy_o;
   output  wire    [BUS_WIDTH-1:0]  prdata_o; 
   output  wire              		   pready_o;
   output  wire              		   pslverr_o;


// Internal signal declarations
wire  [MAX_DIM * BUS_WIDTH - 1:0]                a_out;
wire  [ADDR_WIDTH - 1:0]                         addr_out_mem;
wire  [MAX_DIM * BUS_WIDTH - 1:0]                b_out;
wire                                             busy_i;
wire  [BUS_WIDTH - 1:0]                          data_in_from_mem;
wire  [BUS_WIDTH - 1:0]                          data_out_mem;
wire  [MAX_DIM * MAX_DIM - 1:0]                  flags_o;
wire  [MAX_DIM - 1:0]                            pstrb_o;
wire                                             sp_write;
wire                                             start_bit_o;
wire                                             write_en_out;
wire  [BUS_WIDTH * MAX_DIM * MAX_DIM - 1:0]      write_to_sp;
wire [1:0] dimension_N_i;
wire [1:0] dimension_K_i;
wire [1:0] dimension_M_i;
wire [1:0] dimension_N_o;
wire [1:0] dimension_K_o;
wire [1:0] dimension_M_o;


// Instances 
apb_slave U_0( 
   .clk_i            (clk_i), 
   .rst_ni           (rst_ni), 
   .psel_i           (psel_i), 
   .penable_i        (penable_i), 
   .pwrite_i         (pwrite_i), 
   .pstrb_i          (pstrb_i), 
   .pwdata_i         (pwdata_i), 
   .paddr_i          (paddr_i), 
   .pready_o         (pready_o), 
   .pslverr_o        (pslverr_o), 
   .prdata_o         (prdata_o), 
   .busy_o           (busy_o), 
   .pslverr_i        (pslverr_i), 
   .busy_i           (busy_i), 
   .data_in_from_mem (data_in_from_mem), 
   .data_out_mem     (data_out_mem), 
   .addr_out_mem     (addr_out_mem), 
   .write_en_out     (write_en_out), 
   .pstrb_o          (pstrb_o)
); 

matmul_calc U_1( 
   .clk_i       (clk_i), 
   .rst_ni      (rst_ni), 
   .start_bit_i (start_bit_o), 
   .matrix_a_in (a_out), 
   .matrix_b_in (b_out), 
   .sp_write    (sp_write), 
   .flags_o     (flags_o), 
   .write_to_sp (write_to_sp),
   .dimension_N_i (dimension_N_o),
   .dimension_K_i (dimension_K_o),
   .dimension_M_i (dimension_M_o)
); 

mem U_2( 
   .clk_i       (clk_i), 
   .rst_ni      (rst_ni), 
   .pwdata_i    (data_out_mem), 
   .paddr_i     (addr_out_mem), 
   .pwrite_i    (write_en_out), 
   .pstrb_i     (pstrb_o), 
   .prdata_o    (data_in_from_mem), 
   .a_out       (a_out), 
   .b_out       (b_out), 
   .pslverr_o   (pslverr_i), 
   .busy_o      (busy_i), 
   .sp_write    (sp_write), 
   .write_to_sp (write_to_sp), 
   .flags_in    (flags_o), 
   .start_bit_o (start_bit_o),
   .dimension_N_o (dimension_N_o),
   .dimension_K_o (dimension_K_o),
   .dimension_M_o (dimension_M_o) 
); 


endmodule // TOP

