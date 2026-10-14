`timescale 1ns/1ps

module next_pc (
    input  wire [31:0] pc,
    input  wire [31:0] imm_ext,
    input  wire [31:0] alu_result, // Holds (rs1 + imm) for JALR target
    input  wire        branch_taken,
    input  wire        jump,
    input  wire        jalr,
    output reg  [31:0] pc_next
);

    wire [31:0] pc_plus_4  = pc + 32'd4;
    wire [31:0] pc_target  = pc + imm_ext; // Shared by JAL and branches

    always @(*) begin
        if (jalr) begin
            // JALR: clear lowest bit per RISC-V spec
            pc_next = {alu_result[31:1], 1'b0};
        end else if (jump || branch_taken) begin
            // JAL or taken Branch
            pc_next = pc_target;
        end else begin
            // Default sequential fetch
            pc_next = pc_plus_4;
        end
    end

endmodule