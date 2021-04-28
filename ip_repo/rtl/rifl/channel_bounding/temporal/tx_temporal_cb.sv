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
module tx_temporal_cb # (
    parameter int DWIDTH = 128,
    parameter int RATIO = 2
)
(
    input logic clk,
    input logic rst,
    input logic [$clog2(RATIO)-1:0] clk_cnt,
    input logic [DWIDTH-1:0] s_axis_tdata,
    input logic [DWIDTH/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [DWIDTH-1:0] m_axis_tdata[RATIO-1:0],
    output logic [DWIDTH/8-1:0] m_axis_tkeep[RATIO-1:0],
    output logic m_axis_tlast[RATIO-1:0],
    output logic m_axis_tvalid[RATIO-1:0],
    input logic m_axis_tready[RATIO-1:0]
);
    logic [RATIO-1:0] state_onehot = 1'b1;

    logic [DWIDTH-1:0] int_tdata[RATIO-1:0];
    logic [DWIDTH/8-1:0] int_tkeep[RATIO-1:0];
    logic int_tlast[RATIO-1:0];
    logic int_tvalid[RATIO-1:0];
    logic [RATIO-1:0] int_tready;

    always_ff @(posedge clk) begin
        if (rst)
            state_onehot <= 1'b1;
        else if (s_axis_tready & s_axis_tvalid)
            state_onehot <= {state_onehot[RATIO-2:0],state_onehot[RATIO-1]};
    end

    genvar i;

    for (i = 0; i < RATIO; i++) begin
        fast2slow_buffer #(
            .DWIDTH        (DWIDTH),
            .RATIO         (RATIO)
        ) u_fast2slow_buffer(
        	.clk           (clk),
            .rst           (rst),
            .clk_cnt       (clk_cnt),
            .s_axis_tdata  (int_tdata[i]),
            .s_axis_tkeep  (int_tkeep[i]),
            .s_axis_tlast  (int_tlast[i]),
            .s_axis_tvalid (int_tvalid[i]),
            .s_axis_tready (int_tready[i]),
            .m_axis_tdata  (m_axis_tdata[i]),
            .m_axis_tkeep  (m_axis_tkeep[i]),
            .m_axis_tlast  (m_axis_tlast[i]),
            .m_axis_tvalid (m_axis_tvalid[i]),
            .m_axis_tready (m_axis_tready[i])
        );        
        assign int_tdata[i] = s_axis_tdata;
        assign int_tkeep[i] = s_axis_tkeep;
        assign int_tlast[i] = s_axis_tlast;
        assign int_tvalid[i] = s_axis_tvalid & state_onehot[i];
    end

    assign s_axis_tready = |(int_tready & state_onehot);

endmodule