`timescale 1ns/1ps
module tkeep_gen #(
    parameter int DWIDTH = 8,
    parameter bit [63:0] S0 = 64'd1,
    parameter bit [63:0] S1 = 64'd2
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [15:0] pkt_len_min,
    input logic [15:0] pkt_len_max,
    output logic [DWIDTH-1:0] tkeep,
    output logic tlast,
    output logic vld
);
    logic [63:0] rand64;
    logic [15:0] pkt_len_diff = 16'b0;
    logic [15:0] pkt_len[3:0];
    logic [15:0] pkt_len_mask = {16{1'b1}};

    logic [15:0] pkt_len_buf_in = 16'b0;
    logic pkt_len_buf_in_vld = 1'b0;
    logic pkt_len_buf_in_rdy;
    logic [15:0] pkt_len_buf_out;
    logic pkt_len_buf_out_vld;
    logic pkt_len_buf_out_rdy;

    logic [15:0] pkt_len_curr = 16'b0;

    axis_gen_xoshiro128ss #(
        .S0 (S0),
        .S1 (S1)
    ) u_xoshiro128ss(
        .*,
        .enable (pkt_len_buf_in_rdy)
    );

    easy_fifo_axis_sync #(
        .DWIDTH     (16),
        .DEPTH      (16)
    ) u_easy_fifo_axis_sync(
        .*,
        .s_axis_tdata  (pkt_len_buf_in),
        .s_axis_tvalid (pkt_len_buf_in_vld),
        .s_axis_tready (pkt_len_buf_in_rdy),
        .m_axis_tdata  (pkt_len_buf_out),
        .m_axis_tvalid (pkt_len_buf_out_vld),
        .m_axis_tready (pkt_len_buf_out_rdy)
    );    

    always_ff @(posedge clk) begin
        pkt_len_diff <= pkt_len_max - pkt_len_min;
    end

    genvar i;
    for (i = 0; i < 16; i++) begin
        always_ff @(posedge clk) begin
            pkt_len_mask[i] <= |pkt_len_diff[15:i];
        end
    end

    always_ff @(posedge clk) begin
        if (rst)
            pkt_len_buf_in_vld <= 1'b0;
        else if (pkt_len_buf_in_rdy) begin
            if (pkt_len[0] <= pkt_len_diff) begin
                pkt_len_buf_in <= pkt_len[0] + pkt_len_min;
                pkt_len_buf_in_vld <= 1'b1;
            end
            else if (pkt_len[1] <= pkt_len_diff) begin
                pkt_len_buf_in <= pkt_len[1] + pkt_len_min;
                pkt_len_buf_in_vld <= 1'b1;
            end
            else if (pkt_len[2] <= pkt_len_diff) begin
                pkt_len_buf_in <= pkt_len[2] + pkt_len_min;
                pkt_len_buf_in_vld <= 1'b1;
            end
            else begin
                pkt_len_buf_in_vld <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            pkt_len_curr <= 16'b0;
            vld <= 1'b0;
        end
        else if (enable) begin
            if (pkt_len_curr > 16'(DWIDTH)) begin
                pkt_len_curr <= pkt_len_curr - 16'(DWIDTH);
                vld <= 1'b1;
            end
            else if (pkt_len_buf_out_vld) begin
                pkt_len_curr <= pkt_len_buf_out;
                vld <= 1'b1;
            end
            else begin
                pkt_len_curr <= 16'b0;
                vld <= 1'b0;
            end
        end
    end

    assign pkt_len_buf_out_rdy = ((pkt_len_curr <= 16'(DWIDTH)) && enable) || (pkt_len_curr == 16'b0);
    for (i = 0; i < 4; i++)
        assign pkt_len[i] = rand64[63-i*16-:16] & pkt_len_mask;
    for (i = 0; i < DWIDTH; i++)
        assign tkeep[DWIDTH-1-i] = pkt_len_curr > 16'(i);
    assign tlast = pkt_len_curr <= 16'(DWIDTH);
endmodule
