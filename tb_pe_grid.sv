`timescale 1ns/1ps

module tb_pe_grid_12x14;

    reg clk;
    reg rst;

    reg  [15:0] image_val_in;
    reg  [3:0]  tag_col;
    reg         valid_x;

    reg  [15:0] weight_val_in;
    reg  [3:0]  tag_row;
    reg         valid_y;

    reg  [31:0] psum_ins  [0:13];
    wire [31:0] psum_outs [0:13];

    // Instantiate the DUT
    PE_Grid_12x14 dut (
        .clk(clk),
        .rst(rst),
        .image_val_in(image_val_in),
        .tag_col(tag_col),
        .valid_x(valid_x),
        .weight_val_in(weight_val_in),
        .tag_row(tag_row),
        .valid_y(valid_y),
        .psum_ins(psum_ins),
        .psum_outs(psum_outs)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;

    initial begin
        $display("== PE Grid Vertical Propagation Test Begin ==");

        // Apply reset
        rst = 1;
        valid_x = 0;
        valid_y = 0;
        image_val_in = 0;
        weight_val_in = 0;
        tag_col = 0;
        tag_row = 0;

        // Initialize all psum inputs to zero
        for (i = 0; i < 14; i = i + 1)
            psum_ins[i] = 32'd0;

        #20;
        rst = 0;

        // === Activate only PE[2][2] ===
        // Send weight to row 2
        weight_val_in = 16'd3;
        tag_row       = 4'd2;
        valid_y       = 1;

        // Send image to column 2
        image_val_in  = 16'd30;
        tag_col       = 4'd2;
        valid_x       = 1;

        #10;
        valid_x = 0;
        valid_y = 0;

        // Wait for value to propagate up to psum_outs[2]
        #100;

        // Check result
        $display("\n== psum_outs[2] = %0d (expected: 90) ==", psum_outs[2]);

        if (psum_outs[2] == 90)
            $display("✅ SUCCESS: Vertical accumulation works.");
        else
            $display("❌ FAILURE: psum_outs[2] incorrect!");

        $finish;
    end

endmodule
