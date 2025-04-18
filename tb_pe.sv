`timescale 1ns/1ps

module tb_pe;

    logic clk;
    logic rst;
    logic [15:0] image_val;
    logic [15:0] weight_val;
    logic [31:0] psum_in;
    logic [31:0] psum_out;

    // Instantiate DUT
    pe dut (
        .clk(clk),
        .rst(rst),
        .image_val(image_val),
        .weight_val(weight_val),
        .psum_in(psum_in),
        .psum_out(psum_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns clock period

    initial begin
        $display("=== PE Test ===");
        $dumpfile("tb_pe.vcd");
        $dumpvars(0, tb_pe);

        // Test: Reset
        rst = 1;
        image_val = 0;
        weight_val = 0;
        psum_in = 0;
        #10;

        rst = 0;

        // Test 1: MAC operation
        image_val = 16'd2;
        weight_val = 16'd3;
        psum_in = 32'd10;
        #10; // wait 1 cycle

        // Check result
        if (psum_out !== 32'd16)
            $display("❌ FAIL: Expected 16, got %0d", psum_out);
        else
            $display("✅ PASS: psum_out = %0b", psum_out);

        // Test 2: Another MAC
        image_val = 16'd4;
        weight_val = 16'd5;
        psum_in = psum_out;
        #10;

        if (psum_out !== 32'd36)
            $display("❌ FAIL: Expected 36, got %0d", psum_out);
        else
            $display("✅ PASS: psum_out = %0d", psum_out);

        $finish;
    end

endmodule
