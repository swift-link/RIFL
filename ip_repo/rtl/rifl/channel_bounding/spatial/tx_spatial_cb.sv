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
    output logic [DWIDTH_OUT/8-1:0] m_axis_tkeep[N_CHANNEL-1:0],
    output logic [N_CHANNEL-1:0] m_axis_tlast,
    output logic [N_CHANNEL-1:0] m_axis_tvalid,
    input logic [N_CHANNEL-1:0] m_axis_tready
);
    logic [N_CHANNEL-1:0] lane_mask;
    logic [N_CHANNEL-1:0] m_axis_tvalid_int;
    always_comb begin
        lane_mask = {N_CHANNEL{1'b1}};
        for (int i = N_CHANNEL-2; i >= 0; i--)
            for (int j = N_CHANNEL-1; j > i; j--)
                lane_mask[i] = lane_mask[i] & ~(m_axis_tlast[j]&m_axis_tvalid_int[j]);
    end

    genvar i;
    for (i = 0; i < N_CHANNEL; i++) begin
        assign m_axis_tdata[i] = s_axis_tdata[(i+1)*DWIDTH_OUT-1-:DWIDTH_OUT];
        assign m_axis_tkeep[i] = s_axis_tkeep[(i+1)*DWIDTH_OUT/8-1-:DWIDTH_OUT/8];
        assign m_axis_tvalid_int[i] = s_axis_tvalid & s_axis_tkeep[(i+1)*DWIDTH_OUT/8-1];
    end
    assign m_axis_tlast[0] = s_axis_tvalid & s_axis_tlast & s_axis_tkeep[DWIDTH_OUT/8-1];
    for (i = 1; i < N_CHANNEL; i++) begin
       assign m_axis_tlast[i] = s_axis_tvalid & s_axis_tlast & s_axis_tkeep[(i+1)*DWIDTH_OUT/8-1] & ~s_axis_tkeep[i*DWIDTH_OUT/8-1];
    end 
    assign m_axis_tvalid = m_axis_tvalid_int & {N_CHANNEL{s_axis_tready}};
    assign s_axis_tready = &(m_axis_tready | ~lane_mask);
endmodule