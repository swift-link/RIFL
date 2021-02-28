`timescale 1ns / 1ps
module rifl #
(
//gt
    parameter int N_CHANNEL = 1,
    parameter MASTER_CHAN = "UNDEFINED",
    parameter int DWIDTH = 64,
//rifl
    parameter int FRAME_WIDTH = 256,
    parameter int CRC_WIDTH = 12,
    parameter int CRC_POLY = 12'h02f,
    parameter int FRAME_ID_WIDTH = 8,
    parameter int SCRAMBLER_N1 = 13,
    parameter int SCRAMBLER_N2 = 33
)
(
//clk and rst
    input logic gt_ref_clk_p,
    input logic gt_ref_clk_n,
    input logic init_clk,
    input logic rst,
    input logic gt_rst,
//clk out
    output logic usr_clk,
//gt
    input logic [3*N_CHANNEL-1:0] gt_loopback_in,
    input logic [N_CHANNEL-1:0] gt_rxp_in,
    input logic [N_CHANNEL-1:0] gt_rxn_in,
    output logic [N_CHANNEL-1:0] gt_txp_out,
    output logic [N_CHANNEL-1:0] gt_txn_out,
//user AXI4_Stream interface
    input logic [N_CHANNEL*FRAME_WIDTH-1:0] s_axis_tdata,
    input logic [N_CHANNEL*FRAME_WIDTH/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [N_CHANNEL*FRAME_WIDTH-1:0] m_axis_tdata,
    output logic [N_CHANNEL*FRAME_WIDTH/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tvalid,
    input logic m_axis_tready,
//stats
    //tx
    output logic [N_CHANNEL-1:0] tx_state_init,
    output logic [N_CHANNEL-1:0] tx_state_send_pause,
    output logic [N_CHANNEL-1:0] tx_state_pause,
    output logic [N_CHANNEL-1:0] tx_state_send_retrans,
    output logic [N_CHANNEL-1:0] tx_state_retrans,
    output logic [N_CHANNEL-1:0] tx_state_normal,
    //rx
    output logic [N_CHANNEL-1:0] rx_up,
    output logic [N_CHANNEL-1:0] rx_aligned,
    output logic [N_CHANNEL-1:0] rx_error,
    output logic [N_CHANNEL-1:0] rx_pause_request,
    output logic [N_CHANNEL-1:0] rx_retrans_request,
    output logic compensate
);
    localparam int RATIO = FRAME_WIDTH/DWIDTH;
    localparam int CNT_WIDTH = RATIO == 1 ? 1 : $clog2(RATIO);

//clks
    logic tx_frame_clk;
    logic rx_frame_clk;
    logic tx_gt_clk;
    logic rx_gt_clk;
//resets
    logic tx_frame_rst;
    logic rx_frame_rst;
    logic gt_init_rst;

//gt
    logic [N_CHANNEL-1:0] tx_gt_src_clk;
    logic [N_CHANNEL-1:0] rx_gt_src_clk;
    logic tx_usr_clk;
    logic rx_usr_clk;
    logic tx_usr_clk_active, rx_usr_clk_active;
    logic tx_gt_clk_rst, rx_gt_clk_rst;
    logic [DWIDTH-1:0] gt_tx_data[N_CHANNEL-1:0];
    logic [DWIDTH-1:0] gt_rx_data[N_CHANNEL-1:0];

//rifl
    //tx
    logic [2:0] tx_state[N_CHANNEL-1:0];
    logic [CNT_WIDTH-1:0] tx_cnt;
    //rx
    logic tx_poweron_rst = 1'b1;
    logic [N_CHANNEL-1:0] rx_aligned_tx;
    logic [N_CHANNEL-1:0] rx_aligned_rx;
//compensate
    logic clock_active;

    rifl_rst_gen u_rifl_rst_gen(.*);

//external clock buffer
    IBUFDS_GTE4 #(
        .REFCLK_EN_TX_PATH  (1'b0),
        .REFCLK_HROW_CK_SEL (2'b00),
        .REFCLK_ICNTL_RX    (2'b00)
    ) gt_ref_inst (
        .I (gt_ref_clk_p),
        .IB (gt_ref_clk_n),
        .CEB (1'b0),
        .O (gt_ref_clk),
        .ODIV2 ()
    );

//gt
    rifl_gt_wrapper #(
        .N_CHANNEL   (N_CHANNEL   ),
        .FRAME_WIDTH (FRAME_WIDTH ),
        .DWIDTH      (DWIDTH      )
    ) u_rifl_gt_wrapper(
    	.gt_ref_clk        (gt_ref_clk),
        .init_clk          (init_clk),
        .rst               (rst),
        .gt_init_rst       (gt_init_rst),
        .rx_aligned        (rx_aligned_rx),
        .gt_rxp_in         (gt_rxp_in),
        .gt_rxn_in         (gt_rxn_in),
        .gt_loopback_in    (gt_loopback_in),
        .gt_tx_data        (gt_tx_data),
        .gt_rx_data        (gt_rx_data),
        .gt_txp_out        (gt_txp_out),
        .gt_txn_out        (gt_txn_out),
        .tx_gt_src_clk     (tx_gt_src_clk),
        .rx_gt_src_clk     (rx_gt_src_clk),
        .tx_usr_clk        ({N_CHANNEL{tx_usr_clk}}),
        .rx_usr_clk        ({N_CHANNEL{rx_usr_clk}}),
        .tx_gt_clk         ({N_CHANNEL{tx_gt_clk}}),
        .rx_gt_clk         ({N_CHANNEL{rx_gt_clk}}),
        .tx_usr_clk_active (tx_usr_clk_active),
        .rx_usr_clk_active (rx_usr_clk_active),
        .tx_gt_clk_rst     (tx_gt_clk_rst),
        .rx_gt_clk_rst     (rx_gt_clk_rst)
    );
    
    clock_buffer #(
        .RATIO     (RATIO)
    ) u_tx_clock_buffer(
    	.src_clk       (tx_gt_src_clk[0]),
        .rst           (tx_gt_clk_rst),
        .usrclk        (tx_usr_clk),
        .usrclk2       (tx_gt_clk),
        .usrclk3       (tx_frame_clk),
        .usrclk_active (tx_usr_clk_active)
    );
    clock_buffer #(
        .RATIO     (RATIO)
    ) u_rx_clock_buffer(
    	.src_clk       (rx_gt_src_clk[0]),
        .rst           (rx_gt_clk_rst),
        .usrclk        (rx_usr_clk),
        .usrclk2       (rx_gt_clk),
        .usrclk3       (rx_frame_clk),
        .usrclk_active (rx_usr_clk_active)
    );

    if (RATIO != 1) begin
        clock_counter #(
            .RATIO (RATIO )
        ) tx_clock_counter(
    	    .rst      (tx_frame_rst),
            .clk_slow (tx_frame_clk),
            .clk_fast (tx_gt_clk),
            .cnt      (tx_cnt)
        );
    end
    else begin
        assign tx_cnt = 1'b0;
    end

    rifl_core #(
        .N_CHANNEL      (N_CHANNEL      ),
        .DWIDTH         (DWIDTH         ),
        .FRAME_WIDTH    (FRAME_WIDTH    ),
        .CRC_WIDTH      (CRC_WIDTH      ),
        .CRC_POLY       (CRC_POLY       ),
        .FRAME_ID_WIDTH (FRAME_ID_WIDTH ),
        .SCRAMBLER_N1   (SCRAMBLER_N1   ),
        .SCRAMBLER_N2   (SCRAMBLER_N2   ),
        .CNT_WIDTH      (CNT_WIDTH      )
    ) u_rifl_core(
    	.tx_frame_clk          (tx_frame_clk          ),
        .rst                   (rst                   ),
        .tx_frame_rst          (tx_frame_rst|tx_poweron_rst),
        .rx_frame_rst          (rx_frame_rst          ),
        .rifl_core_tx_tdata    (s_axis_tdata          ),
        .rifl_core_tx_tkeep    (s_axis_tkeep          ),
        .rifl_core_tx_tlast    (s_axis_tlast          ),
        .rifl_core_tx_tvalid   (s_axis_tvalid         ),
        .rifl_core_tx_tready   (s_axis_tready         ),
        .rifl_core_rx_tdata    (m_axis_tdata          ),
        .rifl_core_rx_tkeep    (m_axis_tkeep          ),
        .rifl_core_rx_tlast    (m_axis_tlast          ),
        .rifl_core_rx_tvalid   (m_axis_tvalid         ),
        .rifl_core_rx_tready   (m_axis_tready         ),
        .tx_gt_clk             (tx_gt_clk             ),
        .rx_gt_clk             (rx_gt_clk             ),
        .gt_rx_data            (gt_rx_data            ),
        .gt_tx_data            (gt_tx_data            ),
        .tx_cnt                (tx_cnt                ),
        .compensate            (compensate            ),
        .tx_state              (tx_state              ),
        .rx_up                 (rx_up                 ),
        .rx_aligned_tx         (rx_aligned_tx         ),
        .rx_aligned_rx         (rx_aligned_rx         ),
        .rx_error              (rx_error              ),
        .rx_pause_request      (rx_pause_request      ),
        .rx_retrans_request    (rx_retrans_request    )
    );

    clock_compensate u_clock_compensate(
    	.init_clk     (init_clk       ),
        .tx_frame_clk (tx_frame_clk   ),
        .rx_frame_clk (rx_frame_clk   ),
        .rst          (rst            ),
        .clock_active (clock_active   ),
        .compensate   (compensate     )
    );

    always_ff @(posedge tx_frame_clk) begin
        if (&rx_aligned_tx)
            tx_poweron_rst <= 1'b0;
    end

    assign clock_active = tx_usr_clk_active & rx_usr_clk_active;
//stats
    assign rx_aligned = rx_aligned_tx;
    genvar i;
    for (i = 0; i < N_CHANNEL; i++) begin
        assign tx_state_init[i] = tx_state[i] == 3'd0;
        assign tx_state_send_pause[i] = tx_state[i] == 3'd1;
        assign tx_state_pause[i] = tx_state[i] == 3'd2;
        assign tx_state_retrans[i] = tx_state[i] == 3'd3;
        assign tx_state_send_retrans[i] = tx_state[i] == 3'd4;
        assign tx_state_normal[i] = tx_state[i] == 3'd5;
    end
    assign usr_clk = tx_frame_clk;
endmodule
