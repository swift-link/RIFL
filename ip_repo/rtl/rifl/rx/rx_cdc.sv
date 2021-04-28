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
module rx_cdc (
    input logic tx_frame_clk,
    input logic rst,
    input logic pause_req_rx,
    input logic retrans_req_rx,
    input logic rx_aligned_rx,
    input logic rx_up_rx,
    input logic rx_error_rx,
    output logic pause_req_tx,
    output logic retrans_req_tx,
    output logic rx_aligned_tx,
    output logic rx_up_tx,
    output logic rx_error_tx   
);
    sync_signle_bit sync_pause(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (pause_req_rx),
        .dout    (pause_req_tx)
    );
    sync_signle_bit sync_retrans(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (retrans_req_rx),
        .dout    (retrans_req_tx)
    );
    sync_signle_bit sync_rx_up(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (rx_up_rx),
        .dout    (rx_up_tx)
    );
    sync_signle_bit sync_rx_aligned(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (rx_aligned_rx),
        .dout    (rx_aligned_tx)
    );
    sync_signle_bit sync_rx_error(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (rx_error_rx),
        .dout    (rx_error_tx)
    );    

endmodule