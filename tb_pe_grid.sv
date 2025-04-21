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
    reg [15:0] image_data  [0:35];  // 6x6
    reg [15:0] kernel_data [0:35];  // 6x6

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
        $display("== PE Grid 6x6 Image × 6x6 Kernel Test Begin ==");

        // Load input data
        $readmemh("image_fp16_1.mem", image_data);
        $readmemh("kernel_fp16_1.mem", kernel_data);
        // Reset and init
        rst = 1;
        valid_x = 0;
        valid_y = 0;
        image_val_in = 0;
        weight_val_in = 0;
        tag_col = 0;
        tag_row = 0;

        for (i = 0; i < 14; i = i + 1)
            psum_ins[i] = 32'd0;

        repeat (2) @(posedge clk);  // 2 cycles of reset
        rst = 0;

        // === First MAC: PE[4][5] => 10 × 1 ===
        // === Feed the 6x6 image and kernel into the array ===
     for (int t = 0; t < 6; t++) begin
    // Send 6 image vals at row t to cols 0-5
    for (int c = 0; c < 6; c++) begin
        image_val_in = image_data[t * 6 + c];
        tag_col = c;
        valid_x = 1;

        // Simultaneously, send 6 kernel vals at col t to rows 0-5
        weight_val_in = kernel_data[t * 6 + c];  // t is column index
        tag_row = c;
        valid_y = 1;

        @(posedge clk);

        valid_x = 0;
        valid_y = 0;
    end
end
        // Wait for accumulation to reach top row
        repeat (10) @(posedge clk);

        $finish;
    end

endmodule
