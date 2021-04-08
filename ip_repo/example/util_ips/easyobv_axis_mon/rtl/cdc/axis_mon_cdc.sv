module axis_mon_cdc #
(
    parameter bit LOOPBACK = 1'b1
)
(
    input logic clk,
    input logic s_axil_aclk,
    input logic rst,
//single-bit
    input logic clear_axil,
    input logic mismatch,
    output logic clear,
    output logic mismatch_axil,
//multi-bit
    input logic [63:0] tx_pkt_cnt,
    input logic [63:0] tx_time_elapsed,
    input logic [63:0] tx_transferred_size,
    input logic [63:0] rx_pkt_cnt,
    input logic [63:0] rx_time_elapsed,
    input logic [63:0] rx_transferred_size,
    input logic [63:0] latency_sum,
    output logic [63:0] tx_pkt_cnt_axil,
    output logic [63:0] tx_time_elapsed_axil,
    output logic [63:0] tx_transferred_size_axil,
    output logic [63:0] rx_pkt_cnt_axil,
    output logic [63:0] rx_time_elapsed_axil,
    output logic [63:0] rx_transferred_size_axil,
    output logic [63:0] latency_sum_axil
);
    logic s_axil_rst;
//resets
    sync_reset #(
        .N_STAGE (6)
    ) u_sync_s_axil_rst(
    	.clk     (s_axil_aclk),
        .rst_in  (rst),
        .rst_out (s_axil_rst)
    );

//single-bit signals
    sync_signle_bit #(
        .N_STAGE   (5),
        .INPUT_REG (1)
    ) sync_clear(
        .clk_in  (s_axil_aclk),
    	.clk_out (clk),
        .rst     (rst),
        .din     (clear_axil),
        .dout    (clear)
    );

//multi-bit signals
    sync_multi_bit #(
        .SIZE       (64),
        .N_STAGE    (5),
        .OUTPUT_REG (1)
    ) sync_tx_pkt_cnt(
    	.clk_in   (clk),
        .clk_out  (s_axil_aclk),
        .rst      (rst),
        .din      (tx_pkt_cnt),
        .din_vld  (1'b1),
        .din_rdy  (),
        .dout     (tx_pkt_cnt_axil),
        .dout_vld (),
        .dout_rdy (1'b1)
    );    
    sync_multi_bit #(
        .SIZE       (64),
        .N_STAGE    (5),
        .OUTPUT_REG (1)
    ) sync_tx_time_elapsed(
    	.clk_in   (clk),
        .clk_out  (s_axil_aclk),
        .rst      (rst),
        .din      (tx_time_elapsed),
        .din_vld  (1'b1),
        .din_rdy  (),
        .dout     (tx_time_elapsed_axil),
        .dout_vld (),
        .dout_rdy (1'b1)
    );
    sync_multi_bit #(
        .SIZE       (64),
        .N_STAGE    (5),
        .OUTPUT_REG (1)
    ) sync_tx_transferred_size(
    	.clk_in   (clk),
        .clk_out  (s_axil_aclk),
        .rst      (rst),
        .din      (tx_transferred_size),
        .din_vld  (1'b1),
        .din_rdy  (),
        .dout     (tx_transferred_size_axil),
        .dout_vld (),
        .dout_rdy (1'b1)
    );
    if (LOOPBACK) begin
        sync_signle_bit #(
            .N_STAGE   (5),
            .INPUT_REG (1)
        ) sync_mismatch(
            .clk_in  (clk),
        	.clk_out (s_axil_aclk),
            .rst     (rst),
            .din     (mismatch),
            .dout    (mismatch_axil)
        );
        sync_multi_bit #(
            .SIZE       (64),
            .N_STAGE    (5),
            .OUTPUT_REG (1)
        ) sync_rx_pkt_cnt(
        	.clk_in   (clk),
            .clk_out  (s_axil_aclk),
            .rst      (rst),
            .din      (rx_pkt_cnt),
            .din_vld  (1'b1),
            .din_rdy  (),
            .dout     (rx_pkt_cnt_axil),
            .dout_vld (),
            .dout_rdy (1'b1)
        );    
        sync_multi_bit #(
            .SIZE       (64),
            .N_STAGE    (5),
            .OUTPUT_REG (1)
        ) sync_rx_time_elapsed(
        	.clk_in   (clk),
            .clk_out  (s_axil_aclk),
            .rst      (rst),
            .din      (rx_time_elapsed),
            .din_vld  (1'b1),
            .din_rdy  (),
            .dout     (rx_time_elapsed_axil),
            .dout_vld (),
            .dout_rdy (1'b1)
        );
        sync_multi_bit #(
            .SIZE       (64),
            .N_STAGE    (5),
            .OUTPUT_REG (1)
        ) sync_rx_transferred_size(
        	.clk_in   (clk),
            .clk_out  (s_axil_aclk),
            .rst      (rst),
            .din      (rx_transferred_size),
            .din_vld  (1'b1),
            .din_rdy  (),
            .dout     (rx_transferred_size_axil),
            .dout_vld (),
            .dout_rdy (1'b1)
        );
        sync_multi_bit #(
            .SIZE       (64),
            .N_STAGE    (5),
            .OUTPUT_REG (1)
        ) sync_latency_sum(
        	.clk_in   (clk),
            .clk_out  (s_axil_aclk),
            .rst      (rst),
            .din      (latency_sum),
            .din_vld  (1'b1),
            .din_rdy  (),
            .dout     (latency_sum_axil),
            .dout_vld (),
            .dout_rdy (1'b1)
        );
    end
    else begin
        assign mismatch_axil = 1'b0;
        assign rx_pkt_cnt_axil = 64'b0;
        assign rx_time_elapsed_axil = 64'b0;
        assign rx_transferred_size_axil = 64'b0;
        assign latency_sum_axil = 64'b0;
    end
endmodule
