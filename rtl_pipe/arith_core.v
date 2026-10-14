`timescale 1ns/1ps

`include "rv32i_defines.vh"

module arith_core #(
    parameter INIT_FILE = "sw/arith.hex"
) (
    input  wire clk,
    input  wire rst
);

    // Internal wires
    wire [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] instr;
    
    // Control signals
    wire        reg_write;
    wire [2:0]  imm_src;
    wire        alu_src_a;
    wire        alu_src_b;
    wire        mem_write;
    wire [1:0]  result_src;
    wire        branch;
    wire        jump;
    wire        jalr;
    wire [1:0]  alu_op;
    wire [3:0]  alu_ctrl;

    // Datapath wires
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] imm_ext;
    wire [31:0] alu_b_in;
    wire [31:0] alu_result;

    // 1. PC Register
    pc_reg u_pc_reg (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc(pc)
    );

    // 2. PC + 4 Adder (Sequential execution for arith core)
    adder u_pc_adder (
        .a(pc),
        .b(32'd4),
        .y(pc_next)
    );

    // 3. Instruction Memory
    imem #(
        .INIT_FILE(INIT_FILE)
    ) u_imem (
        .addr(pc),
        .rdata(instr)
    );

    // 4. Control Unit
    control_unit u_control_unit (
        .opcode(instr[6:0]),
        .reg_write(reg_write),
        .imm_src(imm_src),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .mem_write(mem_write),
        .result_src(result_src),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .alu_op(alu_op)
    );

    // 5. ALU Decoder
    alu_decoder u_alu_decoder (
        .opcode_5(instr[5]),
        .funct3(instr[14:12]),
        .funct7_5(instr[30]),
        .alu_op(alu_op),
        .alu_ctrl(alu_ctrl)
    );

    // 6. Immediate Generator
    imm_gen u_imm_gen (
        .instr(instr),
        .imm_src(imm_src),
        .imm_ext(imm_ext)
    );

    // 7. Register File
    regfile u_regfile (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .rs1_addr(instr[19:15]),
        .rs2_addr(instr[24:20]),
        .rd_addr(instr[11:7]),
        .rd_data(alu_result), // In arith core, writeback comes directly from ALU result
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // 8. ALU Operand B Mux (rs2 vs imm_ext)
    mux2 u_mux_alu_b (
        .sel(alu_src_b),
        .d0(rs2_data),
        .d1(imm_ext),
        .y(alu_b_in)
    );

    // 9. ALU
    alu u_alu (
        .a(rs1_data),
        .b(alu_b_in),
        .alu_ctrl(alu_ctrl),
        .result(alu_result)
    );

endmodule