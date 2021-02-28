`timescale 1ns/1ps
module gt_cdc #
(
    parameter N_CHANNEL = 1
)
(
    input logic init_clk,
    input logic tx_gt_clk,
    input logic [N_CHANNEL-1:0] rx_gt_clk,
    input logic rst,
    input logic tx_good_tx_synced,
    input logic [N_CHANNEL-1:0] rx_good_rx_synced,
    output logic tx_good_init_synced,
    output logic [N_CHANNEL-1:0] rx_good_init_synced
);
    sync_signle_bit #(
        .N_STAGE   (5),
        .INPUT_REG (1)
    ) tx_good_init_sync_inst (
        .clk_in  (tx_gt_clk),
    	.clk_out (init_clk),
        .rst     (rst),
        .din     (tx_good_tx_synced),
        .dout    (tx_good_init_synced)
    );
    genvar i;
    for (i = 0; i < N_CHANNEL; i++) begin
        sync_signle_bit #(
            .N_STAGE   (5),
            .INPUT_REG (1)
        ) rx_good_init_sync_inst (
            .clk_in  (rx_gt_clk[i]),
    	    .clk_out (init_clk),
            .rst     (rst),
            .din     (rx_good_rx_synced[i]),
            .dout    (rx_good_init_synced[i])
        );
    end
endmodule
