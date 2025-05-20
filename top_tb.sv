`timescale 1ns/1ps

module tb_main;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;


    // Instantiate the DUT (top-level main module)
    main uut();

    // Connect for observing outputs
    // If 'main' already declares psum_outs as wire, you may need to expose it via bind or interface
    // Otherwise, you can modify 'main' to declare psum_outs as 'wire' and mark it as '(* keep *)' for visibility in simulation

    // Clock generation
        localparam int RESET_CYCLES = 3;
    integer reset_counter = 0;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset_counter < RESET_CYCLES) begin
            rst <= 1;
            reset_counter <= reset_counter + 1;
        end else begin
            rst <= 0;
        end
    end

    // Initial block for simulation control and observation
    initial begin
        $display("== TB: MAIN (Top) ==");
        // Optionally assert and deassert reset here if main module doesn't already do so internally
        // rst = 1;
        // repeat (2) @(posedge clk);
        // rst = 0;

        // Run long enough to complete the FSM sequence in main
        repeat (100) @(posedge clk);

        // Print outputs (assuming main's psum_outs[0:5] are the interesting outputs)
        $display("\n== TB: Final psum_outs ==");
        for (int i = 0; i < 6; i++) begin
            $display("psum_outs[%0d] = %0d (0x%h)", i, uut.psum_outs[i], uut.psum_outs[i]);
        end

        $finish;
    end

    // Optional: dump waveforms for viewing in sim
    initial begin
        $dumpfile("tb_main.vcd");
        $dumpvars(0, tb_main);
    end

endmodule
