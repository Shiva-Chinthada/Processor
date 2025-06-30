// Stages: Fetch (IF) -> Decode (ID) -> Execute (EX) -> Writeback (WB)
// Instructions: ADD, SUB, AND, LOAD

// Instruction Memory Module
module instruction_memory (
    input clk,
    input [31:0] addr,
    output reg [31:0] data_out
);
    reg [31:0] memory [0:1023];
    
    initial begin
        // Initialize with sample instructions
             
        // ADD r1, r0, r0 (r1 = r0 + r0 = 0)
        // opcode=0110011 (R-type), funct3=000, funct7=0000000
        memory[0] = 32'b00000000000000000000000010110011;
        
        // LOAD r2, 0(r0) - Load from memory address 0
        // opcode=0000011 (I-type), funct3=010 (LW)
        memory[1] = 32'b00000000000000000010000100000011;
        
        // ADD r3, r1, r2 (r3 = r1 + r2)
        memory[2] = 32'b00000000001000001000000110110011;
        
        // SUB r4, r3, r1 (r4 = r3 - r1)
        // funct7=0100000 for SUB
        memory[3] = 32'b01000000000100011000001000110011;
        
        // AND r5, r3, r2 (r5 = r3 & r2)
        // funct3=111 for AND
        memory[4] = 32'b00000000001000011111001010110011;
        
        // NOP instructions for remaining slots
        memory[5] = 32'h00000013; // ADDI r0, r0, 0 (NOP)
        memory[6] = 32'h00000013;
        memory[7] = 32'h00000013;
    end
    
    always @(posedge clk) begin
        data_out <= memory[addr[31:2]]; // Word addressed
    end
endmodule

// Data Memory Module
module data_memory (
    input clk,
    input [31:0] addr,
    input [31:0] data_in,
    input mem_write,
    input mem_read,
    output reg [31:0] data_out
);
    reg [31:0] memory [0:1023];
    
    initial begin
        memory[0] = 32'h12345678;
        memory[1] = 32'hABCDEF00;
        memory[2] = 32'h87654321;
        memory[3] = 32'hDEADBEEF;
    end
    
    always @(posedge clk) begin
        if (mem_write) begin
            memory[addr[31:2]] <= data_in;
        end
        if (mem_read) begin
            data_out <= memory[addr[31:2]];
        end
    end
endmodule

