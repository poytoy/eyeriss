`timescale 1ns/1ps

module tb_main;

    logic clk;
    logic reset;
    logic btnprev;
    logic btnedge;
    logic button_leds;
    logic [7:0] AN;      // 7-segment display anode control (8 digits)
    logic [6:0] SEG;     // 7-segment display segments
    logic DP;            // 7-segment display decimal point
    logic [15:0] LED;
    logic LED16_R, LED16_G, LED16_B;  // RGB LED 16
    logic LED17_R, LED17_G, LED17_B;  // RGB LED 17
    
    // For monitoring internal signals
    logic [15:0] result_read_index;
    logic [15:0] resultsout;
    logic [4:0] fsm_state;      // Main FSM state
    logic [15:0] resultsout;
    
    // Clock generation - 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate the DUT
    main dut (
        .clk(clk),
        .reset(reset),
        .btnprev(btnprev),
        .btnedge(btnedge),
        .button_leds(button_leds),
        .AN(AN),
        .SEG(SEG),
        .DP(DP),
        .LED(LED),
        .LED16_R(LED16_R),
        .LED16_G(LED16_G),
        .LED16_B(LED16_B),
        .LED17_R(LED17_R),
        .LED17_G(LED17_G),
        .LED17_B(LED17_B)
    );
    
    // Connect internal signals for monitoring
    assign fsm_state = dut.state;
    assign result_read_index = dut.result_read_index;
    assign resultsout = dut.resultsout;

    initial begin
        $display("Starting simulation...");

        // Initialize inputs
        reset = 0;
        btnprev = 0;
        btnedge = 0;
        button_leds = 0;
        
        repeat (10) @(posedge clk);
        $display("Initial state - fsm_state: %d", fsm_state);
        
        $display("Forcing rst to 1 at %0t", $time);
        force dut.rst = 1;
        repeat (20) @(posedge clk);
        $display("Forcing rst to 0 at %0t", $time);
        force dut.rst = 0;       
        repeat (20) @(posedge clk);       
        $display("Releasing forced rst at %0t", $time);
        release dut.rst;       

        $display("Waiting for processing to complete...");
        repeat (10000) @(posedge clk);

        $display("Simulation finished.");
        $finish;
    end

endmodule





