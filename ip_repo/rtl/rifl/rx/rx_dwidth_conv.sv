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
   parameter int PAYLOAD_WIDTH = 240
)
(
   input logic clk,
   input logic [DWIDTH-1:0] din,
   input logic data_sof,
   input logic crc_good,
   output logic [PAYLOAD_WIDTH-1:0] int_tdata,
   output logic [PAYLOAD_WIDTH/8-1:0] int_tkeep,
   output logic int_tlast,
   output logic int_tvalid = 1'b0
);
    localparam TKEEP_WIDTH = PAYLOAD_WIDTH/8;

    logic [1:0] rifl_rx_meta = 2'b0;
    if (DWIDTH == FRAME_WIDTH) begin
        genvar i;
        assign int_tdata = din[DWIDTH-5-:PAYLOAD_WIDTH];
        for (i = 0; i < PAYLOAD_WIDTH/8; i++)
            assign int_tkeep[PAYLOAD_WIDTH/8-1-i] = (din[DWIDTH+3-PAYLOAD_WIDTH-:8] > i && |rifl_rx_meta) || rifl_rx_meta[0];
        assign int_tlast = rifl_rx_meta[1];
        always_comb begin
            rifl_rx_meta = din[DWIDTH-3-:2];
            int_tvalid = (|rifl_rx_meta[0]) & crc_good;
        end
    end
    else begin
        localparam int RATIO = FRAME_WIDTH / DWIDTH;
        localparam bit [$clog2(RATIO)-1:0] EOF_CNT = RATIO-1;
        localparam int DWIDTH_INT = FRAME_WIDTH - DWIDTH;
        
        logic [$clog2(RATIO)-1:0] cnt = {$clog2(RATIO){1'b0}};
        logic [DWIDTH_INT-1:0] int_reg = {DWIDTH_INT{1'b0}};

        if (2*DWIDTH == FRAME_WIDTH) begin
            always_ff @(posedge clk) begin
                if (data_sof)
                    cnt <= 1'b1;
                else
                    cnt <= ~cnt;
            end
            always_ff @(posedge clk) begin
                if (data_sof) begin
                    int_reg <= din;
                    rifl_rx_meta <= din[DWIDTH-3-:2];
                end

                if (cnt) begin
                    int_tdata <= {int_reg[DWIDTH-5:0],din[DWIDTH-1:FRAME_WIDTH-4-PAYLOAD_WIDTH]};
                    for (int i = 0; i < PAYLOAD_WIDTH/8; i++)
                        int_tkeep[PAYLOAD_WIDTH/8-1-i] <= rifl_rx_meta[0] || (din[FRAME_WIDTH+3-PAYLOAD_WIDTH-:8] > i && |rifl_rx_meta);
                    int_tlast <= rifl_rx_meta[1];
                    int_tvalid <= (|rifl_rx_meta) & crc_good;
                end
            end
        end
        else begin
            always_ff @(posedge clk) begin
                if (data_sof)
                    cnt <= {{($clog2(RATIO)-1){1'b0}},1'b1};
                else
                    cnt <= cnt + 1'b1;
            end
            always_ff @(posedge clk) begin
                if (data_sof) begin
                    int_reg <= {{(DWIDTH_INT-DWIDTH){1'b0}},din};
                    rifl_rx_meta <= din[DWIDTH-3-:2];
                end
                else
                    int_reg <= {int_reg[DWIDTH_INT-DWIDTH-1:0],din};

                if (cnt == EOF_CNT) begin
                    int_tdata <= {int_reg[DWIDTH_INT-5:0],din[DWIDTH-1:FRAME_WIDTH-4-PAYLOAD_WIDTH]};
                    for (int i = 0; i < PAYLOAD_WIDTH/8; i++)
                        int_tkeep[PAYLOAD_WIDTH/8-1-i] <= rifl_rx_meta[0] || (din[FRAME_WIDTH+3-PAYLOAD_WIDTH-:8] > i && |rifl_rx_meta);
                    int_tlast <= rifl_rx_meta[1];
                    int_tvalid <= (|rifl_rx_meta) & crc_good;
                end
            end
        end
    end
endmodule //dwidth_conv