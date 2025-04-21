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
//keep psum_in for one more cycle
logic [31:0] psum_in_saved;
always_ff @(posedge clk or posedge rst) begin
            psum_in_saved <= psum_in;
            end 
always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            psum_out <= 0;
        end else if (image_en && weight_en) begin
            psum_out <= psum_in_saved + image_val * weight_val;
        end else begin
            psum_out <= psum_in; // ⬅️ Forward directly
        end
    end
always_ff @(posedge clk or posedge rst) begin

     // Debug display on every cycle
    if (image_en && weight_en) begin
    $display(" @%0t | MAC: %0d * %0d + %0d = %0d | image_en=%b weight_en=%b",
              $time, image_val, weight_val, psum_in, image_val * weight_val + psum_in,
             image_en, weight_en);
end else if (psum_in != 0 || psum_out != 0) begin
    $display(" @%0t | Forward: psum_in=%0d  psum_out=%0d",
              $time, psum_in, psum_out);
end
end 
endmodule
