`timescale 1ns/1ps

`include "rv32i_defines.vh"

module top #(
    parameter INIT_FILE = "sw/arith.hex"
) (
    input  wire clk,
    input  wire rst
);

    // --- Wires ---
    wire [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] pc_plus_4;
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
    wire [31:0] alu_a_in;
    wire [31:0] alu_b_in;
    wire [31:0] alu_result;
    
    // Branch and LSU wires
    wire        branch_taken;
    wire        dmem_write_en;
    wire [3:0]  wstrb;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire [31:0] ld_data;
    wire [31:0] rd_data;

    // 1. Program Counter Register
    pc_reg u_pc_reg (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc(pc)
    );

    // 2. PC + 4 Adder
    adder u_adder_pc4 (
        .a(pc),
        .b(32'd4),
        .y(pc_plus_4)
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
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // 8. Branch Unit
    branch_unit u_branch_unit (
        .branch(branch),
        .funct3(instr[14:12]),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .branch_taken(branch_taken)
    );

    // 9. Next PC Logic
    next_pc u_next_pc (
        .pc(pc),
        .imm_ext(imm_ext),
        .alu_result(alu_result), // Used for JALR target (rs1 + imm)
        .branch_taken(branch_taken),
        .jump(jump),
        .jalr(jalr),
        .pc_next(pc_next)
    );

    // 10. ALU Operand A Mux (rs1 vs PC for AUIPC)
    mux2 u_mux_alu_a (
        .sel(alu_src_a),
        .d0(rs1_data),
        .d1(pc),
        .y(alu_a_in)
    );

    // 11. ALU Operand B Mux (rs2 vs imm_ext)
    mux2 u_mux_alu_b (
        .sel(alu_src_b),
        .d0(rs2_data),
        .d1(imm_ext),
        .y(alu_b_in)
    );

    // 12. ALU
    alu u_alu (
        .a(alu_a_in),
        .b(alu_b_in),
        .alu_ctrl(alu_ctrl),
        .result(alu_result)
    );

    // 13. Load-Store Unit (LSU)
    lsu u_lsu (
        .clk(clk),
        .mem_write(mem_write),
        .funct3(instr[14:12]),
        .addr(alu_result),
        .st_data(rs2_data),
        .mem_rdata(dmem_rdata),
        .ld_data(ld_data),
        .dmem_write_en(dmem_write_en),
        .wstrb(wstrb),
        .dmem_wdata(dmem_wdata)
    );

    // 14. Data Memory
    dmem u_dmem (
        .clk(clk),
        .addr(alu_result),
        .wdata(dmem_wdata),
        .wstrb(wstrb),
        .mem_write(dmem_write_en),
        .rdata(dmem_rdata)
    );

    // 15. Writeback Multiplexer (ALU result vs Memory load vs PC+4)
    mux4 u_mux_result (
        .sel(result_src),
        .d0(alu_result),
        .d1(ld_data),
        .d2(pc_plus_4),
        .d3(32'd0),
        .y(rd_data)
    );

endmodule