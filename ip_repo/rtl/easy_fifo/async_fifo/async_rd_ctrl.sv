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
module async_rd_ctrl #
(
    parameter int DEPTH = 4
)
(
    input logic rst,
    input logic rd_clk,
    input logic rd_en,
    input logic [$clog2(DEPTH):0] wr_ptr_rsync,
    output logic [$clog2(DEPTH)-1:0] rd_addr,
    output logic [$clog2(DEPTH):0] rd_ptr,
    output logic rd_empty,
	output logic [$clog2(DEPTH):0] fifo_cnt_rd_synced = {($clog2(DEPTH)+1){1'b0}}
);
    localparam AWIDTH = $clog2(DEPTH);
    logic [AWIDTH:0] rd_ptr_bin;
    logic [AWIDTH:0] wr_ptr_rsync_bin;

    graycntr #(
        .SIZE (AWIDTH+1)
    ) u_graycntr (
    	.rst  (rst),
        .clk  (rd_clk),
        .inc  (rd_en&~rd_empty),
        .gray (rd_ptr)
    );
    
    gray2bin #(
        .SIZE (AWIDTH+1)
    ) u_gray2bin1 (
    	.gray (wr_ptr_rsync),
        .bin  (wr_ptr_rsync_bin)
    );
    gray2bin #(
        .SIZE (AWIDTH+1)
    ) u_gray2bin2 (
    	.gray (rd_ptr),
        .bin  (rd_ptr_bin)
    );

	always_ff @(posedge rd_clk) begin
		if (rst)
			fifo_cnt_rd_synced <= {($clog2(DEPTH)+1){1'b0}};
		else
			fifo_cnt_rd_synced <= wr_ptr_rsync_bin - rd_ptr_bin;
	end

    assign rd_empty = rd_ptr_bin == wr_ptr_rsync_bin;

    assign rd_addr = rd_ptr_bin[AWIDTH-1:0];
endmodule