// Main Pipelined Processor
module pipelined_processor (
    input clk,
    input rst,
    output [31:0] pc_out,
    output [31:0] result_out,
    output [4:0] wb_rd_out,
    output wb_reg_write_out
);

    // Program Counter
    reg [31:0] pc;
    
    // Pipeline Registers
    // IF/ID Pipeline Register
    reg [31:0] if_id_instruction;
    reg [31:0] if_id_pc;
    
    // ID/EX Pipeline Register
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;
    reg [31:0] id_ex_immediate;
    reg [4:0] id_ex_rd;
    reg [3:0] id_ex_alu_op;
    reg id_ex_reg_write;
    reg id_ex_mem_read;
    
    // EX/WB Pipeline Register
    reg [31:0] ex_wb_result;
    reg [4:0] ex_wb_rd;
    reg ex_wb_reg_write;
    
    // Register File
    reg [31:0] registers [0:31];
    
    // Memory Interface Signals
    wire [31:0] instruction;
    wire [31:0] mem_data_out;
    reg [31:0] mem_addr;
    reg mem_read_en;
    
    // Instruction Fields
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [31:0] immediate;
    
    // ALU
    reg [31:0] alu_result;
    
    // ALU Operations
    parameter ALU_ADD = 4'b0000;
    parameter ALU_SUB = 4'b0001;
    parameter ALU_AND = 4'b0010;
    parameter ALU_OR  = 4'b0011;
    parameter ALU_XOR = 4'b0100;
    
    // Instruction decode
    assign opcode = if_id_instruction[6:0];
    assign rd = if_id_instruction[11:7];
    assign funct3 = if_id_instruction[14:12];
    assign rs1 = if_id_instruction[19:15];
    assign rs2 = if_id_instruction[24:20];
    assign funct7 = if_id_instruction[31:25];
    assign immediate = {{20{if_id_instruction[31]}}, if_id_instruction[31:20]}; // I-type immediate
    
    // Output assignments
    assign pc_out = pc;
    assign result_out = ex_wb_result;
    assign wb_rd_out = ex_wb_rd;
    assign wb_reg_write_out = ex_wb_reg_write;
    
    // Instantiate Instruction Memory
    instruction_memory imem (
        .clk(clk),
        .addr(pc),
        .data_out(instruction)
    );
    
    // Instantiate Data Memory
    data_memory dmem (
        .clk(clk),
        .addr(mem_addr),
        .data_in(32'h0),
        .mem_write(1'b0),
        .mem_read(mem_read_en),
        .data_out(mem_data_out)
    );
    
    // Initialize registers
    integer i;
    initial begin
        pc = 0;
        if_id_instruction = 0;
        if_id_pc = 0;
        id_ex_pc = 0;
        id_ex_rs1_data = 0;
        id_ex_rs2_data = 0;
        id_ex_immediate = 0;
        id_ex_rd = 0;
        id_ex_alu_op = 0;
        id_ex_reg_write = 0;
        id_ex_mem_read = 0;
        ex_wb_result = 0;
        ex_wb_rd = 0;
        ex_wb_reg_write = 0;
        mem_addr = 0;
        mem_read_en = 0;
        
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 0;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 0;
            if_id_instruction <= 0;
            if_id_pc <= 0;
            id_ex_pc <= 0;
            id_ex_rs1_data <= 0;
            id_ex_rs2_data <= 0;
            id_ex_immediate <= 0;
            id_ex_rd <= 0;
            id_ex_alu_op <= 0;
            id_ex_reg_write <= 0;
            id_ex_mem_read <= 0;
            ex_wb_result <= 0;
            ex_wb_rd <= 0;
            ex_wb_reg_write <= 0;
            mem_addr <= 0;
            mem_read_en <= 0;
            
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 0;
            end
        end else begin
            // Stage 4: Writeback (WB)
            if (ex_wb_reg_write && ex_wb_rd != 0) begin
                registers[ex_wb_rd] <= ex_wb_result;
            end
            
            // Stage 3: Execute (EX)
            case (id_ex_alu_op)
                ALU_ADD: alu_result = id_ex_rs1_data + id_ex_rs2_data;
                ALU_SUB: alu_result = id_ex_rs1_data - id_ex_rs2_data;
                ALU_AND: alu_result = id_ex_rs1_data & id_ex_rs2_data;
                ALU_OR:  alu_result = id_ex_rs1_data | id_ex_rs2_data;
                ALU_XOR: alu_result = id_ex_rs1_data ^ id_ex_rs2_data;
                default: alu_result = 0;
            endcase
            
            // Handle LOAD instruction
            if (id_ex_mem_read) begin
                mem_addr <= id_ex_rs1_data + id_ex_immediate;
                mem_read_en <= 1;
                ex_wb_result <= mem_data_out;
            end else begin
                mem_read_en <= 0;
                ex_wb_result <= alu_result;
            end
            
            ex_wb_rd <= id_ex_rd;
            ex_wb_reg_write <= id_ex_reg_write;
            
            // Stage 2: Decode (ID)
            id_ex_pc <= if_id_pc;
            id_ex_rs1_data <= (rs1 == 0) ? 0 : registers[rs1];
            id_ex_rs2_data <= (rs2 == 0) ? 0 : registers[rs2];
            id_ex_immediate <= immediate;
            id_ex_rd <= rd;
            
            // Control Unit - Decode instruction and set control signals
            case (opcode)
                7'b0110011: begin // R-type (ADD, SUB, AND, OR, XOR)
                    case ({funct7, funct3})
                        10'b0000000000: begin // ADD
                            id_ex_alu_op <= ALU_ADD;
                            id_ex_reg_write <= 1;
                            id_ex_mem_read <= 0;
                        end
                        10'b0100000000: begin // SUB
                            id_ex_alu_op <= ALU_SUB;
                            id_ex_reg_write <= 1;
                            id_ex_mem_read <= 0;
                        end
                        10'b0000000111: begin // AND
                            id_ex_alu_op <= ALU_AND;
                            id_ex_reg_write <= 1;
                            id_ex_mem_read <= 0;
                        end
                        10'b0000000110: begin // OR
                            id_ex_alu_op <= ALU_OR;
                            id_ex_reg_write <= 1;
                            id_ex_mem_read <= 0;
                        end
                        10'b0000000100: begin // XOR
                            id_ex_alu_op <= ALU_XOR;
                            id_ex_reg_write <= 1;
                            id_ex_mem_read <= 0;
                        end
                        default: begin
                            id_ex_alu_op <= ALU_ADD;
                            id_ex_reg_write <= 0;
                            id_ex_mem_read <= 0;
                        end
                    endcase
                end
                7'b0000011: begin // I-type LOAD
                    if (funct3 == 3'b010) begin // LW (Load Word)
                        id_ex_alu_op <= ALU_ADD;
                        id_ex_reg_write <= 1;
                        id_ex_mem_read <= 1;
                    end else begin
                        id_ex_alu_op <= ALU_ADD;
                        id_ex_reg_write <= 0;
                        id_ex_mem_read <= 0;
                    end
                end
                default: begin
                    id_ex_alu_op <= ALU_ADD;
                    id_ex_reg_write <= 0;
                    id_ex_mem_read <= 0;
                end
            endcase
            
            // Stage 1: Instruction Fetch (IF)
            if_id_instruction <= instruction;
            if_id_pc <= pc;
            pc <= pc + 4; // Next instruction
        end
    end
    
endmodule

// Comprehensive Testbench
module tb_pipelined_processor;
    reg clk;
    reg rst;
    wire [31:0] pc_out;
    wire [31:0] result_out;
    wire [4:0] wb_rd_out;
    wire wb_reg_write_out;
    
    // Test control variables
    integer cycle_count;
    integer test_pass_count;
    integer test_fail_count;
    
    pipelined_processor uut (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .result_out(result_out),
        .wb_rd_out(wb_rd_out),
        .wb_reg_write_out(wb_reg_write_out)
    );
    
    // Clock generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus and verification
    initial begin
        // Initialize test variables
        cycle_count = 0;
        test_pass_count = 0;
        test_fail_count = 0;
        
        // Initialize waveform dump (for viewing in simulator)
        $dumpfile("pipelined_processor.vcd");
        $dumpvars(0, tb_pipelined_processor);
        
        $display("=== Starting Pipelined Processor Test ===");
        $display("Time: %0t", $time);
        
        // Reset sequence
        rst = 1;
        #25;  // Hold reset for 2.5 clock cycles
        rst = 0;
        $display("Reset released at time: %0t", $time);
        
        // Wait for pipeline to fill and execute instructions
        #10; // Small delay after reset
        
        // Monitor execution for enough cycles to see all instructions complete
        repeat(20) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        
        $display("\n=== Pipeline Execution Complete ===");
        
        // Verify results after pipeline has processed all instructions
        #20; // Additional cycles for pipeline to fully complete
        
        verify_results();
        
        // Final statistics
        $display("\n=== Test Summary ===");
        $display("Total clock cycles: %0d", cycle_count);
        $display("Tests passed: %0d", test_pass_count);
        $display("Tests failed: %0d", test_fail_count);
        
        if (test_fail_count == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** SOME TESTS FAILED ***");
        end
        
        $display("Simulation completed at time: %0t", $time);
        $finish;
    end
    
    // Task to verify expected results
    task verify_results;
        begin
            $display("\n=== Verifying Results ===");
            
            // Check register values after all instructions have executed
            // Expected results based on the instruction sequence:
            
            // r0 should always be 0
            check_register(0, 32'h00000000, "r0 (hardwired zero)");
            
            // r1 = 0 + 0 = 0 (from ADD r1, r0, r0)
            check_register(1, 32'h00000000, "r1 (ADD r0, r0)");
            
            // r2 = memory[0] = 0x12345678 (from LOAD r2, 0(r0))
            check_register(2, 32'h12345678, "r2 (LOAD from mem[0])");
            
            // r3 = r1 + r2 = 0 + 0x12345678 = 0x12345678 (from ADD r3, r1, r2)
            check_register(3, 32'h12345678, "r3 (ADD r1, r2)");
            
            // r4 = r3 - r1 = 0x12345678 - 0 = 0x12345678 (from SUB r4, r3, r1)
            check_register(4, 32'h12345678, "r4 (SUB r3, r1)");
            
            // r5 = r3 & r2 = 0x12345678 & 0x12345678 = 0x12345678 (from AND r5, r3, r2)
            check_register(5, 32'h12345678, "r5 (AND r3, r2)");
            
            // Verify PC progression
            if (pc_out >= 32'h00000018) begin // Should have executed at least 6 instructions (6*4 = 24 = 0x18)
                $display("PASS: PC advanced correctly to %h", pc_out);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("FAIL: PC did not advance as expected. Current PC: %h", pc_out);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Task to check individual register values
    task check_register;
        input [4:0] reg_num;
        input [31:0] expected_val;
        input [200*8:1] description;
        reg [31:0] actual_val;
        begin
            actual_val = uut.registers[reg_num];
            if (actual_val == expected_val) begin
                $display("PASS: %s - Expected: %h, Got: %h", description, expected_val, actual_val);
                test_pass_count = test_pass_count + 1;
            end else begin
                $display("FAIL: %s - Expected: %h, Got: %h", description, expected_val, actual_val);
                test_fail_count = test_fail_count + 1;
            end
        end
    endtask
    
    // Continuous monitoring during simulation
    always @(posedge clk) begin
        if (!rst && cycle_count > 0) begin
            $display("Cycle %0d: PC=%h | IF/ID_Inst=%h | WB: r%0d=%h (en=%b)", 
                     cycle_count, pc_out, uut.if_id_instruction, wb_rd_out, result_out, wb_reg_write_out);
            
            // Display pipeline stage information
            $display("  Pipeline: IF_PC=%h | ID_OP=%b | EX_ALU=%h | WB_RD=%d", 
                     uut.if_id_pc, uut.id_ex_alu_op, uut.ex_wb_result, uut.ex_wb_rd);
        end
    end
    
    // Monitor register file changes
    always @(posedge clk) begin
        if (!rst && wb_reg_write_out && wb_rd_out != 0) begin
            $display("  >>> Register Update: r%0d <= %h", wb_rd_out, result_out);
        end
    end
    
    // Display register file contents periodically
    always @(posedge clk) begin
        if (!rst && (cycle_count % 5 == 0) && cycle_count > 0) begin
            $display("  RegFile: r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
                     uut.registers[0], uut.registers[1], uut.registers[2], uut.registers[3],
                     uut.registers[4], uut.registers[5], uut.registers[6], uut.registers[7]);
        end
    end
    
    // Timeout watchdog
    initial begin
        #1000; // 1000ns timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
endmodule
