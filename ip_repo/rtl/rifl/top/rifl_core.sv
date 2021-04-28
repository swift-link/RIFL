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
module rifl_core #
(
//gt
    parameter int N_CHANNEL = 1,
    parameter int GT_WIDTH = 64,
//rifl
    parameter int FRAME_WIDTH = 256,
    parameter int PAYLOAD_WIDTH = 240,
    parameter int CRC_WIDTH = 12,
    parameter int CRC_POLY = 12'h02f,
    parameter int FRAME_ID_WIDTH = 8,
    parameter int SCRAMBLER_N1 = 13,
    parameter int SCRAMBLER_N2 = 33,
//conversion
    parameter int CNT_WIDTH = 2,
    parameter int FRAME_FREQ = 100
)
(
//user AXI4_Stream interface
    //clk
    input logic tx_frame_clk,
    //rst
    input logic rst,
    input logic tx_frame_rst,
    input logic rx_frame_rst,
    //data
    input logic [N_CHANNEL*PAYLOAD_WIDTH-1:0] rifl_core_tx_tdata,
    input logic [N_CHANNEL*PAYLOAD_WIDTH/8-1:0] rifl_core_tx_tkeep,
    input logic rifl_core_tx_tlast,
    input logic rifl_core_tx_tvalid,
    output logic rifl_core_tx_tready,
    output logic [N_CHANNEL*PAYLOAD_WIDTH-1:0] rifl_core_rx_tdata,
    output logic [N_CHANNEL*PAYLOAD_WIDTH/8-1:0] rifl_core_rx_tkeep,
    output logic rifl_core_rx_tlast,
    output logic rifl_core_rx_tvalid,
    input logic rifl_core_rx_tready,
//gt interface
    //clk
    input logic tx_gt_clk,
    input logic rx_gt_clk,
    //data
    input logic [GT_WIDTH-1:0] gt_rx_data[N_CHANNEL-1:0],
    output logic [GT_WIDTH-1:0] gt_tx_data[N_CHANNEL-1:0],
//frame-gt convertion
    input logic [CNT_WIDTH-1:0] clk_cnt,
//control
    input logic compensate,
//stats
    //tx
    output logic [2:0] tx_state[N_CHANNEL-1:0],
    //rx
    output logic [N_CHANNEL-1:0] rx_up,
    output logic [N_CHANNEL-1:0] rx_aligned_tx,
    output logic [N_CHANNEL-1:0] rx_aligned_rx,
    output logic [N_CHANNEL-1:0] rx_error,
    output logic [N_CHANNEL-1:0] rx_pause_request,
    output logic [N_CHANNEL-1:0] rx_retrans_request,
    //flow control
    output logic [N_CHANNEL-1:0] local_fc,
    output logic [N_CHANNEL-1:0] remote_fc
);
//tx
    logic [PAYLOAD_WIDTH-1:0] tx_lane_tdata[N_CHANNEL-1:0];
    logic [PAYLOAD_WIDTH/8-1:0] tx_lane_tkeep[N_CHANNEL-1:0];
    logic [N_CHANNEL-1:0] tx_lane_tlast;
    logic [N_CHANNEL-1:0] tx_lane_tvalid;
    logic [N_CHANNEL-1:0] tx_lane_tready;

