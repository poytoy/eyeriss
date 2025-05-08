module MulticastRouter #(
    parameter PE_COUNT = 9,  // 3x3 example
    parameter DATA_WIDTH = 16,
    parameter ID_WIDTH = 8
)(
    input  logic                      clk,
    input  logic                      rst,

    input  logic [DATA_WIDTH-1:0]     in_val,
    input  logic [ID_WIDTH-1:0]       tag_id,
    input  logic                      in_valid,

    input  logic [ID_WIDTH-1:0]       pe_ids [PE_COUNT-1:0], // assigned PE IDs

    output logic [DATA_WIDTH-1:0]     out_vals [PE_COUNT-1:0],
    output logic                      out_valids [PE_COUNT-1:0]
);

    genvar i;
    generate
        for (i = 0; i < PE_COUNT; i++) begin : PE_MATCH
            assign out_vals[i]    = in_val;
            assign out_valids[i]  = (in_valid && pe_ids[i] == tag_id);
        end
    endgenerate

endmodule
module RowVectorRouter #(
    parameter ROW_SIZE = 14,         // Number of PEs in a row
    parameter DATA_WIDTH = 16,
    parameter ID_WIDTH = 4
)(
    input  logic [DATA_WIDTH-1:0] in_vec [0:ROW_SIZE-1], // vector of weights
    input  logic [ID_WIDTH-1:0]   tag_row,               // target row ID
    input  logic                  in_valid,

    input  logic [ID_WIDTH-1:0]   my_row_id,             // this PE's row ID
    input  logic [ID_WIDTH-1:0]   my_col_id,             // this PE's col ID

    output logic [DATA_WIDTH-1:0] out_val,
    output logic                  out_valid
);

    assign out_val   = in_vec[my_col_id];
    assign out_valid = (in_valid && tag_row == my_row_id);

endmodule
