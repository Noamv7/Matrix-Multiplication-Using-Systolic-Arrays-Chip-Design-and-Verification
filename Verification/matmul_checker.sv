`include "headers.vh"
`include "matmul_pkg.sv"
`include "matmul_interface.sv"


module matmul_checker (
    matmul_interface.matmul_checkcoverage intf
);
import matmul_pkg::*;

property active_reset; 
    @(posedge intf.clk)
        (~intf.rst_ni) |=> ~intf.pslverr_o;
endproperty

a_active_reset: assert property(active_reset) else $error("\n\tAssertion active_reset failed!");
cover property(active_reset);


property valid_write_and_read_addresses; 
    @(posedge intf.clk_i) disable iff(intf.rst_ni)
        ((intf.pwrite_i && (intf.paddr_i[4:0] == 0 || intf.paddr_i[4:0] == 4 || intf.paddr_i[4:0] == 8) && ~intf.busy_o) || 
		(~intf.pwrite_i && (intf.paddr_i[4:0] == 0 || intf.paddr_i[4:0] == 4 || intf.paddr_i[4:0] == 8 || intf.paddr_i[4:0] == 12 || intf.paddr_i[4:0] == 16)))
		|-> ~intf.pslverr_o;
endproperty

a_valid_write_and_read_addresses: assert property(valid_write_and_read_addresses) else $error("\n\tAssertion valid_write_and_read_addresses failed!\n\addr : %0d", intf.paddr_i[4:0]); // assert property checks if a statement is true through the simulation, or check sequence of events
cover property(valid_write_and_read_addresses); // cover property checks if a specified sequence of events occurred during the simulation


property invalid_write_and_read_addresses; 
    @(posedge intf.clk_i) disable iff(intf.rst_ni)
        ((intf.pwrite_i && ~(intf.paddr_i[4:0] == 0 || intf.paddr_i[4:0] == 4 || intf.paddr_i[4:0] == 8)) || (intf.pwrite_i && (intf.paddr_i[4:0] == 0 || intf.paddr_i[4:0] == 4 || intf.paddr_i[4:0] == 8) && intf.busy_o) ||
		(~intf.pwrite_i && ~(intf.paddr_i[4:0] == 0 || intf.paddr_i[4:0] == 4 || intf.paddr_i[4:0] == 8 || intf.paddr_i[4:0] == 12 || intf.paddr_i[4:0] == 16)))
		|-> intf.pslverr_o;
endproperty

a_invalid_write_and_read_addresses: assert property(invalid_write_and_read_addresses) else $error("\n\tAssertion invalid_write_and_read_addresses failed!\n\addr : %0d", intf.paddr_i[4:0]); // assert property checks if a statement is true through the simulation, or check sequence of events
cover property(invalid_write_and_read_addresses); // cover property checks if a specified sequence of events occurred during the simulation

property valid_start_bit_busy; 
    @(posedge intf.clk) disable iff(intf.rst)
        (intf.paddr_i[4:0] == 0 && intf.pwrite_i && intf.penable_i && intf.pwdata_i[0] && ~intf.busy_o) |-> ##[1:2] intf.busy_o;
endproperty

a_valid_start_bit_busy: assert property(valid_start_bit_busy) else $error("\n\tAssertion valid_start_bit_busy failed!");
cover property(valid_start_bit_busy);

property valid_transfer; 
    @(posedge intf.clk_i) disable iff(intf.rst_ni)
        (intf.psel |=> intf.penable_i);
endproperty

a_valid_transfer: assert property(valid_transfer) else $error("\n\tAssertion valid_transfer failed!"); // assert property checks if a statement is true through the simulation, or check sequence of events
cover property(valid_transfer); // cover property checks if a specified sequence of events occurred during the simulation

property valid_read_and_write_targets; 
    @(posedge intf.clk) disable iff(intf.rst)
        (intf.paddr_i[4:0] == 0 && intf.pwrite_i && intf.penable_i) |-> (intf.pwdata_i[3:2] < SP_NTARGETS && intf.pwdata_i[5:4] < SP_NTARGETS) ;
endproperty

a_valid_read_and_write_targets: assert property(valid_read_and_write_targets) else $error("\n\tAssertion valid_read_and_write_targets failed!\n\addr : %0d", intf.pwdata_i[5:2]);
cover property(valid_read_and_write_targets);


endmodule
