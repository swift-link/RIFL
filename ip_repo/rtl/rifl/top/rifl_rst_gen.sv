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
module rifl_rst_gen (
    input logic init_clk,
    input logic tx_frame_clk,
    input logic rx_frame_clk,
    input logic rst,
    input logic gt_rst,
    output logic tx_frame_rst,
    output logic rx_frame_rst,
    output logic gt_init_rst
);
    sync_reset u_sync_gt_init(
    	.clk     (init_clk),
        .rst_in  (gt_rst),
        .rst_out (gt_init_rst)
    );
    sync_reset u_sync_tx_frame(
    	.clk     (tx_frame_clk),
        .rst_in  (rst),
        .rst_out (tx_frame_rst)
    );
    sync_reset u_sync_rx_frame(
        .clk     (rx_frame_clk),
        .rst_in  (rst),
        .rst_out (rx_frame_rst)
    );
endmodule