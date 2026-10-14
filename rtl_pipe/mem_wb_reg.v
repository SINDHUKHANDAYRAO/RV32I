`timescale 1ns/1ps

module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_rdata_in,
    input  wire [4:0]  rd_in,
    
    // Control signals in
    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    
    // Outputs
    output reg  [31:0] alu_result_out,
    output reg  [31:0] mem_rdata_out,
    output reg  [4:0]  rd_out,
    output reg         reg_write_out,
    output reg         mem_to_reg_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_out <= 32'b0;
            mem_rdata_out  <= 32'b0;
            rd_out         <= 5'b0;
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end else begin
            alu_result_out <= alu_result_in;
            mem_rdata_out  <= mem_rdata_in;
            rd_out         <= rd_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end

endmodule