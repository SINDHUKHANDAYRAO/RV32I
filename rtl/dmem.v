`timescale 1ns/1ps

module dmem #(
    parameter DEPTH = 1024,
    parameter ADDR_BITS = 10
) (
    input  wire        clk,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    input  wire        mem_write,
    output wire [31:0] rdata
);

    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'd0;
        end
    end

    wire [ADDR_BITS-1:0] word_index = addr[ADDR_BITS+1:2];

    // Combinational read
    assign rdata = mem[word_index];

    // Synchronous write with byte enables
    always @(posedge clk) begin
        if (mem_write) begin
            if (wstrb[0]) mem[word_index][7:0]   <= wdata[7:0];
            if (wstrb[1]) mem[word_index][15:8]  <= wdata[15:8];
            if (wstrb[2]) mem[word_index][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[word_index][31:24] <= wdata[31:24];
        end
    end

endmodule