`timescale 1ns/1ps

module pc_reg #(
    parameter RESET_VECTOR = 32'h00000000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc
);

    always @(posedge clk) begin
        if (rst) begin
            pc <= RESET_VECTOR;
        end else begin
            pc <= pc_next;
        end
    end

endmodule