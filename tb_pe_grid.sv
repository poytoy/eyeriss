`timescale 1ns/1ps

module tb_pe_grid_12x14;

    // Clock and reset
    reg clk;
    reg rst;

    // Parallel image injection
    reg  [15:0] image_val_vec [0:13];
    reg         valid_x_vec    [0:13];

    reg  [15:0] row_weight_vals [0:13];  // Vector for weight row injection
    reg  [3:0]  tag_row;
    reg         valid_y;

    reg  [31:0] psum_ins [0:13];
    wire [31:0] psum_outs [0:13];

    // Memory preload
    reg [15:0] image_data  [0:35]; // 6x6 image
    reg [15:0] kernel_data [0:35]; // 6x6 kernel

    // Instantiate DUT
    PE_Grid_12x14 dut (
        .clk(clk),
        .rst(rst),
        .image_val_vec(image_val_vec),
        .valid_x_vec(valid_x_vec),
        .row_weight_vals(row_weight_vals),
        .tag_row(tag_row),
        .valid_y(valid_y),
        .psum_ins(psum_ins),
        .psum_outs(psum_outs)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer i, r, c;

    initial begin
        $display("== TB: PE_Grid_12x14 | 6x6 Image × 6x6 Kernel ==");

        // Load data
        $readmemh("image_q7_8.mem", image_data);
        $readmemh("kernel_q7_8.mem", kernel_data);

        // Initialize
        rst = 1;
        tag_row = 0;
        valid_y = 0;
        for (i = 0; i < 14; i++) begin
            image_val_vec[i] = 0;
            valid_x_vec[i] = 0;
            psum_ins[i] = 0;
        end

        repeat (2) @(posedge clk);
        rst = 0;

        // === Preload all weights row by row ===
        for (r = 0; r < 6; r++) begin
            $display("Loading Weights for Row %0d:", r);
            for (c = 0; c < 6; c++) begin
                row_weight_vals[c] = kernel_data[r * 6 + c];
                $display("  PE[Row=%0d][Col=%0d] <- weight_val = 0x%h (decimal: %0d)",
                         r, c, kernel_data[r * 6 + c], kernel_data[r * 6 + c]);
            end
            for (c = 6; c < 14; c++) row_weight_vals[c] = 0;

            tag_row = r;
            @(posedge clk);
            valid_y = 1;
            @(posedge clk);
            valid_y = 0;
            @(posedge clk);
        end

        // === Inject each row's image values ===
        for (r = 0; r < 6; r++) begin
            $display("Injecting Row %0d Image Data:", r);
            for (c = 0; c < 6; c++) begin
                image_val_vec[c] = image_data[r * 6 + c];
                valid_x_vec[c] = 1;
                $display("  PE[Row=%0d][Col=%0d] <- image_val = 0x%h (decimal: %0d)",
                         r, c, image_data[r * 6 + c], image_data[r * 6 + c]);
            end
            for (c = 6; c < 14; c++) begin
                image_val_vec[c] = 0;
                valid_x_vec[c] = 0;
            end

            @(posedge clk);
            for (c = 0; c < 14; c++) valid_x_vec[c] = 0;
            @(posedge clk);
        end


        // Print outputs
        $display("\n== Final psum_outs ==");
        for (i = 0; i < 6; i++) begin
            $display("psum_outs[%0d] = 0x%h", i, psum_outs[i]);
        end

        $finish;
    end

endmodule
