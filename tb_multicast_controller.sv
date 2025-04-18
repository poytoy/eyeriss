`timescale 1ns/1ps

module tb_multicast_controller;

    logic [15:0] in_val;
    logic [3:0]  in_tag;
    logic        valid;
    logic [3:0]  cfg_id;

    logic        en;
    logic [15:0] out_val;

    // DUT
    MulticastController dut (
        .in_val(in_val),
        .in_tag(in_tag),
        .valid(valid),
        .cfg_id(cfg_id),
        .en(en),
        .out_val(out_val)
    );

    // Test sequence
    initial begin
        $display("=== MulticastController Test ===");
        $dumpfile("tb_multicast_controller.vcd");
        $dumpvars(0, tb_multicast_controller);

        // Case 1: valid = 0 → en must be 0
        in_val = 16'hDEAD;
        in_tag = 4'd2;
        cfg_id = 4'd2;
        valid  = 0;

        #1;
        assert(en == 0) else $fatal("❌ FAIL: en should be 0 when valid = 0");
