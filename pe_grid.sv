// Top-level PE Grid with parallel column injection (no tag_col)
module PE_Grid_12x14 (
    input  logic clk,
    input  logic rst,

    input  logic [15:0] image_val_vec [0:13],   // One image value per column
    input  logic        valid_x_vec    [0:13],

    input  logic [15:0] row_weight_vals [0:13], // One weight per PE in the row
    input  logic [3:0]  tag_row,                // Which row to inject weights into
    input  logic        valid_y,

    input  logic [31:0] psum_ins   [0:13],
    output logic [31:0] psum_outs  [0:13]
);

    logic [31:0] psum_wires[0:12][0:13];

    genvar i;
    generate
        for (i = 0; i < 14; i++) begin
            assign psum_wires[12][i] = psum_ins[i];
            assign psum_outs[i]      = psum_wires[0][i];
        end
    endgenerate

    // Routers
    MulticastRouter #(
        .PE_COUNT(14), .DATA_WIDTH(16), .ID_WIDTH(4)
    ) x_router (
        .clk(clk), .rst(rst),
        .in_val(image_val_in),
        .tag_id(tag_col),            // fixed
        .in_valid(valid_x),
        .pe_ids(col_ids),
        .out_vals(x_vals),
        .out_valids(x_en)
    );

    genvar r, c;
    generate
        for (r = 0; r < 12; r++) begin: row_loop
            for (c = 0; c < 14; c++) begin: col_loop
            
                logic [3:0] row_id_logic = r;
                logic [3:0] col_id_logic = c;
            
                logic [15:0] image_wire, weight_wire;
                logic image_en, weight_en;

                // Image routing per column
                assign image_wire = image_val_vec[c];
                assign image_en   = valid_x_vec[c];

                // Row weight routing logic
                RowVectorRouter #(14, 16, 4) weight_router (
                    .in_vec(row_weight_vals),
                    .tag_row(tag_row),
                    .in_valid(valid_y),
                    .my_row_id(row_id_logic),
                    .my_col_id(col_id_logic),
                    .out_val(weight_wire),
                    .out_valid(weight_en)
                );

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