//rx
    logic [PAYLOAD_WIDTH-1:0] rx_lane_tdata[N_CHANNEL-1:0];
    logic [PAYLOAD_WIDTH/8-1:0] rx_lane_tkeep[N_CHANNEL-1:0];
    logic [N_CHANNEL-1:0] rx_lane_tlast;
    logic [N_CHANNEL-1:0] rx_lane_tvalid;
    logic [N_CHANNEL-1:0] rx_lane_tready;

    //single N*PAYLOAD_WIDTH interface -> N PAYLOAD_WIDTH interfaces
    tx_spatial_cb #(
        .DWIDTH_IN  (N_CHANNEL*PAYLOAD_WIDTH),
        .DWIDTH_OUT (PAYLOAD_WIDTH),
        .N_CHANNEL  (N_CHANNEL)
    ) u_tx_spatial_cb(
    	.clk             (tx_frame_clk),
        .rst             (tx_frame_rst),
        .s_axis_tdata    (rifl_core_tx_tdata),
        .s_axis_tkeep    (rifl_core_tx_tkeep),
        .s_axis_tlast    (rifl_core_tx_tlast),
        .s_axis_tvalid   (rifl_core_tx_tvalid),
        .s_axis_tready   (rifl_core_tx_tready),
        .m_axis_tdata    (tx_lane_tdata),
        .m_axis_tkeep    (tx_lane_tkeep),
        .m_axis_tlast    (tx_lane_tlast),
        .m_axis_tvalid   (tx_lane_tvalid),
        .m_axis_tready   (tx_lane_tready)
    );
    
    genvar i;
    for (i = 0; i < N_CHANNEL; i++) begin
        rifl_tx #(
            .FRAME_WIDTH    (FRAME_WIDTH),
            .PAYLOAD_WIDTH  (PAYLOAD_WIDTH),
            .GT_WIDTH       (GT_WIDTH),
            .CNT_WIDTH      (CNT_WIDTH),
            .CRC_WIDTH      (CRC_WIDTH),
            .CRC_POLY       (CRC_POLY),
            .FRAME_ID_WIDTH (FRAME_ID_WIDTH),
            .SCRAMBLER_N1   (SCRAMBLER_N1),
            .SCRAMBLER_N2   (SCRAMBLER_N2)
        ) u_rifl_tx(
        	.tx_frame_clk     (tx_frame_clk),
            .tx_gt_clk        (tx_gt_clk),
            .tx_frame_rst     (tx_frame_rst),
            .gt_tx_data       (gt_tx_data[i]),
            .tx_lane_tdata    (tx_lane_tdata[i]),
            .tx_lane_tkeep    (tx_lane_tkeep[i]),
            .tx_lane_tlast    (tx_lane_tlast[i]),
            .tx_lane_tvalid   (tx_lane_tvalid[i]),
            .tx_lane_tready   (tx_lane_tready[i]),
            .clk_cnt          (clk_cnt),
            .rx_up            (&rx_up),
            .rx_error         (rx_error[i]),
            .pause_req        (rx_pause_request[i]),
            .retrans_req      (rx_retrans_request[i]),
            .compensate       (compensate),
            .tx_state         (tx_state[i]),
            .local_fc         (local_fc[i]),
            .remote_fc        (remote_fc[i])
        );

        rifl_rx #(
            .FRAME_WIDTH    (FRAME_WIDTH),
            .PAYLOAD_WIDTH  (PAYLOAD_WIDTH),
            .GT_WIDTH       (GT_WIDTH),
            .CNT_WIDTH      (CNT_WIDTH),
            .CRC_WIDTH      (CRC_WIDTH),
            .CRC_POLY       (CRC_POLY),
            .FRAME_ID_WIDTH (FRAME_ID_WIDTH ),
            .SCRAMBLER_N1   (SCRAMBLER_N1),
            .SCRAMBLER_N2   (SCRAMBLER_N2),
            .FRAME_FREQ     (FRAME_FREQ)
        ) u_rifl_rx(
        	.tx_frame_clk   (tx_frame_clk),
            .tx_gt_clk      (tx_gt_clk),
            .rx_gt_clk      (rx_gt_clk),
            .rst            (rst),
            .tx_frame_rst   (tx_frame_rst),
            .rx_frame_rst   (rx_frame_rst),
            .clk_cnt        (clk_cnt),
            .gt_rx_data     (gt_rx_data[i]),
            .rx_lane_tdata  (rx_lane_tdata[i]),
            .rx_lane_tkeep  (rx_lane_tkeep[i]),
            .rx_lane_tlast  (rx_lane_tlast[i]),
            .rx_lane_tvalid (rx_lane_tvalid[i]),
            .rx_lane_tready (rx_lane_tready[i]),
            .rx_aligned_tx  (rx_aligned_tx[i]),
            .rx_aligned_rx  (rx_aligned_rx[i]),
            .rx_up          (rx_up[i]),
            .rx_error       (rx_error[i]),
            .pause_req      (rx_pause_request[i]),
            .retrans_req    (rx_retrans_request[i]),
            .local_fc       (local_fc[i]),
            .remote_fc      (remote_fc[i])
        );
    end

    rx_spatial_cb #(
        .DWIDTH_IN  (PAYLOAD_WIDTH),
        .DWIDTH_OUT (N_CHANNEL*PAYLOAD_WIDTH),
        .N_CHANNEL  (N_CHANNEL)
    ) u_rx_spatial_cb(
    	.clk           (tx_frame_clk),
        .rst           (tx_frame_rst),
        .s_axis_tdata  (rx_lane_tdata),
        .s_axis_tkeep  (rx_lane_tkeep),
        .s_axis_tlast  (rx_lane_tlast),
        .s_axis_tvalid (rx_lane_tvalid),
        .s_axis_tready (rx_lane_tready),
        .m_axis_tdata  (rifl_core_rx_tdata),
        .m_axis_tkeep  (rifl_core_rx_tkeep),
        .m_axis_tlast  (rifl_core_rx_tlast),
        .m_axis_tvalid (rifl_core_rx_tvalid),
        .m_axis_tready (rifl_core_rx_tready)
    );
endmodule