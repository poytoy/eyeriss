`timescale 1ns/1ps

// Synthesizable, top-level module with a basic FSM and hardcoded image/kernel data.
// No inputs/outputs. On reset, loads a 6x6 kernel and 6x6 image into a 12x14 PE grid.

module main (
    input logic clk,
    input logic btnprev,
    input logic btnedge,
    input logic reset,
    input logic button_leds,
    output logic [7:0] AN,      
    output logic [6:0] SEG,     
    output logic DP,          
    output logic[15:0] LED,
    output logic LED16_R, LED16_G, LED16_B,  // RGB LED 16
    output logic LED17_R, LED17_G, LED17_B   // RGB LED 17
);

    //BUNLAR ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¾U ANLIK FIXED, NON-PARAMETERIZED
    logic [14:0] imgaddr;
    logic [14:0] resultsaddr;
    logic [14:0] kerneladdr;
    logic [3:0] addr_hex0, addr_hex1, pc_hex0, pc_hex1, pc_hex2, pc_hex3;
    ////////////////////////////////// BUNLAR KALABÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°LÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°R BÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¿ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â½-YLE
    logic [15:0] imgdout, kerneldout, resultsout, resultsin, resultsincopy, next_idx;
    logic [2:0] bram_delay;
    logic all_completed, delay_active, btn_prev, rst, btn_edge, next_flag;
    logic led_toggle = 0;
    logic toggler2 = 0;
    logic [5:0] index0, index1;
    logic [15:0] buffer [15:0];
    logic [15:0] kernelbuf [15:0];
    logic [15:0] idx, idx1, idx2, idx3;
    
    logic [15:0] result_read_index;
    logic [1:0] result_delay_counter;
    
    // Add button debounce flags
    logic btn_edge_prev, btn_prev_prev;
    
    // RGB LED control
    logic [32:0] rgb_counter = 0;
    
    // Add a new 8-digit display controller
    logic [3:0] digits[7:0];  // 8 digits, each 4 bits
    
    // Assign the digits
    assign digits[0] = addr_hex0;  // Lower display, rightmost digit
    assign digits[1] = addr_hex1;  // Lower display, second digit
    assign digits[2] = 4'd0;       // Lower display, third digit
    assign digits[3] = 4'd0;       // Lower display, leftmost digit
    assign digits[4] = pc_hex0;    // Upper display, rightmost digit
    assign digits[5] = pc_hex1;    // Upper display, second digit
    assign digits[6] = pc_hex2;    // Upper display, third digit
    assign digits[7] = pc_hex3;    // Upper display, leftmost digit
    
    // Counter for digit selection
    logic [19:0] display_counter = 0;
    always @(posedge clk) begin
        display_counter <= display_counter + 1;
    end
    
    // Digit selection (3 bits to select among 8 digits)
    logic [2:0] digit_select;
    assign digit_select = display_counter[19:17];  // Use higher bits for slower refresh
    
    // Digit value based on selection
    logic [3:0] current_digit;
    assign current_digit = digits[digit_select];
    
    // Anode selection (one-hot encoding)
    always_comb begin
        AN = 8'b11111111;  // All off by default (active low)
        AN[digit_select] = 1'b0;  // Turn on selected digit
    end
    
    // 7-segment decoder
    always_comb begin
        case(current_digit)
            4'd0: SEG = 7'b1000000;  // 0
            4'd1: SEG = 7'b1111001;  // 1
            4'd2: SEG = 7'b0100100;  // 2
            4'd3: SEG = 7'b0110000;  // 3
            4'd4: SEG = 7'b0011001;  // 4
            4'd5: SEG = 7'b0010010;  // 5
            4'd6: SEG = 7'b0000010;  // 6
            4'd7: SEG = 7'b1111000;  // 7
            4'd8: SEG = 7'b0000000;  // 8
            4'd9: SEG = 7'b0010000;  // 9
            4'd10: SEG = 7'b0001000; // A
            4'd11: SEG = 7'b0000011; // b
            4'd12: SEG = 7'b1000110; // C
            4'd13: SEG = 7'b0100001; // d
            4'd14: SEG = 7'b0000110; // E
            4'd15: SEG = 7'b0001110; // F
            default: SEG = 7'b1111111; // All off
        endcase
    end
    
    // Decimal point always off
    assign DP = 1'b1;
    
    // RGB LED control - adjust brightness and speed
    always @(posedge clk) begin
        rgb_counter <= rgb_counter + 1;
        if(rgb_counter[31])
            toggler2 <= ~toggler2;
        
        if(btn_leds) begin
            led_toggle <= ~led_toggle;            
        end    
        if(led_toggle) begin
            // Adjust brightness by using PWM with shorter duty cycle
            // and speed by using slightly lower counter bits
            if(!toggler2)
            LED16_R <= rgb_counter[27] & (rgb_counter[7:0] < 8'd16);   // ~6% duty cycle, slower transition
            LED16_G <= rgb_counter[28] & (rgb_counter[7:0] < 8'd16);   // Different phase
            LED16_B <= rgb_counter[29] & (rgb_counter[7:0] < 8'd16);   // Different phase
            if(toggler2) 
            LED17_R <= rgb_counter[27] & (rgb_counter[7:0] < 8'd16);   // Different phase
            LED17_G <= rgb_counter[28] & (rgb_counter[7:0] < 8'd16);   // Different phase
            LED17_B <= rgb_counter[29] & (rgb_counter[7:0] < 8'd16);   // Different phase
        end
    end
   
    pulse_controller clk_controller(.CLK(clk), .sw_input(btnprev), .clear(1'b0), .clk_pulse(btn_prev));
    pulse_controller ret (.CLK(clk), .sw_input(btnedge), .clear(1'b0), .clk_pulse(btn_edge));       
    pulse_controller pulse_reset (.CLK(clk), .sw_input(reset), .clear(1'b0), .clk_pulse(rst));    
    pulse_controller leds (.CLK(clk), .sw_input(button_leds), .clear(1'b0), .clk_pulse(btn_leds));    
    

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
    .clka(clk),                // Clock signal
    .ena(1'b1),                // Enable signal
    .wea(state == S_BRAM_WRITE && delay_active), // Only write when in write state and delay is active
    .addra(resultsaddr),       // Address input
    .dina(resultsincopy),      // Data input
    .douta(resultsout)         // Data output
    );
    
    // Binary to BCD conversion for display
    always_comb begin
        // For result display, use the lower 16 bits in hex
        pc_hex0 = resultsout[3:0];   // Lower 4 bits
        pc_hex1 = resultsout[7:4];   // Next 4 bits
        pc_hex2 = resultsout[11:8];  // Next 4 bits
        pc_hex3 = resultsout[15:12]; // Upper 4 bits
        
        // For address display, convert result_read_index to BCD
        case (result_read_index)
            16'd0:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd0; end
            16'd1:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd1; end
            16'd2:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd2; end
            16'd3:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd3; end
            16'd4:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd4; end
            16'd5:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd5; end
            16'd6:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd6; end
            16'd7:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd7; end
            16'd8:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd8; end
            16'd9:  begin addr_hex1 = 4'd0; addr_hex0 = 4'd9; end
            16'd10: begin addr_hex1 = 4'd1; addr_hex0 = 4'd0; end
            16'd11: begin addr_hex1 = 4'd1; addr_hex0 = 4'd1; end
            16'd12: begin addr_hex1 = 4'd1; addr_hex0 = 4'd2; end
            16'd13: begin addr_hex1 = 4'd1; addr_hex0 = 4'd3; end
            16'd14: begin addr_hex1 = 4'd1; addr_hex0 = 4'd4; end
            16'd15: begin addr_hex1 = 4'd1; addr_hex0 = 4'd5; end
            16'd16: begin addr_hex1 = 4'd1; addr_hex0 = 4'd6; end
            16'd17: begin addr_hex1 = 4'd1; addr_hex0 = 4'd7; end
            16'd18: begin addr_hex1 = 4'd1; addr_hex0 = 4'd8; end
            16'd19: begin addr_hex1 = 4'd1; addr_hex0 = 4'd9; end
            16'd20: begin addr_hex1 = 4'd2; addr_hex0 = 4'd0; end
            16'd21: begin addr_hex1 = 4'd2; addr_hex0 = 4'd1; end
            16'd22: begin addr_hex1 = 4'd2; addr_hex0 = 4'd2; end
            16'd23: begin addr_hex1 = 4'd2; addr_hex0 = 4'd3; end
            16'd24: begin addr_hex1 = 4'd2; addr_hex0 = 4'd4; end
            16'd25: begin addr_hex1 = 4'd2; addr_hex0 = 4'd5; end
            16'd26: begin addr_hex1 = 4'd2; addr_hex0 = 4'd6; end
            16'd27: begin addr_hex1 = 4'd2; addr_hex0 = 4'd7; end
            16'd28: begin addr_hex1 = 4'd2; addr_hex0 = 4'd8; end
            16'd29: begin addr_hex1 = 4'd2; addr_hex0 = 4'd9; end
            16'd30: begin addr_hex1 = 4'd3; addr_hex0 = 4'd0; end
            16'd31: begin addr_hex1 = 4'd3; addr_hex0 = 4'd1; end
            16'd32: begin addr_hex1 = 4'd3; addr_hex0 = 4'd2; end
            16'd33: begin addr_hex1 = 4'd3; addr_hex0 = 4'd3; end
            16'd34: begin addr_hex1 = 4'd3; addr_hex0 = 4'd4; end
            16'd35: begin addr_hex1 = 4'd3; addr_hex0 = 4'd5; end
            16'd36: begin addr_hex1 = 4'd3; addr_hex0 = 4'd6; end
            default: begin addr_hex1 = 4'd0; addr_hex0 = 4'd0; end
        endcase
    end
    
    // Main FSM
    always @(posedge clk) begin
        if (rst) begin
            valid_y <= 0;
            bram_delay <= 0;
            delay_active <= 0;
            all_completed <= 0;
            imgaddr <= 0;
            idx <= 0;
            idx1 <= 0;
            idx2 <= 0;
            idx3 <= 0;
            index0 <= 0;
            index1 <= 0;
            resultsin <= 0;
            kerneladdr <= 0;
            LED <= 16'h0000;
            next_idx <= 0;
            result_read_index <= 0;
            result_delay_counter <= 0;
            tag_row <= 0;
            for (int i = 0; i < GRID_COLS; i++) begin
                image_val_vec[i] <= 0;
                valid_x_vec[i] <= 0;
                row_weight_vals[i] <= 0;
                psum_ins[i] <= 0;
            end
            state <= S_RESET;
            r <= 0;
            c <= 0;
        end
        else begin
            case (state)
                S_RESET: begin
                    state <= S_BRAM_LOAD;
                    r <= 0;
                end
                
                S_BRAM_LOAD: begin
                    if(index0 < 16) begin
                        if(!delay_active) begin
                            imgaddr <= idx;       
                            delay_active <= 1'b1;
                            state <= S_BRAM_LWAIT;
                        end else if(delay_active) begin
                            buffer[index0] <= imgdout;
                            idx <= idx + 1'b1;
                            index0 <= index0 + 1'b1;
                            delay_active <= 1'b0;  
                        end
                    end          
                    if(index0 == 16) begin
                        state <= S_BRAM_KERNEL;
                    end    
                end
                S_BRAM_LWAIT: begin
                    bram_delay <= bram_delay + 1;
                    if(bram_delay == 2'd3) begin
                        state <= S_BRAM_LOAD;
                        bram_delay <= 0;   
                    end      
                end
                S_BRAM_KERNEL: begin
                    if(index1 < 16) begin
                        if(!delay_active) begin
                            kerneladdr <= idx1;
                            idx1 <= idx1 + 1'b1;
                            delay_active <= 1'b1;
                            state <= S_BRAM_KWAIT;
                        end else if(delay_active) begin
                            kernelbuf[index1] <= kerneldout;
                            index1 <= index1 + 1'b1;
                            delay_active <= 1'b0;  
                        end
                    end          
                    if(index1 == 16) begin
                        state <= S_LOAD_KERNEL;
                    end    
                end
                S_BRAM_KWAIT: begin
                    bram_delay <= bram_delay + 1;
                    if(bram_delay == 2'd3) begin
                        state <= S_BRAM_KERNEL;
                        bram_delay <= 0;   
                    end    
                end
                S_LOAD_KERNEL: begin
                    // Load one row of kernel weights
                    for (c = 0; c < IMG_W; c = c + 1)
                        row_weight_vals[c] <= kernelbuf[c];
                    for (c = IMG_W; c < GRID_COLS; c = c + 1)
                        row_weight_vals[c] <= 0;
                    tag_row <= r[3:0];
                    valid_y <= 1;
                    state <= S_WAIT_KERNEL;
                end
                S_WAIT_KERNEL: begin
                    valid_y <= 0;
                    if (r < IMG_H-1) begin
                        r <= r + 1;
                        state <= S_LOAD_KERNEL;
                    end else begin
                        r <= 0;
                        state <= S_IMAGE_ROW;
                    end
                end
                S_IMAGE_ROW: begin
                    for (c = 0; c < IMG_W; c = c + 1) begin
                        image_val_vec[c] <= buffer[c];
                        valid_x_vec[c] <= 1;
                    end
                    for (c = IMG_W; c < GRID_COLS; c = c + 1) begin
                        image_val_vec[c] <= 0;
                        valid_x_vec[c] <= 0;
                    end
                    state <= S_PSUM_SUM;
                end
                
                S_PSUM_SUM: begin
                    resultsincopy <= tree_sum;
                    $display("Final 14-way Q7.8 sum: %d (hex: %h)", tree_sum, tree_sum);
                    state <= S_BRAM_WRITE;
                end
                    
                S_BRAM_WRITE: begin
                    if(!delay_active) begin
                        resultsaddr <= idx2;
                        idx2 <= idx2 + 1;
                        delay_active <= 1'b1;
                        state <= S_BRAM_WWAIT;
                        $display("Writing result to BRAM: addr=%d, data=%h", idx2, resultsincopy);
                    end
                    else if(delay_active) begin
                        resultsin <= resultsincopy;
                        delay_active <= 0;
                        state <= S_DONE;
                    end
                end
                S_BRAM_WWAIT: begin
                    bram_delay <= bram_delay + 1;
                    if(bram_delay == 2'd3) begin
                        state <= S_BRAM_WRITE;
                        index0 <= 1'b0;
                        bram_delay <= 0;   
                    end                  
                end
                S_DONE: begin
                    idx3 <= idx3 + 1;
                    if(idx3 > 16'd36)
                        state <= S_IDLE;
                    else if(idx3 < 16'd36)
                        state <= S_BRAM_LOAD;
                end
                S_IDLE: begin
                    // Show a pattern on LEDs to indicate IDLE state
                    LED <= resultsout;
                    if (btn_edge && result_read_index < 36) begin
                        resultsaddr <= result_read_index;
                        result_delay_counter <= 0;
                        next_flag <= 1; 
                        state <= S_RESULT_DELAY;
                    end
                    
                    if (btn_prev && result_read_index > 0) begin
                        result_read_index <= result_read_index - 1;
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
                    // Display the result on LEDs
                    LED <= resultsout;
                    
                    if (!btn_edge && !btn_prev && next_flag) begin
                        result_read_index <= result_read_index + 1;
                        next_flag <= 0;
                        state <= S_IDLE;
                    end
                    
                    if (!btn_prev && btn_edge && next_flag == 0) begin
                        resultsaddr <= result_read_index - 1;
                        state <= S_IDLE;
                    end
                end
            
                default: state <= S_DONE;
            endcase
        end
    end

endmodule

module display_controller(
    input clk,
    input [3:0] in3, in2, in1, in0,
    output [6:0]seg, logic dp,
    output [3:0] an
);

    localparam N = 18;

    logic [N-1:0] count = {N{1'b0}};
    always@ (posedge clk)
        count <= count + 1;

    logic [4:0]digit_val;

    logic [3:0]digit_en;
    always@ (*)

    begin
        digit_en = 4'b1111;
        digit_val = in0;

        case(count[N-1:N-2])

        2'b00 :	//select first 7Seg.

        begin
            digit_val = {1'b0, in0};
            digit_en = 4'b1110;
        end

        2'b01:	//select second 7Seg.

        begin
            digit_val = {1'b0, in1};
            digit_en = 4'b1101;
        end

        2'b10:	//select third 7Seg.

        begin
            digit_val = {1'b0, in2};
            digit_en = 4'b1011;
        end

        2'b11:	//select forth 7Seg.

        begin
            digit_val = {1'b0, in3};
            digit_en = 4'b0111;
        end
        endcase
    end

    //Convert digit number to LED vector. LEDs are active low.

    logic [6:0] sseg_LEDs;
    always @(*)
    begin
        sseg_LEDs = 7'b1111111; //default
        case( digit_val)
        5'd0 : sseg_LEDs = 7'b1000000; //to display 0
        5'd1 : sseg_LEDs = 7'b1111001; //to display 1
        5'd2 : sseg_LEDs = 7'b0100100; //to display 2
        5'd3 : sseg_LEDs = 7'b0110000; //to display 3
        5'd4 : sseg_LEDs = 7'b0011001; //to display 4
        5'd5 : sseg_LEDs = 7'b0010010; //to display 5
        5'd6 : sseg_LEDs = 7'b0000010; //to display 6
        5'd7 : sseg_LEDs = 7'b1111000; //to display 7
        5'd8 : sseg_LEDs = 7'b0000000; //to display 8
        5'd9 : sseg_LEDs = 7'b0010000; //to display 9
        5'd10: sseg_LEDs = 7'b0001000; //to display a
        5'd11: sseg_LEDs = 7'b0000011; //to display b
        5'd12: sseg_LEDs = 7'b1000110; //to display c
        5'd13: sseg_LEDs = 7'b0100001; //to display d
        5'd14: sseg_LEDs = 7'b0000110; //to display e
        5'd15: sseg_LEDs = 7'b0001110; //to display f
        5'd16: sseg_LEDs = 7'b0110111; //to display "="
        default : sseg_LEDs = 7'b0111111; //dash 
        endcase
    end

    assign an = digit_en;

    assign seg = sseg_LEDs;
    assign dp = 1'b1; //turn dp off

endmodule

module pulse_controller(
    input CLK, sw_input, clear,
    output reg clk_pulse
);

    reg [2:0] state, nextstate;
    reg [27:0] CNT; 
    wire cnt_zero; 

    always @ (posedge CLK, posedge clear)
        if(clear)
            state <=3'b000;
        else
            state <= nextstate;

    always @ (sw_input, state, cnt_zero)
        case (state)
            3'b000: begin if (sw_input) nextstate = 3'b001; 
                        else nextstate = 3'b000; clk_pulse = 0; end	     
            3'b001: begin nextstate = 3'b010; clk_pulse = 1; end
            3'b010: begin if (cnt_zero) nextstate = 3'b011; 
                        else nextstate = 3'b010; clk_pulse = 1; end
            3'b011: begin if (sw_input) nextstate = 3'b011; 
                        else nextstate = 3'b100; clk_pulse = 0; end
            3'b100: begin if (cnt_zero) nextstate = 3'b000; 
                        else nextstate = 3'b100; clk_pulse = 0; end
            default: begin nextstate = 3'b000; clk_pulse = 0; end
        endcase

    always @(posedge CLK)
        case(state)
            3'b001: CNT <= 1000000;
            3'b010: CNT <= CNT-1;
            3'b011: CNT <= 1000000;
            3'b100: CNT <= CNT-1;
        endcase

    //  reduction operator |CNT gives the OR of all bits in the CNT register	
    assign cnt_zero = ~|CNT;

endmodule







