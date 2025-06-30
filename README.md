# Processor

COMPANY: CODTECH IT SOLUTIONS


NAME : CHINTHADA VENKATA SIVA DURGA RAO


INTERN ID : CT06DN155


DOMAIN : VLSI


DURATION : 6 WEEKS


MENTOR : NEELA SANTOSH


This project presents a comprehensive implementation of a 4-stage pipelined RISC-V processor designed primarily for educational purposes and FPGA deployment using Xilinx Vivado 2023.3.

**Overview**

The processor features a 4-stage pipeline architecture with distinct Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), and Writeback (WB) stages. It employs a Harvard architecture separating instruction and data memory, supports essential RISC-V instructions, and includes a complete testbench for automated verification.

**Key Features**

* 4-stage pipeline (IF → ID → EX → WB)
* Separate instruction and data memories
* Support for core RISC-V instructions (ADD, SUB, AND, OR, XOR, LOAD)
* FPGA-ready Verilog implementation optimized for Xilinx Vivado
* Detailed documentation and educational focus

**Pipeline Stages**

1. **Instruction Fetch (IF):** Fetches instructions from memory using the Program Counter (PC).
2. **Instruction Decode (ID):** Decodes instruction, reads registers, and generates control signals.
3. **Execute (EX):** Performs ALU operations, computes memory addresses.
4. **Writeback (WB):** Writes results to the register file.

**Core Components**

* **Processor Core:** Includes a 32-bit PC, pipeline registers, 32 × 32-bit register file, ALU supporting arithmetic/logical operations, and control unit for decoding.
* **Memory Subsystem:** Comprises 1024-word instruction and data memories (32-bit words), initialized with test programs and data.

**Supported Instructions**

* **R-Type:** ADD, SUB, AND, OR, XOR
* **I-Type:** LOAD (with immediate offset)

**Memory Layout and Program Example**

Sample instructions and memory content demonstrate typical data flow through the pipeline. For instance, initial instructions load data from memory, perform arithmetic operations, and store results in registers.

**Expected Register Values After Execution:**

* r1 = 0x00000000
* r2 = 0x12345678
* r3 = 0x12345678
* r4 = 0x12345678
* r5 = 0x12345678

**Getting Started**

Users require Xilinx Vivado 2023.3, a Verilog simulator, and familiarity with basic digital design concepts. Compilation and simulation can be performed using standard Vivado commands, and synthesis for FPGA is provided via Vivado TCL scripts.

**Simulation and Verification**

The project includes a testbench that runs a sample program, verifies output, and displays pass/fail results. Console logs and waveform outputs confirm correct processor operation.

**Performance**

* Pipeline latency: 4 cycles
* Throughput: 1 instruction per cycle (after pipeline fill)
* Tested clock frequency: Up to 100 MHz on Artix-7 FPGA

**Educational Value**

The project is excellent for exploring pipeline design, datapath/control integration, Verilog development, FPGA synthesis, and simulation/debug methodologies. It provides ample documentation for students and educators to extend the design, add new instructions, or perform further optimization.


