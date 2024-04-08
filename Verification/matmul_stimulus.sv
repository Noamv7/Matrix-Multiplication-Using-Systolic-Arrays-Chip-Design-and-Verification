`include "headers.vh"
`include "matmul_pkg.sv"
`include "matmul_interface.sv"
// Stimulus Module
module matmul_stimulus #(
    parameter string MAT_A_FILE = "",
    parameter string MAT_B_FILE = ""
 )(
    matmul_interface.matmul_stimulus    intf
);

`define NULL 0
// Default file paths for matrices, parameters, and dimensions
parameter string MAT_A = "C:/logic design/matrixa.txt";
parameter string MAT_B = "C:/logic design/matrixb.txt";
parameter string MAT_C = "C:/logic design/matrixc.txt";
parameter string PARAMETERS = "C:/logic design/parameters.txt";
parameter string DIMENSIONS = "C:/logic design/dimensions.txt";
import matmul_pkg::*;


reg [5:0] i,j;
reg [BUS_WIDTH-1:0] mat_a;
reg [BUS_WIDTH-1:0] mat_b;
reg [1:0] line_number;
integer mat_a_fd, mat_b_fd,mat_c_fd, parameters_fd,dimensions_fd, read_line_fd, assign_line_fd;
logic unsigned [2:0] n_dim, k_dim, m_dim;
integer DW, BW, AW, SPN, count_error, count_right, incorrect_flag;
string line;
integer k,p;
int total_errors, total_correct, count;
logic signed [DATA_WIDTH-1:0] matA [0:MAX_DIM-1][0:MAX_DIM-1];
logic signed [BUS_WIDTH-1:0] matA_lines [0:MAX_DIM-1];
logic signed [BUS_WIDTH-1:0] matB_lines [0:MAX_DIM-1];
logic signed [DATA_WIDTH-1:0] matB [0:MAX_DIM-1][0:MAX_DIM-1];
logic signed [BUS_WIDTH-1:0] matC [0:MAX_DIM-1][0:MAX_DIM-1];
logic signed [BUS_WIDTH-1:0] matC_from_sp [0:MAX_DIM*MAX_DIM-1];
logic [BUS_WIDTH-1:0] flags, data;
logic unsigned [1:0] m_dim_o,n_dim_o,k_dim_o;

// Assigning dimensions so it'll fit to 2 bits
assign m_dim_o = m_dim - 1;
assign n_dim_o = n_dim - 1;
assign k_dim_o = k_dim - 1;

// Reset task to initialize variables and open files
task do_reset(); 
	begin
		wait(~intf.rst_ni)
        intf.paddr_i  = 0;
        intf.penable_i= 1'b0;
        intf.psel_i   = 1'b0;
        intf.pstrb_i  = 0;
        intf.pwdata_i = 0;
        intf.pwrite_i = 1'b0;
		total_errors = 0;
		total_correct = 0;
		mat_a = 0;
		mat_b = 0;
		line_number = 0;
		i = 0;
		j = 0;
		k = 0;
		p = 0;
		count_right = 0;
		count_error = 0;
		n_dim = 0;
		k_dim = 0;
		m_dim = 0;
		flags = 0;
		incorrect_flag = 0;
		for (int i = 0; i < MAX_DIM; i++) begin
			for (int j = 0; j < MAX_DIM; j++) begin
				matA[i][j] = 0;
				matB[i][j] = 0;
				matC[i][j] = 0;
				matC_from_sp[i*MAX_DIM+j] = 0;
				matA_lines[i] <= 0;
				matB_lines[i] <= 0;
			end
		end
		open_txt_files();
		read_parameters();
	end endtask

// Local reset task for resetting local variables
task do_local_reset(); 
	begin
		mat_a = 0;
		mat_b = 0;
		line_number = 0;
		i = 0;
		j = 0;
		k = 0;
		p = 0;
		count_right = 0;
		count_error = 0;
		n_dim = 0;
		k_dim = 0;
		m_dim = 0;
		flags = 0;
		for (int i = 0; i < MAX_DIM; i++) begin
			for (int j = 0; j < MAX_DIM; j++) begin
				matA[i][j] = 0;
				matB[i][j] = 0;
				matC[i][j] = 0;
				matC_from_sp[i*MAX_DIM+j] = 0;
				matA_lines[i] <= 0;
				matB_lines[i] <= 0;
			end
		end
	end endtask

