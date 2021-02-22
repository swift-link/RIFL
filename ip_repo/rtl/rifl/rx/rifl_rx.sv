`timescale 1ns/1ps
module rifl_rx # 
(
    parameter int FRAME_WIDTH = 256,
    parameter int DWIDTH = 64,
    parameter int CRC_WIDTH = 12,
    parameter int CRC_POLY = 12'h02f,
    parameter int FRAME_ID_WIDTH = 8,
    parameter int SCRAMBLER_N1 = 13,
    parameter int SCRAMBLER_N2 = 33
)
(
    input logic tx_frame_clk,
    input logic rx_frame_clk,
    input logic tx_gt_clk,
    input logic rx_gt_clk,
    input logic rst,
    input logic tx_rst,
    input logic rx_rst,
    input logic [DWIDTH-1:0] gt_rx_data,
//user data interface (packed)
    output logic [FRAME_WIDTH+FRAME_WIDTH/8:0] rifl_rx_data,
    output logic rifl_rx_vld,
    input logic rifl_rx_rdy,
//event flags
    output logic link_up,
    output logic rx_aligned_tx,
    output logic rx_aligned_rx,
    output logic rx_up,
    output logic rx_error,
    output logic pause_req,
    output logic retrans_req
);
    localparam int PAYLOAD_WIDTH = FRAME_WIDTH-CRC_WIDTH-4;
    localparam int BUFFER_DEPTH = 1 << (FRAME_ID_WIDTH+1);
    localparam int PAUSE_ON_VAL = 2*BUFFER_DEPTH/3;
    localparam int PAUSE_OFF_VAL = BUFFER_DEPTH/3;

//control signals
    logic rx_up_rx, rx_up_tx, rx_up_user;
    logic rx_error_tx, rx_error_rx;
    logic pause_req_tx, pause_req_rx;
    logic retrans_req_tx, retrans_req_rx;

//rx aligner
    logic [DWIDTH-1:0] gt_rx_data_aligned;
    logic sof_aligner;
    logic rx_up_unsynced;
//verification code validation
    logic crc_good, isdata;
//descrambler
    logic sof_descrambler;
    logic [DWIDTH-1:0] descrambled_data;
//async fifo
    logic async_fifo_wr_rst;
    logic async_fifo_rd_rst;
    logic async_fifo_empty;
//datawidth converter
    logic [DWIDTH+1:0] dwidth_conv_in;
    logic dwidth_conv_in_vld;
    logic [PAYLOAD_WIDTH-1:0] int_tdata;
    logic [PAYLOAD_WIDTH/8-1:0] int_tkeep;
    logic int_tlast;
    logic int_tvalid;
//rx decoder
    logic [FRAME_WIDTH+FRAME_WIDTH/8:0] rx_axis_product;
    logic rx_axis_valid;
//rx user buffer
    logic [$clog2(BUFFER_DEPTH):0] rxbuffer_cnt;

    rx_aligner #(
        .DWIDTH        (DWIDTH),
        .FRAME_WIDTH   (FRAME_WIDTH)
    ) u_rx_aligner(
        .rst                 (rx_rst),
        .clk                 (rx_gt_clk),
        .rxdata_unaligned_in (gt_rx_data),
        .rxdata_aligned_out  (gt_rx_data_aligned),
        .sof                 (sof_aligner),
	    .rx_up               (rx_up_rx),
        .rx_aligned          (rx_aligned_rx)
    );

    vcode_val #(
        .FRAME_WIDTH     (FRAME_WIDTH),
        .DWIDTH          (DWIDTH),
        .CRC_WIDTH       (CRC_WIDTH),
        .CRC_POLY        (CRC_POLY),
        .FRAME_ID_WIDTH  (FRAME_ID_WIDTH)
    ) u_vcode_val(
        .clk          (rx_gt_clk),
        .rst          (rx_rst),
        .sof          (sof_aligner&rx_up_rx),
        .data_in      (gt_rx_data_aligned),
        .crc_good_out (crc_good),
        .rx_error     (rx_error_rx),
        .isdata       (isdata)
    );

    rifl_scramble_cntrl #(
        .FRAME_WIDTH (FRAME_WIDTH),
        .DWIDTH      (DWIDTH),
        .CRC_WIDTH   (CRC_WIDTH),
        .DIRECTION   (1'b1),
        .N1          (SCRAMBLER_N1),
        .N2          (SCRAMBLER_N2)
    ) u_rifl_scramble_cntrl(
        .clk      (rx_gt_clk),
        .rst      (rx_rst),
        .sof      (sof_aligner&rx_up_rx),
        .data_in  (gt_rx_data_aligned),
        .sof_out  (sof_descrambler),
        .data_out (descrambled_data)
    );

    rx_controller u_rx_controller(
        .clk         (rx_gt_clk),
        .rst         (rx_rst),
        .sof         (sof_descrambler),
        .rx_up       (rx_up_rx),
        .code        (descrambled_data[DWIDTH-1-:18]),
        .pause_req   (pause_req_rx),
        .retrans_req (retrans_req_rx)
    );

//this buffer suppose to be never overflowed because of the clock compensation mechanism
    async_fifo #(
        .DWIDTH (DWIDTH+2),
        .DEPTH  (32)
    ) u_async_fifo(
    	.rst                (rst),
        .wr_rst             (async_fifo_wr_rst),
        .rd_rst             (async_fifo_rd_rst),
        .wr_clk             (rx_gt_clk),
        .rd_clk             (tx_gt_clk),
        .wr_en              (isdata),
        .rd_en              (1'b1),
        .wr_data            ({crc_good,sof_descrambler,descrambled_data}),
        .wr_full            (),
        .rd_data            (dwidth_conv_in),
        .rd_empty           (async_fifo_empty),
        .fifo_cnt_wr_synced (),
        .fifo_cnt_rd_synced ()
    );
    assign dwidth_conv_in_vld = ~async_fifo_empty;
    rst_cntrl u_rst_cntrl(
    	.rst    (rst),
        .wr_clk (rx_gt_clk),
        .rd_clk (tx_gt_clk),
        .rd_rst (async_fifo_rd_rst),
        .wr_rst (async_fifo_wr_rst)
    );

    rx_dwidth_conv #(
        .DWIDTH (DWIDTH),
        .FRAME_WIDTH (FRAME_WIDTH),
        .PAYLOAD_WIDTH (PAYLOAD_WIDTH)
    ) u_rx_dwidth_conv(
        .*,
        .clk      (tx_gt_clk),
        .din      (dwidth_conv_in[DWIDTH-1:0]),
        .data_sof (dwidth_conv_in[DWIDTH]&dwidth_conv_in_vld),
        .crc_good (dwidth_conv_in[DWIDTH+1]&dwidth_conv_in_vld)
    );

    rifl_decode #(
        .FRAME_WIDTH   (FRAME_WIDTH),
        .PAYLOAD_WIDTH (PAYLOAD_WIDTH)
    ) u_rifl_decode(
        .*,
    	.clk                 (tx_frame_clk),
        .rst                 (tx_rst),
        .rx_axis_product     (rx_axis_product),
        .rx_axis_valid       (rx_axis_valid)
    );

    easy_fifo_axis_sync #(
        .DWIDTH     (FRAME_WIDTH+FRAME_WIDTH/8+1),
        .DEPTH      (BUFFER_DEPTH)
    ) rx_buffer(
        .rst           (tx_rst),
        .clk           (tx_frame_clk),
        .s_axis_tdata  (rx_axis_product),
        .s_axis_tvalid (rx_axis_valid),
        .s_axis_tready (),
        .m_axis_tdata  (rifl_rx_data),
        .m_axis_tvalid (rifl_rx_vld),
        .m_axis_tready (rifl_rx_rdy),
        .fifo_cnt      (rxbuffer_cnt)
    );

    rx_cdc u_rx_cdc(.*);

    always_ff @(posedge tx_frame_clk) begin
        if (tx_rst)
            rx_up_user <= 1'b1;
        else if (rxbuffer_cnt >= PAUSE_ON_VAL)
            rx_up_user <= 1'b0;
        else if (rxbuffer_cnt <= PAUSE_OFF_VAL)
            rx_up_user <= 1'b1;
    end

    assign rx_up = rx_up_tx & rx_up_user;
    assign rx_error = rx_error_tx;
    assign pause_req = pause_req_tx;
    assign retrans_req = retrans_req_tx;
    assign link_up = rx_up_tx;
endmodule