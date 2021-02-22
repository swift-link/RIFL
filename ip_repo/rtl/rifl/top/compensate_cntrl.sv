`timescale 1ns / 1ps
module clock_compensate(
    input logic init_clk,
    input logic tx_frame_clk,
    input logic rx_frame_clk,
    input logic rst,
    input logic clock_active,
    output logic compensate
);
    localparam bit [1:0] UNKNOWN = 2'd0;
    localparam bit [1:0] YES = 2'd1;
    localparam bit [1:0] NO = 2'd2;
    logic [15:0] tx_cnt_gray, rx_cnt_gray;
    logic [15:0] tx_cnt_gray_init_synced, rx_cnt_gray_init_synced;
    logic [15:0] tx_cnt_init_synced, rx_cnt_init_synced;
    logic [15:0] tx_cnt_init_syncedp1;
    logic [15:0] rx_cnt_init_syncedp1;

    logic [1:0] compensate_type;
    logic [15:0] cnt_difference;
    logic [15:0] cnt_difference_wire;
    logic cnt_diff_flag;
    logic [3:0] compensate_cnt_init;
    logic compensate_cnt_init_vld;
    logic compensate_cnt_init_rdy;
    logic [3:0] compensate_cnt_tx;
    logic compensate_cnt_tx_vld;
    logic [3:0] compensate_cnt;

//gray code counters
    graycntr #(
        .SIZE (16)
    ) tx_cntr(
        .rst  (~clock_active|rst),
        .clk  (tx_frame_clk),
        .inc  (1'b1),
        .gray (tx_cnt_gray)
    );
    graycntr #(
        .SIZE (16)
    ) rx_cntr(
        .rst  (~clock_active|rst),
        .clk  (rx_frame_clk),
        .inc  (1'b1),
        .gray (rx_cnt_gray)
    );
//cdc
    sync_signle_bit #(
        .SIZE      (16),
        .N_STAGE   (5)
    ) sync_tx_cntr(
    	.clk_in  (tx_frame_clk),
        .clk_out (init_clk),
        .rst     (rst),
        .din     (tx_cnt_gray),
        .dout    (tx_cnt_gray_init_synced)
    );
    sync_signle_bit #(
        .SIZE      (16),
        .N_STAGE   (5)
    ) sync_rx_cntr(
    	.clk_in  (rx_frame_clk),
        .clk_out (init_clk),
        .rst     (rst),
        .din     (rx_cnt_gray),
        .dout    (rx_cnt_gray_init_synced)
    );    
//gray to bin
    gray2bin #(
        .SIZE (16)
    ) u_gray2bin_tx(
    	.gray (tx_cnt_gray_init_synced),
        .bin  (tx_cnt_init_synced)
    );
    gray2bin #(
        .SIZE (16)
    ) u_gray2bin_rx(
    	.gray (rx_cnt_gray_init_synced),
        .bin  (rx_cnt_init_synced)
    );    

    sync_multi_bit #(
        .SIZE       (4)
    ) u_sync_comp_cnt(
        .rst      (rst),
    	.clk_in   (init_clk),
        .clk_out  (tx_frame_clk),
        .din      (compensate_cnt_init),
        .din_vld  (compensate_cnt_init_vld),
        .din_rdy  (compensate_cnt_init_rdy),
        .dout     (compensate_cnt_tx),
        .dout_vld (compensate_cnt_tx_vld),
        .dout_rdy (~(|compensate_cnt))
    );


    always_ff @(posedge init_clk or posedge rst) begin
        if (rst)
            compensate_type <= UNKNOWN;
        else if (compensate_type == UNKNOWN) begin
            if (tx_cnt_init_synced > rx_cnt_init_syncedp1 && ~(tx_cnt_init_synced[15]^rx_cnt_init_syncedp1[15]))
                compensate_type <= YES;
            else if (tx_cnt_init_syncedp1 < rx_cnt_init_synced && ~(tx_cnt_init_syncedp1[15]^rx_cnt_init_synced[15]))
                compensate_type <= NO;
        end
    end

    always_ff @(posedge init_clk or posedge rst) begin
        if (rst) begin
            cnt_difference <= 16'b0;
            compensate_cnt_init <= 4'b0;
            compensate_cnt_init_vld <= 1'b0;
        end
        else if (compensate_type == YES) begin
            if (compensate_cnt_init_rdy && cnt_difference_wire > cnt_difference) begin
                cnt_difference <= tx_cnt_init_synced[14:0] - rx_cnt_init_synced[14:0];
                compensate_cnt_init <= cnt_difference_wire - cnt_difference;
            end
            if (compensate_cnt_init_rdy)
                compensate_cnt_init_vld <= cnt_difference_wire > cnt_difference;
        end
    end

    always_ff @(posedge tx_frame_clk or posedge rst) begin
        if (rst)
            compensate_cnt <= 4'b0;
        else if (~(|compensate_cnt)) begin
            if (compensate_cnt_tx_vld)
                compensate_cnt <= compensate_cnt_tx;
        end
        else
            compensate_cnt <= compensate_cnt - 1'b1;
    end

    always_ff @(posedge tx_frame_clk) begin
        compensate <= |compensate_cnt;
    end

    assign cnt_diff_flag = tx_cnt_init_synced[15] ^ rx_cnt_init_synced[15];
    assign cnt_difference_wire = cnt_diff_flag ? {1'b1,tx_cnt_init_synced[14:0]} - {1'b0,rx_cnt_init_synced[14:0]} : tx_cnt_init_synced - rx_cnt_init_synced;
    assign tx_cnt_init_syncedp1 = tx_cnt_init_synced + 1'b1;
    assign rx_cnt_init_syncedp1 = rx_cnt_init_synced + 1'b1;

endmodule