// Task for writing matrix A to memory
task write_mat_a(
	input logic [BUS_WIDTH-1:0] mat_a,
	input logic [1:0] line_number); 
	begin
		@(posedge intf.clk_i);
			intf.psel_i = 1; 
			intf.paddr_i = 16'h0004 + 16'h0020 * line_number; 
			intf.pwrite_i = 1; 
			intf.pwdata_i = mat_a;
			intf.pstrb_i= {MAX_DIM{1'b1}};
		@(posedge intf.clk_i);
			intf.penable_i = 1;
		@(posedge intf.clk_i);
			intf.penable_i =0;
			intf.psel_i = 0;
			// intf.pwrite_i = 0;
	end endtask

// Task for writing matrix B to memory
task write_mat_b(
	input logic [BUS_WIDTH-1:0] mat_b,
	input logic [1:0] line_number); 
	begin
		@(posedge intf.clk_i); 
			intf.psel_i = 1; 
			intf.paddr_i = 16'h0008 + 16'h0020 * line_number; 
			intf.pwrite_i = 1; 
			intf.pwdata_i = mat_b;
			intf.pstrb_i= {MAX_DIM{1'b1}};
		@(posedge intf.clk_i);
			intf.penable_i = 1;
		@(posedge intf.clk_i);
			intf.penable_i =0;
			intf.psel_i = 0;
			// intf.pwrite_i = 0;
	end endtask

// Task for configuring control signals with inputs (start bit, mode bit, write target, read target)	
task write_to_control( // start bit, mode bit, write target, read target
	input logic start_bit, mode_bit,
	input logic [1:0] write_target, read_target); 
	begin
		@(posedge intf.clk_i);
			intf.psel_i = 1; 
			intf.paddr_i = 16'h0000; 
			intf.pwrite_i = 1; 
			intf.pwdata_i = {{(BUS_WIDTH-14){1'b0}},m_dim_o,k_dim_o,n_dim_o,2'b0,read_target,write_target,mode_bit,start_bit};
			intf.pstrb_i= {MAX_DIM{1'b1}};
		@(posedge intf.clk_i);
			intf.penable_i = 1;
		@(posedge intf.clk_i);
			intf.psel_i = 0;
			intf.penable_i = 0;
			intf.pwrite_i = 0;
	end endtask

// Task for general write
task write_to_mem(
	input logic [ADDR_WIDTH-1:0] address,
	input logic [BUS_WIDTH-1:0] data); 
	begin
		@(posedge intf.clk_i);
			intf.psel_i = 1; 
			intf.paddr_i = address; 
			intf.pwrite_i = 1; 
			intf.pwdata_i = data;
			intf.pstrb_i= {MAX_DIM{1'b1}};
		@(posedge intf.clk_i);
			intf.penable_i = 1;
		@(posedge intf.clk_i);
			intf.penable_i =0;
			intf.psel_i = 0;
	end endtask

// Task for general read
task read_from_mem(
	input logic [ADDR_WIDTH-1:0] address,
	output logic [BUS_WIDTH-1:0] data); 
	begin
	@(posedge intf.clk_i);
		intf.psel_i = 1; 
		intf.paddr_i = address; 
		intf.pwrite_i = 0; 
	@(posedge intf.clk_i);
		intf.penable_i = 1;
		wait(intf.pready_o)
		data = intf.prdata_o;
	@(posedge intf.clk_i);
		intf.penable_i =0;
		intf.psel_i = 0;
	end endtask

// Task for reading the entire SP
task read_entire_sp(); begin
	for(i = 0; i < n_dim*m_dim; i = i + 1) begin 
		@(posedge intf.clk_i);
			intf.psel_i = 1; 
			intf.paddr_i = 16'h0010 + 16'h0020*i; 
			intf.pwrite_i = 0; 
		@(posedge intf.clk_i);
			intf.penable_i = 1;
			wait(intf.pready_o)
			matC_from_sp[i] = intf.prdata_o;
		@(posedge intf.clk_i);
			intf.penable_i =0;
			intf.psel_i = 0;
	end end endtask

// Task for reading flags from memory
task read_flags(); begin
	@(posedge intf.clk_i);
		intf.psel_i = 1; 
		intf.paddr_i = 16'h000c; 
		intf.pwrite_i = 0; 
	@(posedge intf.clk_i);
		intf.penable_i = 1;
		wait(intf.pready_o)
		flags = intf.prdata_o;
	@(posedge intf.clk_i);
		intf.penable_i =0;
		intf.psel_i = 0;
	end endtask

// Task for opening text files safely
task open_txt_files(); 
 	begin
		mat_a_fd = $fopen(MAT_A, "r"); // open mat a txt file with read permition
		if(mat_a_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to open %s", MAT_A));
		mat_b_fd = $fopen(MAT_B, "r"); // open mat a txt file with read permition
		if(mat_b_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to open %s", MAT_B));
		mat_c_fd = $fopen(MAT_C, "r"); // open mat a txt file with read permition
		if(mat_c_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to open %s", MAT_C));
		parameters_fd = $fopen(PARAMETERS, "r"); // open mat a txt file with read permition
		if(parameters_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to open %s", PARAMETERS));
		dimensions_fd = $fopen(DIMENSIONS, "r"); // open mat a txt file with read permition
		if(dimensions_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed to open %s", DIMENSIONS));
	end endtask

// Task for reading parameters from text file
task read_parameters(); begin
		read_line_fd = ($fgets(line, parameters_fd));
		if (read_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading parameters line"));
		else begin
            assign_line_fd = $sscanf(line, "DW=%0d,BW=%0d,AW=%0d,SPN=%0d", DW, BW, AW, SPN);
		     if (assign_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed assigning parameters line to variables"));
		 end	
		//$display("DW: %s", DW);
		 if (DW != DATA_WIDTH) $fatal("[STIMULUS] Read DW= %2d\t!=\t Defined DW= %2d",DW , DATA_WIDTH);
		 if (BW != BUS_WIDTH) $fatal("[STIMULUS] Read BW= %2d\t!=\t Defined BW= %2d", BW, BUS_WIDTH);
		 if (AW != ADDR_WIDTH) $fatal("[STIMULUS] Read AW= %2d\t!=\t Defined AW= %2d", AW, ADDR_WIDTH);
		 if (SPN != SP_NTARGETS) $fatal("[STIMULUS] Read SPN=%2d\t!=\t Defined SPN=%2d", SPN, SP_NTARGETS);
		//end
    end endtask

// Task for reading matrice's dimensions from text file
task read_dimensions(); begin
		read_line_fd = ($fgets(line, dimensions_fd));
		if (read_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading dimensions line"));
		else begin
            assign_line_fd = $sscanf(line, "n_dim=%0d,k_dim=%0d,m_dim=%0d",n_dim,k_dim,m_dim);
		     if (assign_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed assigning dimensions line to variables"));
		 end	
    end endtask	

// Task for reading matrices from text file
task read_matrices(); begin
	for (int i = 0; i < n_dim && !$feof(mat_a_fd); i++) begin
		read_line_fd = $fgets(line, mat_a_fd);
		if (read_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading matrixA line"));
		else begin
			case(k_dim)
					1: begin 
						assign_line_fd = $sscanf(line, "%d\n", matA[i][0]);
						matA_lines[i] <= matA[i][0];
					end
					2: begin
						assign_line_fd = $sscanf(line, "%d %d\n", matA[i][0], matA[i][1]);
						matA_lines[i] <= {matA[i][1], matA[i][0]};
					end
					3: begin
						assign_line_fd = $sscanf(line, "%d %d %d\n", matA[i][0], matA[i][1], matA[i][2]);
						matA_lines[i] <= {matA[i][2], matA[i][1], matA[i][0]};
					end
					4: begin
						assign_line_fd = $sscanf(line, "%d %d %d %d\n", matA[i][0], matA[i][1], matA[i][2], matA[i][3]);
						matA_lines[i] <= {matA[i][3], matA[i][2], matA[i][1], matA[i][0]};
					end
					default: begin
						// Handle unexpected K value
						$fatal(1, $sformatf("[STIMULUS] Unexpected K value while reading matrixa"));
					end
				endcase
			if (assign_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed assigning matrixA line to variables"));
			end
		end

	for (int i = 0; i < m_dim && !$feof(mat_b_fd); i++) begin
		read_line_fd = $fgets(line, mat_b_fd);
		if (read_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading matrixB line"));
		else begin
			case(k_dim)
					1: begin 
						assign_line_fd = $sscanf(line, "%d\n", matB[i][0]);
						matB_lines[i] <= matB[i][0];
					end
					2: begin
						assign_line_fd = $sscanf(line, "%d %d\n", matB[i][0], matB[i][1]);
						matB_lines[i] <= {matB[i][1], matB[i][0]};
					end
					3: begin
						assign_line_fd = $sscanf(line, "%d %d %d\n", matB[i][0], matB[i][1], matB[i][2]);
						matB_lines[i] <= {matB[i][2], matB[i][1], matB[i][0]};
					end
					4: begin
						assign_line_fd = $sscanf(line, "%d %d %d %d\n", matB[i][0], matB[i][1], matB[i][2], matB[i][3]);
						matB_lines[i] <= {matB[i][3], matB[i][2], matB[i][1], matB[i][0]};
					end
					
					default: begin
						// Handle unexpected K value
						$fatal(1, $sformatf("[STIMULUS] Unexpected K value while reading matrixb"));
					end
				endcase
			if (assign_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed assigning matrixB line to variables"));
			end
		end

	
	for (int i = 0; i < n_dim && !$feof(mat_c_fd); i++) begin
		read_line_fd = $fgets(line, mat_c_fd);
		if (read_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed reading matrixC line"));
		else begin
			case(m_dim)
					1: assign_line_fd = $sscanf(line, "%d\n", matC[i][0]);
					2: assign_line_fd = $sscanf(line, "%d %d\n", matC[i][0], matC[i][1]);
					3: assign_line_fd = $sscanf(line, "%d %d %d\n", matC[i][0], matC[i][1], matC[i][2]);
					4: assign_line_fd = $sscanf(line, "%d %d %d %d\n", matC[i][0], matC[i][1], matC[i][2], matC[i][3]);
					
					default: begin
						// Handle unexpected M value
						$fatal(1, $sformatf("[STIMULUS] Unexpected M value while reading matrixc"));
					end
				endcase
			if (assign_line_fd == 0) $fatal(1, $sformatf("[STIMULUS] Failed assigning matrixC line to variables"));
			end
		end
end endtask

// Task for checking various scenrios that leads to errors
task check_validity_of_errors(); begin
	// write to wrong address
	write_to_mem(3,15);// address in,data in
	write_to_mem(5,15);// address in,data in
	write_to_mem(6,15);// address in,data in
	write_to_mem(7,15);// address in,data in
	write_to_mem(9,15);// address in,data in
	write_to_mem(12,15);// address in,data in
	write_to_mem(16,15);// address in,data in
	write_to_mem(17,15);// address in,data in
	// read from wrong address
	read_from_mem(3,data);// address in,data out
	read_from_mem(5,data);// address in,data out
	read_from_mem(6,data);// address in,data out
	read_from_mem(17,data);// address in,data out
	// attempt to write during operation
	read_dimensions();
	read_matrices();
	@(posedge intf.clk_i);
	for(i=0; i< n_dim; i++) begin
		write_mat_a(matA_lines[i],i);
	end
	for(j=0; j< m_dim; j++) begin
		write_mat_b(matB_lines[j],j);
	end
	write_to_control(1,0,00,00); // start bit, mode bit, write target, read target
	wait(intf.busy_o);
	write_to_mem(8,15);// address in,data in
	read_from_mem(4,data);// address in,data out
end endtask

// Task for closing the files at the end of an operation
task close_files(); begin
	$fclose(mat_a_fd);
	$fclose(mat_b_fd);
	$fclose(mat_c_fd);
	$fclose(parameters_fd);
	$fclose(dimensions_fd);
end endtask

// Task for comparing the output vs golden model
task compare_golden(); begin
	count_right = 0;
	count_error = 0;
	for (int k = 0; k < n_dim; k++) begin
		for (int p = 0; p < m_dim; p++) begin
			if(matC_from_sp[k*m_dim+p] == matC[k][p]) begin
				count_right++;
			end
			else begin
				count_error++;
				$display("[STIMULUS] wrong result from sp, matC_from_sp[k*n_dim+p] = %0d, matC[k][p] = %0d, k= %0d, p=%0d",matC_from_sp[k*m_dim+p],matC[k][p],k,p);
			end
			if(((matC_from_sp[k*m_dim+p] > 2**(2*DATA_WIDTH-1)-1 || matC_from_sp[k*m_dim+p] < -2**(2*DATA_WIDTH-1)) && ~flags[k*m_dim+p]) || ((matC_from_sp[k*m_dim+p] < 2**(2*DATA_WIDTH-1)-1 && matC_from_sp[k*m_dim+p] > -2**(2*DATA_WIDTH-1)) && flags[k*m_dim+p])) begin
				$display("[STIMULUS] wrong flag from matmul, matC_from_sp[k*n_dim+p] = %0d, flags[k*m_dim+p]= %0d, k= %0d, p=%0d",matC_from_sp[k*m_dim+p],flags[k*m_dim+p],k,p);
				incorrect_flag ++;
			end
		end
	end
	count_errors(count_right, count_error);
end endtask

// Task for counting errors of the expected result vs actual result from sp
task count_errors(input int count_right, count_error); begin
	total_errors += count_error;
	total_correct += count_right;
end endtask


// Task for checking the golden model using function from stimulus
task matmul_check_golden(input logic mode_bit,
	input logic [1:0] write_target, read_target);
	begin
	if (~(write_target < SP_NTARGETS && read_target < SP_NTARGETS)) $fatal(1, $sformatf("[STIMULUS] Impossible read_target or write_target"));
	do_local_reset(); 
	read_dimensions();
	read_matrices();
	@(posedge intf.clk_i);
	for(i=0; i< n_dim; i++) begin
		write_mat_a(matA_lines[i],i);
	end
	for(j=0; j< m_dim; j++) begin
		write_mat_b(matB_lines[j],j);
	end
	write_to_control(1,mode_bit,write_target,read_target); // start bit, mode bit, write target, read target
	// start bit going down manually at the end of an operation
	wait(intf.busy_o); // wait for start
	wait(~intf.busy_o); // wait for end
 	read_entire_sp();
	read_flags();
	compare_golden();
end endtask


initial 
 	begin: main_stimulus
	do_reset();
	@(posedge intf.clk_i);
	count = 0;
	for(int n=0; n < 50000; n++) begin // change loop size accordingly. up to 50000 (2 checks for each run of the loop)
		matmul_check_golden(0,01,01);
		matmul_check_golden(0,00,00);
		count = count + 2;
		$display("total correct results: %0d\ntotal wrong results: %0d\ntotal matrices checked: %0d\n", total_correct, total_errors,count);//,error_precentge);
	end
	$display("total correct results: %0d\ntotal wrong results: %0d\ntotal matrices checked: %0d\ntotal incorrect flags: %0d\n", total_correct, total_errors,count, incorrect_flag);

	// check biased operations
	// matmul_check_golden(1,01,01);
	// matmul_check_golden(1,00,00);
	// check error scenrios
	// check_validity_of_errors();
	close_files();
end

endmodule