// Eyeriss Top-Level Controller FSM
// For poytoy/eyeriss implementation
// Based on CSE550.Eyeriss.pdf paper

module eyeriss_controller (
    input  logic clk,
    input  logic rst,
    
    // Configuration and control signals
    input  logic start_compute,
    input  logic [7:0] num_rows,         // Number of rows in the input
    input  logic [7:0] num_cols,         // Number of columns in the input
    input  logic [7:0] filter_size,      // Filter size (assuming square filter)
    
    // Memory interface signals
    output logic mem_rd_en,
    output logic [15:0] mem_rd_addr,
    input  logic [15:0] mem_rd_data,
    
    // Weight buffer control
    output logic weight_load_en,
    output logic [3:0] weight_row_id,
    output logic [15:0] weight_data [0:13],
    output logic weight_valid,
    
    // Input feature map control
    output logic ifmap_load_en,
    output logic [15:0] ifmap_data [0:13],
    output logic [13:0] ifmap_valid_vec,
    
    // Output psum control
    input  logic [31:0] psum_out [0:13],
    output logic [31:0] psum_in [0:13],
    
    // Status signals
    output logic compute_done
);

    // FSM state definitions
    typedef enum logic [3:0] {
        IDLE,
        LOAD_WEIGHTS,
        LOAD_IFMAP_ROW,
        COMPUTE_ROW,
        NEXT_ROW,
        STORE_RESULTS,
        DONE
    } state_t;
    
    state_t current_state, next_state;
    
    // Internal counters and registers
    logic [7:0] row_counter;
    logic [7:0] col_counter;
    logic [7:0] weight_row_counter;
    logic [7:0] compute_cycles;
    logic [15:0] weight_addr_base;
    logic [15:0] ifmap_addr_base;
    logic [15:0] result_addr_base;
    
    // State transition logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            row_counter <= 0;
            col_counter <= 0;
            weight_row_counter <= 0;
            compute_cycles <= 0;
            weight_addr_base <= 0;
            ifmap_addr_base <= 0;
            result_addr_base <= 0;
        end else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    if (start_compute) begin
                        // Reset counters and prepare for computation
                        row_counter <= 0;
                        col_counter <= 0;
                        weight_row_counter <= 0;
                        compute_cycles <= 0;
                        // Set up memory base addresses (could be configured externally)
                        weight_addr_base <= 16'h0000;  // Weights start at address 0
                        ifmap_addr_base <= 16'h1000;   // Input feature maps start at 0x1000
                        result_addr_base <= 16'h2000;  // Results will be stored at 0x2000
                    end
                end
                
                LOAD_WEIGHTS: begin
                    if (weight_row_counter < filter_size) begin
                        weight_row_counter <= weight_row_counter + 1;
                    end
                end
                
                LOAD_IFMAP_ROW: begin
                    // No counter updates here, handled in next state
                end
                
                COMPUTE_ROW: begin
                    compute_cycles <= compute_cycles + 1;
                    if (compute_cycles >= filter_size - 1) begin
                        compute_cycles <= 0;
                    end
                end
                
                NEXT_ROW: begin
                    row_counter <= row_counter + 1;
                    compute_cycles <= 0;
                end
                
                STORE_RESULTS: begin
                    // No counter updates here, handled in next state
                end
                
                DONE: begin
                    // Stay in DONE state until reset
                end
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = current_state; // Default: stay in current state
        
        case (current_state)
            IDLE: begin
                if (start_compute) begin
                    next_state = LOAD_WEIGHTS;
                end
            end
            
            LOAD_WEIGHTS: begin
                if (weight_row_counter >= filter_size - 1) begin
                    next_state = LOAD_IFMAP_ROW;
                end
            end
            
            LOAD_IFMAP_ROW: begin
                next_state = COMPUTE_ROW;
            end
            
            COMPUTE_ROW: begin
                if (compute_cycles >= filter_size - 1) begin
                    next_state = STORE_RESULTS;
                end
            end
            
            STORE_RESULTS: begin
                if (row_counter >= num_rows - filter_size) begin
                    next_state = DONE;
                end else begin
                    next_state = NEXT_ROW;
                end
            end
            
            NEXT_ROW: begin
                next_state = LOAD_IFMAP_ROW;
            end
            
            DONE: begin
                if (!start_compute) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // Output logic
    always_comb begin
        // Default values
        mem_rd_en = 0;
        mem_rd_addr = 0;
        weight_load_en = 0;
        weight_row_id = 0;
        for (int i = 0; i < 14; i++) begin
            weight_data[i] = 0;
            ifmap_data[i] = 0;
            psum_in[i] = 0;
        end
        weight_valid = 0;
        ifmap_load_en = 0;
        ifmap_valid_vec = 0;
        compute_done = 0;
        
        case (current_state)
            IDLE: begin
                // Reset all outputs
            end
            
            LOAD_WEIGHTS: begin
                mem_rd_en = 1;
                mem_rd_addr = weight_addr_base + weight_row_counter * filter_size;
                weight_load_en = 1;
                weight_row_id = weight_row_counter[3:0];
                
                // Set up weight data from memory read (assuming sequential reads)
                // In real implementation, would need multiple clock cycles to load an entire row
                for (int i = 0; i < filter_size; i++) begin
                    weight_data[i] = mem_rd_data; // This is simplified; actual implementation would need memory pipelining
                end
                
                weight_valid = 1;
            end
            
            LOAD_IFMAP_ROW: begin
                mem_rd_en = 1;
                mem_rd_addr = ifmap_addr_base + (row_counter * num_cols);
                ifmap_load_en = 1;
                
                // Set up ifmap data for the current row
                for (int i = 0; i < filter_size; i++) begin
                    ifmap_data[i] = mem_rd_data; // Simplified; would need multiple reads
                end
                
                // Set valid signals for active columns
                for (int i = 0; i < filter_size; i++) begin
                    ifmap_valid_vec[i] = 1;
                end
            end
            
            COMPUTE_ROW: begin
                // During computation, maintain the input validity signals
                for (int i = 0; i < filter_size; i++) begin
                    ifmap_valid_vec[i] = 1;
                end
                
                // Initialize psum inputs to 0 for the first cycle
                if (compute_cycles == 0) begin
                    for (int i = 0; i < 14; i++) begin
                        psum_in[i] = 0;
                    end
                end
            end
            
            STORE_RESULTS: begin
                // In a real implementation, would write psum_out back to memory
                // For now, just signal computation is done for this row
            end
            
            NEXT_ROW: begin
                // Reset for next row processing
            end
            
            DONE: begin
                compute_done = 1;
            end
        endcase
    end

