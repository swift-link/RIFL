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
module rst_cntrl (
    input logic rst,
    input logic wr_clk,
    input logic rd_clk,
    output logic wr_rst = 1'b0,
    output logic rd_rst = 1'b0
);
    logic wr_rst_request, rd_rst_request;
    logic wr_rst_rd_synced, rd_rst_wr_synced;

    sync_reset # (
        .N_STAGE(4)
    ) u_sync_reset_wr (
    	.clk        (wr_clk),
        .rst_in     (rst),
        .rst_out    (wr_rst_request)
    );

    sync_reset # (
        .N_STAGE(4)
    ) u_sync_reset_rd (
    	.clk        (rd_clk),
        .rst_in     (rst),
        .rst_out    (rd_rst_request)
    );

    sync_reset # (
        .N_STAGE(6)
    ) u_sync_reset_rd2wr (
    	.clk        (wr_clk),
        .rst_in     (rd_rst),
        .rst_out    (rd_rst_wr_synced)
    );

    sync_reset # (
        .N_STAGE(6)
    ) u_sync_reset_wr2rd (
    	.clk        (rd_clk),
        .rst_in     (wr_rst),
        .rst_out    (wr_rst_rd_synced)
    );

    always_ff @(posedge wr_clk) begin
        if (wr_rst_request)
            wr_rst <= 1'b1;
        else if (rd_rst_wr_synced)
            wr_rst <= 1'b0;
    end

    always_ff @(posedge rd_clk) begin
        if (rd_rst_request)
            rd_rst <= 1'b1;
        else if (wr_rst_rd_synced)
            rd_rst <= 1'b0;
    end

endmodule
