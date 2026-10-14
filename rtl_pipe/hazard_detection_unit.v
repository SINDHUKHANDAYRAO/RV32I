`timescale 1ns/1ps

module hazard_detection_unit (
    input  wire        id_ex_mem_read,
    input  wire [4:0]  id_ex_rd,
    input  wire [4:0]  if_id_rs1,
    input  wire [4:0]  if_id_rs2,
    output reg         pc_write_en,
    output reg         if_id_write_en,
    output reg         control_mux_sel // Inserts bubble (NOP) into ID/EX on stall
);

    always @(*) begin
        // Load-use hazard detection
        if (id_ex_mem_read && ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin
            pc_write_en     = 1'b0; // Freeze PC
            if_id_write_en  = 1'b0; // Freeze IF/ID register
            control_mux_sel = 1'b1; // Insert NOP (bubble) into ID/EX
        end else begin
            pc_write_en     = 1'b1;
            if_id_write_en  = 1'b1;
            control_mux_sel = 1'b0;
        end
    end

endmodule