module pe (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] image_val,   // image activation
    input  logic        image_en,
    input  logic [15:0] weight_val,  // filter weight
    input  logic        weight_en,
    input  logic [31:0] psum_in,     // incoming partial sum
    output logic [31:0] psum_out     // output partial sum
);
 //IMPLEMENT
//very basic impl.
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        psum_out <= 0;
    end else if (image_en && weight_en) begin
        psum_out <= psum_in + image_val * weight_val;
    end else begin
        psum_out <= psum_in;
    end
end


endmodule
