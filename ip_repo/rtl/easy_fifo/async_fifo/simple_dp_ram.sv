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
`timescale 1ns/1ps
module simple_dp_ram #
(
    parameter int DWIDTH = 64,
    parameter int DEPTH = 16
)
(
    input logic wr_clk,
    input logic [DWIDTH-1:0] wr_data,
    input logic [$clog2(DEPTH)-1:0] wr_addr,
    input logic wr_en,
    input logic [$clog2(DEPTH)-1:0] rd_addr,
    output logic [DWIDTH-1:0] rd_data
);
    logic [DWIDTH-1:0] mem_int[DEPTH-1:0];
    always_ff @(posedge wr_clk) begin
        if (wr_en) mem_int[wr_addr] <= wr_data;
    end

    assign rd_data = mem_int[rd_addr];
endmodule