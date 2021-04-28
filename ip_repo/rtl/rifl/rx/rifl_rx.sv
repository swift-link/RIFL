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
module rifl_rx # 
(
    parameter int FRAME_WIDTH = 256,
    parameter int PAYLOAD_WIDTH = 240,
    parameter int GT_WIDTH = 64,
    parameter int CNT_WIDTH = 2,
    parameter int CRC_WIDTH = 12,
    parameter int CRC_POLY = 12'h02f,
    parameter int FRAME_ID_WIDTH = 8,
    parameter int SCRAMBLER_N1 = 13,
    parameter int SCRAMBLER_N2 = 33,
    parameter int FRAME_FREQ = 100
)
(
    input logic tx_frame_clk,
    input logic tx_gt_clk,
    input logic rx_gt_clk,
    input logic rst,
    input logic tx_frame_rst,
    input logic rx_frame_rst,
    input logic [CNT_WIDTH-1:0] clk_cnt,
    input logic [GT_WIDTH-1:0] gt_rx_data,
//user data interface (packed)
    output logic [PAYLOAD_WIDTH-1:0] rx_lane_tdata,
    output logic [PAYLOAD_WIDTH/8-1:0] rx_lane_tkeep,
    output logic rx_lane_tlast,
    output logic rx_lane_tvalid,
    input logic rx_lane_tready,
//event flags
    output logic rx_aligned_tx,
    output logic rx_aligned_rx,
    output logic rx_up,
    output logic rx_error,
    output logic pause_req,
    output logic retrans_req,
    //flow control
    output logic local_fc,
    output logic remote_fc
);
    localparam int BUFFER_DEPTH = 1 << (FRAME_ID_WIDTH+1);
    localparam int PAUSE_ON_VAL = 2*BUFFER_DEPTH/3;
    localparam int PAUSE_OFF_VAL = BUFFER_DEPTH/3;
    //add an output buffer for frequency more than 200MHz
    localparam bit RX_BUFFER_REG = FRAME_FREQ >= 200 ? 1'b1 : 1'b0;

//control signals
    logic rx_up_rx, rx_up_tx;
    logic rx_error_tx, rx_error_rx;
    logic pause_req_tx, pause_req_rx;
    logic retrans_req_tx, retrans_req_rx;

//rx aligner
    logic [GT_WIDTH-1:0] gt_rx_data_aligned;
    logic sof_aligner;
//verification code validation
    logic crc_good, isdata;
//descrambler
    logic sof_descrambler;
    logic [GT_WIDTH-1:0] descrambled_data;
//datawidth converter
    logic [GT_WIDTH+1:0] dwidth_conv_in;
    logic dwidth_conv_in_vld;
    logic [PAYLOAD_WIDTH-1:0] dwidth_conv_out_tdata;
    logic [PAYLOAD_WIDTH/8-1:0] dwidth_conv_out_tkeep;
    logic dwidth_conv_out_tlast;
    logic dwidth_conv_out_tvalid;
//rx user buffer
    logic [$clog2(BUFFER_DEPTH):0] rxbuffer_cnt;

//debug
    logic s_ready;

    rx_aligner #(
        .DWIDTH        (GT_WIDTH),
        .FRAME_WIDTH   (FRAME_WIDTH)
    ) u_rx_aligner(
        .rst                 (rx_frame_rst),
        .clk                 (rx_gt_clk),
        .rxdata_unaligned_in (gt_rx_data),
        .rxdata_aligned_out  (gt_rx_data_aligned),
        .sof                 (sof_aligner),
	    .rx_up               (rx_up_rx),
        .rx_aligned          (rx_aligned_rx)
    );

    vcode_val #(
        .FRAME_WIDTH     (FRAME_WIDTH),
        .DWIDTH          (GT_WIDTH),
        .CRC_WIDTH       (CRC_WIDTH),
        .CRC_POLY        (CRC_POLY),
        .FRAME_ID_WIDTH  (FRAME_ID_WIDTH)
    ) u_vcode_val(
        .clk          (rx_gt_clk),
        .rst          (rx_frame_rst),
        .sof          (sof_aligner),
        .rx_up        (rx_up_rx),
        .data_in      (gt_rx_data_aligned),
        .crc_good_out (crc_good),
        .rx_error     (rx_error_rx),
        .isdata       (isdata)
    );

    rifl_scramble_cntrl #(
        .FRAME_WIDTH (FRAME_WIDTH),
        .DWIDTH      (GT_WIDTH),
        .CRC_WIDTH   (CRC_WIDTH),
        .DIRECTION   (1'b1),
        .N1          (SCRAMBLER_N1),
        .N2          (SCRAMBLER_N2)
    ) u_rifl_scramble_cntrl(
        .clk      (rx_gt_clk),
        .sof      (sof_aligner),
        .data_in  (gt_rx_data_aligned),
        .sof_out  (sof_descrambler),
        .data_out (descrambled_data)
    );

    rx_controller u_rx_controller(
        .clk         (rx_gt_clk),
        .rst         (rx_frame_rst),
        .sof         (sof_descrambler),
        .rx_aligned  (rx_aligned_rx),
        .code        (descrambled_data[GT_WIDTH-1-:18]),
        .pause_req   (pause_req_rx),
        .retrans_req (retrans_req_rx)
    );

