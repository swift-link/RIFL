`timescale 1ns / 1ps
module rifl #
(
//gt
    parameter int N_CHANNEL = 1,
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
    output logic [N_CHANNEL-1:0] link_up,
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
//resets
    logic tx_frame_rst, rx_frame_rst;

//gt
    //clk
    logic tx_gt_clk, rx_gt_clk;
    logic tx_frame_clk, rx_frame_clk;
    logic clock_active;
    //rst
    logic gt_init_rst;
    //data
    logic [DWIDTH*N_CHANNEL-1:0] gt_tx_data, gt_rx_data;

//rx
    logic [N_CHANNEL-1:0] rx_aligned_rx;
    logic [FRAME_WIDTH+FRAME_WIDTH/8:0] rifl_rx_data[N_CHANNEL-1:0];
    logic [N_CHANNEL-1:0] rifl_rx_vld;
    logic [N_CHANNEL-1:0] rifl_rx_rdy;
    logic [N_CHANNEL-1:0] tlast_int;
//tx
    logic [2:0] tx_state [N_CHANNEL-1:0];
    logic [N_CHANNEL-1:0] ritl_tx_rdy;
    logic [N_CHANNEL-1:0] tx_poweron_rst = {N_CHANNEL{1'b1}};

    rifl_rst_gen u_rifl_rst_gen(.*);

    rifl_gt_wrapper #(
        .N_CHANNEL   (N_CHANNEL ),
        .FRAME_WIDTH (FRAME_WIDTH),
        .DWIDTH      (DWIDTH    )
    ) u_rifl_gt_wrapper(
        .*,
        .rx_aligned(&rx_aligned_rx)
    );

    genvar i;
    for (i = 0; i < N_CHANNEL; i++) begin
        rifl_rx #(
            .FRAME_WIDTH    (FRAME_WIDTH    ),
            .DWIDTH         (DWIDTH         ),
            .CRC_WIDTH      (CRC_WIDTH      ),
            .CRC_POLY       (CRC_POLY       ),
            .FRAME_ID_WIDTH (FRAME_ID_WIDTH ),
            .SCRAMBLER_N1   (SCRAMBLER_N1   ),
            .SCRAMBLER_N2   (SCRAMBLER_N2   )
        ) u_rifl_rx(
            .*,
            .tx_rst       (tx_frame_rst),
            .rx_rst       (rx_frame_rst),
            .gt_rx_data   (gt_rx_data[(i+1)*DWIDTH-1-:DWIDTH]),
            .rifl_rx_data (rifl_rx_data[i]),
            .rifl_rx_vld  (rifl_rx_vld[i]),
            .rifl_rx_rdy  (m_axis_tready & (&rifl_rx_vld)),
            .rx_aligned_tx (rx_aligned[i]),
            .rx_aligned_rx (rx_aligned_rx[i]),
            .rx_up         (rx_up[i]),
            .rx_error      (rx_error[i]),
            .pause_req     (rx_pause_request[i]),
            .retrans_req   (rx_retrans_request[i]),
            .link_up       (link_up[i])    
        );

        rifl_tx #(
            .FRAME_WIDTH    (FRAME_WIDTH    ),
            .DWIDTH         (DWIDTH         ),
            .CRC_WIDTH      (CRC_WIDTH      ),
            .CRC_POLY       (CRC_POLY       ),
            .FRAME_ID_WIDTH (FRAME_ID_WIDTH ),
            .SCRAMBLER_N1   (SCRAMBLER_N1   ),
            .SCRAMBLER_N2   (SCRAMBLER_N2   )
        ) u_rifl_tx(
            .*,
            .rst (tx_frame_rst|tx_poweron_rst[i]),
            .gt_tx_data (gt_tx_data[(i+1)*DWIDTH-1-:DWIDTH]),
            .s_axis_tdata  (s_axis_tdata[(i+1)*FRAME_WIDTH-1-:FRAME_WIDTH]),
            .s_axis_tkeep  (s_axis_tkeep[(i+1)*FRAME_WIDTH/8-1-:FRAME_WIDTH/8]),
            .s_axis_tlast  (s_axis_tlast),
            .s_axis_tvalid (s_axis_tvalid),
            .s_axis_tready (ritl_tx_rdy[i]),
            .rx_up (rx_up[i]),
            .rx_error (rx_error[i]),
            .pause_req (rx_pause_request[i]),
            .retrans_req (rx_retrans_request[i]),
            .tx_state (tx_state[i])
        );
        always_ff @(posedge tx_frame_clk) begin
            if (rx_aligned[i])
                tx_poweron_rst[i] <= 1'b0;
        end
        assign m_axis_tdata[(i+1)*FRAME_WIDTH-1-:FRAME_WIDTH] = rifl_rx_data[i][FRAME_WIDTH-1:0];
        assign m_axis_tkeep[(i+1)*FRAME_WIDTH/8-1-:FRAME_WIDTH/8] = rifl_rx_data[i][FRAME_WIDTH+FRAME_WIDTH/8-1:FRAME_WIDTH];
        assign tlast_int[i] = rifl_rx_data[i][FRAME_WIDTH+FRAME_WIDTH/8];
    end
    clock_compensate u_clock_compensate(.*);
    
    assign s_axis_tready = &ritl_tx_rdy;
    assign m_axis_tlast = |tlast_int;
    assign m_axis_tvalid = &rifl_rx_vld;

//stats
    for (i = 0; i < N_CHANNEL; i++) begin
        assign tx_state_init[i] = tx_state[i] == 3'd0;
        assign tx_state_send_pause[i] = tx_state[i] == 3'd1;
        assign tx_state_pause[i] = tx_state[i] == 3'd2;
        assign tx_state_send_retrans[i] = tx_state[i] == 3'd3;
        assign tx_state_retrans[i] = tx_state[i] == 3'd4;
        assign tx_state_normal[i] = tx_state[i] == 3'd5;
    end
    assign usr_clk = tx_frame_clk;
endmodule
