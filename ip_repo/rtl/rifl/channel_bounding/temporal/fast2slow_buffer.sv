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
module fast2slow_buffer # (
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
    output logic [DWIDTH-1:0] m_axis_tdata,
    output logic [DWIDTH/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tvalid,
    input logic m_axis_tready
);
    localparam bit [$clog2(RATIO)-1:0] SAMPLE_EDGE_IDX = RATIO - 1;

    logic [DWIDTH-1:0] int_tdata;
    logic [DWIDTH/8-1:0] int_tkeep;
    logic int_tlast;

    logic wr_flag, rd_flag;

//write logic
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_flag <= 1'b0;
            int_tdata <= {DWIDTH{1'b0}};
            int_tkeep <= {DWIDTH/8{1'b0}};
            int_tlast <= 1'b0;
        end
        else if (s_axis_tready && s_axis_tvalid && ((~m_axis_tready && m_axis_tvalid) || clk_cnt != SAMPLE_EDGE_IDX)) begin
            int_tdata <= s_axis_tdata;
            int_tkeep <= s_axis_tkeep;
            int_tlast <= s_axis_tlast;
            wr_flag <= ~wr_flag;
        end
    end
    assign s_axis_tready = ~(wr_flag ^ rd_flag);

//read logic
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_flag <= 1'b0;
            m_axis_tdata <= {DWIDTH{1'b0}};
            m_axis_tkeep <= {DWIDTH/8{1'b0}};
            m_axis_tlast <= 1'b0;
            m_axis_tvalid <= 1'b0;
        end
        else if (clk_cnt == SAMPLE_EDGE_IDX && (m_axis_tready | ~m_axis_tvalid)) begin
            if (wr_flag ^ rd_flag) begin
                m_axis_tdata <= int_tdata;
                m_axis_tkeep <= int_tkeep;
                m_axis_tlast <= int_tlast;
                m_axis_tvalid <= 1'b1;
                rd_flag <= ~rd_flag;
            end
            else begin
                m_axis_tdata <= s_axis_tdata;
                m_axis_tkeep <= s_axis_tkeep;
                m_axis_tlast <= s_axis_tlast;
                m_axis_tvalid <= s_axis_tvalid;
            end
        end
    end
endmodule