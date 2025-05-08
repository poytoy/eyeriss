module add(
    input  logic signed [15:0] a, // Q7.8
    input  logic signed [15:0] b, // Q7.8
    output logic signed [15:0] s  // Q7.8
);

    always_comb begin
        s = a + b;
    end
endmodule