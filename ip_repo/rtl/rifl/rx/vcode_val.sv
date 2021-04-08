//Polynomial should use the normal representation
`timescale 1ns/1ps
module vcode_val #
(
    parameter int FRAME_WIDTH = 256,
    parameter int DWIDTH = 64,
    parameter int CRC_WIDTH = 12,
    parameter int CRC_POLY = 12'h02f,
    parameter int FRAME_ID_WIDTH = 8
)
(
    input logic clk,
    input logic rst,
    input logic sof,
    input logic rx_up,
    input logic [DWIDTH-1:0] data_in,
    (* keep = "true" *) output logic crc_good_out = 1'b0,
    (* keep = "true" *) output logic rx_error = 1'b0,
    (* keep = "true" *) output logic isdata = 1'b0
);
    localparam bit [FRAME_ID_WIDTH-1:0] ROLLBACK_CYCLES = 'd16;

    logic [DWIDTH-1:0] data_int;
    logic [CRC_WIDTH-1:0] crc_golden;

    (* keep = "true" *) logic [FRAME_ID_WIDTH-1:0] frame_id;
    (* keep = "true" *) logic [FRAME_ID_WIDTH-1:0] frame_id_threshold = ROLLBACK_CYCLES;

    logic [CRC_WIDTH-1:0] crc_int_in, crc_int_out;
    (* keep = "true" *) logic [CRC_WIDTH-1:0] crc_previous;
    logic crc_good;

    always_comb begin
        crc_int_in = crc_previous;
        for (int i = 0; i < DWIDTH; i++) begin
            crc_int_out[0] = crc_int_in[CRC_WIDTH-1] ^ data_int[DWIDTH-1-i];
            for (int j = 1; j < CRC_WIDTH; j++) begin
                crc_int_out[j] = crc_int_in[j-1];
                if (CRC_POLY[j])
                    crc_int_out[j] = crc_int_out[j] ^ crc_int_out[0];
            end
            crc_int_in = crc_int_out;
        end
    end

    if (FRAME_WIDTH == DWIDTH) begin
        always_ff @(posedge clk) begin
            if (rst) begin
                frame_id <= {FRAME_ID_WIDTH{1'b0}};
                frame_id_threshold <= ROLLBACK_CYCLES;
                rx_error <= 1'b0;
            end
            else if (rx_up) begin
                if (crc_good && data_in[DWIDTH-1-:2] == 2'b01)
                    frame_id <= frame_id + 1'b1;
                else if (~crc_good)
                    frame_id <= frame_id_threshold - ROLLBACK_CYCLES;
                if (~crc_good)
                    rx_error <= 1'b1;
                else if (frame_id_threshold === (frame_id + 1'b1) && crc_good)
                    rx_error <= 1'b0;
                if (frame_id_threshold == frame_id && crc_good && data_in[DWIDTH-1-:2] == 2'b01)
                    frame_id_threshold <= frame_id_threshold + 1'b1;
            end
        end
        always_ff @(posedge clk) begin
            if (rst)
                crc_good_out <= 1'b0;
            else
            //one cycle for descrambler
                crc_good_out <= frame_id_threshold == frame_id && crc_good && data_in[DWIDTH-1-:2] == 2'b01;
        end
        always_ff @(posedge clk) begin
            if (rst)
                isdata <= 1'b0;
            else if (~rx_up)
                isdata <= 1'b0;
            else
                isdata <= data_in[DWIDTH-1-:2] == 2'b01 ? 1'b1 : 1'b0;
        end
        assign crc_previous = {CRC_WIDTH{1'b0}};
        assign data_int = {data_in[DWIDTH-1:CRC_WIDTH],{CRC_WIDTH{1'b0}}};

        assign crc_good = ~(|(crc_golden ^ crc_int_out ^ frame_id));
        assign crc_golden = data_in[CRC_WIDTH-1:0];
    end
    else begin
        localparam int CNT_WIDTH = $clog2(FRAME_WIDTH/DWIDTH) == 0 ? 1 : $clog2(FRAME_WIDTH/DWIDTH);
        localparam bit [CNT_WIDTH-1:0] TAIL_CNT = (1 << $clog2(FRAME_WIDTH/DWIDTH)) - 1;
        (* keep = "true" *) logic [CNT_WIDTH-1:0] cnt = {CNT_WIDTH{1'b0}};
        always_ff @(posedge clk) begin
            if (rst)
                cnt <= 'b0;
            else if (sof & rx_up)
                cnt <= 'b1;
            else if (|cnt)
                cnt <= cnt + 1'b1;
        end
        always_ff @(posedge clk) begin
            if (rst)
                isdata <= 1'b0;
            else if (sof & rx_up)
                isdata <= data_in[DWIDTH-1-:2] == 2'b01 ? 1'b1 : 1'b0;
            else if (cnt == 'b0)
                isdata <= 1'b0;
        end
        always_ff @(posedge clk) begin
            if (rst)
                crc_previous <= {CRC_WIDTH{1'b0}};
            else if (cnt == TAIL_CNT)
                crc_previous <= {CRC_WIDTH{1'b0}};
            else if ((|cnt) || (sof & rx_up))
                crc_previous <= crc_int_out;
        end
        always_ff @(posedge clk) begin
            if (rst) begin
                frame_id <= {FRAME_ID_WIDTH{1'b0}};
                frame_id_threshold <= ROLLBACK_CYCLES;
                rx_error <= 1'b0;
            end
            else if (cnt == TAIL_CNT) begin
                if (crc_good & isdata)
                    frame_id <= frame_id + 1'b1;
                else if (~crc_good)
                    frame_id <= frame_id_threshold - ROLLBACK_CYCLES;
                if (~crc_good)
                    rx_error <= 1'b1;
                else if ((frame_id_threshold == frame_id + 1'b1) && crc_good)
                    rx_error <= 1'b0;
                if (frame_id_threshold == frame_id && crc_good && isdata)
                    frame_id_threshold <= frame_id_threshold + 1'b1;
            end
        end
        always_ff @(posedge clk) begin
            if (rst)
                crc_good_out <= 1'b0;
            else if (cnt == TAIL_CNT)
            //one cycle for descrambler
                crc_good_out <= frame_id_threshold == frame_id && crc_good;
            else
                crc_good_out <= 1'b0;
        end
        assign data_int = (cnt == TAIL_CNT) ? {data_in[DWIDTH-1:CRC_WIDTH],{CRC_WIDTH{1'b0}}} : data_in;

        assign crc_golden = data_in[CRC_WIDTH-1:0];
        assign crc_good = ~(|(crc_golden ^ crc_int_out ^ frame_id));
    end
endmodule