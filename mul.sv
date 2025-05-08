module mul (
    input  logic signed [15:0] a, // Q7.8
    input  logic signed [15:0] b, // Q7.8
    output logic signed [15:0] p  // Q7.8 result
);
    logic signed [31:0] product_full;

    always_comb begin
        product_full = a * b;        // Q14.16
        p = product_full[23:8];      // Shift right by 8 to return to Q7.8
    end
endmodule
