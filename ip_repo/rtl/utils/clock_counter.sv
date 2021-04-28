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
module clock_counter #
(
    parameter int RATIO = 4
)
(
    input logic clk_slow,
    input logic clk_fast,
    output logic [$clog2(RATIO)-1:0] cnt = {$clog2(RATIO){1'b0}}
);
    logic slow_flag = 1'b0;
    logic fast_flag[RATIO-1:0];
    always_ff @(posedge clk_slow) begin
        slow_flag <= ~slow_flag;
    end
    always_ff @(posedge clk_fast) begin
        fast_flag[0] <= slow_flag;
        for (int i = 0; i < RATIO-1; i++)
            fast_flag[i+1] <= fast_flag[i];
    end
    always_ff @(posedge clk_fast) begin
        if (fast_flag[RATIO-1]^fast_flag[RATIO-2])
            cnt <= 'b0;
        else
            cnt <= cnt + 'b1;
    end
endmodule