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
module async_fifo #
(
    parameter int DWIDTH = 64,
    parameter int DEPTH = 16
)
(
    input logic rst,
    input logic wr_rst,
    input logic rd_rst,
    input logic wr_clk,
    input logic rd_clk,
    input logic wr_en,
    input logic rd_en,
    input logic [DWIDTH-1:0] wr_data,
    output logic wr_full,
    output logic [DWIDTH-1:0] rd_data,
    output logic rd_empty,
	output logic [$clog2(DEPTH):0] fifo_cnt_wr_synced,
	output logic [$clog2(DEPTH):0] fifo_cnt_rd_synced
);
    logic [$clog2(DEPTH)-1:0] wr_addr, rd_addr;
    logic [$clog2(DEPTH):0] wr_ptr, rd_ptr, wr_ptr_rsync, rd_ptr_wsync;

    sync_signle_bit #(
        .SIZE      ($clog2(DEPTH)+1),
        .N_STAGE   (2),
        .INPUT_REG (0)
    ) u_sync_signle_bit1 (
    	.clk_in  (wr_clk),
        .clk_out (rd_clk),
        .rst     (rst),
        .din     (wr_ptr),
        .dout    (wr_ptr_rsync)
    );
    sync_signle_bit #(
        .SIZE      ($clog2(DEPTH)+1),
        .N_STAGE   (2),
        .INPUT_REG (0)
    ) u_sync_signle_bit2 (
    	.clk_in  (rd_clk),
        .clk_out (wr_clk),
        .rst     (rst),
        .din     (rd_ptr),
        .dout    (rd_ptr_wsync)
    );

    simple_dp_ram #(
        .DWIDTH (DWIDTH),
        .DEPTH  (DEPTH)
    ) u_simple_dp_ram (
        .*,
        .wr_en(wr_en&~wr_full)
    );

    async_rd_ctrl #(
        .DEPTH  (DEPTH)
    ) u_async_rd_ctrl (
        .*,
        .rst(rd_rst)
    );
    async_wr_ctrl #(
        .DEPTH  (DEPTH)
    ) u_async_wr_ctrl(
        .*,
        .rst(wr_rst)
    );

endmodule
