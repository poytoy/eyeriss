`timescale 1ns/1ps

module tb_main;

    logic clk;
    logic rst;
    logic btn_prev;
    logic btn_edge;
    logic [15:0] LED;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz clock

    // Instantiate the DUT
    main dut (
        .clk(clk),
        .rst(rst),
        .btn_prev(btn_prev),
        .btn_edge(btn_edge),
        .LED(LED)
    );

    initial begin
        $display("Starting simulation...");
        $dumpfile("waveform.vcd"); // for GTKWave
        $dumpvars(0, tb_main);

        // Initialize inputs
        rst = 1;
        btn_prev = 0;
        btn_edge = 0;

        // Hold reset for a few cycles
        repeat (5) @(posedge clk);
        rst = 0;

        // Wait for FSM to finish processing (simulate a few ms)
        repeat (10000) @(posedge clk);

        // Simulate user pressing the button to view results
        btn_edge = 1;
        @(posedge clk);
        btn_edge = 0;
        repeat (20) @(posedge clk)
        repeat (10) begin
            @(posedge clk);
            btn_edge = 1;
            @(posedge clk);
            btn_edge = 0;
            @(posedge clk);
        end

        // Finish
        $display("Simulation finished.");
        $finish;
    end

endmodule
