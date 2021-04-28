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

module tx_dwidth_conv # (
   parameter int DWIDTH_IN = 256,
   parameter int DWIDTH_OUT = 64,
   parameter int CNT_WIDTH = 2
)
(
   input logic clk,
   input logic [CNT_WIDTH-1:0] clk_cnt,
   input logic [DWIDTH_IN-1:0] din,
   output logic [DWIDTH_OUT-1:0] dout,
   output logic sof_out = 1'b0
);
    if (DWIDTH_IN > DWIDTH_OUT) begin
        localparam int RATIO = DWIDTH_IN / DWIDTH_OUT;
        logic [DWIDTH_IN-1:0] din_reg = {DWIDTH_IN{1'b0}};
        always_ff @(posedge clk) begin
            if (clk_cnt == 'b0) begin
                din_reg <= din;
                sof_out <= 1'b1;
            end
            else begin
                din_reg <= din_reg << DWIDTH_OUT;
                sof_out <= 1'b0;
            end
        end
        assign dout = din_reg[DWIDTH_IN-1-:DWIDTH_OUT];
    end
    else begin
        assign dout = din;
        always_comb begin
            sof_out = 1'b1;
        end
    end
endmodule