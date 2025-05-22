module adder_tree_14 (
    input  logic [15:0] in [0:13],
    output logic [15:0] sum
);

    // Level 1
    wire [15:0] s0, s1, s2, s3, s4, s5, s6;
    add a0 (.a(in[0]),  .b(in[1]),  .s(s0));
    add a1 (.a(in[2]),  .b(in[3]),  .s(s1));
    add a2 (.a(in[4]),  .b(in[5]),  .s(s2));
    add a3 (.a(in[6]),  .b(in[7]),  .s(s3));
    add a4 (.a(in[8]),  .b(in[9]),  .s(s4));
    add a5 (.a(in[10]), .b(in[11]), .s(s5));
    add a6 (.a(in[12]), .b(in[13]), .s(s6));

    // Level 2
    wire  [15:0] s7, s8, s9, s10;
    add a7 (.a(s0),  .b(s1),  .s(s7));
    add a8 (.a(s2),  .b(s3),  .s(s8));
    add a9 (.a(s4),  .b(s5),  .s(s9));
    add a10(.a(s6),  .b(16'sd0), .s(s10)); // Padding

    // Level 3
    wire  [15:0] s11, s12;
    add a11(.a(s7),  .b(s8),  .s(s11));
    add a12(.a(s9),  .b(s10), .s(s12));

    // Final sum
    add a13(.a(s11), .b(s12), .s(sum));

endmodule