endmodule

// Top-level integration of the Eyeriss accelerator
module eyeriss_top (
    input  logic clk,
    input  logic rst,
    input  logic start,
    output logic done,
    
    // Memory interface (could be expanded to include external memory)
    input  logic [15:0] mem_data_in,
    output logic [15:0] mem_addr_out,
    output logic mem_read_en,
    output logic mem_write_en,
    output logic [15:0] mem_data_out
);

    // Parameters for the neural network
    localparam INPUT_SIZE = 6;         // 6x6 input feature map from MNIST
    localparam FILTER_SIZE = 6;        // 6x6 filter
    localparam PE_ROWS = 12;           // 12x14 PE array
    localparam PE_COLS = 14;
    
    // Internal signals
    logic [15:0] ifmap_data [0:PE_COLS-1];
    logic [PE_COLS-1:0] ifmap_valid_vec;
    logic [15:0] weight_data [0:PE_COLS-1];
    logic [3:0] weight_row_id;
    logic weight_valid;
    logic [31:0] psum_in [0:PE_COLS-1];
    logic [31:0] psum_out [0:PE_COLS-1];
    
    // Controller signals
    logic controller_mem_rd_en;
    logic [15:0] controller_mem_addr;
    logic [15:0] controller_mem_data;
    logic weight_load_en;
    logic ifmap_load_en;
    
    // Instantiate the PE Grid
    PE_Grid_12x14 pe_grid (
        .clk(clk),
        .rst(rst),
        .image_val_vec(ifmap_data),
        .valid_x_vec(ifmap_valid_vec),
        .row_weight_vals(weight_data),
        .tag_row(weight_row_id),
        .valid_y(weight_valid),
        .psum_ins(psum_in),
        .psum_outs(psum_out)
    );
    
    // Instantiate the controller
    eyeriss_controller controller (
        .clk(clk),
        .rst(rst),
        .start_compute(start),
        .num_rows(INPUT_SIZE),
        .num_cols(INPUT_SIZE),
        .filter_size(FILTER_SIZE),
        .mem_rd_en(controller_mem_rd_en),
        .mem_rd_addr(controller_mem_addr),
        .mem_rd_data(controller_mem_data),
        .weight_load_en(weight_load_en),
        .weight_row_id(weight_row_id),
        .weight_data(weight_data),
        .weight_valid(weight_valid),
        .ifmap_load_en(ifmap_load_en),
        .ifmap_data(ifmap_data),
        .ifmap_valid_vec(ifmap_valid_vec),
        .psum_out(psum_out),
        .psum_in(psum_in),
        .compute_done(done)
    );
    
    // Memory interface
    assign mem_read_en = controller_mem_rd_en;
    assign mem_addr_out = controller_mem_addr;
    assign controller_mem_data = mem_data_in;
    
    // For now, no write back to memory
    assign mem_write_en = 0;
    assign mem_data_out = 0;

endmodule
