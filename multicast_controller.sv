module MulticastController (
    input  logic [15:0] in_val,     // input data value
    input  logic [3:0]  in_tag,     // tag for routing (ID of target)
    input  logic        valid,      // input is valid
    input  logic [3:0]  cfg_id,     // this PE's configured ID

    output logic        en,         // enable signal if match
    output logic [15:0] out_val     // forwarded value (always in_val)
);

    assign en      = valid && (in_tag == cfg_id);
    assign out_val = in_val;

endmodule