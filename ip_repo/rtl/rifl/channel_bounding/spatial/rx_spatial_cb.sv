`timescale 1ns/1ps
module rx_spatial_cb #
(
    parameter int DWIDTH_IN = 240,
    parameter int DWIDTH_OUT = 240,
    parameter int N_CHANNEL = 1
)
(
    input logic clk,
    input logic rst,
    input logic [DWIDTH_IN-1:0] s_axis_tdata[N_CHANNEL-1:0],
    input logic [DWIDTH_IN/8-1:0] s_axis_tkeep[N_CHANNEL-1:0],
    input logic [N_CHANNEL-1:0] s_axis_tlast,
    input logic [N_CHANNEL-1:0] s_axis_tvalid,
    output logic [N_CHANNEL-1:0] s_axis_tready,
    output logic [DWIDTH_OUT-1:0] m_axis_tdata,
    output logic [DWIDTH_OUT/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tvalid,
    input logic m_axis_tready
);
    logic [N_CHANNEL-1:0] lane_mask;

    always_comb begin
        lane_mask = {N_CHANNEL{1'b1}};
        for (int i = N_CHANNEL-2; i >= 0; i--)
            for (int j = N_CHANNEL-1; j > i; j--)
                lane_mask[i] = lane_mask[i] & ~(s_axis_tlast[j]&s_axis_tvalid[j]);
    end
    assign s_axis_tready = {N_CHANNEL{m_axis_tready}} & lane_mask;

/*
    //this is for better timing
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < N_CHANNEL; i++) begin
                m_axis_tdata[(i+1)*DWIDTH_IN-1-:DWIDTH_IN] <= {DWIDTH_IN{1'b0}};
                m_axis_tkeep[(i+1)*DWIDTH_IN/8-1-:DWIDTH_IN/8] <= {DWIDTH_IN/8{1'b0}};
            end
            m_axis_tlast <= 1'b0;
            m_axis_tvalid <= 1'b0;
        end
        else if (m_axis_tready) begin
            for (int i = 0; i < N_CHANNEL; i++) begin
                m_axis_tdata[(i+1)*DWIDTH_IN-1-:DWIDTH_IN] <= s_axis_tdata[i];
                m_axis_tkeep[(i+1)*DWIDTH_IN/8-1-:DWIDTH_IN/8] <= s_axis_tkeep[i] & {DWIDTH_IN/8{lane_mask[i]}};
            end
            m_axis_tlast <= |(s_axis_tvalid & s_axis_tlast);
            m_axis_tvalid <= s_axis_tvalid[N_CHANNEL-1];
        end
    end
*/

    genvar i;
    for (i = 0; i < N_CHANNEL; i++) begin
        assign m_axis_tdata[(i+1)*DWIDTH_IN-1-:DWIDTH_IN] = s_axis_tdata[i];
        assign m_axis_tkeep[(i+1)*DWIDTH_IN/8-1-:DWIDTH_IN/8] = s_axis_tkeep[i] & {DWIDTH_IN/8{lane_mask[i]}};
    end
    assign m_axis_tlast = |(s_axis_tvalid & s_axis_tlast);
    assign m_axis_tvalid = |(s_axis_tvalid | ~lane_mask);

endmodule