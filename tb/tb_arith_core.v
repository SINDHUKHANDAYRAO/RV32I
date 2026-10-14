`timescale 1ns/1ps

module tb_arith_core;

    reg clk;
    reg rst;

    // Instantiate the Arithmetic Core
    arith_core #(
        .INIT_FILE("sw/arith.hex")
    ) u_core (
        .clk(clk),
        .rst(rst)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("report/arith_core.vcd");
        $dumpvars(0, tb_arith_core);

        clk = 0;
        rst = 1;
        #20;
        rst = 0;

        // Run simulation for enough cycles to execute the arith test program
        #200;

        $display("=== ARITH CORE SIMULATION FINISHED ===");
        $display("Final PC: 0x%08x", u_core.pc);
        
        // Print out register file contents for inspection
        $display("\n--- Register File State ---");
        $display("x1  (ra) = 0x%08x | x2  (sp) = 0x%08x", u_core.u_regfile.regs[1],  u_core.u_regfile.regs[2]);
        $display("x5  (t0) = 0x%08x | x6  (t1) = 0x%08x", u_core.u_regfile.regs[5],  u_core.u_regfile.regs[6]);
        $display("x7  (t2) = 0x%08x | x10 (a0) = 0x%08x", u_core.u_regfile.regs[7],  u_core.u_regfile.regs[10]);
        $display("x11 (a1) = 0x%08x | x12 (a2) = 0x%08x", u_core.u_regfile.regs[11], u_core.u_regfile.regs[12]);
        
        $finish;
    end

endmodule