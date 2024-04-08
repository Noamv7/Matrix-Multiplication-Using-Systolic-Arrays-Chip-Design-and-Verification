`include "headers.vh"
`include "matmul_interface.sv"
`include "matmul_stimulus.sv"
module matmul_tb();
  
import matmul_pkg::*;
logic clk_i = 1'b0, rst_ni = 1'b1;
matmul_interface intf(
	.clk_i(clk_i), .rst_ni(rst_ni)
);

initial forever 
	#(CLK_NS/2) clk_i = ~clk_i;
// Init reset process


initial begin: TOP_RST
  rst_ni = 1'b1;
  @(posedge clk_i);
	rst_ni = 1'b0; // Assert reset
	@(posedge clk_i);
	rst_ni = 1'b1; // Deassert reset
end


matmul overall_uut (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .psel_i(intf.psel_i),
    .penable_i(intf.penable_i),
    .pwrite_i(intf.pwrite_i),
    .pstrb_i(intf.pstrb_i),
    .pwdata_i(intf.pwdata_i),
    .paddr_i(intf.paddr_i),
    .pready_o(intf.pready_o),
    .pslverr_o(intf.pslverr_o),
    .prdata_o(intf.prdata_o),
    .busy_o(intf.busy_o)
  );

matmul_tester #(
	.RESOURCE_BASE("OVERRIDE_ME")
) u_tester (
   .intf(intf)
);

endmodule
