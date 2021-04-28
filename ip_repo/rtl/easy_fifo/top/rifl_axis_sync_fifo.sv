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
`timescale 1ns/1ps
module rifl_axis_sync_fifo #
(
    parameter int DWIDTH = 32,
    parameter int DEPTH = 1,
    parameter bit OUTPUT_REG = 0
)
(
    input logic rst,
    input logic clk,
    input logic [DWIDTH-1:0] s_axis_tdata,
    input logic [DWIDTH/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [DWIDTH-1:0] m_axis_tdata,
    output logic [DWIDTH/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tvalid,
    input logic m_axis_tready,
	output logic [$clog2(DEPTH):0] fifo_cnt
);
//internal data
    logic [DWIDTH*9/8:0] wr_data_int, rd_data_int;
    logic wr_en_int, rd_en_int;
    logic wr_full_int, rd_empty_int;

    rifl_sync_fifo #(
        .DWIDTH   (DWIDTH*9/8+1),
        .DEPTH    (DEPTH)
    ) u_sync_fifo (
    	.clk      (clk),
        .rst      (rst),
        .wr_data  (wr_data_int),
        .wr_en    (wr_en_int),
        .rd_en    (rd_en_int),
        .rd_data  (rd_data_int),
        .wr_full  (wr_full_int),
        .rd_empty (rd_empty_int),
		.fifo_cnt (fifo_cnt)
    );

    if (OUTPUT_REG) begin
        always_ff @(posedge clk) begin
            if (rst) begin
                m_axis_tdata <= {DWIDTH{1'b0}};
                m_axis_tkeep <= {DWIDTH/8{1'b0}};
                m_axis_tlast <= 1'b0;
                m_axis_tvalid <= 1'b0;
            end
            else if (rd_en_int) begin
                m_axis_tdata <= rd_data_int[DWIDTH-1:0];
                m_axis_tkeep <= rd_data_int[DWIDTH*9/8-1-:DWIDTH/8];
                m_axis_tlast <= rd_data_int[DWIDTH*9/8];
                m_axis_tvalid <= ~rd_empty_int;            
            end
        end
        assign rd_en_int = m_axis_tready | ~m_axis_tvalid;
    end
    else begin
        assign m_axis_tdata = rd_data_int[DWIDTH-1:0];
        assign m_axis_tkeep = rd_data_int[DWIDTH*9/8-1-:DWIDTH/8];
        assign m_axis_tlast = rd_data_int[DWIDTH*9/8];
        assign m_axis_tvalid = ~rd_empty_int;
        assign rd_en_int = m_axis_tready;        
    end

    assign wr_data_int = {s_axis_tlast,s_axis_tkeep,s_axis_tdata};
    assign wr_en_int = s_axis_tvalid;
    assign s_axis_tready = ~wr_full_int;
endmodule
