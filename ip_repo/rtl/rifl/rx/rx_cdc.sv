module rx_cdc (
    input logic tx_frame_clk,
    input logic rst,
    input logic pause_req_rx,
    input logic retrans_req_rx,
    input logic rx_aligned_rx,
    input logic rx_up_rx,
    input logic rx_error_rx,
    output logic pause_req_tx,
    output logic retrans_req_tx,
    output logic rx_aligned_tx,
    output logic rx_up_tx,
    output logic rx_error_tx   
);
    sync_signle_bit sync_pause(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (pause_req_rx),
        .dout    (pause_req_tx)
    );
    sync_signle_bit sync_retrans(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (retrans_req_rx),
        .dout    (retrans_req_tx)
    );
    sync_signle_bit sync_rx_up(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (rx_up_rx),
        .dout    (rx_up_tx)
    );
    sync_signle_bit sync_rx_aligned(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (rx_aligned_rx),
        .dout    (rx_aligned_tx)
    );
    sync_signle_bit sync_rx_error(
        .clk_in  (1'b0),
    	.clk_out (tx_frame_clk),
        .rst     (rst),
        .din     (rx_error_rx),
        .dout    (rx_error_tx)
    );    

endmodule