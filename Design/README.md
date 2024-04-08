

---

# Matrix Multiplication Using Systolic Arrays - Design Part

This project focuses on implementing matrix multiplication using systolic arrays with an emphasis on chip design and verification. The design is coded in Verilog and incorporates various modules including APB slave, memory, processing elements (PE), and the main matrix multiplication calculation module.

## Modules Overview:

### 1. APB Slave (`apb_slave.v`)
- **Description:** Acts as an interface between the Advanced Peripheral Bus (APB) and the rest of the design. It handles read and write operations, memory addressing, and error signaling.
- **Inputs:** Clock signal (`clk_i`), reset signal (`rst_ni`), APB control signals (`psel_i`, `penable_i`, `pwrite_i`), data signals (`pwdata_i`, `paddr_i`), and signals from the design (`pslverr_i`, `busy_i`, `data_in_from_mem`).
- **Outputs:** APB response signals (`pready_o`, `pslverr_o`, `prdata_o`), signals to the design (`busy_o`, `data_out_mem`, `addr_out_mem`, `write_en_out`, `pstrb_o`).

![image](https://github.com/Noamv7/DDLS/assets/79940366/0c948f0e-68f7-4274-99aa-1acd51717fca)

### 2. Memory (`mem.v`)
- **Description:** Implements the memory functionality required for storing matrices, flags, and intermediate results.
- **Inputs:** Clock signal (`clk_i`), reset signal (`rst_ni`), APB control signals (`pwrite_i`, `pstrb_i`, `pwdata_i`, `paddr_i`), signals from MATMUL (`sp_write`, `write_to_sp`, `flags_in`), and matrix data (`data_in_from_mem`).
- **Outputs:** APB response signals (`prdata_o`, `pslverr_o`), signals to MATMUL (`data_out_mem`, `addr_out_mem`, `write_en_out`, `pstrb_o`), and matrix data (`a_out`, `b_out`).

### 3. Processing Element (PE) (`pe_module.v`)
- **Description:** Represents a single processing unit responsible for multiplying and accumulating elements of matrices A and B.
- **Inputs:** Clock signal (`clk_i`), reset signal (`rst_ni`), start signal (`start_bit_i`), matrix elements from A and B (`in_a`, `in_b`).
- **Outputs:** Updated matrix elements for chaining (`out_a`, `out_b`), result of multiplication and accumulation (`out_c`), and overflow signal (`overflow_signal`).

### 4. Matrix Multiplication Calculation (`matmul_calc.v`)
- **Description:** Orchestrates the matrix multiplication process by controlling the flow of matrix elements through processing elements and memory.
- **Inputs:** Clock signal (`clk_i`), reset signal (`rst_ni`), start signal (`start_bit_i`), matrices A and B (`matrix_a_in`, `matrix_b_in`), and dimensions (`dimension_N_i`, `dimension_K_i`, `dimension_M_i`).
- **Outputs:** Flags indicating operation completion (`flags_o`), data to be written to memory (`write_to_sp`), and control signal for memory write (`sp_write`).

![image](https://github.com/Noamv7/DDLS/assets/79940366/c6068bc9-da85-46a5-99ee-2313cfb121fc)

---

## Overflow Handling in Processing Elements (PE):

The PE module includes overflow detection mechanisms to ensure accurate multiplication and accumulation operations. When overflow occurs, the module adjusts the result to maintain data integrity, preventing loss and ensuring reliable performance throughout the matrix multiplication process.

--- 


## Design Parameters and Configurations:

### Parameters:
- **DATA_WIDTH:** Determines the width of data in bits, impacting the precision of computations. It must satisfy `DATA_WIDTH <= BUS_WIDTH / 2`.
- **BUS_WIDTH:** Specifies the width of the data bus in bits, affecting the amount of data transferred at once.
- **ADDR_WIDTH:** Defines the width of address lines, determining the maximum addressable memory size.
- **SP_NTARGETS:** Indicates the number of scratchpad memory targets available for use.

### Possible Values:
- **DATA_WIDTH:** 8, 16, 32 (satisfying `DATA_WIDTH <= BUS_WIDTH / 2`)
- **BUS_WIDTH:** 16, 32, 64
- **ADDR_WIDTH:** 16, 24, 32
- **SP_NTARGETS:** 1, 2, 4
- **MAX_DIM:** 2, 4

The `MAX_DIM` parameter is derived from `BUS_WIDTH` and `DATA_WIDTH`, calculated as `MAX_DIM = BUS_WIDTH / DATA_WIDTH`, impacting the parallelism and granularity of computations.

--- 

## Design Flow:

1. **Memory Initialization:** Initializes memory elements to prepare for data storage and retrieval operations.
2. **Matrix Multiplication:** The matrix multiplication calculation module orchestrates the process by sending matrix elements to processing elements and managing the flow of data through memory.
3. **Data Transfer:** The APB slave module facilitates data transfer between the main processor and memory, ensuring proper addressing and error handling.

![image](https://github.com/Noamv7/DDLS/assets/79940366/88142e91-c615-41ec-99ea-7fccc915517d)


## Usage:

The design modules can be instantiated and interconnected according to specific system requirements. Proper clocking and reset signals should be provided to ensure correct functionality.

## Future Improvements:

- Addition of power optimization techniques to reduce overall power consumption.
- Integration of advanced memory architectures for enhanced performance.

---