//this buffer suppose to be never overflowed because of the clock compensation mechanism
    rifl_axis_async_fifo #(
        .DWIDTH (GT_WIDTH+2),
        .DEPTH  (32)
    ) u_rifl_axis_async_fifo(
        .rst           (rst),
        .s_axis_aclk   (rx_gt_clk),
        .m_axis_aclk   (tx_gt_clk),
        .s_axis_tdata  ({crc_good,sof_descrambler,descrambled_data}),
        .s_axis_tvalid (isdata),
        .s_axis_tready (),
        .m_axis_tdata  (dwidth_conv_in),
        .m_axis_tvalid (dwidth_conv_in_vld),
        .m_axis_tready (1'b1)
    );

    remote_fc_detector #(
        .DWIDTH      (GT_WIDTH),
        .FRAME_WIDTH (FRAME_WIDTH),
        .CRC_WIDTH   (CRC_WIDTH)
    ) u_remote_fc_detector(
    	.tx_gt_clk    (tx_gt_clk),
        .tx_frame_clk (tx_frame_clk),
        .rst          (tx_frame_rst),
        .din          (dwidth_conv_in[GT_WIDTH-1:0]),
        .data_sof     (dwidth_conv_in[GT_WIDTH]),
        .crc_good     (dwidth_conv_in[GT_WIDTH+1]),
        .din_valid    (dwidth_conv_in_vld),
        .remote_fc    (remote_fc)
    );

    rx_dwidth_conv #(
        .DWIDTH (GT_WIDTH),
        .FRAME_WIDTH (FRAME_WIDTH),
        .PAYLOAD_WIDTH (PAYLOAD_WIDTH),
        .CNT_WIDTH(CNT_WIDTH)
    ) u_rx_dwidth_conv(
        .*,
        .clk      (tx_gt_clk),
        .rst      (tx_frame_rst),
        .din      (dwidth_conv_in[GT_WIDTH-1:0]),
        .data_sof (dwidth_conv_in[GT_WIDTH]),
        .crc_good (dwidth_conv_in[GT_WIDTH+1]),
        .din_valid(dwidth_conv_in_vld)
    );

    rifl_axis_sync_fifo #(
        .DWIDTH (PAYLOAD_WIDTH),
        .DEPTH  (BUFFER_DEPTH),
        .OUTPUT_REG (RX_BUFFER_REG)
    ) u_rifl_axis_sync_fifo(
    	.rst           (tx_frame_rst),
        .clk           (tx_frame_clk),
        .s_axis_tdata  (dwidth_conv_out_tdata),
        .s_axis_tkeep  (dwidth_conv_out_tkeep),
        .s_axis_tlast  (dwidth_conv_out_tlast),
        .s_axis_tvalid (dwidth_conv_out_tvalid),
        .s_axis_tready (s_ready),
        .m_axis_tdata  (rx_lane_tdata),
        .m_axis_tkeep  (rx_lane_tkeep),
        .m_axis_tlast  (rx_lane_tlast),
        .m_axis_tvalid (rx_lane_tvalid),
        .m_axis_tready (rx_lane_tready),
        .fifo_cnt      (rxbuffer_cnt)
    );
    
    rx_cdc u_rx_cdc(.*);

    always_ff @(posedge tx_frame_clk) begin
        if (tx_frame_rst)
            local_fc <= 1'b0;
        else if (rxbuffer_cnt > PAUSE_ON_VAL)
            local_fc <= 1'b1;
        else if (rxbuffer_cnt < PAUSE_OFF_VAL)
            local_fc <= 1'b0;
    end

    assign rx_up = rx_up_tx;
    assign rx_error = rx_error_tx;
    assign pause_req = pause_req_tx;
    assign retrans_req = retrans_req_tx;

endmodule