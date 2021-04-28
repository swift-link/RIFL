//MIT License
//
//Author: Qianfeng (Clark) Shen
//Copyright (c) 2021 swift-link
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
`timescale 1ns / 1ps
module rx_temporal_cb # (
    parameter int DWIDTH = 128,
    parameter int RATIO = 2
)
(
    input logic clk,
    input logic rst,
    input logic [$clog2(RATIO)-1:0] clk_cnt,
    input logic [DWIDTH-1:0] s_axis_tdata[RATIO-1:0],
    input logic [DWIDTH/8-1:0] s_axis_tkeep[RATIO-1:0],
    input logic s_axis_tlast[RATIO-1:0],
    input logic s_axis_tvalid[RATIO-1:0],
    output logic s_axis_tready[RATIO-1:0],
    output logic [DWIDTH-1:0] m_axis_tdata,
    output logic [DWIDTH/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tvalid,
    input logic m_axis_tready
);
    logic [RATIO-1:0] state_onehot = 1'b1;

    logic [DWIDTH-1:0] int_tdata[RATIO-1:0];
    logic [DWIDTH/8-1:0] int_tkeep[RATIO-1:0];
    logic int_tlast[RATIO-1:0];
    logic int_tvalid[RATIO-1:0];

    logic [DWIDTH-1:0] buffer_tdata[RATIO-1:0];
    logic [DWIDTH/8-1:0] buffer_tkeep[RATIO-1:0];
    logic buffer_tlast[RATIO-1:0];
    logic buffer_tvalid[RATIO-1:0];
    logic buffer_tready[RATIO-1:0];

    always_ff @(posedge clk) begin
        if (rst)
            state_onehot <= 1'b1;
        else if (m_axis_tready & m_axis_tvalid)
            state_onehot <= {state_onehot[RATIO-2:0],state_onehot[RATIO-1]};
    end

    genvar i;

    for (i = 0; i < RATIO; i++) begin
        slow2fast_buffer #(
            .DWIDTH        (DWIDTH),
            .RATIO         (RATIO)
        ) u_slow2fast_buffer(
        	.clk           (clk),
            .rst           (rst),
            .clk_cnt       (clk_cnt),
            .s_axis_tdata  (s_axis_tdata[i]),
            .s_axis_tkeep  (s_axis_tkeep[i]),
            .s_axis_tlast  (s_axis_tlast[i]),
            .s_axis_tvalid (s_axis_tvalid[i]),
            .s_axis_tready (s_axis_tready[i]),
            .m_axis_tdata  (buffer_tdata[i]),
            .m_axis_tkeep  (buffer_tkeep[i]),
            .m_axis_tlast  (buffer_tlast[i]),
            .m_axis_tvalid (buffer_tvalid[i]),
            .m_axis_tready (buffer_tready[i])
        );
        assign buffer_tready[i] = m_axis_tready & state_onehot[i];
        assign int_tdata[i] = buffer_tdata[i] & {DWIDTH{state_onehot[i]}};
        assign int_tkeep[i] = buffer_tkeep[i] & {DWIDTH/8{state_onehot[i]}};
        assign int_tlast[i] = buffer_tlast[i] & state_onehot[i];
        assign int_tvalid[i] = buffer_tvalid[i] & state_onehot[i];
    end
    always_comb begin
        m_axis_tdata = int_tdata[0];
        m_axis_tkeep = int_tkeep[0];
        m_axis_tlast = int_tlast[0];
        m_axis_tvalid = int_tvalid[0];
        for (int i = 1; i < RATIO; i++) begin
            m_axis_tdata = m_axis_tdata | int_tdata[i];
            m_axis_tkeep = m_axis_tkeep | int_tkeep[i];
            m_axis_tlast = m_axis_tlast | int_tlast[i];
            m_axis_tvalid = m_axis_tvalid | int_tvalid[i];
        end
    end
endmodule