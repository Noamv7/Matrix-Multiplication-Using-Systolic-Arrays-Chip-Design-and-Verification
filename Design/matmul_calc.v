`include "headers.vh"
`include "pe_module.v"
`define OP_SIGN signed
module matmul_calc(clk_i, rst_ni, start_bit_i, matrix_a_in, matrix_b_in, sp_write, flags_o, write_to_sp,dimension_N_i,dimension_K_i,dimension_M_i);
  // Parameter definitions
  parameter DATA_WIDTH = 8;//8,16,32  Data width in bits
  parameter BUS_WIDTH = 32;// 16,32,64     Bus width in bits
  parameter ADDR_WIDTH = 16;//16,24,32  Address width in bits
  parameter SP_NTARGETS = 2; // 1,2,4  Number of SP targets
  localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH;// 2,4

  // Input and output ports
  input wire clk_i;// clk in from design
  input wire rst_ni; // reset in from design
  input wire start_bit_i; // start bit from MEM
  input wire [MAX_DIM * BUS_WIDTH - 1:0] matrix_a_in; // mat a from mem
  input wire [MAX_DIM * BUS_WIDTH - 1:0] matrix_b_in;// mat b from mem
  input wire [1:0] dimension_N_i;//2,3,4
  input wire [1:0] dimension_K_i;//2,3,4
  input wire [1:0] dimension_M_i;//2,3,4
  output reg sp_write; // indicates that the MATMUL finished and can write to SP
  output reg [MAX_DIM * MAX_DIM - 1:0] flags_o; // flags output to MEM
  output reg [BUS_WIDTH * MAX_DIM * MAX_DIM - 1:0] write_to_sp; // write results to sp

  // Internal registers and wires
  reg signed [2 * MAX_DIM:0] counter; // local counter //[$clog2(MAX_DIM)*2 - 1:0] - לא בטוח שעובד לקטן מ4 על 4
  reg finish_pe; // local finish signal
  reg `OP_SIGN [DATA_WIDTH-1:0] mat_a[MAX_DIM-1:0]; // temp mat a
  reg `OP_SIGN [DATA_WIDTH-1:0] mat_b[MAX_DIM-1:0];// temp mat b
  wire `OP_SIGN [DATA_WIDTH-1:0] mat_a_wire[MAX_DIM-1:0][MAX_DIM:0];// similar to mat a, but needs to be wire
  wire `OP_SIGN [DATA_WIDTH-1:0] mat_b_wire[MAX_DIM:0][MAX_DIM-1:0];// similar to mat b, but needs to be wire
  wire `OP_SIGN [2 * DATA_WIDTH-1:0] mat_c_wire[MAX_DIM-1:0][MAX_DIM-1:0];// results matrix
  wire [MAX_DIM * MAX_DIM-1:0] flags_o_wire; // flags output, need to be wire
  reg signed [$clog2(MAX_DIM):0] k; // temporary signal
  reg [1:0] dim_m;//2,3,4

  // Matrix assignment for parallelism
  genvar n,h;// generate variable for for loop
  generate // start gen
    for (n = 0; n < MAX_DIM; n = n + 1) // for
		begin : lines_and_columns_assign  // start for
      assign mat_a_wire[n][0] = mat_a[n];   // Assign matrix_a_in to mat_a
      assign mat_b_wire[0][n] = mat_b[n];   // Assign matrix_b_in to mat_b
    end// end for
  endgenerate // end gen

  // Matrix multiplication PE instances
  genvar i, j;// generate variable for for loop
  generate// start gen
    for (i = 0; i < MAX_DIM; i = i + 1) // for rows
	begin : rows // start for
      for (j = 0; j < MAX_DIM; j = j + 1) // for columns
	  begin : columns // start for
        // Instantiate PE_MODULE for matrix multiplication
        pe_module pe_1 (.clk_i(clk_i), // pe portmap
                        .rst_ni(rst_ni),// pe portmap
                        .start_bit_i(start_bit_i),// pe portmap
                        .in_a(mat_a_wire[i][j]), // mat a in pe
                        .in_b(mat_b_wire[i][j]),// mat b in pe
                        .out_a(mat_a_wire[i][j+1]), // insert value for next vertical pe
                        .out_b(mat_b_wire[i+1][j]),// insert value for next horizontal pe
                        .out_c(mat_c_wire[i][j]), // save results in mat c
                        .overflow_signal(flags_o_wire[j+MAX_DIM*i]) // save overflow signals
                        );
      end// end for
    end// end for
  endgenerate// end gen

  // State machine for inserting vectors

  always @(posedge clk_i) // always block
  begin : insert_a_and_b_vectors // begin always
    if (~rst_ni || ~start_bit_i) // reset
	  begin // reset
      for (k = 0; k < MAX_DIM[$clog2(MAX_DIM):0]; k = k + 1) // for
	    begin : rst // start for
        mat_a[k[$clog2(MAX_DIM)-1:0]] <= 0; // reset matrix
        mat_b[k[$clog2(MAX_DIM)-1:0]] <= 0;// reset matrix
        counter <= 0;// reset counter
        sp_write <= 0; // reset finish signal
        finish_pe <= 0; // reset local signal
		    write_to_sp <= 0; // reset output
		    flags_o <= 0;// reset output
        // dim_n <= 0;
        // dim_k <= 0;
         dim_m <= 0;
      end// end for
    end 
	else 
  if (start_bit_i && counter < (dimension_M_i + dimension_N_i + dimension_K_i + 2))  // slicing condition
	begin // begin if
    dim_m <= dimension_M_i;
		counter <= counter + 1; // count up
    for (k = 0; k < MAX_DIM[$clog2(MAX_DIM):0]; k = k + 1) // for
	    begin : slicing_matrixes // start for
        // Load matrix_a_in and matrix_b_in into mat_a and mat_b
        mat_a[k[$clog2(MAX_DIM)-1:0]] <= (counter - k[$clog2(MAX_DIM)-1:0] < MAX_DIM) ? matrix_a_in[(k[$clog2(MAX_DIM)-1:0]*BUS_WIDTH)+((counter - k[$clog2(MAX_DIM)-1:0])*DATA_WIDTH)+:DATA_WIDTH]:0; // indicates the slicing for matrix a, inserts the elements in the correct order. when finished, inserts zeros to keep the design from making mistakes
        mat_b[k[$clog2(MAX_DIM)-1:0]] <= (counter - k[$clog2(MAX_DIM)-1:0] < MAX_DIM) ? matrix_b_in[(k[$clog2(MAX_DIM)-1:0]*BUS_WIDTH)+((counter - k[$clog2(MAX_DIM)-1:0])*DATA_WIDTH)+:DATA_WIDTH]:0; // indicates the slicing for matrix b, inserts the elements in the correct order. when finished, inserts zeros to keep the design from making mistakes
      end// end for
  end // end if
	else // enough slicing, everything is zeros
	begin // begin else
    finish_pe <= 1; // matmul is finished
	  counter <= 0;
    end // end else
  end// end always

  // Output generation
  genvar m, p;// generate variable for for loop
  generate// start gen
    
    for (m = 0; m < MAX_DIM; m = m + 1) 
	  begin : c_rows // start for
      for (p = 0; p < MAX_DIM + 1; p = p + 1) 
	    begin : c_columns // start for
        always @(posedge clk_i) 
		    begin: write_mat_c_to_sp
          if (finish_pe && (m < (dimension_N_i+1)) && (p < (dimension_M_i+1)) ) // calc is finished
		      begin // write to SP
            sp_write <= 1; // allowed to write to SP
			      finish_pe <= 0; // let the values out at once for one cycle
            // Write mat_c_wire to write_to_sp and set flags_o
            write_to_sp[m*(dim_m+1)*BUS_WIDTH + p*BUS_WIDTH + BUS_WIDTH - 1 -:BUS_WIDTH] <= ((flags_o_wire[m*MAX_DIM+p] && mat_c_wire[m][p] > 0) || (mat_c_wire[m][p] < 0 && ~flags_o_wire[m*MAX_DIM+p])) ? {{(BUS_WIDTH-2*DATA_WIDTH){1'b1}}, mat_c_wire[m][p]} :mat_c_wire[m][p]; // results to SP
            //$display("matCwire = %0d, m= %0d, p=%0d, flags_o_wire[m*MAX_DIM+p] = %0h, (m*(dim_m+1)*BUS_WIDTH + p*BUS_WIDTH + BUS_WIDTH - 1) = %0d",mat_c_wire[m][p],m,p,flags_o_wire[m*MAX_DIM+p], (m*(dim_m+1)*BUS_WIDTH + p*BUS_WIDTH + BUS_WIDTH - 1));
            flags_o[m*(dim_m+1)+p] <= flags_o_wire[m*MAX_DIM+p]; // flags out
            mat_a[m] <= 0;
            mat_b[m] <= 0;
          end// end if
        end// end always
      end// end for
    end// end for
  endgenerate// end gen
endmodule
