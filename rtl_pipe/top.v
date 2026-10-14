`timescale 1ns/1ps
`include "rv32i_defines.vh"

module top #(
    parameter INIT_FILE = "sw/arith.hex"
) (
    input  wire clk,
    input  wire rst
);

    // ==========================================
    // 1. FETCH STAGE
    // ==========================================
    wire [31:0] pc_if, pc_plus_4_if, instr_if;
    wire        pc_write_en, if_id_write_en;
    
    wire        pc_redirect_ex;
    wire [31:0] pc_next_from_ex;
    wire [31:0] pc_next_logic = pc_redirect_ex ? pc_next_from_ex : pc_plus_4_if;
    wire [31:0] pc_next_actual = pc_write_en ? pc_next_logic : pc_if; 

    pc_reg u_pc_reg (.clk(clk), .rst(rst), .pc_next(pc_next_actual), .pc(pc_if));
    adder u_adder_pc4 (.a(pc_if), .b(32'd4), .y(pc_plus_4_if));
    imem #(.INIT_FILE(INIT_FILE)) u_imem (.addr(pc_if), .rdata(instr_if));

    // ==========================================
    // 2. IF/ID PIPELINE REGISTERS
    // ==========================================
    reg [31:0] pc_id, instr_id;

    always @(posedge clk) begin
        if (rst || pc_redirect_ex) begin 
            pc_id <= 32'd0;
            instr_id <= 32'h00000013; // NOP
        end else if (if_id_write_en) begin
            pc_id <= pc_if;
            instr_id <= instr_if;
        end
    end

    // ==========================================
    // 3. DECODE STAGE
    // ==========================================
    wire [31:0] rs1_data_rf, rs2_data_rf, rs1_data_raw, rs2_data_raw, imm_ext_id, rd_data_wb;
    wire        reg_write_d, alu_src_a_d, alu_src_b_d, mem_write_d, branch_d, jump_d, jalr_d;
    wire [1:0]  result_src_d, alu_op_d;
    wire [2:0]  imm_src_d;
    wire        control_mux_sel; 

    control_unit u_control_unit (
        .opcode(instr_id[6:0]), .reg_write(reg_write_d), .imm_src(imm_src_d),
        .alu_src_a(alu_src_a_d), .alu_src_b(alu_src_b_d), .mem_write(mem_write_d),
        .result_src(result_src_d), .branch(branch_d), .jump(jump_d), .jalr(jalr_d), .alu_op(alu_op_d)
    );

    imm_gen u_imm_gen (.instr(instr_id), .imm_src(imm_src_d), .imm_ext(imm_ext_id));

    regfile u_regfile (
        .clk(clk), .rst(rst), .reg_write(reg_write_wb),
        .rs1_addr(instr_id[19:15]), .rs2_addr(instr_id[24:20]), .rd_addr(instr_wb[11:7]),
        .rd_data(rd_data_wb), .rs1_data(rs1_data_rf), .rs2_data(rs2_data_rf)
    );

    // FIX: Internal forwarding to resolve same-cycle WB->ID Register File hazards
    assign rs1_data_raw = (reg_write_wb && (instr_wb[11:7] == instr_id[19:15]) && (instr_id[19:15] != 5'd0)) ? rd_data_wb : rs1_data_rf;
    assign rs2_data_raw = (reg_write_wb && (instr_wb[11:7] == instr_id[24:20]) && (instr_id[24:20] != 5'd0)) ? rd_data_wb : rs2_data_rf;

    hazard_detection_unit u_hazard_unit (
        .id_ex_mem_read(result_src_ex == 2'b01), .id_ex_rd(instr_ex[11:7]),
        .if_id_rs1(instr_id[19:15]), .if_id_rs2(instr_id[24:20]),
        .pc_write_en(pc_write_en), .if_id_write_en(if_id_write_en), .control_mux_sel(control_mux_sel)
    );

    // ==========================================
    // 4. ID/EX PIPELINE REGISTERS
    // ==========================================
    reg [31:0] pc_ex, instr_ex, rs1_data_ex, rs2_data_ex, imm_ext_ex;
    reg        reg_write_ex, alu_src_a_ex, alu_src_b_ex, mem_write_ex, branch_ex, jump_ex, jalr_ex;
    reg [1:0]  result_src_ex, alu_op_ex;

    always @(posedge clk) begin
        if (rst || control_mux_sel || pc_redirect_ex) begin 
            pc_ex <= 32'd0; instr_ex <= 32'h00000013; // NOP
            rs1_data_ex <= 32'd0; rs2_data_ex <= 32'd0; imm_ext_ex <= 32'd0;
            reg_write_ex <= 1'b0; alu_src_a_ex <= 1'b0; alu_src_b_ex <= 1'b0; mem_write_ex <= 1'b0;
            branch_ex <= 1'b0; jump_ex <= 1'b0; jalr_ex <= 1'b0; result_src_ex <= 2'b00; alu_op_ex <= 2'b00;
        end else begin
            pc_ex <= pc_id; instr_ex <= instr_id;
            rs1_data_ex <= rs1_data_raw; rs2_data_ex <= rs2_data_raw; imm_ext_ex <= imm_ext_id;
            reg_write_ex <= reg_write_d; alu_src_a_ex <= alu_src_a_d; alu_src_b_ex <= alu_src_b_d; mem_write_ex <= mem_write_d;
            branch_ex <= branch_d; jump_ex <= jump_d; jalr_ex <= jalr_d; result_src_ex <= result_src_d; alu_op_ex <= alu_op_d;
        end
    end

    // ==========================================
    // 5. EXECUTE STAGE
    // ==========================================
    wire [31:0] alu_a_in, alu_b_in, alu_result_ex, forward_a_data, forward_b_data;
    wire [3:0]  alu_ctrl_ex;
    wire [1:0]  forward_a, forward_b;
    wire        branch_taken_ex;

    forwarding_unit u_forwarding (
        .id_ex_rs1(instr_ex[19:15]), .id_ex_rs2(instr_ex[24:20]),
        .ex_mem_rd(instr_mem[11:7]), .ex_mem_reg_write(reg_write_mem),
        .mem_wb_rd(instr_wb[11:7]), .mem_wb_reg_write(reg_write_wb),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    // FIX: Forward PC+4 if the instruction in MEM is a JAL/JALR
    wire [31:0] fwd_data_mem = (result_src_mem == 2'b10) ? pc_plus_4_mem : alu_result_mem;

    mux4 u_fwd_mux_a (.sel(forward_a), .d0(rs1_data_ex), .d1(rd_data_wb), .d2(fwd_data_mem), .d3(32'd0), .y(forward_a_data));
    mux4 u_fwd_mux_b (.sel(forward_b), .d0(rs2_data_ex), .d1(rd_data_wb), .d2(fwd_data_mem), .d3(32'd0), .y(forward_b_data));
    
    mux2 u_mux_alu_a (.sel(alu_src_a_ex), .d0(forward_a_data), .d1(pc_ex), .y(alu_a_in));
    mux2 u_mux_alu_b (.sel(alu_src_b_ex), .d0(forward_b_data), .d1(imm_ext_ex), .y(alu_b_in));

    alu_decoder u_alu_decoder (.opcode_5(instr_ex[5]), .funct3(instr_ex[14:12]), .funct7_5(instr_ex[30]), .alu_op(alu_op_ex), .alu_ctrl(alu_ctrl_ex));
    alu u_alu (.a(alu_a_in), .b(alu_b_in), .alu_ctrl(alu_ctrl_ex), .result(alu_result_ex));
    
    branch_unit u_branch_unit (.branch(branch_ex), .funct3(instr_ex[14:12]), .rs1_data(forward_a_data), .rs2_data(forward_b_data), .branch_taken(branch_taken_ex));

    next_pc u_next_pc_ex (
        .pc(pc_ex), .imm_ext(imm_ext_ex), .alu_result(alu_result_ex),
        .branch_taken(branch_taken_ex), .jump(jump_ex), .jalr(jalr_ex), .pc_next(pc_next_from_ex)
    );
    assign pc_redirect_ex = branch_taken_ex || jump_ex || jalr_ex;

    // ==========================================
    // 6. EX/MEM PIPELINE REGISTERS
    // ==========================================
    reg [31:0] alu_result_mem, rs2_data_mem, instr_mem, pc_plus_4_mem;
    reg        reg_write_mem, mem_write_mem;
    reg [1:0]  result_src_mem;

    always @(posedge clk) begin
        if (rst) begin
            alu_result_mem <= 32'd0; rs2_data_mem <= 32'd0; instr_mem <= 32'h00000013; pc_plus_4_mem <= 32'd0;
            reg_write_mem <= 1'b0; mem_write_mem <= 1'b0; result_src_mem <= 2'b00;
        end else begin
            alu_result_mem <= alu_result_ex; rs2_data_mem <= forward_b_data; instr_mem <= instr_ex; pc_plus_4_mem <= pc_ex + 32'd4;
            reg_write_mem <= reg_write_ex; mem_write_mem <= mem_write_ex; result_src_mem <= result_src_ex;
        end
    end

    // ==========================================
    // 7. MEMORY STAGE
    // ==========================================
    wire        dmem_write_en;
    wire [3:0]  wstrb;
    wire [31:0] dmem_wdata, dmem_rdata, ld_data_mem;

    lsu u_lsu (
        .clk(clk), .mem_write(mem_write_mem), .funct3(instr_mem[14:12]),
        .addr(alu_result_mem), .st_data(rs2_data_mem), .mem_rdata(dmem_rdata),
        .ld_data(ld_data_mem), .dmem_write_en(dmem_write_en), .wstrb(wstrb), .dmem_wdata(dmem_wdata)
    );
    dmem u_dmem (.clk(clk), .addr(alu_result_mem), .wdata(dmem_wdata), .wstrb(wstrb), .mem_write(dmem_write_en), .rdata(dmem_rdata));

    // ==========================================
    // 8. MEM/WB PIPELINE REGISTERS
    // ==========================================
    reg [31:0] alu_result_wb, ld_data_wb, instr_wb, pc_plus_4_wb;
    reg        reg_write_wb;
    reg [1:0]  result_src_wb;

    always @(posedge clk) begin
        if (rst) begin
            alu_result_wb <= 32'd0; ld_data_wb <= 32'd0; instr_wb <= 32'h00000013; pc_plus_4_wb <= 32'd0;
            reg_write_wb <= 1'b0; result_src_wb <= 2'b00;
        end else begin
            alu_result_wb <= alu_result_mem; ld_data_wb <= ld_data_mem; instr_wb <= instr_mem; pc_plus_4_wb <= pc_plus_4_mem;
            reg_write_wb <= reg_write_mem; result_src_wb <= result_src_mem;
        end
    end

    // ==========================================
    // 9. WRITEBACK STAGE
    // ==========================================
    mux4 u_mux_result (.sel(result_src_wb), .d0(alu_result_wb), .d1(ld_data_wb), .d2(pc_plus_4_wb), .d3(32'd0), .y(rd_data_wb));

endmodule