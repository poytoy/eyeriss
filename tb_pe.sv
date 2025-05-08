module tb_PE;

    logic clk = 0;
    logic rst;
    logic [15:0] image_val, weight_val;
    logic image_en, weight_en;
    logic [31:0] psum_in, psum_out;

    // Instantiate DUT
    PE dut (
        .clk(clk),
        .rst(rst),
        .image_val(image_val),
        .weight_val(weight_val),
        .image_en(image_en),
        .weight_en(weight_en),
        .psum_in(psum_in),
        .psum_out(psum_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        rst = 1;
        image_val = 0;
        weight_val = 0;
        image_en = 0;
        weight_en = 0;
        psum_in = 0;

        // Reset pulse
        #12;
        rst = 0;

        // Apply weight
        weight_val = 16'd3;
        weight_en = 1;
        #10;
        weight_en = 0;

        // Apply image + psum_in
        image_val = 16'd4;
        image_en = 1;
        psum_in = 32'd5;
        #10;
        image_en = 0;

        // Wait and observe
        #20;

        $display("Test done. Final psum_out = %0d (Expected: 3*4+5=17)", psum_out);

        $finish;
    end
endmodule
