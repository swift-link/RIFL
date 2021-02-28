`timescale 1ns / 1ps

module tx_dwidth_conv # (
   parameter int DWIDTH_IN = 256,
   parameter int DWIDTH_OUT = 64,
   parameter int CNT_WIDTH = 2
)
(
   input logic clk,
   input logic [CNT_WIDTH-1:0] cnt,
   input logic [DWIDTH_IN-1:0] din,
   output logic [DWIDTH_OUT-1:0] dout,
   output logic sof_out = 1'b0
);
    if (DWIDTH_IN > DWIDTH_OUT) begin
        localparam int RATIO = DWIDTH_IN / DWIDTH_OUT;
        logic [DWIDTH_IN-1:0] din_reg = {DWIDTH_IN{1'b0}};
        always_ff @(posedge clk) begin
            if (cnt == 'b1) begin
                din_reg <= din;
                sof_out <= 1'b1;
            end
            else begin
                din_reg <= din_reg << DWIDTH_OUT;
                sof_out <= 1'b0;
            end
        end
        assign dout = din_reg[DWIDTH_IN-1-:DWIDTH_OUT];
    end
    else begin
        assign dout = din;
        always_comb begin
            sof_out = 1'b1;
        end
    end
endmodule