`include "headers.vh"

module apb_slave(clk_i,rst_ni,psel_i,penable_i,pwrite_i,pstrb_i,pwdata_i,paddr_i,pready_o ,pslverr_o,prdata_o,busy_o,
pslverr_i, busy_i,data_in_from_mem,data_out_mem,addr_out_mem,write_en_out, pstrb_o); // inputs and outputs

// global parameters definition
  parameter DATA_WIDTH = 8;// 8,16,32
  parameter BUS_WIDTH = 32;// 16,32,64
  parameter ADDR_WIDTH = 16;// 16,24,32
  parameter SP_NTARGETS = 2;// 1,2,4
  localparam MAX_DIM = BUS_WIDTH/DATA_WIDTH;// 2,4
  
 // local parameter definition 
  parameter idle_state = 2'b00;// default state until start
  parameter setup_write_state = 2'b01; // going to setup state when paddr_i, pwrite_i, psel and prdata_o/pwdata are in (pstrb_i is coming with pwdata).
  parameter setup_read_state = 2'b10;// going to access_state when penable are high.
  
  // inputs that are coming from master Mike
  // before disaster => obey your master
  input                         clk_i; // Clock signal for the design
  input                         rst_ni; // Reset signal, active low
  input                         psel_i; // APB select
  input							penable_i; // APB enable
  input                         pwrite_i; // APB write enable, when incative it's APB read enable
  input		   [MAX_DIM-1:0]	pstrb_i; // APB write strobe (�byte� select). must be incative for read transfer. corresponds to pwdata
  input        [BUS_WIDTH-1:0] pwdata_i; // APB write data
  input        [ADDR_WIDTH-1:0] paddr_i; // APB address
  output wire                    pready_o; // APB slave ready
  output reg   					pslverr_o; // APB slave error, both on read and write. only valid during the last cycle of a transfer. meaning, when psel, penable and pready are high.
  output wire   [BUS_WIDTH-1:0]  prdata_o; // APB read data
  output wire					busy_o; // Busy signal, indicating the design cannot be written to. coming from Register File.
  
  // inputs and outputs from and to the design
  input 						pslverr_i; // plsverr input from Register File
  //input                         wait_i; // signal for wait states. (maybe unnesecery)
  input                         busy_i; // from the design
  input   [BUS_WIDTH-1:0]       data_in_from_mem; // APB read data from Register File
  output wire   [BUS_WIDTH-1:0]  data_out_mem; // APB write data to memory (in RF module)
  output wire   [ADDR_WIDTH-1:0] addr_out_mem; // indicates which address to write to in memory (in RF module)
  output wire                    write_en_out;// indicates write/read enable to memory
  output wire    [MAX_DIM-1:0]   pstrb_o;// indicates write/read enable to memory
// local temporary regs
  reg [1:0] current_state;// indicates the current state which we are in FSM
// assign output values
assign pready_o = (current_state == setup_write_state || current_state == setup_read_state) && psel_i && penable_i;
assign write_en_out = pwrite_i;
assign addr_out_mem = paddr_i;
assign data_out_mem = pwdata_i;
assign prdata_o = data_in_from_mem;
assign pstrb_o = pstrb_i;
assign busy_o = busy_i;


always @(posedge clk_i) 
begin: apbing
  if (~rst_ni) // negedge reset
  begin // start if
    current_state <= idle_state;// on reset, returning to default state
	  pslverr_o <= 0; // reset error signal
	end // end reset

  else// if not reset
  begin// start else
  	//busy_o <= busy_i; // sending to master busy signal from the design
    case (current_state)// FSM declaration
		idle_state : begin
			pslverr_o <= 0;
			if (psel_i)// when psel is high, transfer incoming, go to setup state 
			begin // start if
				current_state <= (pwrite_i) ? setup_write_state : setup_read_state;// next state definition
			end // end if
		end
		setup_write_state : begin  // idle state is default state and is defined at the end
			// next state definition
			if (psel_i && penable_i) // if psel and penable are high => going to access state
			begin // start if
				pslverr_o <= pslverr_i;// transfer error signal from the design if address is incorrect or design is busy
				current_state <= idle_state; // next state definition
			end// end if
		end

		setup_read_state : begin  // idle state is default state and is defined at the end
			// next state definition
			if (psel_i && penable_i) // if psel and penable are high => going to access state
			begin // start if
				pslverr_o <= pslverr_i; // transfer error signal from the design if address is incorrect or design is busy
				current_state <= idle_state; // next state definition
			end// end else
		end// end state

	default: begin // defined as idle_state for design checker purposes
			current_state <= idle_state;
			pslverr_o <= 1'b1;
        end	// end default (idle) state	
    endcase // end cases
  end // end else
end // end always
endmodule // end APB_SLAVE module

