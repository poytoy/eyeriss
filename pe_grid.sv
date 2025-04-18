module PE_Grid_12x14 (
    input  logic clk,
    input  logic rst,

    input  logic [15:0] image_val_in,
    input  logic [3:0]  tag_col,   // target column ID for image
    input  logic        valid_x,

    input  logic [15:0] weight_val_in,
    input  logic [3:0]  tag_row,   // target row ID for weight
    input  logic        valid_y,


    input  logic [31:0] psum_ins   [0:13],
    output logic [31:0] psum_outs  [0:13]
);
    //broadcast busses
    logic [15:0] x_vals[0:13]; // one per column
    logic        x_en  [0:13];

    logic [15:0] y_vals[0:11]; // one per row
    logic          y_en  [0:11];

    // Column id's
    logic [3:0] col_ids[0:13];
    logic [3:0] row_ids[0:11];

    genvar i;
    generate
        for (i = 0; i < 14; i++) assign col_ids[i] = i;
        for (i = 0; i < 12; i++) assign row_ids[i] = i;
    endgenerate

    MulticastRouter #(
        .PE_COUNT(12), .DATA_WIDTH(16), .ID_WIDTH(4)
    ) x_router (
        .clk(clk), .rst(rst),
        .in_val(weight_val_in),
        .tag_id(tag_row),
        .in_valid(valid_y),
        .pe_ids(row_ids),
        .out_vals(y_vals),
        .out_valids(y_en)
    );
    MulticastRouter #(
        .PE_COUNT(14), .DATA_WIDTH(16), .ID_WIDTH(4)
    ) y_router (
        .clk(clk), .rst(rst),
        .in_val(weight_val_in),
        .tag_id(tag_row),
        .in_valid(valid_y),
        .pe_ids(col_ids),
        .out_vals(y_vals),
        .out_valids(y_en)
    );
    //psum local connectiopns
    logic [31:0] psum_wires[0:12][0:13];
    // psum wires initiated.
    generate
        for (i = 0; i < 14; i++) assign psum_wires[12][i] = psum_ins[i];  // input to bottom row
        for (i = 0; i < 14; i++) assign psum_outs[i] = psum_wires[0][i];  // output from top row
    endgenerate
     // 2D PE Array
    genvar r, c;
    generate
        for (r = 0; r < 12; r++) begin: row_loop
            for (c = 0; c < 14; c++) begin: col_loop
                logic [15:0] image_wire, weight_wire;
                logic image_en, weight_en;
                // X multicast controller per PE (image)
                MulticastController ctrl_x (
                    .in_val(x_vals[c]),
                    .in_tag(tag_col),
                    .valid(valid_x),
                    .cfg_id(c),
                    .en(image_en),
                    .out_val(image_wire)
                );
                 // Y multicast controller per PE (weight)
                MulticastController ctrl_y (
                    .in_val(y_vals[r]),
                    .in_tag(tag_row),
                    .valid(valid_y),
                    .cfg_id(r),
                    .en(weight_en),
                    .out_val(weight_wire)
                );
                 // PE with vertical accumulation
                pe pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .image_val(image_wire),
                    .image_en(image_en),
                    .weight_val(weight_wire),
                    .weight_en(weight_en),
                    .psum_in(psum_wires[r+1][c]),
                    .psum_out(psum_wires[r][c])
                );
            end
        end
    endgenerate

endmodule
