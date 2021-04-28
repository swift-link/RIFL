//MIT License
//
//Author: Qianfeng (Clark) Shen;Contact: qianfeng.shen@gmail.com
//
//Copyright (c) 2021 swift-link
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
`timescale 1ns / 1ps
`define GET_STATE_sub1(val) (val+64'h9e3779b97f4a7c15)
`define GET_STATE_sub2(val) ((`GET_STATE_sub1(val) ^ (`GET_STATE_sub1(val) >> 30)) * 64'hbf58476d1ce4e5b9)
`define GET_STATE_sub3(val) ((`GET_STATE_sub2(val) ^ (`GET_STATE_sub2(val) >> 27)) * 64'h94d049bb133111eb)
`define GET_STATE(val) (`GET_STATE_sub3(val) ^ (`GET_STATE_sub3(val) >> 31))
`define A 64'd19911102
`define B 64'h9e3779b97f4a7c15

module rifl_err_inj #
(
    parameter int DWIDTH = 64,
    parameter bit [63:0] SEED = 64'b0
)
(
    input logic clk,
    input logic [63:0] threshold,
    output logic [DWIDTH-1:0] err_vec
);
    logic [63:0] rand64[DWIDTH-1:0];

    always_ff @(posedge clk) begin
        for (int i = 0; i < DWIDTH; i++) begin
            err_vec[i] <= rand64[i] < threshold ? 1'b1 : 1'b0;
        end
    end

    genvar i;
    for (i = 0; i < DWIDTH; i++) begin
        rifl_xoshiro128ss #(
            .S0 (`GET_STATE(SEED+(`A+`B*(i*2)))),
            .S1 (`GET_STATE(SEED+(`A+`B*(i*2+1))))
        ) u_xoshiro128ss(
        	.clk    (clk),
            .rand64 (rand64[i])
        );
    end

endmodule
