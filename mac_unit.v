`timescale 1ns / 1ps

module mac_unit (
    input clk,
    input rst,
    input signed [7:0] a,         
    input signed [7:0] b,         
    output reg signed [15:0] prod
);


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            prod <= 16'sd0;
        end else begin
            prod <= a * b; 
        end
    end

endmodule
