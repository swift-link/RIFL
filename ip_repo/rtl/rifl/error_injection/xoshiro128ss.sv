`timescale 1ns / 1ps
`define ROTL(X,K) ({X << K} | {X >> (64-K)})
module xoshiro128ss #
(
    parameter bit [63:0] S0 = 64'd1,
    parameter bit [63:0] S1 = 64'd2
)
(
    input logic clk,
    output logic [63:0] rand64
);
    logic [63:0] s0 = S0;
    logic [63:0] s1 = S1;

    logic [63:0] s0_new, s1_new;
    
    logic [63:0] s0m5;
    logic [63:0] s0m5_rotl;
            
    always_comb begin
        s0_new = s0;
        s1_new = s1;
        s1_new = s1_new ^ s0;
        s0_new = `ROTL(s0_new, 24) ^ s1_new ^ (s1_new << 16);
        s1_new = `ROTL(s1_new, 37);
    end

    always_ff @(posedge clk) begin
        s0m5 <= s0 * 5;
        s0m5_rotl <= `ROTL(s0m5,7);
        rand64 <= s0m5_rotl * 9;
        //rand64 <= `ROTL({s0*5},7)*9;
    end

    always_ff @(posedge clk) begin
        s0 <= s0_new;
        s1 <= s1_new;
    end
endmodule
