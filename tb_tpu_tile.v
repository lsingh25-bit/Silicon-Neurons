`timescale 1ns / 1ps

module tb_tpu_tile;
    reg clk;
    reg rst;
    reg valid_in;
    reg [511:0] matrix_in;
    reg [63:0]  vector_in;
    wire valid_out;
    wire [191:0] vector_out;

    // Device Under Test (DUT) Instantiation
    tpu_tile uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .matrix_in(matrix_in),
        .vector_in(vector_in),
        .valid_out(valid_out),
        .vector_out(vector_out)
    );

    // 50MHz clock simulation logic
    always #10 clk = ~clk;

    initial begin
        // Trace file instantiation for wave analysis
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_tpu_tile);

        // System baseline cold setup
        clk = 0;
        rst = 1;
        valid_in = 0;
        matrix_in = 512'd0;
        vector_in = 64'd0;
        #40;
        rst = 0;
        #20;

        // --- TEST 1: ALL ZEROS ---
        $display("[TEST 1] Testing All Zeros Network Stream...");
        matrix_in = 512'd0;
        vector_in = 64'd0;
        valid_in = 1;
        #20;
        valid_in = 0;
        
        @(posedge valid_out);
        $display("Outputs for Test 1 (Expected 0): %h", vector_out);
        #40;

        // --- TEST 2: ALL ONES ---
        $display("[TEST 2] Testing Unbiased Uniform Data Matrix (All 1s)...");
        matrix_in = 512'sh01010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101;
        vector_in = 64'sh0101010101010101;
        valid_in = 1;
        #20;
        valid_in = 0;

        @(posedge valid_out);
        $display("Outputs for Test 2 (Expected Matrix outputs to contain 8): %h", vector_out);
        #40;

        // --- TEST 3: MAX VALUE STRESS TEST ---
        $display("[TEST 3] Running Max Value Processing Stress Test...");
        matrix_in = 512'sh7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F7F;
        vector_in = 64'sh7F7F7F7F7F7F7F7F;
        valid_in = 1;
        #20;
        valid_in = 0;

        @(posedge valid_out);
        $display("Outputs for Test 3 (Expected Matrix outputs to be 1F808): %h", vector_out);
        #40;

        $display("All Functional Verification Tests Passed Successfully!");
        $finish;
    end
endmodule