`timescale 1ns / 1ps

module tpu_tile (
    input clk,
    input rst,
    input valid_in,
    input signed [511:0] matrix_in,       // 8x8 flattened signed matrix
    input signed [63:0]  vector_in,       // 8-element signed vector
    output reg valid_out,
    output reg signed [191:0] vector_out  // 8 packed 24-bit outputs
);

    // Control Path: 3-cycle shift register to match execution latency
    reg valid_p1;
    reg valid_p2;
    reg valid_p3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_p1  <= 1'b0;
            valid_p2  <= 1'b0;
            valid_p3  <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_p1  <= valid_in;
            valid_p2  <= valid_p1;
            valid_p3  <= valid_p2;
            valid_out <= valid_p3; 
        end
    end

    // Explicitly slicing input vector to avoid Icarus indexing bugs
    wire signed [7:0] v0 = vector_in[7:0];
    wire signed [7:0] v1 = vector_in[15:8];
    wire signed [7:0] v2 = vector_in[23:16];
    wire signed [7:0] v3 = vector_in[31:24];
    wire signed [7:0] v4 = vector_in[39:32];
    wire signed [7:0] v5 = vector_in[47:40];
    wire signed [7:0] v6 = vector_in[55:48];
    wire signed [7:0] v7 = vector_in[63:56];

    // Data Path: 8 parallel computing rows (Engines)

    // --- ROW 0 ---
    wire signed [15:0] p0_0, p0_1, p0_2, p0_3, p0_4, p0_5, p0_6, p0_7;
    mac_unit mu0_0(clk, rst, matrix_in[7:0],     v0, p0_0);
    mac_unit mu0_1(clk, rst, matrix_in[15:8],    v1, p0_1);
    mac_unit mu0_2(clk, rst, matrix_in[23:16],   v2, p0_2);
    mac_unit mu0_3(clk, rst, matrix_in[31:24],   v3, p0_3);
    mac_unit mu0_4(clk, rst, matrix_in[39:32],   v4, p0_4);
    mac_unit mu0_5(clk, rst, matrix_in[47:40],   v5, p0_5);
    mac_unit mu0_6(clk, rst, matrix_in[55:48],   v6, p0_6);
    mac_unit mu0_7(clk, rst, matrix_in[63:56],   v7, p0_7);
    
    // Stage 2 pipeline registers for balanced adder tree
    reg signed [17:0] s0_L2_L, s0_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) begin s0_L2_L <= 18'd0; s0_L2_R <= 18'd0; end
        else begin s0_L2_L <= (p0_0 + p0_1) + (p0_2 + p0_3); s0_L2_R <= (p0_4 + p0_5) + (p0_6 + p0_7); end
    end
    
    // Stage 3 execution: Final summation and integrated ReLU activation
    wire signed [18:0] f0_sum = s0_L2_L + s0_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) vector_out[23:0] <= 24'd0;
        else vector_out[23:0] <= (f0_sum[18] == 1'b1) ? 24'd0 : {{5{f0_sum[18]}}, f0_sum};
    end

    // --- ROW 1 ---
    wire signed [15:0] p1_0, p1_1, p1_2, p1_3, p1_4, p1_5, p1_6, p1_7;
    mac_unit mu1_0(clk, rst, matrix_in[71:64],   v0, p1_0);
    mac_unit mu1_1(clk, rst, matrix_in[79:72],   v1, p1_1);
    mac_unit mu1_2(clk, rst, matrix_in[87:80],   v2, p1_2);
    mac_unit mu1_3(clk, rst, matrix_in[95:88],   v3, p1_3);
    mac_unit mu1_4(clk, rst, matrix_in[103:96],  v4, p1_4);
    mac_unit mu1_5(clk, rst, matrix_in[111:104], v5, p1_5);
    mac_unit mu1_6(clk, rst, matrix_in[119:112], v6, p1_6);
    mac_unit mu1_7(clk, rst, matrix_in[127:120], v7, p1_7);
    
    reg signed [17:0] s1_L2_L, s1_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) begin s1_L2_L <= 18'd0; s1_L2_R <= 18'd0; end
        else begin s1_L2_L <= (p1_0 + p1_1) + (p1_2 + p1_3); s1_L2_R <= (p1_4 + p1_5) + (p1_6 + p1_7); end
    end
    
    wire signed [18:0] f1_sum = s1_L2_L + s1_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) vector_out[47:24] <= 24'd0;
        else vector_out[47:24] <= (f1_sum[18] == 1'b1) ? 24'd0 : {{5{f1_sum[18]}}, f1_sum};
    end

    // --- ROW 2 ---
    wire signed [15:0] p2_0, p2_1, p2_2, p2_3, p2_4, p2_5, p2_6, p2_7;
    mac_unit mu2_0(clk, rst, matrix_in[135:128], v0, p2_0);
    mac_unit mu2_1(clk, rst, matrix_in[143:136], v1, p2_1);
    mac_unit mu2_2(clk, rst, matrix_in[151:144], v2, p2_2);
    mac_unit mu2_3(clk, rst, matrix_in[159:152], v3, p2_3);
    mac_unit mu2_4(clk, rst, matrix_in[167:160], v4, p2_4);
    mac_unit mu2_5(clk, rst, matrix_in[175:168], v5, p2_5);
    mac_unit mu2_6(clk, rst, matrix_in[183:176], v6, p2_6);
    mac_unit mu2_7(clk, rst, matrix_in[191:184], v7, p2_7);
    
    reg signed [17:0] s2_L2_L, s2_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) begin s2_L2_L <= 18'd0; s2_L2_R <= 18'd0; end
        else begin s2_L2_L <= (p2_0 + p2_1) + (p2_2 + p2_3); s2_L2_R <= (p2_4 + p2_5) + (p2_6 + p2_7); end
    end
    
    wire signed [18:0] f2_sum = s2_L2_L + s2_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) vector_out[71:48] <= 24'd0;
        else vector_out[71:48] <= (f2_sum[18] == 1'b1) ? 24'd0 : {{5{f2_sum[18]}}, f2_sum};
    end

    // --- ROW 3 ---
    wire signed [15:0] p3_0, p3_1, p3_2, p3_3, p3_4, p3_5, p3_6, p3_7;
    mac_unit mu3_0(clk, rst, matrix_in[199:192], v0, p3_0);
    mac_unit mu3_1(clk, rst, matrix_in[207:200], v1, p3_1);
    mac_unit mu3_2(clk, rst, matrix_in[215:208], v2, p3_2);
    mac_unit mu3_3(clk, rst, matrix_in[223:216], v3, p3_3);
    mac_unit mu3_4(clk, rst, matrix_in[231:224], v4, p3_4);
    mac_unit mu3_5(clk, rst, matrix_in[239:232], v5, p3_5);
    mac_unit mu3_6(clk, rst, matrix_in[247:240], v6, p3_6);
    mac_unit mu3_7(clk, rst, matrix_in[255:248], v7, p3_7);
    
    reg signed [17:0] s3_L2_L, s3_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) begin s3_L2_L <= 18'd0; s3_L2_R <= 18'd0; end
        else begin s3_L2_L <= (p3_0 + p3_1) + (p3_2 + p3_3); s3_L2_R <= (p3_4 + p3_5) + (p3_6 + p3_7); end
    end
    
    wire signed [18:0] f3_sum = s3_L2_L + s3_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) vector_out[95:72] <= 24'd0;
        else vector_out[95:72] <= (f3_sum[18] == 1'b1) ? 24'd0 : {{5{f3_sum[18]}}, f3_sum};
    end

    // --- ROW 4 ---
    wire signed [15:0] p4_0, p4_1, p4_2, p4_3, p4_4, p4_5, p4_6, p4_7;
    mac_unit mu4_0(clk, rst, matrix_in[263:256], v0, p4_0);
    mac_unit mu4_1(clk, rst, matrix_in[271:264], v1, p4_1);
    mac_unit mu4_2(clk, rst, matrix_in[279:272], v2, p4_2);
    mac_unit mu4_3(clk, rst, matrix_in[287:280], v3, p4_3);
    mac_unit mu4_4(clk, rst, matrix_in[295:288], v4, p4_4);
    mac_unit mu4_5(clk, rst, matrix_in[303:296], v5, p4_5);
    mac_unit mu4_6(clk, rst, matrix_in[311:304], v6, p4_6);
    mac_unit mu4_7(clk, rst, matrix_in[319:312], v7, p4_7);
    
    reg signed [17:0] s4_L2_L, s4_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) begin s4_L2_L <= 18'd0; s4_L2_R <= 18'd0; end
        else begin s4_L2_L <= (p4_0 + p4_1) + (p4_2 + p4_3); s4_L2_R <= (p4_4 + p4_5) + (p4_6 + p4_7); end
    end
    
    wire signed [18:0] f4_sum = s4_L2_L + s4_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) vector_out[119:96] <= 24'd0;
        else vector_out[119:96] <= (f4_sum[18] == 1'b1) ? 24'd0 : {{5{f4_sum[18]}}, f4_sum};
    end

    // --- ROW 5 ---
    wire signed [15:0] p5_0, p5_1, p5_2, p5_3, p5_4, p5_5, p5_6, p5_7;
    mac_unit mu5_0(clk, rst, matrix_in[327:320], v0, p5_0);
    mac_unit mu5_1(clk, rst, matrix_in[335:328], v1, p5_1);
    mac_unit mu5_2(clk, rst, matrix_in[343:336], v2, p5_2);
    mac_unit mu5_3(clk, rst, matrix_in[351:344], v3, p5_3);
    mac_unit mu5_4(clk, rst, matrix_in[359:352], v4, p5_4);
    mac_unit mu5_5(clk, rst, matrix_in[367:360], v5, p5_5);
    mac_unit mu5_6(clk, rst, matrix_in[375:368], v6, p5_6);
    mac_unit mu5_7(clk, rst, matrix_in[383:376], v7, p5_7);
    
    reg signed [17:0] s5_L2_L, s5_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) begin s5_L2_L <= 18'd0; s5_L2_R <= 18'd0; end
        else begin s5_L2_L <= (p5_0 + p5_1) + (p5_2 + p5_3); s5_L2_R <= (p5_4 + p5_5) + (p5_6 + p5_7); end
    end
    
    wire signed [18:0] f5_sum = s5_L2_L + s5_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) vector_out[143:120] <= 24'd0;
        else vector_out[143:120] <= (f5_sum[18] == 1'b1) ? 24'd0 : {{5{f5_sum[18]}}, f5_sum};
    end

    // --- ROW 6 ---
    wire signed [15:0] p6_0, p6_1, p6_2, p6_3, p6_4, p6_5, p6_6, p6_7;
    mac_unit mu6_0(clk, rst, matrix_in[391:384], v0, p6_0);
    mac_unit mu6_1(clk, rst, matrix_in[399:392], v1, p6_1);
    mac_unit mu6_2(clk, rst, matrix_in[407:400], v2, p6_2);
    mac_unit mu6_3(clk, rst, matrix_in[415:408], v3, p6_3);
    mac_unit mu6_4(clk, rst, matrix_in[423:416], v4, p6_4);
    mac_unit mu6_5(clk, rst, matrix_in[431:424], v5, p6_5);
    mac_unit mu6_6(clk, rst, matrix_in[439:432], v6, p6_6);
    mac_unit mu6_7(clk, rst, matrix_in[447:440], v7, p6_7);
    
    reg signed [17:0] s6_L2_L, s6_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) begin s6_L2_L <= 18'd0; s6_L2_R <= 18'd0; end
        else begin s6_L2_L <= (p6_0 + p6_1) + (p6_2 + p6_3); s6_L2_R <= (p6_4 + p6_5) + (p6_6 + p6_7); end
    end
    
    wire signed [18:0] f6_sum = s6_L2_L + s6_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) vector_out[167:144] <= 24'd0;
        else vector_out[167:144] <= (f6_sum[18] == 1'b1) ? 24'd0 : {{5{f6_sum[18]}}, f6_sum};
    end

    // --- ROW 7 ---
    wire signed [15:0] p7_0, p7_1, p7_2, p7_3, p7_4, p7_5, p7_6, p7_7;
    mac_unit mu7_0(clk, rst, matrix_in[455:448], v0, p7_0);
    mac_unit mu7_1(clk, rst, matrix_in[463:456], v1, p7_1);
    mac_unit mu7_2(clk, rst, matrix_in[471:464], v2, p7_2);
    mac_unit mu7_3(clk, rst, matrix_in[479:472], v3, p7_3);
    mac_unit mu7_4(clk, rst, matrix_in[487:480], v4, p7_4);
    mac_unit mu7_5(clk, rst, matrix_in[495:488], v5, p7_5);
    mac_unit mu7_6(clk, rst, matrix_in[503:496], v6, p7_6);
    mac_unit mu7_7(clk, rst, matrix_in[511:504], v7, p7_7);
    
    reg signed [17:0] s7_L2_L, s7_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) begin s7_L2_L <= 18'd0; s7_L2_R <= 18'd0; end
        else begin s7_L2_L <= (p7_0 + p7_1) + (p7_2 + p7_3); s7_L2_R <= (p7_4 + p7_5) + (p7_6 + p7_7); end
    end
    
    wire signed [18:0] f7_sum = s7_L2_L + s7_L2_R;
    always @(posedge clk or posedge rst) begin
        if (rst) vector_out[191:168] <= 24'd0;
        else vector_out[191:168] <= (f7_sum[18] == 1'b1) ? 24'd0 : {{5{f7_sum[18]}}, f7_sum};
    end

endmodule