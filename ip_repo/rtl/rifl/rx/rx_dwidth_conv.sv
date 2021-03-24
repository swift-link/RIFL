`timescale 1ns / 1ps
/*
    Meta Code       Valid Frame     EOP     ABV
    00                  NO          NO      NO
    01                  YES         NO      YES
    10                  YES         YES     NO
    11                  YES         YES     YES
    meta[0]=ABV
    meta[1]=EOP
*/
module rx_dwidth_conv # 
(
   parameter int DWIDTH = 64,
   parameter int FRAME_WIDTH = 256,
   parameter int PAYLOAD_WIDTH = 240,
   parameter int CNT_WIDTH = 1
)
(
    input logic clk,
    input logic rst,
    input logic [CNT_WIDTH-1:0] clk_cnt,
    input logic [DWIDTH-1:0] din,
    input logic data_sof,
    input logic crc_good,
    input logic din_valid,
    output logic [PAYLOAD_WIDTH-1:0] dwidth_conv_out_tdata,
    output logic [PAYLOAD_WIDTH/8-1:0] dwidth_conv_out_tkeep,
    output logic dwidth_conv_out_tlast,
    output logic dwidth_conv_out_tvalid
);
    logic [1:0] rifl_rx_meta = 2'b0;

    if (DWIDTH == FRAME_WIDTH) begin
        genvar i;
        assign dwidth_conv_out_tdata = din[DWIDTH-5-:PAYLOAD_WIDTH];
        for (i = 0; i < PAYLOAD_WIDTH/8; i++)
            assign dwidth_conv_out_tkeep[PAYLOAD_WIDTH/8-1-i] = (din[DWIDTH+3-PAYLOAD_WIDTH-:8] > i && |rifl_rx_meta) || rifl_rx_meta[0];
        assign dwidth_conv_out_tlast = rifl_rx_meta[1];
        always_comb begin
            rifl_rx_meta = din[DWIDTH-3-:2];
            dwidth_conv_out_tvalid = (|rifl_rx_meta[0]) & crc_good & din_valid;
        end
    end
    else begin
        localparam int RATIO = FRAME_WIDTH / DWIDTH;
        localparam bit [$clog2(RATIO)-1:0] EOF_CNT = RATIO-1;
        localparam int DWIDTH_INT = FRAME_WIDTH - DWIDTH;
        localparam bit [CNT_WIDTH-1:0] SAMPLE_EDGE_IDX = (1 << CNT_WIDTH) - 1;

        logic [PAYLOAD_WIDTH-1:0] int_tdata;
        logic [PAYLOAD_WIDTH/8-1:0] int_tkeep;
        logic int_tlast;
        logic int_tvalid;

        logic [$clog2(RATIO)-1:0] cnt = {$clog2(RATIO){1'b0}};
        logic [DWIDTH_INT-1:0] int_reg = {DWIDTH_INT{1'b0}};

        logic buffer_wr_flag = 1'b0;
        logic buffer_rd_flag = 1'b0;

        if (2*DWIDTH == FRAME_WIDTH) begin
            always_ff @(posedge clk) begin
                if (din_valid) begin
                    if (data_sof)
                        cnt <= 1'b1;
                    else
                        cnt <= ~cnt;
                end
            end
            always_ff @(posedge clk) begin
                if (rst) begin
                    buffer_wr_flag <= 1'b0;
                end
                else if (din_valid) begin
                    if (data_sof) begin
                        int_reg <= din;
                        rifl_rx_meta <= din[DWIDTH-3-:2];
                    end

                    if (cnt & ~clk_cnt) begin
                        int_tdata <= {int_reg[DWIDTH-5:0],din[DWIDTH-1:FRAME_WIDTH-4-PAYLOAD_WIDTH]};
                        for (int i = 0; i < PAYLOAD_WIDTH/8; i++)
                            int_tkeep[PAYLOAD_WIDTH/8-1-i] <= rifl_rx_meta[0] || (din[FRAME_WIDTH+3-PAYLOAD_WIDTH-:8] > i && |rifl_rx_meta);
                        int_tlast <= rifl_rx_meta[1];
                        int_tvalid <= (|rifl_rx_meta) & crc_good;
                        buffer_wr_flag <= ~buffer_wr_flag;
                    end
                end
            end
        end
        else begin
            always_ff @(posedge clk) begin
                if (din_valid) begin
                    if (data_sof)
                        cnt <= {{($clog2(RATIO)-1){1'b0}},1'b1};
                    else
                        cnt <= cnt + 1'b1;
                end
            end
            always_ff @(posedge clk) begin
                if (rst) begin
                    buffer_wr_flag <= 1'b0;
                end
                else if (din_valid) begin
                    if (data_sof) begin
                        int_reg <= {{(DWIDTH_INT-DWIDTH){1'b0}},din};
                        rifl_rx_meta <= din[DWIDTH-3-:2];
                    end
                    else
                        int_reg <= {int_reg[DWIDTH_INT-DWIDTH-1:0],din};
                    if (cnt == EOF_CNT && clk_cnt != SAMPLE_EDGE_IDX) begin
                        int_tdata <= {int_reg[DWIDTH_INT-5:0],din[DWIDTH-1:FRAME_WIDTH-4-PAYLOAD_WIDTH]};
                        for (int i = 0; i < PAYLOAD_WIDTH/8; i++)
                            int_tkeep[PAYLOAD_WIDTH/8-1-i] <= rifl_rx_meta[0] || (din[FRAME_WIDTH+3-PAYLOAD_WIDTH-:8] > i && |rifl_rx_meta);
                        int_tlast <= rifl_rx_meta[1];
                        int_tvalid <= (|rifl_rx_meta) && crc_good;
                        buffer_wr_flag <= ~buffer_wr_flag;
                    end
                end
            end
        end
        always_ff @(posedge clk) begin
            if (rst) begin
                buffer_rd_flag <= 1'b0;
                dwidth_conv_out_tvalid <= 1'b0;
            end
            else if (clk_cnt == SAMPLE_EDGE_IDX) begin
                if (buffer_wr_flag ^ buffer_rd_flag) begin
                    dwidth_conv_out_tdata <= int_tdata;
                    dwidth_conv_out_tkeep <= int_tkeep;
                    dwidth_conv_out_tlast <= int_tlast;
                    dwidth_conv_out_tvalid <= int_tvalid;
                    buffer_rd_flag <= ~buffer_rd_flag;
                end
                else if (cnt == EOF_CNT) begin
                    dwidth_conv_out_tdata <= {int_reg[DWIDTH_INT-5:0],din[DWIDTH-1:FRAME_WIDTH-4-PAYLOAD_WIDTH]};
                    for (int i = 0; i < PAYLOAD_WIDTH/8; i++)
                        dwidth_conv_out_tkeep[PAYLOAD_WIDTH/8-1-i] <= rifl_rx_meta[0] || (din[FRAME_WIDTH+3-PAYLOAD_WIDTH-:8] > i && |rifl_rx_meta);
                    dwidth_conv_out_tlast <= rifl_rx_meta[1];
                    dwidth_conv_out_tvalid <= (|rifl_rx_meta) && crc_good && din_valid;
                end
                else begin
                    dwidth_conv_out_tvalid <= 1'b0;
                end
            end
        end        
    end
endmodule