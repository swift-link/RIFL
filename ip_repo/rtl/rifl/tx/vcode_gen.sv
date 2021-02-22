//Polynomial should use the normal representation
`timescale 1ns/1ps
module vcode_gen #
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
    input logic [DWIDTH-1:0] data_in,
    output logic [DWIDTH-1:0] data_out
);
    logic [FRAME_ID_WIDTH-1:0] frame_id = {FRAME_ID_WIDTH{1'b0}};

    logic [CRC_WIDTH-1:0] crc_int_in, crc_int_out;
    logic [CRC_WIDTH-1:0] crc_previous = {CRC_WIDTH{1'b0}};

    always_comb begin
        crc_int_in = crc_previous;
        for (int i = 0; i < DWIDTH; i++) begin
            crc_int_out[0] = crc_int_in[CRC_WIDTH-1] ^ data_in[DWIDTH-1-i];
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
            if (rst)
                frame_id <= {FRAME_ID_WIDTH{1'b0}};
            else if (sof && data_in[DWIDTH-1-:2] == 2'b01)
                frame_id <= frame_id + 1'b1;
        end
        always_ff @(posedge clk) begin
            data_out <= {data_in[DWIDTH-1:CRC_WIDTH],crc_int_out} ^ frame_id;
        end
    end
    else begin
        localparam int CNT_WIDTH = $clog2(FRAME_WIDTH/DWIDTH) == 0 ? 1 : $clog2(FRAME_WIDTH/DWIDTH);
        localparam bit [CNT_WIDTH-1:0] TAIL_CNT = (1 << $clog2(FRAME_WIDTH/DWIDTH)) - 1;
        logic [CNT_WIDTH-1:0] cnt = {CNT_WIDTH{1'b0}};
        logic isdata = 1'b0;
        always_ff @(posedge clk) begin
            if (sof)
                cnt <= 'b1;
            else if (cnt != 'b0)
                cnt <= cnt + 1'b1;
        end
        always_ff @(posedge clk) begin
            if (cnt == TAIL_CNT)
                isdata <= 1'b0;
            else if (sof)
                isdata <= data_in[DWIDTH-1-:2] == 2'b01 ? 1'b1 : 1'b0;
        end
        always_ff @(posedge clk) begin
            if (rst)
                frame_id <= {FRAME_ID_WIDTH{1'b0}};
            else if (cnt == TAIL_CNT && isdata)
                frame_id <= frame_id + 1'b1;
        end
        always_ff @(posedge clk) begin
            if (cnt == TAIL_CNT)
                crc_previous <= {CRC_WIDTH{1'b0}};
            else if ((sof && data_in[DWIDTH-1-:2] == 2'b01) || isdata)
                crc_previous <= crc_int_out;
        end
        always_ff @(posedge clk) begin
            if (cnt == TAIL_CNT)
                data_out <= {data_in[DWIDTH-1:CRC_WIDTH],crc_int_out} ^ frame_id;
            else
                data_out <= data_in;
        end
    end
endmodule