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
        $dumpfile("pe_grid.vcd");
        $dumpvars(0, tb_pe_grid_12x14);
        $display("== PE Grid Test Begin ==");

        // Reset
        rst = 1;
        image_val_in = 0;
        weight_val_in = 0;
        tag_col = 0;
        tag_row = 0;
        valid_x = 0;
        valid_y = 0;

        for (i = 0; i < 14; i = i + 1)
            psum_ins[i] = 0;

        #10;
        rst = 0;

        // Send activation and weight to PE[3][5]
        image_val_in = 16'd4;
        tag_col      = 4'd5;
        valid_x      = 1;

        weight_val_in = 16'd10;
        tag_row       = 4'd3;
        valid_y       = 1;

        #10;
        valid_x = 0;
        valid_y = 0;

        // Wait a few cycles for value to propagate up
        #50;

        $display(">> psum_outs[5] = %0d (expected 40)", psum_outs[5]);

        if (psum_outs[5] == 32'd40)
            $display("✅ PASS");
        else
            $display("❌ FAIL");

        $finish;
    end

endmodule
