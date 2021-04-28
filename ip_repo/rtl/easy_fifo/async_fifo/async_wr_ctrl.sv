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
module async_wr_ctrl #
(
    parameter int DEPTH = 4
)
(
    input logic rst,
    input logic wr_clk,
    input logic wr_en,
    input logic [$clog2(DEPTH):0] rd_ptr_wsync,
    output logic [$clog2(DEPTH)-1:0] wr_addr,
    output logic [$clog2(DEPTH):0] wr_ptr,
    output logic wr_full = 1'b0,
	output logic [$clog2(DEPTH):0] fifo_cnt_wr_synced = {($clog2(DEPTH)+1){1'b0}}
);
    localparam AWIDTH = $clog2(DEPTH);
    logic [AWIDTH:0] wr_ptr_bin;
    logic [AWIDTH:0] rd_ptr_wsync_bin;

    graycntr #(
        .SIZE (AWIDTH+1)
    ) u_graycntr (
    	.rst  (rst),
        .clk  (wr_clk),
        .inc  (wr_en&~wr_full),
        .gray (wr_ptr)
    );
    
    gray2bin #(
        .SIZE (AWIDTH+1)
    ) u_gray2bin1 (
    	.gray (rd_ptr_wsync),
        .bin  (rd_ptr_wsync_bin)
    );
    gray2bin #(
        .SIZE (AWIDTH+1)
    ) u_gray2bin2 (
    	.gray (wr_ptr),
        .bin  (wr_ptr_bin)
    );


	always_ff @(posedge wr_clk) begin
		if (rst)
			fifo_cnt_wr_synced <= {($clog2(DEPTH)+1){1'b0}};
		else
			fifo_cnt_wr_synced <= wr_ptr_bin - rd_ptr_wsync_bin;
	end

    always_ff @(posedge wr_clk) begin
        if (rst) begin
            wr_full <= 1'b0;
        end
        else begin
            wr_full <= (wr_ptr_bin+(wr_en&~wr_full)) == {~rd_ptr_wsync_bin[AWIDTH],rd_ptr_wsync_bin[AWIDTH-1:0]};
        end
    end

    assign wr_addr = wr_ptr_bin[AWIDTH-1:0];
endmodule
