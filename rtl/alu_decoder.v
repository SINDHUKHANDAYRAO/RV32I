`timescale 1ns/1ps

`include "rv32i_defines.vh"

module alu_decoder (
    input  wire       opcode_5,
    input  wire [2:0] funct3,
    input  wire       funct7_5,
    input  wire [1:0] alu_op,
    output reg  [3:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            `ALUOP_ADD:   alu_ctrl = `ALU_ADD;
            `ALUOP_PASSB: alu_ctrl = `ALU_PASS_B; // Used by LUI
            `ALUOP_FUNCT: begin
                case (funct3)
                    3'b000: begin
                        // SUB only for R-type (opcode_5 == 1) when funct7_5 is 1.
                        // I-type (opcode_5 == 0) is always ADD (no SUBI exists).
                        if (opcode_5 && funct7_5)
                            alu_ctrl = `ALU_SUB;
                        else
                            alu_ctrl = `ALU_ADD;
                    end
                    3'b001: alu_ctrl = `ALU_SLL;
                    3'b010: alu_ctrl = `ALU_SLT;
                    3'b011: alu_ctrl = `ALU_SLTU;
                    3'b100: alu_ctrl = `ALU_XOR;
                    3'b101: begin
                        // SRA if funct7_5 is 1, SRL if funct7_5 is 0 (applies to both R-type and I-type SRAI/SRLI)
                        if (funct7_5)
                            alu_ctrl = `ALU_SRA;
                        else
                            alu_ctrl = `ALU_SRL;
                    end
                    3'b110: alu_ctrl = `ALU_OR;
                    3'b111: alu_ctrl = `ALU_AND;
                    default: alu_ctrl = `ALU_ADD;
                endcase
            end
            default: alu_ctrl = `ALU_ADD;
        endcase
    end

endmodule