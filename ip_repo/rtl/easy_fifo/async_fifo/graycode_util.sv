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
module graycntr #
(
    parameter int SIZE = 4
)
(
    input logic rst,
    input logic clk,
    input logic inc,
    output logic [SIZE-1:0] gray = {SIZE{1'b0}}
);
    logic [SIZE-1:0] bin;
    logic [SIZE-1:0] bin_reg = {SIZE{1'b0}};
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bin_reg <= {SIZE{1'b0}};
            gray <= {SIZE{1'b0}};
        end
        else begin
            bin_reg <= bin;
            gray <= (bin>>1) ^ bin;
        end
    end
    assign bin = bin_reg + inc;
endmodule

module gray2bin #
(
    parameter int SIZE = 4
)
(
    input logic [SIZE-1:0] gray,
    output logic [SIZE-1:0] bin
);
    genvar i;
    for (i=0; i<SIZE; i=i+1) begin
        assign bin[i] = ^(gray>>i);
    end
endmodule