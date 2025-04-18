`timescale 1ns/1ps

module tb_multicast_router;

    parameter PE_COUNT    = 5;
    parameter DATA_WIDTH  = 16;
    parameter ID_WIDTH    = 4;

    // DUT signals
    logic clk, rst;
    logic [DATA_WIDTH-1:0] in_val;
    logic [ID_WIDTH-1:0]   tag_id;
    logic                  in_valid;

    logic [ID_WIDTH-1:0]   pe_ids     [PE_COUNT-1:0];
    logic [DATA_WIDTH-1:0] out_vals   [PE_COUNT-1:0];
    logic                  out_valids [PE_COUNT-1:0];

    // DUT instance
    MulticastRouter #(
        .PE_COUNT(PE_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .clk(clk), .rst(rst),
        .in_val(in_val),
        .tag_id(tag_id),
        .in_valid(in_valid),
        .pe_ids(pe_ids),
        .out_vals(out_vals),
        .out_valids(out_valids)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Test setup
    initial begin
        $display("=== MulticastRouter Test ===");
        $dumpfile("tb_multicast_router.vcd");
        $dumpvars(0, tb_multicast_router);

        // Setup PE IDs
        pe_ids[0] = 4'd0;
        pe_ids[1] = 4'd1;
        pe_ids[2] = 4'd2;
        pe_ids[3] = 4'd3;
        pe_ids[4] = 4'd4;

        rst      = 0;
        in_val   = 16'hBEEF;
        tag_id   = 4'd2;
        in_valid = 1;

        #10;

        // Check which PE received it
        for (int i = 0; i < PE_COUNT; i++) begin
            if (pe_ids[i] == tag_id) begin
                if (out_valids[i] !== 1 || out_vals[i] !== 16'hBEEF)
                    $display("❌ FAIL: PE[%0d] should be valid with value BEEF, got en=%0b, val=0x%h", i, out_valids[i], out_vals[i]);
                else
                    $display("✅ PASS: PE[%0d] received multicast", i);
            end else begin
                if (out_valids[i] !== 0 || out_vals[i] !== 16'hBEEF)
                    $display("❌ FAIL: PE[%0d] should be disabled but got en=%0b, val=0x%h", i, out_valids[i], out_vals[i]);
                else
                    $display("✅ PASS: PE[%0d] ignored multicast", i);
            end
        end

        $finish;
    end

endmodule
