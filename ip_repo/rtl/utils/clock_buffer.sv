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
module clock_buffer #
(
    parameter bit [2:0] GT_RATIO = 1'b1,
    parameter bit [2:0] FRAME_RATIO = 1'b1
)
(
    input logic src_clk,
    input logic rst,
    output logic usrclk,
    output logic usrclk2,
    output logic usrclk3,
    output logic usrclk_active
);
    localparam bit [2:0] GT_DIV_CODE = GT_RATIO - 1'b1;
    localparam bit [2:0] FRAME_DIV_CODE = FRAME_RATIO - 1'b1;

    (* ASYNC_REG = "TRUE" *) logic usrclk_active_meta = 1'b0;
    (* ASYNC_REG = "TRUE" *) logic usrclk_active_sync = 1'b0;

    BUFG_GT bufg_inst1 (
        .CE(1'b1),
        .CEMASK(1'b0),
        .CLR(rst),
        .CLRMASK(1'b0),
        .DIV(3'b0),
        .I(src_clk),
        .O(usrclk)
    );
    BUFG_GT bufg_inst2 (
        .CE(1'b1),
        .CEMASK(1'b0),
        .CLR(rst),
        .CLRMASK(1'b0),
        .DIV(GT_DIV_CODE),
        .I(src_clk),
        .O(usrclk2)
    );
    BUFG_GT bufg_inst3 (
        .CE(1'b1),
        .CEMASK(1'b0),
        .CLR(rst),
        .CLRMASK(1'b0),
        .DIV(FRAME_DIV_CODE),
        .I(src_clk),
        .O(usrclk3)
    );

    always_ff @(posedge usrclk2, posedge rst) begin
        if (rst) begin
            usrclk_active_meta <= 1'b0;
            usrclk_active_sync <= 1'b0;
        end
        else begin
            usrclk_active_meta <= 1'b1;
            usrclk_active_sync <= usrclk_active_meta;
        end
    end

    assign usrclk_active = usrclk_active_sync;
endmodule

