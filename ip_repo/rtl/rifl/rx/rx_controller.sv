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
module rx_controller (
    input logic clk,
    input logic rst,
    input logic sof,
    input logic rx_aligned,
    input logic [17:0] code,
    output logic pause_req,
    output logic retrans_req
);
    localparam bit [15:0] IDLE_KEY = 16'h001;
    localparam bit [15:0] PAUSE_KEY = 16'h0010;
    localparam bit [15:0] RETRANS_KEY = 16'h1000;
    logic [3:0] pause_cnt;
    logic [3:0] retrans_cnt;
    logic [4:0] regular_cnt;
    always_ff @(posedge clk) begin
        if (rst) begin
            pause_cnt <= 4'b0;
            retrans_cnt <= 4'b0;
            regular_cnt <= 5'b0;
        end
        else if (~rx_aligned) begin
            pause_cnt <= 4'b0;
            retrans_cnt <= 4'b0;
            regular_cnt <= 5'b0;
        end
        else if (sof) begin
            if (code[17:16] == 2'b10) begin
                if (code[15:0] != PAUSE_KEY)
                    pause_cnt <= 4'b0;
                else if (~pause_cnt[3])
                    pause_cnt <= pause_cnt + 1'b1;
                if (code[15:0] != RETRANS_KEY)
                    retrans_cnt <= 4'b0;
                else if (~retrans_cnt[3])
                    retrans_cnt <= retrans_cnt + 1'b1;
            end
            else if (regular_cnt[4]) begin
                pause_cnt <= 4'b0;
                retrans_cnt <= 4'b0;
            end
            if (code[15:0] != IDLE_KEY && code[17:16] != 2'b01)
                regular_cnt <= 5'b0;
            else if (~regular_cnt[4])
                regular_cnt <= regular_cnt + 1'b1;
        end        
    end
    assign retrans_req = retrans_cnt[3];
    assign pause_req = pause_cnt[3];
endmodule