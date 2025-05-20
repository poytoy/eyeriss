`timescale 1ns/1ps

module pe_inst (
    input  logic        clk,
    input  logic        rst,
    input  logic signed [15:0] image_val,   // Q7.8
    input  logic signed [15:0] weight_val,  // Q7.8
    input  logic        image_en,
    input  logic        weight_en,
    input  logic signed [15:0] psum_in,     // Q7.8
    output logic signed [15:0] psum_out     // Q7.8
);

    logic signed [15:0] weight_reg;
    logic signed [15:0] mul_out;
    logic signed [15:0] add_out;

    // Register weight
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            weight_reg <= 16'sd0;
        else if (weight_en)
            weight_reg <= weight_val;
    end

    // Instantiate Q7.8 multiplier
    mul mul_inst (
        .a(image_val),
        .b(weight_reg),
        .p(mul_out)
    );

    // Instantiate Q7.8 adder
    add add_inst (
        .a(mul_out),
        .b(psum_in),
        .s(add_out)
    );

    // Output logic
    always_comb begin
        if (image_en)
            psum_out = add_out;
        else
            psum_out = psum_in;
    end

    // Debug display logic (only on positive clock edge)
    always_ff @(posedge clk) begin
        if (psum_out) begin
            $display("PE Calculation:");
            $display("  image_val  = %0d (Q7.8)", image_val);
            $display("  weight_reg = %0d (Q7.8)", weight_reg);
            $display("  mul_out    = %0d (Q7.8)", mul_out);
            $display("  psum_in    = %0d (Q7.8)", psum_in);
            $display("  psum_out   = %0d (Q7.8)", psum_out);
            $display("-------------------------------");
        end
    end

endmodule
