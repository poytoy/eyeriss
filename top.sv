`timescale 1ns/1ps

// Synthesizable, top-level module with a basic FSM and hardcoded image/kernel data.
// No inputs/outputs. On reset, loads a 6x6 kernel and 6x6 image into a 12x14 PE grid.

module main (
    input logic clk,
    input logic rst,
    input logic btn_prev,
    input logic btn_edge,
    output logic[15:0] LED
);
    //14 psum summer inputs-outputs
    logic [15:0] tree_input [0:13];
    logic [15:0] tree_sum;

    // PE grid connections
    reg  [15:0] image_val_vec [0:13];
    reg         valid_x_vec   [0:13];
    reg  [15:0] row_weight_vals [0:13];
    reg  [3:0]  tag_row;
    reg         valid_y;
    reg  [15:0] psum_ins [0:13];
    wire [15:0] psum_outs [0:13];

    // Hardcoded memory for image and kernel (6x6 each)
    localparam int IMG_W = 6, IMG_H = 6;
    localparam int GRID_COLS = 14;
    localparam int GRID_ROWS = 12;
    localparam int KERNEL_SIZE = 4;
    localparam int IMG_SIZE = 24;



    // FSM state encoding
    typedef enum logic [4:0] {
        S_RESET,
        S_BRAM_LOAD,
        S_BRAM_LWAIT,
        S_BRAM_KERNEL,
        S_BRAM_KWAIT,
        S_LOAD_KERNEL,
        S_WAIT_KERNEL,
        S_IMAGE_ROW,
        S_PSUM_SUM,
        S_BRAM_WRITE,
        S_BRAM_WWAIT,
        S_DONE,
        S_IDLE,
        S_RESULT_DELAY,
        S_RESULT_SHOW
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
    //initiate 14 tree adder
    assign tree_input = psum_outs;
        adder_tree_14 my_tree (
            .in(psum_outs),
            .sum(tree_sum)
        );

    // Hardcoded image and kernel initialization (all 1s, change as needed)

    //BUNLAR ŞU ANLIK FIXED, NON-PARAMETERIZED
    logic [14:0] imgaddr;
    logic [14:0] resultsaddr;
    logic [14:0] kerneladdr;
    ////////////////////////////////// BUNLAR KALABİLİR BÖYLE
    logic [15:0] imgdout, kerneldout, resultsout, resultsin, resultsincopy, next_idx;
    logic [2:0] bram_delay;
    logic all_completed, delay_active;
    logic [5:0] index0, index1;
    logic [15:0] buffer [15:0];
    logic [15:0] kernelbuf [15:0];
    logic [15:0] idx, idx1, idx2, idx3;
    
    logic [15:0] result_read_index;
    logic [1:0] result_delay_counter;

    blk_mem_img imagebram(
    .clka(clk), // Clock signal
    .ena(1'b1), // Enable signal
    .wea(1'b0), // Write enable signal
    .addra(imgaddr), // Address input
    .dina(16'b0), // Data input
    .douta(imgdout) // Data output
    );
    
    blk_mem_kernel matrixbram(
    .clka(clk), // Clock signal
    .ena(1'b1), // Enable signal
    .wea(1'b0), // Write enable signal
    .addra(kerneladdr), // Address input
    .dina(16'b0), // Data input
    .douta(kerneldout) // Data output
    );
 
    blk_mem_results resultsbram(
    .clka(clk), // Clock signal
    .ena(1'b1), // Enable signal
    .wea(1'b1), // Write enable signal
    .addra(resultsaddr), // Address input
    .dina(resultsin), // Data input
    .douta(resultsout) // Data output
    );
    
    

        

    // Main FSM
    initial begin
        valid_y = 0;
        bram_delay = 0;
        delay_active = 0;
        all_completed = 0;
        imgaddr = 0;
        idx = 0;
        idx1 = 0;
        idx2 = 0;
        idx3 = 0;
        index0 = 0;
        index1 = 0;
        kerneldout = 0;
        resultsin = 0;
        kerneladdr = 0;
        next_idx = 0;
        result_read_index=0;
        result_delay_counter=0;
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
        state = S_BRAM_LOAD;
        r = 0;
        




        forever @(posedge clk) begin
            case (state)
            S_BRAM_LOAD: begin
                if(index0 < 16) begin
                    if(!delay_active) begin
                        imgaddr <= idx;       
                        delay_active <= 1'b1;
                        state = S_BRAM_LWAIT;
                    end else if(delay_active) begin
                        buffer[index0] <= imgdout;
                        idx <= idx + 1'b1;
                        index0 <= index0 + 1'b1;
                        delay_active <= 1'b0;  
                    end
                end          
                if(index0 == 16) begin
                    state = S_BRAM_KERNEL;
                end    
            end
            S_BRAM_LWAIT: begin
                bram_delay += 1;
                if(bram_delay == 2'd3) begin
                    state = S_BRAM_LOAD;
                    bram_delay <= 0;   
                end      
            end
            S_BRAM_KERNEL: begin
                if(index1 < 16) begin
                    if(!delay_active) begin
                        kerneladdr <= idx1;
                        idx1 <= idx1 + 1'b1;
                        delay_active <= 1'b1;
                        state = S_BRAM_KWAIT;
                    end else if(delay_active) begin
                        kernelbuf[index1] <= kerneldout;
                        index1 <= index1 + 1'b1;
                        delay_active <= 1'b0;  
                    end
                end          
                if(index1 == 16) begin
                    state = S_LOAD_KERNEL;
                end    
            end
            S_BRAM_KWAIT: begin
                bram_delay += 1;
                if(bram_delay == 2'd3) begin
                    state = S_BRAM_KERNEL;
                    bram_delay <= 0;   
                end    
            end
            S_LOAD_KERNEL: begin
                // Load one row of kernel weights
                for (c = 0; c < IMG_W; c = c + 1)
                    row_weight_vals[c] = kernelbuf[c];
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
                    image_val_vec[c] = buffer[c];
                    valid_x_vec[c] = 1;
                end
                for (c = IMG_W; c < GRID_COLS; c = c + 1) begin
                    image_val_vec[c] = 0;
                    valid_x_vec[c] = 0;
                end
                state = S_PSUM_SUM;
            end
            
            S_PSUM_SUM: begin
            
                resultsincopy   <= tree_sum;
                $display("Final 14-way Q7.8 sum: %d (hex: %h)", tree_sum, tree_sum);
                state       <= S_BRAM_WRITE;
            end
                
            S_BRAM_WRITE: begin
                if(!delay_active) begin        
                resultsaddr <= idx2;
                idx2 <= idx2 + 1;
                delay_active <= 1'b1;
                state = S_BRAM_WWAIT;
                end
                else if(delay_active) begin
                    resultsin <= resultsincopy;
                    delay_active <= 0;
                    state = S_DONE;
                end
            end
            S_BRAM_WWAIT: begin
                bram_delay += 1;
                if(bram_delay == 2'd3) begin
                    state = S_BRAM_WRITE;
                    index0 <= 1'b0;
                    bram_delay <= 0;   
                end                  
            end
            S_DONE: begin
                idx3 <= idx3 + 1;
                if(idx3 > 16'd36)
                state = S_IDLE;
                else if(idx3 < 16'd36)
                state = S_BRAM_LOAD;
            end
            S_IDLE: begin
                LED <= 16'd1;
                if (btn_edge && result_read_index < 36) begin
                    resultsaddr <= result_read_index;
                    result_delay_counter <= 0;
                    state <= S_RESULT_DELAY;
                end
            end
            
            S_RESULT_DELAY: begin
                result_delay_counter <= result_delay_counter + 1;
                if (result_delay_counter == 3) begin // Wait for BRAM latency
                    state <= S_RESULT_SHOW;
                end
            end
            
            S_RESULT_SHOW: begin
                LED <= resultsout;
                if(btn_edge)begin
                result_read_index <= result_read_index + 1;
                state <= S_IDLE;
                end
            end 
        
            default: state = S_DONE;
            endcase
        end
    end

endmodule
