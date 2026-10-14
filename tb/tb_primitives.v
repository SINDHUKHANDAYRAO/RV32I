`timescale 1ns/1ps
`include "rtl/rv32i_defines.vh"

module tb_primitives;

    // Test signals
    reg         clk;
    reg         rst;
    
    // Adder test signals
    reg  [31:0] add_a, add_b;
    wire [31:0] add_y;

    // ALU test signals
    reg  [31:0] alu_a, alu_b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] alu_result;

    // Regfile test signals
    reg         reg_write;
    reg  [4:0]  rs1_addr, rs2_addr, rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    // Imm_gen test signals
    reg  [31:0] instr;
    reg  [2:0]  imm_src;
    wire [31:0] imm_ext;

    // Instantiate modules
    adder u_adder (
        .a(add_a), .b(add_b), .y(add_y)
    );

    alu u_alu (
        .a(alu_a), .b(alu_b), .alu_ctrl(alu_ctrl), .result(alu_result)
    );

    regfile u_regfile (
        .clk(clk), .rst(rst), .reg_write(reg_write),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .rd_addr(rd_addr),
        .rd_data(rd_data), .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    imm_gen u_imm_gen (
        .instr(instr), .imm_src(imm_src), .imm_ext(imm_ext)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("report/primitives.vcd");
        $dumpvars(0, tb_primitives);

        clk = 0;
        rst = 1;
        #20;
        rst = 0;
        #10;

        $display("=== STARTING PRIMITIVE TESTS ===");

        // 1. Test Adder ($pc + 4$ and $pc + imm$)
        add_a = 32'h00000040; add_b = 32'hffffffffe0; // 64 + (-32)
        #10;
        if (add_y === 32'h00000020) 
            $display("[PASS] Adder: 0x40 + (-32) = 0x%08x", add_y);
        else 
            $display("[FAIL] Adder: expected 0x00000020, got 0x%08x", add_y);

        // 2. Test ALU Boundary Cases & Operations
        alu_a = 32'h80000000; alu_b = 32'h00000001; alu_ctrl = `ALU_ADD;
        #10;
        $display("[INFO] ALU ADD boundary (0x80000000 + 1) = 0x%08x", alu_result);

        alu_a = 32'hFFFFFFFF; alu_b = 32'h00000001; alu_ctrl = `ALU_SLT;
        #10;
        if (alu_result === 32'd1) 
            $display("[PASS] ALU SLT (-1 < 1) = %0d", alu_result);
        else 
            $display("[FAIL] ALU SLT failed");

        // 3. Test Register File ($x0$ hardwired to 0, write protection)
        reg_write = 1'b1; rd_addr = 5'd0; rd_data = 32'h12345678;
        rs1_addr = 5'd0; rs2_addr = 5'd5;
        #10;
        if (rs1_data === 32'd0) 
            $display("[PASS] Regfile: x0 correctly reads as 0 after write attempt");
        else 
            $display("[FAIL] Regfile: x0 modified! Got 0x%08x", rs1_data);

        // 4. Test Immediate Generator (Assignment 1 instruction: 32'hFE008CE3)
        // Instruction word: FE008CE3 -> B-type branch instruction
        instr = 32'hFE008CE3; imm_src = `IMM_B;
        #10;
        $display("[INFO] Imm_gen decoded 32'hFE008CE3 as signed decimal: %0d (hex: 0x%08x)", $signed(imm_ext), imm_ext);

        #20;
        $display("=== ALL DIRECTED TESTS FINISHED ===");
        $finish;
    end

endmodule