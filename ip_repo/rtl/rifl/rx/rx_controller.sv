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
            pause_req <= 1'b0;
            retrans_req <= 1'b0;
        end
        else if (~rx_aligned) begin
            pause_cnt <= 4'b0;
            retrans_cnt <= 4'b0;
            regular_cnt <= 5'b0;
            pause_req <= 1'b0;
            retrans_req <= 1'b0;            
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
            else begin
                pause_cnt <= 4'b0;
                retrans_cnt <= 4'b0;
            end
            if (code[15:0] != IDLE_KEY && code[17:16] != 2'b01)
                regular_cnt <= 5'b0;
            else if (~regular_cnt[4])
                regular_cnt <= regular_cnt + 1'b1;

            if (pause_cnt[3])
                pause_req <= 1'b1;
            else if (retrans_cnt[3] | regular_cnt[4])
                pause_req <= 1'b0;

            if (regular_cnt[4])
                retrans_req <= 1'b0;
            else if (retrans_cnt[3])
                retrans_req <= 1'b1;
        end        
    end

endmodule