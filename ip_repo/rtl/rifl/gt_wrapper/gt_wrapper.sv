`timescale 1ns / 1ps
module rifl_gt_wrapper # (
    parameter int N_CHANNEL = 1,
    parameter int FRAME_WIDTH = 256,
    parameter int DWIDTH = 64
)
(
//clk and rst
    input logic gt_ref_clk_p,
    input logic gt_ref_clk_n,
    input logic init_clk,
    input logic rst,
    input logic gt_init_rst,
//align status
    input logic rx_aligned,
//gt input pins
    input logic [N_CHANNEL-1:0] gt_rxp_in,
    input logic [N_CHANNEL-1:0] gt_rxn_in,
//gt loopback port
    input logic [3*N_CHANNEL-1:0] gt_loopback_in,
//tx data interface
    input logic [DWIDTH*N_CHANNEL-1:0] gt_tx_data,
//rx data interface
    output logic [DWIDTH*N_CHANNEL-1:0] gt_rx_data,
//output clks
    output logic tx_gt_clk,
    output logic rx_gt_clk,
    output logic tx_frame_clk,
    output logic rx_frame_clk,
//gt output pins
    output logic [N_CHANNEL-1:0] gt_txp_out,
    output logic [N_CHANNEL-1:0] gt_txn_out,
//clock active
    output logic clock_active
);
    localparam bit [2:0] RATIO = FRAME_WIDTH/DWIDTH;
//clks
    logic gt_ref_clk;
    logic tx_usr_clk_active;
    logic rx_usr_clk_active;
    logic [N_CHANNEL-1:0] tx_gt_src_clk_grp;
    logic [N_CHANNEL-1:0] rx_gt_src_clk_grp;
    logic [N_CHANNEL-1:0] tx_usr_clk_grp;
    logic [N_CHANNEL-1:0] rx_usr_clk_grp;
    logic [N_CHANNEL-1:0] tx_usr_clk2_grp;
    logic [N_CHANNEL-1:0] rx_usr_clk2_grp;
    logic tx_usr_clk;
    logic rx_usr_clk;

//rsts
    logic bypass_tx_reset_gt;
    logic bypass_rx_reset_gt;
    logic rst_all_gt;
    logic rst_rx_datapath_gt;
    logic rst_tx_done_gt;
    logic rst_rx_done_gt;
    logic bypass_tx_done_gt;
    logic bypass_rx_done_gt;
    logic [N_CHANNEL-1:0] txpmaresetdone_out;
    logic [N_CHANNEL-1:0] txprgdivresetdone_out;
    logic [N_CHANNEL-1:0] rxpmaresetdone_out;
    logic tx_gt_rst;
    logic rx_gt_rst;

//control and status
    logic tx_good_tx_synced;
    logic rx_good_rx_synced;
    logic tx_good_init_synced;
    logic rx_good_init_synced;

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

//internal clk buffer
    clock_buffer #(
        .RATIO(RATIO)
    ) tx_clock_buffer (
        .src_clk(tx_gt_src_clk_grp[N_CHANNEL-1]),
        .rst(tx_gt_rst),
        .usrclk(tx_usr_clk),
        .usrclk2(tx_gt_clk),
        .usrclk3(tx_frame_clk),
        .usrclk_active(tx_usr_clk_active)
    );
    clock_buffer #(
        .RATIO(RATIO)
    ) rx_clock_buffer (
        .src_clk(rx_gt_src_clk_grp[N_CHANNEL-1]),
        .rst(rx_gt_rst),
        .usrclk(rx_usr_clk),
        .usrclk2(rx_gt_clk),
        .usrclk3(rx_frame_clk),
        .usrclk_active(rx_usr_clk_active)
    );

//synchronizer
    gt_cdc gt_cdc_inst (
        .init_clk(init_clk),
        .tx_gt_clk(tx_gt_clk),
        .rx_gt_clk(rx_gt_clk),
        .rst(rst),
        .tx_good_tx_synced(tx_good_tx_synced),
        .rx_good_rx_synced(rx_good_rx_synced),
        .tx_good_init_synced(tx_good_init_synced),
        .rx_good_init_synced(rx_good_init_synced)
    );

//datapath resets
    datapath_reset # (
        .COUNTER_WIDTH(20)
    ) gt_all_reset_inst (
        .clk(init_clk),
        .rst(gt_init_rst),
        .channel_good(tx_good_init_synced),
        .rst_out(rst_all_gt)
    );

    datapath_reset # (
        .COUNTER_WIDTH(23)
    ) rx_datapath_reset_inst (
        .clk(init_clk),
        .rst(gt_init_rst),
        .channel_good(rx_good_init_synced),
        .rst_out(rst_rx_datapath_gt)
    );

//gt_core
    rifl_gt_core rifl_gt_core_inst (
        .gtyrxn_in                               (gt_rxn_in),
        .gtyrxp_in                               (gt_rxp_in),
        .gtytxn_out                              (gt_txn_out),
        .gtytxp_out                              (gt_txp_out),
        .gtwiz_buffbypass_tx_reset_in            (bypass_tx_reset_gt),
        .gtwiz_buffbypass_tx_start_user_in       (1'b0),
        .gtwiz_buffbypass_tx_done_out            (bypass_tx_done_gt),
        .gtwiz_buffbypass_tx_error_out           (),
        .gtwiz_buffbypass_rx_reset_in            (bypass_rx_reset_gt),
        .gtwiz_buffbypass_rx_start_user_in       (1'b0),
        .gtwiz_buffbypass_rx_done_out            (bypass_rx_done_gt),
        .gtwiz_buffbypass_rx_error_out           (),
        .gtwiz_reset_clk_freerun_in              (init_clk),
        .gtwiz_reset_all_in                      (gt_init_rst | rst_all_gt),
        .gtwiz_reset_tx_pll_and_datapath_in      (1'b0),
        .gtwiz_reset_tx_datapath_in              (1'b0),
        .gtwiz_reset_rx_pll_and_datapath_in      (1'b0),
        .gtwiz_reset_rx_datapath_in              (rst_rx_datapath_gt),
        .gtwiz_reset_rx_cdr_stable_out           (),
        .gtwiz_reset_tx_done_out                 (rst_tx_done_gt),
        .gtwiz_reset_rx_done_out                 (rst_rx_done_gt),
        .gtwiz_userclk_tx_active_in              (tx_usr_clk_active),
        .txusrclk_in                             (tx_usr_clk_grp),
        .txusrclk2_in                            (tx_usr_clk2_grp),
        .txoutclk_out                            (tx_gt_src_clk_grp),
        .gtwiz_userclk_rx_active_in              (rx_usr_clk_active),
        .rxusrclk_in                             (rx_usr_clk_grp),
        .rxusrclk2_in                            (rx_usr_clk2_grp),
        .rxoutclk_out                            (rx_gt_src_clk_grp),
        .gtwiz_userdata_tx_in                    (gt_tx_data),
        .gtwiz_userdata_rx_out                   (gt_rx_data),
        .gtrefclk00_in                           (gt_ref_clk),
        .qpll0outclk_out                         (),
        .qpll0outrefclk_out                      (),
        .loopback_in                             (gt_loopback_in),
        .gtpowergood_out                         (),
        .rxpmaresetdone_out                      (rxpmaresetdone_out),
        .txpmaresetdone_out                      (txpmaresetdone_out),
        .txprgdivresetdone_out                   (txprgdivresetdone_out)
    );

    assign tx_usr_clk_grp = {N_CHANNEL{tx_usr_clk}};
    assign tx_usr_clk2_grp = {N_CHANNEL{tx_gt_clk}};
    assign rx_usr_clk_grp = {N_CHANNEL{rx_usr_clk}};
    assign rx_usr_clk2_grp = {N_CHANNEL{rx_gt_clk}};

    assign bypass_tx_reset_gt = ~tx_usr_clk_active;
    assign bypass_rx_reset_gt = ~rx_usr_clk_active | ~bypass_tx_done_gt;
    assign tx_gt_rst = ~(&txpmaresetdone_out && &txprgdivresetdone_out);
    assign rx_gt_rst = ~(&rxpmaresetdone_out);
    assign tx_good_tx_synced = rst_tx_done_gt & bypass_tx_done_gt;
    assign rx_good_rx_synced = rst_rx_done_gt & bypass_rx_done_gt & rx_aligned;
    assign clock_active = tx_usr_clk_active & rx_usr_clk_active;

endmodule
