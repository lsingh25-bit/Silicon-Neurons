`timescale 1ns / 1ps

module mac_unit (
    input clk,
    input rst,
    input signed [7:0] a,         // Matrix element (weight)
    input signed [7:0] b,         // Vector element (activation)
    output reg signed [15:0] prod // Synchronous product output
);

    // Stage 1 pipeline register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prod <= 16'sd0;
        end else begin
            prod <= a * b; 
        end
    end

endmodule