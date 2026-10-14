`timescale 1ns/1ps

module lsu (
    input  wire        clk,
    input  wire        mem_write,
    input  wire [2:0]  funct3,
    input  wire [31:0] addr,
    input  wire [31:0] st_data,
    input  wire [31:0] mem_rdata,
    output reg  [31:0] ld_data,
    output wire        dmem_write_en,
    output reg  [3:0]  wstrb,
    output wire [31:0] dmem_wdata
);

    // Direct memory write enable pass-through
    assign dmem_write_en = mem_write;

    // Byte lane shift amount based on address bits [1:0]
    wire [1:0] byte_offset = addr[1:0];

    // Align store data to proper byte lanes
    always @(*) begin
        wstrb = 4'b0000;
        case (funct3)
            3'b000: begin // SB (Store Byte)
                case (byte_offset)
                    2'b00: wstrb = 4'b0001;
                    2'b01: wstrb = 4'b0010;
                    2'b10: wstrb = 4'b0100;
                    2'b11: wstrb = 4'b1000;
                endcase
            end
            3'b001: begin // SH (Store Halfword)
                case (byte_offset[1])
                    1'b0:  wstrb = 4'b0011;
                    1'b1:  wstrb = 4'b1100;
                endcase
            end
            3'b010: begin // SW (Store Word)
                wstrb = 4'b1111;
            end
            default: wstrb = 4'b0000;
        endcase
    end

    // Shift store data to align with byte lanes
    assign dmem_wdata = st_data << (byte_offset * 8);

    // Load data formatting and extension
    always @(*) begin
        case (funct3)
            3'b000: begin // LB (Load Byte Signed)
                case (byte_offset)
                    2'b00: ld_data = {{24{mem_rdata[7]}},  mem_rdata[7:0]};
                    2'b01: ld_data = {{24{mem_rdata[15]}}, mem_rdata[15:8]};
                    2'b10: ld_data = {{24{mem_rdata[23]}}, mem_rdata[23:16]};
                    2'b11: ld_data = {{24{mem_rdata[31]}}, mem_rdata[31:24]};
                endcase
            end
            3'b001: begin // LH (Load Halfword Signed)
                case (byte_offset[1])
                    1'b0:  ld_data = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
                    1'b1:  ld_data = {{16{mem_rdata[31]}}, mem_rdata[31:16]};
                endcase
            end
            3'b010: begin // LW (Load Word)
                ld_data = mem_rdata;
            end
            3'b100: begin // LBU (Load Byte Unsigned)
                case (byte_offset)
                    2'b00: ld_data = {24'd0, mem_rdata[7:0]};
                    2'b01: ld_data = {24'd0, mem_rdata[15:8]};
                    2'b10: ld_data = {24'd0, mem_rdata[23:16]};
                    2'b11: ld_data = {24'd0, mem_rdata[31:24]};
                endcase
            end
            3'b101: begin // LHU (Load Halfword Unsigned)
                case (byte_offset[1])
                    1'b0:  ld_data = {16'd0, mem_rdata[15:0]};
                    1'b1:  ld_data = {16'd0, mem_rdata[31:16]};
                endcase
            end
            default: ld_data = mem_rdata;
        endcase
    end

endmodule