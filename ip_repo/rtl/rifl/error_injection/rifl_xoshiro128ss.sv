//MIT License
//
//Author: Qianfeng (Clark) Shen
//Copyright (c) 2021 swift-link
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
`timescale 1ns / 1ps
`define ROTL(X,K) ({X << K} | {X >> (64-K)})
module rifl_xoshiro128ss #
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
    end

    always_ff @(posedge clk) begin
        s0 <= s0_new;
        s1 <= s1_new;
    end
endmodule
