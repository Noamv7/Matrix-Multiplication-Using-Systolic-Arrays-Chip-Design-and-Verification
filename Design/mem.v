`include "headers.vh"

module mem(clk_i, rst_ni, pwdata_i, paddr_i, pwrite_i, pstrb_i, prdata_o, a_out,b_out, pslverr_o, busy_o, sp_write, write_to_sp, flags_in, start_bit_o,dimension_N_o,dimension_K_o,dimension_M_o );

  // define parameter
  parameter DATA_WIDTH = 8;// 8,16,32
  parameter BUS_WIDTH = 32;// 16,32,64
  parameter ADDR_WIDTH = 16;// 16,24,32
  parameter SP_NTARGETS = 2;// 1,2,4
  localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH;// 2,4
  
  
  // inputs from APB
  input wire clk_i; // positive clock
  input wire rst_ni; // negative reset
  input wire [BUS_WIDTH-1:0] pwdata_i; // data from apb
  input wire [ADDR_WIDTH-1:0] paddr_i; // address from the apb indictaing what to read or what to write.
  input wire pwrite_i;// write enable signal from the apb
  input wire [MAX_DIM-1:0] pstrb_i; // strobes bits in from APB
  
  // inputs from Matmul
  input wire sp_write; // indicate write results&flags from matmul to ScratchPad
  input wire [MAX_DIM*MAX_DIM*BUS_WIDTH-1:0] write_to_sp; // data from MATMUL to SP
  input wire [MAX_DIM*MAX_DIM - 1: 0] flags_in; // flags in from MATMUL to SP
  
  // outputs to APB
  output reg [BUS_WIDTH-1:0] prdata_o; // data out to APB
  output reg pslverr_o;// error signal to apb
  output reg busy_o;// busy signal to apb

  // output to Matmul 
  output reg [MAX_DIM*BUS_WIDTH-1:0] a_out;// matrix A out to MATMUL
  output reg [MAX_DIM*BUS_WIDTH-1:0] b_out;// matrix B out to MATMUL
  output reg start_bit_o;
  output reg [1:0] dimension_N_o;//2,3,4
  output reg [1:0] dimension_K_o;//2,3,4
  output reg [1:0] dimension_M_o;//2,3,4
// Define memory
 reg [BUS_WIDTH-1:0] RAM [16+SP_NTARGETS*MAX_DIM*MAX_DIM-1:0]; // memory definition
 
 
// Control Register (Address 0)
wire start_bit; // start_bit from the APB, buffer starts moving to matmul when set to '1'
wire mode_bit; // biased '1' or unbiased '0'
wire [1:0] write_target; // write to target
wire [1:0] read_target; // read from target
//wire [1:0] dataflow_type; // optional, we didnt use
wire [1:0] dimension_N;//2,3,4
wire [1:0] dimension_K;//2,3,4
wire [1:0] dimension_M;//2,3,4
//wire reload_operand_A; // reserved, didnt use
//wire reload_operand_B; // reserved, didnt use
wire [4:0] addr; // local signal
wire [5:0] addr_write; // local signal
wire [5:0] addr_read_sp; // local signal
wire [$clog2(MAX_DIM)-1:0] sub_addr; // local signal, size for sub-addressing
wire [$clog2(MAX_DIM)*2-1:0] sub_addr_sp; // local signal, size for sub-addressing
reg busy;// local signal



 genvar j; // generate variable for for loop
 generate // reset RAM 
	for (j = 0; j < (16+SP_NTARGETS*MAX_DIM*MAX_DIM); j = j + 1) //for loop inside generate block
	begin // begin for
		always @(posedge clk_i) // always block
		begin : reset_RAM
		if(~rst_ni) // rst
		begin // begin rst
			RAM[j] <= 0; // Set all elements to 0 (or any desired reset value)
	  end// end if
  end// end always
  end// end for
endgenerate //end generate

assign start_bit = RAM[0][0]; // give names to registers for an easy read
assign mode_bit = RAM[0][1];// give names to registers for an easy read
assign write_target = RAM[0][3:2];// give names to registers for an easy read
assign read_target = RAM[0][5:4];// give names to registers for an easy read
//assign dataflow_type = RAM[0][7:6];// unused
assign dimension_N = RAM[0][9:8];// give names to registers for an easy read
assign dimension_K = RAM[0][11:10];// give names to registers for an easy read
assign dimension_M = RAM[0][13:12];// give names to registers for an easy read
assign addr = paddr_i[4:0]; // the actual address from APB
assign sub_addr = paddr_i[5+:$clog2(MAX_DIM)]; // sub-addressing definition for A&B
assign sub_addr_sp = paddr_i[5+:$clog2(MAX_DIM)*2]; // sub-addressing definition for SP
assign addr_write = sub_addr + addr; // the actual address for write/read matrixes
assign addr_read_sp = sub_addr_sp + addr; // the actual address for read SP



genvar i;// generate variable for for loop
generate // generate block
	for (i = 0; i < MAX_DIM; i = i + 1) //for loop inside generate block
	begin// begin for
		always @(posedge clk_i)// always block
		begin : write_from_apb_or_read_to_apb // read/write to memory
		if(~rst_ni) //rst
		begin // begin reset
			 prdata_o <= 0; // rst read data
			 pslverr_o <= 0; // reset error signal
			 a_out <= 0; // reset matrix a out
			 busy_o <= 0; // reset busy out
			 busy <= 1'b0;// reset local busy
			 b_out <= 0;// reset matrix b out
			 start_bit_o <= 0; // reset start_bit_o
			 dimension_N_o <= 0;
			 dimension_K_o <= 0;
			 dimension_M_o <= 0;
			end // end reset
		else
		begin // not reset
			if (pstrb_i[i] && pwrite_i) // if need to write
			begin	
				if ((addr == 0 || addr == 4 || addr == 8) && ~busy) // only allowed addresses to write from APB
				begin// begin if
					pslverr_o <= 0; // disable error
					RAM[addr_write][(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= pwdata_i[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];// write with bit select (strobe bits)
					end // end if
				else // addr != 0,4,8 means APB can't write, raise an error
				begin 
				pslverr_o <= 1; // raise error
				end // end else
			end // end if
			else // can't write
			begin 
			if(~pwrite_i) // read
			begin// begin if
				if (addr == 0 || addr == 4 || addr == 8 || addr == 12) // only allowed addresses to read from APB
				begin// begin if
					pslverr_o <= 0;// disable error
					prdata_o <= RAM[addr_write];// read data
				end // end if
				else 
				begin
					if(addr == 16) // if read from SP which read_target ? ?
					begin
						pslverr_o <= 0;// disable error
						prdata_o <= RAM[addr_read_sp + MAX_DIM*MAX_DIM*read_target];// read from sp
						end  // end if
					else 
					begin 
					pslverr_o <= 1; // addr != 0,4,8,12,16 means APB can't write, raise an error
					end // end else
				end
			end//end if
			end// end else
		end// end else
	end // end always
end// end for	
endgenerate	//end generate


genvar sp;// generate variable for for loop
generate // write to SP
	 for (sp = 0; sp < MAX_DIM*MAX_DIM; sp = sp + 1) //for loop inside generate block
	 begin
		 always @(posedge clk_i)// always block
		 begin : write_from_matmul_to_sp_and_flags
			if(sp_write & busy) // sp write means MATMUL has finished
			begin// begin if
				busy <= 1'b0; // no more busy
				busy_o <= 1'b0;
				RAM[12][MAX_DIM*MAX_DIM-1:0] <= flags_in; // read flags
				start_bit_o <= 0; // finish
				a_out <= 0;
				b_out <= 0;
				RAM[0][0] <= 1'b0; // deassert startbit
				if(~mode_bit) // if mode bit = 0
				begin// begin if
					RAM[16+(write_target)*MAX_DIM*MAX_DIM+sp] <= write_to_sp[(sp+1)*BUS_WIDTH-1: sp*BUS_WIDTH];// normal write
				end // end if
				else // mode bit = 1
				begin// begin mode bit
					RAM[16+(write_target)*MAX_DIM*MAX_DIM+sp] <= RAM[16+(write_target)*MAX_DIM*MAX_DIM+sp]+write_to_sp[(sp+1)*BUS_WIDTH-1: sp*BUS_WIDTH];// write biased
					end// end else
			end // end if
	 end // end always
 end// end for	
endgenerate	//end generate

 genvar ka;// generate variable for for loop
 generate // start the design when start bit = 1, export matrix A
	 for (ka = 0; ka < MAX_DIM; ka = ka + 1)//for loop inside generate block 
	 begin // begin for
		 always @(posedge clk_i)// always block
		 begin : mat_a_to_design
			if (start_bit == 1 && rst_ni && ~sp_write) //when start bit is 1, start MATMUL
			begin // begin if
				if(ka < dimension_N + 1) a_out[(ka+1)*BUS_WIDTH-1:ka*BUS_WIDTH] <= RAM[4+ka]; // matrix a out
				if(ka < dimension_M + 1) b_out[(ka+1)*BUS_WIDTH-1:ka*BUS_WIDTH] <= RAM[8+ka]; // matrix b out
				busy_o <= 1; // busy out
				busy <= 1'b1;// local busy
				start_bit_o <= 1; // let the MATMUL know the matrixes are out
				dimension_N_o <= dimension_N;
				dimension_K_o <= dimension_K;
				dimension_M_o <= dimension_M;
				end // end if
		  end// end always
	 end//end for	
 endgenerate//end generate
	
endmodule 