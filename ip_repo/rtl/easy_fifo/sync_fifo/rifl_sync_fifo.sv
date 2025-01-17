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
module rifl_sync_fifo #
(
    parameter int DWIDTH = 32,
    parameter int DEPTH = 512
)
(
    input logic clk,
    input logic rst,
    input logic [DWIDTH-1:0] wr_data,
    input logic wr_en,
    input logic rd_en,
    output logic [DWIDTH-1:0] rd_data,
    output logic wr_full,
    output logic rd_empty,
    output logic [$clog2(DEPTH):0] fifo_cnt
);
    localparam int LUT_DEPTH = DEPTH < 16 ? DEPTH : 16;
    localparam int BRAM_DEPTH = 1 << $clog2(DEPTH-LUT_DEPTH);
    localparam RAM_STYLE = BRAM_DEPTH > 32 ? "block" : "distributed";
    logic [DWIDTH-1:0] fifo_lutram[LUT_DEPTH-1:0];
    logic [$clog2(LUT_DEPTH)-1:0] lutram_rd_addr;
    logic [$clog2(LUT_DEPTH)-1:0] lutram_wr_addr;
    logic [$clog2(LUT_DEPTH):0] lutram_rd_ptr;
    logic [$clog2(LUT_DEPTH):0] lutram_wr_ptr;

    logic [DWIDTH-1:0] data_from_fifo;

    logic lutram_empty;
    logic lutram_full;
    logic input_to_output;
    logic input_to_lutram;

    logic [$clog2(LUT_DEPTH):0] lutram_cnt;

    if (DEPTH > 16) begin
        (* ram_style = RAM_STYLE *) logic [DWIDTH-1:0] fifo_bram[BRAM_DEPTH-1:0];
        logic [$clog2(BRAM_DEPTH)-1:0] bram_rd_addr;
        logic [$clog2(BRAM_DEPTH)-1:0] bram_wr_addr;
        logic [$clog2(BRAM_DEPTH):0] bram_rd_ptr;
        logic [$clog2(BRAM_DEPTH):0] bram_wr_ptr;
        logic [DWIDTH-1:0] bram_reg_1, bram_reg_2;
        logic bram_valid_1, bram_valid_2;
        logic bram_to_lutram, bram_to_lutram_1, bram_to_lutram_2;
        logic input_to_bram;
        logic bram_full;
        logic bram_empty;
        logic [$clog2(BRAM_DEPTH):0] bram_cnt;

        always_ff @(posedge clk) begin
            bram_reg_1 <= fifo_bram[bram_rd_addr];
            bram_reg_2 <= bram_reg_1;
        end
        always_ff @(posedge clk) begin
            if (rst) begin
                lutram_rd_ptr <= {{$clog2(LUT_DEPTH)+1}{1'b0}};
                lutram_wr_ptr <= {{$clog2(LUT_DEPTH)+1}{1'b0}};
                bram_rd_ptr <= {{$clog2(BRAM_DEPTH)+1}{1'b0}};
                bram_wr_ptr <= {{$clog2(BRAM_DEPTH)+1}{1'b0}};
                bram_valid_1 <= 1'b0;
                bram_valid_2 <= 1'b0;
                bram_to_lutram <= 1'b0;
                bram_to_lutram_1 <= 1'b0;
                bram_to_lutram_2 <= 1'b0;
                fifo_cnt <= {($clog2(DEPTH)+1){1'b0}};
            end
            else begin
                fifo_cnt <= bram_cnt+lutram_cnt;
                if (~bram_full & input_to_bram) begin
                    fifo_bram[bram_wr_addr] <= wr_data;
                    bram_wr_ptr <= bram_wr_ptr + 1'b1;
                end

                if (input_to_lutram)
                    fifo_lutram[lutram_wr_addr] <= wr_data;
                else if (bram_to_lutram_2 & bram_valid_2)
                    fifo_lutram[lutram_wr_addr] <= bram_reg_2;

                if (input_to_lutram | (bram_to_lutram_2 & bram_valid_2))
                    lutram_wr_ptr <= lutram_wr_ptr + 1'b1;

                if (bram_rd_ptr != bram_wr_ptr && bram_to_lutram)
                    bram_rd_ptr <= bram_rd_ptr + 1'b1;

                bram_valid_1 <= bram_rd_ptr != bram_wr_ptr;
                bram_valid_2 <= bram_valid_1;

                bram_to_lutram_1 <= bram_to_lutram;
                bram_to_lutram_2 <= bram_to_lutram_1;

                if (lutram_wr_ptr-lutram_rd_ptr <= 5'd8)
                    bram_to_lutram <= 1'b1;
                else
                    bram_to_lutram <= 1'b0;

                if (rd_en && lutram_rd_ptr != lutram_wr_ptr)
                    lutram_rd_ptr <= lutram_rd_ptr + 1'b1;
            end
        end
        assign wr_full = bram_full;
        assign bram_full = bram_rd_ptr == {~bram_wr_ptr[$clog2(BRAM_DEPTH)], bram_wr_addr};
        assign bram_empty = bram_rd_ptr == bram_wr_ptr && ~bram_valid_1 && ~bram_valid_2;
        assign bram_wr_addr = bram_wr_ptr[$clog2(BRAM_DEPTH)-1:0];
        assign bram_rd_addr = bram_rd_ptr[$clog2(BRAM_DEPTH)-1:0];
        assign input_to_output = lutram_empty & bram_empty & rd_en;
        assign input_to_bram = wr_en && (~bram_empty || lutram_full);
        assign input_to_lutram = (~lutram_empty | ~rd_en) & bram_empty & wr_en & ~lutram_full;

        assign bram_cnt = bram_wr_ptr-bram_rd_ptr;
        assign rd_data = (lutram_empty & bram_empty) ? wr_data : data_from_fifo;
        assign rd_empty = lutram_empty & (~wr_en | ~bram_empty);
    end
    else begin
        always_ff @(posedge clk) begin
            if (rst) begin
                lutram_rd_ptr <= {($clog2(LUT_DEPTH)+1){1'b0}};
                lutram_wr_ptr <= {($clog2(LUT_DEPTH)+1){1'b0}};
                fifo_cnt <= {($clog2(DEPTH)+1){1'b0}};
            end
            else begin
                fifo_cnt <= lutram_cnt;
                if (input_to_lutram) begin
                    fifo_lutram[lutram_wr_addr] <= wr_data;
                    lutram_wr_ptr <= lutram_wr_ptr + 1'b1;
                end
                if (rd_en && lutram_rd_ptr != lutram_wr_ptr)
                    lutram_rd_ptr <= lutram_rd_ptr + 1'b1;
            end
        end
        assign wr_full = lutram_full;
        assign input_to_output = lutram_empty & rd_en;
        assign input_to_lutram = ~input_to_output & wr_en & ~lutram_full;
        assign rd_data = lutram_empty ? wr_data : data_from_fifo;
        assign rd_empty = lutram_empty & ~wr_en;
    end

    assign lutram_wr_addr = lutram_wr_ptr[$clog2(LUT_DEPTH)-1:0];
    assign lutram_rd_addr = lutram_rd_ptr[$clog2(LUT_DEPTH)-1:0];
    assign lutram_full = lutram_rd_ptr == {~lutram_wr_ptr[$clog2(LUT_DEPTH)],lutram_wr_addr};
    assign lutram_empty = lutram_rd_ptr == lutram_wr_ptr;

    assign data_from_fifo = fifo_lutram[lutram_rd_addr];

    assign lutram_cnt = lutram_wr_ptr - lutram_rd_ptr;
endmodule
