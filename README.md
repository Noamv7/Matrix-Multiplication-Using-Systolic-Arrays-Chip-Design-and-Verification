Matrix Multiplication Using Systolic Arrays - Design Part
This project focuses on implementing matrix multiplication using systolic arrays with an emphasis on chip design and verification. The design is coded in Verilog/SystemVerilog and incorporates various modules including APB slave, memory, processing elements (PE), and the main matrix multiplication calculation module.

Modules Overview:
1. APB Slave (apb_slave.v)
Description: Acts as an interface between the Advanced Peripheral Bus (APB) and the rest of the design. It handles read and write operations, memory addressing, and error signaling.
Inputs: Clock signal (clk_i), reset signal (rst_ni), APB control signals (psel_i, penable_i, pwrite_i), data signals (pwdata_i, paddr_i), and signals from the design (pslverr_i, busy_i, data_in_from_mem).
Outputs: APB response signals (pready_o, pslverr_o, prdata_o), signals to the design (busy_o, data_out_mem, addr_out_mem, write_en_out, pstrb_o).
2. Memory (mem.v)
Description: Implements the memory functionality required for storing matrices, flags, and intermediate results.
Inputs: Clock signal (clk_i), reset signal (rst_ni), APB control signals (pwrite_i, pstrb_i, pwdata_i, paddr_i), signals from MATMUL (sp_write, write_to_sp, flags_in), and matrix data (data_in_from_mem).
Outputs: APB response signals (prdata_o, pslverr_o), signals to MATMUL (data_out_mem, addr_out_mem, write_en_out, pstrb_o), and matrix data (a_out, b_out).
3. Processing Element (PE) (pe_module.v)
Description: Represents a single processing unit responsible for multiplying and accumulating elements of matrices A and B.
Inputs: Clock signal (clk_i), reset signal (rst_ni), start signal (start_bit_i), matrix elements from A and B (in_a, in_b).
Outputs: Updated matrix elements for chaining (out_a, out_b), result of multiplication and accumulation (out_c), and overflow signal (overflow_signal).
4. Matrix Multiplication Calculation (matmul_calc.v)
Description: Orchestrates the matrix multiplication process by controlling the flow of matrix elements through processing elements and memory.
Inputs: Clock signal (clk_i), reset signal (rst_ni), start signal (start_bit_i), matrices A and B (matrix_a_in, matrix_b_in), and dimensions (dimension_N_i, dimension_K_i, dimension_M_i).
Outputs: Flags indicating operation completion (flags_o), data to be written to memory (write_to_sp), and control signal for memory write (sp_write).
Design Flow:
Memory Initialization: Initializes memory elements to prepare for data storage and retrieval operations.
Matrix Multiplication: The matrix multiplication calculation module orchestrates the process by sending matrix elements to processing elements and managing the flow of data through memory.
Data Transfer: The APB slave module facilitates data transfer between the main processor and memory, ensuring proper addressing and error handling.
Usage:
The design modules can be instantiated and interconnected according to specific system requirements. Proper clocking and reset signals should be provided to ensure correct functionality.

Future Improvements:
Addition of power optimization techniques to reduce overall power consumption.
Integration of advanced memory architectures for enhanced performance.
