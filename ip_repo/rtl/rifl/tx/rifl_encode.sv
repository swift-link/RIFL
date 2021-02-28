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
    input logic clk,
    input logic rst,
    input logic [PAYLOAD_WIDTH-1:0] tx_lane_tdata,
    input logic [7:0] tx_lane_byte_cnt,
    input logic tx_lane_tlast,
    input logic tx_lane_tvalid,
    output logic tx_lane_tready,
    output logic [PAYLOAD_WIDTH+1:0] rifl_tx_payload,
    input logic rifl_tx_ready
);
    logic [1:0] rifl_tx_meta;
    assign rifl_tx_meta[0] = (tx_lane_byte_cnt == PAYLOAD_WIDTH/8) && tx_lane_tvalid;
    assign rifl_tx_meta[1] = tx_lane_tlast & tx_lane_tvalid;

    assign rifl_tx_payload = rifl_tx_meta[0] ? {rifl_tx_meta,tx_lane_tdata} : {rifl_tx_meta,tx_lane_tdata[PAYLOAD_WIDTH-1:8],tx_lane_byte_cnt};

    assign tx_lane_tready = rifl_tx_ready;
endmodule