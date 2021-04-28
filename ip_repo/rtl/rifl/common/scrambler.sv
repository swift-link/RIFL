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
//out[n]=in[n]^in[n-N1]^in[n-N2]
module scrambler # (
    parameter int DWIDTH = 64,
    parameter int N1 = 13,
    parameter int N2 = 33,
    parameter bit DIRECTION = 1'b0
)
(
    input logic [N2-1:0] scrambler_in,
    input logic [DWIDTH-1:0] data_in,
    output logic [DWIDTH-1:0] data_out,
    output logic [N2-1:0] scrambler_out
);
    logic [DWIDTH+N2-1:0] scrambler_wire;
    logic [DWIDTH-1:0] data_out_wire;

    assign scrambler_out = scrambler_wire[N2-1:0];
    assign data_out = data_in ^ scrambler_wire[DWIDTH-1+N2:N2] ^ scrambler_wire[DWIDTH-1+N1:N1];

    if (DIRECTION == 0)
        assign scrambler_wire = {scrambler_in,data_out};
    else
        assign scrambler_wire = {scrambler_in,data_in};
endmodule