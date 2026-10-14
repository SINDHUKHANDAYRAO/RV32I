`timescale 1ns/1ps

module tb_top;

    reg clk;
    reg rst;

    reg [1023:0] hex_file;

    initial begin
        if (!$value$plusargs("HEX=%s", hex_file)) begin
            hex_file = "sw/arith.hex";
        end
        $display("[INFO] [PIPE] Running simulation with test program: %0s", hex_file);
    end

    // Instantiate Pipelined Top-Level Processor
    top u_top (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    integer i;

    initial begin
        $dumpfile("report/top_pipe_processor.vcd");
        $dumpvars(0, tb_top);

        clk = 0;
        rst = 1;
        #20;
        rst = 0;

        // Run simulation long enough for multi-stage execution
        #50000;

        $display("=== PIPELINED PROCESSOR SIMULATION FINISHED ===");
        $display("Final PC: 0x%08x", u_top.u_pc_reg.pc);

        // Print core register file snapshot (all 32 registers)
        // Print core register file snapshot (all 32 registers)
        $display("\n--- Register File Snapshot ---");
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%0d = 0x%08h", i, u_top.u_regfile.regs[i]);
        end

        $finish;
    end

endmodule