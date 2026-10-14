`timescale 1ns/1ps

module tb_top;

    reg clk;
    reg rst;

    // Allow hex file to be overridden via command-line plusarg +HEX=...
    reg [1023:0] hex_file;

    initial begin
        if (!$value$plusargs("HEX=%s", hex_file)) begin
            hex_file = "sw/arith.hex"; // Default test
        end
        $display("[INFO] Running simulation with test program: %0s", hex_file);
    end

    // Instantiate Top-Level Processor
    top u_top (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    integer i;

    initial begin
        $dumpfile("report/top_processor.vcd");
        $dumpvars(0, tb_top);

        clk = 0;
        rst = 1;
        #20;
        rst = 0;

        // Run simulation for enough cycles to complete test programs
        #2000;

        $display("=== TOP PROCESSOR SIMULATION FINISHED ===");
        $display("Final PC: 0x%08x", u_top.u_pc_reg.pc);

        // Print core register file snapshot (all 32 registers for automated testing)
        $display("\n--- Register File Snapshot ---");
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%0d = 0x%08x", i, u_top.u_regfile.regs[i]);
        end

        $finish;
    end

endmodule