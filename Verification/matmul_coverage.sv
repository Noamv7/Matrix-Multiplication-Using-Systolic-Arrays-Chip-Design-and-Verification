`include "headers.vh"
`include "matmul_pkg.sv"
`include "matmul_interface.sv"

module matmul_coverage (
    matmul_interface.matmul_checkcoverage intf
);
import matmul_pkg::*;

covergroup test @(posedge intf.clk_i);
		RESET: coverpoint intf.rst_ni {
			bins low = {0};
			bins high = {1};
		}

		ERROR: coverpoint intf.pslverr_o {
			bins low = {0};
			bins high = {1};
		}

		ADDRESS: coverpoint intf.paddr_i[4:0] iff (intf.psel_i && intf.penable_i) {
			bins control = {0};
			bins mat_a = {4};
			bins mat_b = {8};
			bins flags = {12};
			bins sp = {16};
			bins others = default;
		}
		
		BUSY: coverpoint intf.busy_o {
			bins low = {0};
			bins high = {1};
		}
		
		WRITE_AND_READ: coverpoint intf.pwrite_i {
			bins low = {0};
			bins high = {1};
		}

		VALID_PENABLE: coverpoint intf.penable_i iff(~intf.psel_i) {
			bins valid = {0};
			bins invalid = {1};
		}

		VALID_WRITE_TARGET: coverpoint intf.pwdata_i[3:2] iff(intf.paddr_i[4:0]==0 && intf.pwrite_i && ~intf.busy_o) {
			bins zero = {0};
			bins one = {1};  // if SP_NTARGETS = 1, this should be zero
			bins two = {2}; // if SP_NTARGETS = 2, this should be zero
			bins three = {3}; // if SP_NTARGETS = 2, this should be zero
			bins invalid = default;
		}

		VALID_READ_TARGET: coverpoint intf.pwdata_i[5:4] iff(intf.paddr_i[4:0]==0 && intf.pwrite_i && ~intf.busy_o) {
			bins zero = {0};
			bins one = {1};  // if SP_NTARGETS = 1, this should be zero
			bins two = {2}; // if SP_NTARGETS = 2, this should be zero
			bins three = {3}; // if SP_NTARGETS = 2, this should be zero
			bins invalid = default;
		}

		N_DIM: coverpoint intf.pwdata_i[9:8] iff(intf.paddr_i[4:0]==0 && intf.pwrite_i && ~intf.busy_o) {
			bins two = {1};  
			bins three = {2};
			bins four = {3};
			bins invalid = default;
		}

		K_DIM: coverpoint intf.pwdata_i[11:10] iff(intf.paddr_i[4:0]==0 && intf.pwrite_i && ~intf.busy_o) {
			bins two = {1};  
			bins three = {2};
			bins four = {3};
			bins invalid = default;
		}

		M_DIM: coverpoint intf.pwdata_i[13:12] iff(intf.paddr_i[4:0]==0 && intf.pwrite_i && ~intf.busy_o) {
			bins two = {1};  
			bins three = {2};
			bins four = {3};
			bins invalid = default;
		}

		

endgroup
test cg = new; // reset the covergroups


endmodule
