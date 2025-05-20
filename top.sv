`timescale 1ns/1ps

// Synthesizable, top-level module with a basic FSM and hardcoded image/kernel data.
// No inputs/outputs. On reset, loads a 6x6 kernel and 6x6 image into a 12x14 PE grid.

module main;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;

    // PE grid connections
    reg  [15:0] image_val_vec [0:13];
    reg         valid_x_vec   [0:13];
    reg  [15:0] row_weight_vals [0:13];
    reg  [3:0]  tag_row;
    reg         valid_y;
    reg  [31:0] psum_ins [0:13];
    wire [31:0] psum_outs [0:13];

    // Hardcoded memory for image and kernel (6x6 each)
    localparam int IMG_W = 6, IMG_H = 6;
    localparam int GRID_COLS = 14;
    localparam int GRID_ROWS = 12;

    // Example: image and kernel are all 1s for demonstration
    logic [15:0] image_data  [0:IMG_W*IMG_H-1];
    logic [15:0] kernel_data [0:IMG_W*IMG_H-1];

    // FSM state encoding
    typedef enum logic [2:0] {
        S_RESET,
        S_LOAD_KERNEL,
        S_WAIT_KERNEL,
        S_IMAGE_ROW,
        S_WAIT_IMAGE,
        S_DONE
    } state_t;
    state_t state = S_RESET;
    int r, c;

    // Instantiate PE grid
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
    always #5 clk = ~clk;

    // Hardcoded image and kernel initialization (all 1s, change as needed)
    initial begin
        for (int i = 0; i < IMG_W*IMG_H; i = i + 1) begin
            image_data[i] = 16'd1 + i;   // e.g. [1,2,3,...,36]
            kernel_data[i] = 16'd1;      // e.g. all 1s
        end
    end

    // Main FSM
    initial begin
        rst = 1;
        valid_y = 0;
        tag_row = 0;
        for (int i = 0; i < GRID_COLS; i++) begin
            image_val_vec[i] = 0;
            valid_x_vec[i] = 0;
            row_weight_vals[i] = 0;
            psum_ins[i] = 0;
        end

        state = S_RESET;
        r = 0;
        c = 0;

        repeat (2) @(posedge clk); // Allow reset to propagate
        rst = 0;
        state = S_LOAD_KERNEL;
        r = 0;

        forever @(posedge clk) begin
            case (state)
            S_LOAD_KERNEL: begin
                // Load one row of kernel weights
                for (c = 0; c < IMG_W; c = c + 1)
                    row_weight_vals[c] = kernel_data[r*IMG_W + c];
                for (c = IMG_W; c < GRID_COLS; c = c + 1)
                    row_weight_vals[c] = 0;
                tag_row = r[3:0];
                valid_y = 1;
                state = S_WAIT_KERNEL;
            end
            S_WAIT_KERNEL: begin
                valid_y = 0;
                if (r < IMG_H-1) begin
                    r = r + 1;
                    state = S_LOAD_KERNEL;
                end else begin
                    r = 0;
                    state = S_IMAGE_ROW;
                end
            end
            S_IMAGE_ROW: begin
                for (c = 0; c < IMG_W; c = c + 1) begin
                    image_val_vec[c] = 16'h0100;
                    valid_x_vec[c] = 1;
                end
                for (c = IMG_W; c < GRID_COLS; c = c + 1) begin
                    image_val_vec[c] = 0;
                    valid_x_vec[c] = 0;
                end
                state = S_WAIT_IMAGE;
            end
            S_WAIT_IMAGE: begin
                for (c = 0; c < GRID_COLS; c = c + 1) valid_x_vec[c] = 0;
                if (r < IMG_H-1) begin
                    r = r + 1;
                    state = S_IMAGE_ROW;
                end else begin
                    state = S_DONE;
                end
            end
            S_DONE: begin
                // Remain in done state; for simulation, you could $finish here
                // but for synthesis, just idle
                // For demo, can route output to chipscope/ILA, etc.
                state = S_DONE;
            end
            default: state = S_DONE;
            endcase
        end
    end

endmodule
