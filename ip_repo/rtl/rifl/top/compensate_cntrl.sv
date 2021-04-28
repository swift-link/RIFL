//MIT License
//
//Author: Qianfeng (Clark) Shen;Contact: qianfeng.shen@gmail.com
//
//Copyright (c) 2021 swift-link
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
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
    localparam int CNT_WIDTH = 4;

    logic [CNT_WIDTH-1:0] tx_cnt_gray, rx_cnt_gray;
    logic [CNT_WIDTH-1:0] tx_cnt_gray_init_synced, rx_cnt_gray_init_synced;
    logic [CNT_WIDTH-1:0] tx_cnt_init_synced, rx_cnt_init_synced;
    logic [CNT_WIDTH-1:0] tx_cnt_init_syncedp1;
    logic [CNT_WIDTH-1:0] rx_cnt_init_syncedp1;

    logic [1:0] compensate_type;
    logic [CNT_WIDTH-1:0] cnt_difference;
    logic [CNT_WIDTH-1:0] cnt_difference_wire;
    logic cnt_diff_flag;
    logic [CNT_WIDTH-1:0] compensate_cnt_init;
    logic compensate_cnt_init_vld;
    logic compensate_cnt_init_vld_wire;
    logic compensate_cnt_init_rdy;
    logic [CNT_WIDTH-1:0] compensate_cnt_tx;
    logic compensate_cnt_tx_vld;
    logic [CNT_WIDTH-1:0] compensate_cnt;

//gray code counters
    graycntr #(
        .SIZE (CNT_WIDTH)
    ) tx_cntr(
        .rst  (~clock_active),
        .clk  (tx_frame_clk),
        .inc  (1'b1),
        .gray (tx_cnt_gray)
    );
    graycntr #(
        .SIZE (CNT_WIDTH)
    ) rx_cntr(
        .rst  (~clock_active),
        .clk  (rx_frame_clk),
        .inc  (1'b1),
        .gray (rx_cnt_gray)
    );
//cdc
    sync_signle_bit #(
        .SIZE      (CNT_WIDTH),
        .N_STAGE   (5)
    ) sync_tx_cntr(
    	.clk_in  (tx_frame_clk),
        .clk_out (init_clk),
        .rst     (rst),
        .din     (tx_cnt_gray),
        .dout    (tx_cnt_gray_init_synced)
    );
    sync_signle_bit #(
        .SIZE      (CNT_WIDTH),
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
        .SIZE (CNT_WIDTH)
    ) u_gray2bin_tx(
    	.gray (tx_cnt_gray_init_synced),
        .bin  (tx_cnt_init_synced)
    );
    gray2bin #(
        .SIZE (CNT_WIDTH)
    ) u_gray2bin_rx(
    	.gray (rx_cnt_gray_init_synced),
        .bin  (rx_cnt_init_synced)
    );    

    sync_multi_bit #(
        .SIZE       (CNT_WIDTH)
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
        else if (~clock_active)
            compensate_type <= UNKNOWN;
        else if (compensate_type == UNKNOWN && tx_cnt_init_synced != rx_cnt_init_synced) begin
            if (tx_cnt_init_synced != rx_cnt_init_syncedp1 && (tx_cnt_init_synced-rx_cnt_init_syncedp1) < 3'd4)
                compensate_type <= YES;
            else if (tx_cnt_init_syncedp1 != rx_cnt_init_synced && (rx_cnt_init_synced-tx_cnt_init_syncedp1) < 3'd4)
                compensate_type <= NO;
        end
    end

    always_ff @(posedge init_clk or posedge rst) begin
        if (rst) begin
            cnt_difference <= {CNT_WIDTH{1'b0}};
            compensate_cnt_init <= {CNT_WIDTH{1'b0}};
            compensate_cnt_init_vld <= 1'b0;
        end
        else if (~clock_active) begin
            cnt_difference <= {CNT_WIDTH{1'b0}};
            compensate_cnt_init <= {CNT_WIDTH{1'b0}};
            compensate_cnt_init_vld <= 1'b0;
        end
        else if (compensate_type == YES) begin
            if (compensate_cnt_init_rdy && compensate_cnt_init_vld_wire) begin
                cnt_difference <= cnt_difference_wire;
                compensate_cnt_init <= cnt_difference_wire - cnt_difference;
            end
            if (compensate_cnt_init_rdy)
                compensate_cnt_init_vld <= compensate_cnt_init_vld_wire;
        end
    end

    always_ff @(posedge tx_frame_clk or posedge rst) begin
        if (rst)
            compensate_cnt <= {CNT_WIDTH{1'b0}};
        else if (~clock_active)
            compensate_cnt <= {CNT_WIDTH{1'b0}};
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

    //sometimes cnt_difference_wire can be smaller than cnt_difference even if compensate type is yes
    //leading to a very high difference between cnt_difference_wire and cnt_difference
    //it doesn't reflect the real difference
    assign compensate_cnt_init_vld_wire = cnt_difference_wire != cnt_difference && (cnt_difference_wire-cnt_difference) < 3'd4;
    assign cnt_difference_wire = tx_cnt_init_synced - rx_cnt_init_synced;
    assign tx_cnt_init_syncedp1 = tx_cnt_init_synced + 1'b1;
    assign rx_cnt_init_syncedp1 = rx_cnt_init_synced + 1'b1;

endmodule