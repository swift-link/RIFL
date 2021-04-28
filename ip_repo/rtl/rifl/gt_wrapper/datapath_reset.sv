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
`timescale 1ns/1ps
module datapath_reset #
(
    parameter int COUNTER_WIDTH = 16
)
(
    input logic clk,
    input logic rst,
    input logic channel_good,
    output logic rst_out
);
    logic [COUNTER_WIDTH-1:0] reset_counter = {COUNTER_WIDTH{1'b0}};

    always_ff @(posedge clk) begin
        if (rst) begin
            rst_out <= 1'b0;
            reset_counter <= {COUNTER_WIDTH{1'b0}};
        end
        else if (channel_good) begin
            rst_out <= 1'b0;
            reset_counter <= {COUNTER_WIDTH{1'b0}};
        end
        else begin
            rst_out <= reset_counter[COUNTER_WIDTH-1];
            if (reset_counter[COUNTER_WIDTH-1])
                reset_counter <= {COUNTER_WIDTH{1'b0}};
            else
                reset_counter <= reset_counter + 1'd1;
        end
    end
endmodule
