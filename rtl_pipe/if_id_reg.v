`timescale 1ns/1ps

module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        en,      // 0 = stall pipeline, 1 = run
    input  wire        flush,   // 1 = clear pipeline (insert NOP)
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);

    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out    <= 32'b0;
            instr_out <= 32'h00000013; // Insert NOP (addi x0, x0, 0)
        end else if (en) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
    end

endmodule