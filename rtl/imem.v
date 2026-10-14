`timescale 1ns/1ps

module imem #(
    parameter INIT_FILE = "sw/arith.hex"
) (
    input  wire [31:0] addr,
    output wire [31:0] rdata
);
    reg [31:0] mem [0:1023];

    // Allow hex file to be defined via iverilog command-line flag -DINIT_FILE="..."
    `ifndef INIT_FILE
        `define INIT_FILE "sw/arith.hex"
    `endif

    initial begin
        $display("[INFO] Loading instruction memory from: %0s", `INIT_FILE);
        $readmemh(`INIT_FILE, mem);
    end

    // Word-aligned instruction memory read (drop bottom 2 bits)
    assign rdata = mem[addr[31:2]];

endmodule