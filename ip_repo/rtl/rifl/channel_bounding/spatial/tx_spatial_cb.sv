`timescale 1ns/1ps
module tx_spatial_cb #
(
    parameter int DWIDTH_IN = 240,
    parameter int DWIDTH_OUT = 240,
    parameter int N_CHANNEL = 1
)
(
    input logic clk,
    input logic rst,
    input logic [DWIDTH_IN-1:0] s_axis_tdata,
    input logic [DWIDTH_IN/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [DWIDTH_OUT-1:0] m_axis_tdata[N_CHANNEL-1:0],
    output logic [7:0] m_axis_byte_cnt[N_CHANNEL-1:0],
    output logic [N_CHANNEL-1:0] m_axis_tlast,
    output logic [N_CHANNEL-1:0] m_axis_tvalid,
    input logic [N_CHANNEL-1:0] m_axis_tready
);
    function [7:0] BYTE_CNT_SUM;
        input [DWIDTH_OUT/8-1:0] tkeep;
        BYTE_CNT_SUM = 8'b0;
        for (int i = 0; i < DWIDTH_OUT/8; i++)
            BYTE_CNT_SUM = BYTE_CNT_SUM + tkeep[i];
    endfunction

    logic [N_CHANNEL-1:0] lane_mask;
    logic [N_CHANNEL-1:0] m_axis_tvalid_int;
    always_comb begin
        lane_mask = {N_CHANNEL{1'b1}};
        for (int i = N_CHANNEL-2; i >= 0; i--)
            for (int j = N_CHANNEL-1; j > i; j--)
                lane_mask[i] = lane_mask[i] & ~(m_axis_tlast[j]&m_axis_tvalid_int[j]);
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < N_CHANNEL; i++) begin
                m_axis_tdata[i] <= {DWIDTH_OUT{1'b0}};
                m_axis_tlast[i] <= 1'b0;
                m_axis_tvalid_int[i] <= 1'b0;
                m_axis_byte_cnt[i] <= 8'b0;
            end
        end
        else if (s_axis_tready) begin
            for (int i = 0; i < N_CHANNEL; i++) begin
                m_axis_tdata[i] <= s_axis_tdata[(i+1)*DWIDTH_OUT-1-:DWIDTH_OUT];
                m_axis_byte_cnt[i] <= BYTE_CNT_SUM(s_axis_tkeep[(i+1)*DWIDTH_OUT/8-1-:DWIDTH_OUT/8]);
                if (i != 0)
                    m_axis_tlast[i] <= s_axis_tvalid & s_axis_tlast & s_axis_tkeep[(i+1)*DWIDTH_OUT/8-1] & ~s_axis_tkeep[i*DWIDTH_OUT/8-1];
                else
                    m_axis_tlast[i] <= s_axis_tvalid & s_axis_tlast & s_axis_tkeep[DWIDTH_OUT/8-1];
                m_axis_tvalid_int[i] = s_axis_tvalid & s_axis_tkeep[(i+1)*DWIDTH_OUT/8-1];
            end
        end
    end
    assign m_axis_tvalid = m_axis_tvalid_int & {N_CHANNEL{s_axis_tready}};
    assign s_axis_tready = &(m_axis_tready | ~lane_mask);
endmodule