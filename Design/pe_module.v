`include "headers.vh"
 `define OP_SIGN signed
 module pe_module(clk_i, rst_ni,start_bit_i, in_a, in_b, out_a, out_b, out_c, overflow_signal); // this module is a proccessing element that takes an element from matrix A and matrix B, multiply them and sums to register repeatedly.
  // define parameters
  parameter DATA_WIDTH = 8;// 8,16,32
  // inputs
  input wire rst_ni, clk_i, start_bit_i; // negative reset, positive clock
  input wire `OP_SIGN [DATA_WIDTH-1:0] in_a, in_b; // matrix element inputs
  // outputs
  output reg `OP_SIGN [DATA_WIDTH*2-1:0] out_c;//[BUS_WIDTH-1:0] out_c;
  output reg `OP_SIGN [DATA_WIDTH-1:0] out_a, out_b; // chained inputs to next PE
  output reg overflow_signal; // indicate overflow
  
  // Multiplier component
  wire `OP_SIGN [2*DATA_WIDTH-1:0] mult_res = in_a * in_b; 
  wire `OP_SIGN [2*DATA_WIDTH:0] macc_res = out_c + mult_res; 

  // start calculation
  always @(posedge clk_i) // we chose to use clk_i instead of * in order to be able to know for sure when the inputs and outputs are ready
  begin: CALC_OUT // start proccessing element calculation
    if (~rst_ni) // negative reset
    begin // we can give up the begin-end block because we don't mind if the statements will be executed sequentially or not
      out_a <= 0; // reset a out
      out_b <= 0; // reset b out
      out_c <= 0; // reset c out
	    overflow_signal <= 0; // reset overflow out
    end // end reset
    else // else statement
    begin 
	    if (start_bit_i) // than it ok to start
	    begin // we can give up the begin-end block because we don't mind if the statements will be executed sequentially or not	
        out_a <= in_a; // chain a to next PE
        out_b <= in_b; // chain b to next PE
	      if ((mult_res[2*DATA_WIDTH-1] && out_c[2*DATA_WIDTH-1] && ~macc_res[2*DATA_WIDTH-1]) || (~mult_res[2*DATA_WIDTH-1] && ~out_c[2*DATA_WIDTH-1] && macc_res[2*DATA_WIDTH-1])) begin
          overflow_signal <= ~overflow_signal;
          out_c <= macc_res[2*DATA_WIDTH-1:0];
        end
		    else begin
		      out_c <= macc_res[2*DATA_WIDTH-1:0];
		    end
	    end // end if
	    else begin
        out_c <= 0;
        overflow_signal <= 0;
		  end
    end// end else
  end // end calculation

endmodule