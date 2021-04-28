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
/*
    Meta Code       Valid Frame     EOP     ABV
    00                  NO          NO      NO
    01                  YES         NO      YES
    10                  YES         YES     NO
    11                  YES         YES     YES
    meta[0]=ABV
    meta[1]=EOP
*/
`timescale 1ns/1ps
module rifl_encode #(
    parameter int PAYLOAD_WIDTH = 240
)
(
    input logic [PAYLOAD_WIDTH-1:0] tx_lane_tdata,
    input logic [PAYLOAD_WIDTH/8-1:0] tx_lane_tkeep,
    input logic tx_lane_tlast,
    input logic tx_lane_tvalid,
    output logic tx_lane_tready,
    output logic [PAYLOAD_WIDTH+1:0] rifl_tx_payload,
    input logic rifl_tx_ready
);
    logic [1:0] rifl_tx_meta;
    logic [7:0] tx_lane_byte_cnt;
    assign rifl_tx_meta[0] = tx_lane_tkeep[0] & tx_lane_tvalid;
    assign rifl_tx_meta[1] = tx_lane_tlast & tx_lane_tvalid;

    always_comb begin
        tx_lane_byte_cnt = 8'b0;
        for (int i = 0; i < PAYLOAD_WIDTH/8; i++)
            tx_lane_byte_cnt = tx_lane_byte_cnt + tx_lane_tkeep[i];
    end

    always_comb begin
        if (~tx_lane_tvalid)
            rifl_tx_payload = {{PAYLOAD_WIDTH+2}{1'b0}};
        else if (tx_lane_tkeep[0])
            rifl_tx_payload = {rifl_tx_meta,tx_lane_tdata};
        else
            rifl_tx_payload = {rifl_tx_meta,tx_lane_tdata[PAYLOAD_WIDTH-1:8],tx_lane_byte_cnt};
    end
    assign tx_lane_tready = rifl_tx_ready;
endmodule
