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
    function [7:0] BYTE_CNT_SUM;
        input [PAYLOAD_WIDTH/8-1:0] tkeep;
        BYTE_CNT_SUM = 8'b0;
        for (int i = 0; i < PAYLOAD_WIDTH/8; i++)
            BYTE_CNT_SUM = BYTE_CNT_SUM + tkeep[i];
    endfunction

    logic [1:0] rifl_tx_meta;
    logic [7:0] tx_lane_byte_cnt;
    assign rifl_tx_meta[0] = tx_lane_tkeep[0] & tx_lane_tvalid;
    assign rifl_tx_meta[1] = tx_lane_tlast & tx_lane_tvalid;

    always_comb begin
        if (~tx_lane_tvalid)
            rifl_tx_payload = {{PAYLOAD_WIDTH+2}{1'b0}};
        else if (tx_lane_tkeep[0])
            rifl_tx_payload = {rifl_tx_meta,tx_lane_tdata};
        else
            rifl_tx_payload = {rifl_tx_meta,tx_lane_tdata[PAYLOAD_WIDTH-1:8],tx_lane_byte_cnt};
    end
    assign tx_lane_byte_cnt = BYTE_CNT_SUM(tx_lane_tkeep);
    assign tx_lane_tready = rifl_tx_ready;
endmodule