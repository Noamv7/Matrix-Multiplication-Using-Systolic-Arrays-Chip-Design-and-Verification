`include "headers.vh"
`include "matmul_interface.sv"
`include "matmul_stimulus.sv"
module matmul_tester#(
    parameter string RESOURCE_BASE = ""
) (
    matmul_interface intf
);

import matmul_pkg::*;
wire rst = intf.rst_ni;

// Functional Coverage untoggle for checking coverage
// matmul_coverage u_cover (
//     .intf(intf)
// );

// Functional Checker untoggle for checker
// matmul_checker u_check (
//     .intf    (intf)
// );

matmul_stimulus #(
    .MAT_A_FILE($sformatf("",RESOURCE_BASE)),
    .MAT_B_FILE($sformatf("",RESOURCE_BASE))
 ) u_stim (
    .intf(intf)
);

initial begin: TB_INIT
    wait(rst); wait(!rst);

end

endmodule
