
---

# Matrix Multiplication Using Systolic Arrays

This repository contains the Verilog code for a matrix multiplication design implemented using systolic arrays. The project is divided into two main parts: the Design Part and the Verification Part.

## Design Part

The Design Part focuses on the implementation of the matrix multiplication algorithm using systolic arrays. Various modules including the APB slave, memory, processing elements (PE), and the main matrix multiplication calculation module are implemented in Verilog. These modules interact to perform matrix multiplication efficiently.

## Verification Part

The Verification Part aims to ensure the correctness and functionality of the matrix multiplication design through rigorous verification techniques. Simulation-based testing, functional checking, functional coverage analysis, and comparison with a Python-based golden model are conducted to validate the design under various conditions and inputs.

## Repository Contents

- **Design Part:**
  - Verilog modules for APB slave, memory, processing elements, and matrix multiplication calculation.
  
- **Verification Part:**
  - Header and package files containing system parameters and definitions.
  - Testbench, tester, functional checker, and functional coverage modules for verification.
  - Python-based golden model for comparison.
  
## Interface Information

The `matmul_interface.sv` file defines the interface for communication between the design and the testbench. It includes signals for clock, reset, control, and data transmission.

## Usage

1. **Design Part:** Instantiate and interconnect the design modules according to system requirements. Ensure proper clocking and reset signals for correct functionality.

2. **Verification Part:** Run simulation-based testing using the provided testbench and modules. Monitor functional behavior using the functional checker and analyze coverage metrics using the functional coverage module.

## Conclusion

This project presents an efficient implementation of matrix multiplication using systolic arrays, accompanied by thorough verification to ensure accuracy and reliability.

---

