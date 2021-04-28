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
module rifl_tx #
(
    parameter int FRAME_WIDTH = 256,
    parameter int PAYLOAD_WIDTH = 240,
    parameter int GT_WIDTH = 64,
    parameter int CNT_WIDTH = 2,
    parameter int CRC_WIDTH = 12,
    parameter int CRC_POLY = 12'h02f,
    parameter int FRAME_ID_WIDTH = 8,
    parameter int SCRAMBLER_N1 = 13,
    parameter int SCRAMBLER_N2 = 33
)
(
    input logic tx_frame_clk,
    input logic tx_gt_clk,
    input logic tx_frame_rst,
//gt
    output logic [GT_WIDTH-1:0] gt_tx_data,
////user data interface
    input logic [PAYLOAD_WIDTH-1:0] tx_lane_tdata,
    input logic [PAYLOAD_WIDTH/8-1:0] tx_lane_tkeep,
    input logic tx_lane_tlast,
    input logic tx_lane_tvalid,
    output logic tx_lane_tready,
//control
    input logic [CNT_WIDTH-1:0] clk_cnt,
//even flags
    input logic rx_up,
    input logic rx_error,
    input logic pause_req,
    input logic retrans_req,
    input logic compensate,
    //flow control
    input logic local_fc,
    input logic remote_fc,
    output logic [2:0] tx_state
);
    logic [PAYLOAD_WIDTH+1:0] rifl_tx_payload;
    logic rifl_tx_ready;

    logic [FRAME_WIDTH-1:0] rifl_tx_data;
    logic sof_dwith_conv;
    logic [GT_WIDTH-1:0] dwidth_conv_data;
    logic [GT_WIDTH-1:0] scrambled_data;
    logic sof_scrambler;

    rifl_encode #(
        .PAYLOAD_WIDTH (PAYLOAD_WIDTH )
    ) u_rifl_encode(
        .tx_lane_tdata   (tx_lane_tdata   ),
        .tx_lane_tkeep   (tx_lane_tkeep   ),
        .tx_lane_tlast   (tx_lane_tlast   ),
        .tx_lane_tvalid  (tx_lane_tvalid  ),
        .tx_lane_tready  (tx_lane_tready  ),
        .rifl_tx_payload (rifl_tx_payload ),
        .rifl_tx_ready   (rifl_tx_ready   )
    );
    
    tx_controller #(
        .FRAME_WIDTH    (FRAME_WIDTH),
        .PAYLOAD_WIDTH  (PAYLOAD_WIDTH),
        .CRC_WIDTH      (CRC_WIDTH),
        .FRAME_ID_WIDTH (FRAME_ID_WIDTH)
    ) u_tx_controller(
        .*,
        .clk(tx_frame_clk),
        .rst(tx_frame_rst),
        .state(tx_state)
    );

    tx_dwidth_conv #(
        .DWIDTH_IN  (FRAME_WIDTH),
        .DWIDTH_OUT (GT_WIDTH),
        .CNT_WIDTH  (CNT_WIDTH)
    ) u_tx_dwidth_conv(
        .clk      (tx_gt_clk),
        .clk_cnt  (clk_cnt),
        .din      (rifl_tx_data),
        .dout     (dwidth_conv_data),
        .sof_out  (sof_dwith_conv)
    );

    rifl_scramble_cntrl #(
        .FRAME_WIDTH (FRAME_WIDTH),
        .DWIDTH      (GT_WIDTH),
        .CRC_WIDTH   (CRC_WIDTH),
        .DIRECTION   (1'b0),
        .N1          (SCRAMBLER_N1),
        .N2          (SCRAMBLER_N2)
    ) u_rifl_scramble_cntrl(
        .clk      (tx_gt_clk),
        .sof      (sof_dwith_conv),
        .data_in  (dwidth_conv_data),
        .sof_out  (sof_scrambler),
        .data_out (scrambled_data)
    );

    vcode_gen #(
        .FRAME_WIDTH    (FRAME_WIDTH    ),
        .DWIDTH         (GT_WIDTH       ),
        .CRC_WIDTH      (CRC_WIDTH      ),
        .CRC_POLY       (CRC_POLY       ),
        .FRAME_ID_WIDTH (FRAME_ID_WIDTH )
    ) u_vcode_gen(
    	.clk      (tx_gt_clk),
        .rst      (tx_frame_rst),
        .sof      (sof_scrambler),
        .data_in  (scrambled_data),
        .data_out (gt_tx_data)
    );
    
endmodule