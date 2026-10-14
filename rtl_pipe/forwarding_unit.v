`timescale 1ns/1ps

module forwarding_unit (
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    input  wire [4:0]  ex_mem_rd,
    input  wire        ex_mem_reg_write,
    input  wire [4:0]  mem_wb_rd,
    input  wire        mem_wb_reg_write,
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b
);

    always @(*) begin
        // --- FORWARD A (rs1 hazards) ---
        forward_a = 2'b00; // Default: use register file value
        if (ex_mem_reg_write && (ex_mem_rd != 5'b00000) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10; // EX hazard (forward from EX/MEM stage)
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'b00000) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01; // MEM hazard (forward from MEM/WB stage)
        end

        // --- FORWARD B (rs2 hazards) ---
        forward_b = 2'b00; // Default: use register file value
        if (ex_mem_reg_write && (ex_mem_rd != 5'b00000) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10; // EX hazard (forward from EX/MEM stage)
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'b00000) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01; // MEM hazard (forward from MEM/WB stage)
        end
    end

endmodule