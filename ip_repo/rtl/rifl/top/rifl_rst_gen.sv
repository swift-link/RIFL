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