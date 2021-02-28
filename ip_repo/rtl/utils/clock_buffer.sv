`timescale 1ns/1ps
module clock_buffer #
(
    parameter bit [2:0] RATIO = 1'b1
)
(
    input logic src_clk,
    input logic rst,
    output logic usrclk,
    output logic usrclk2,
    output logic usrclk3,
    output logic usrclk_active
);
    localparam bit [2:0] DIV_CODE = RATIO - 1'b1;

    (* ASYNC_REG = "TRUE" *) logic usrclk_active_meta = 1'b0;
    (* ASYNC_REG = "TRUE" *) logic usrclk_active_sync = 1'b0;

    BUFG_GT bufg_inst1 (
        .CE(1'b1),
        .CEMASK(1'b0),
        .CLR(rst),
        .CLRMASK(1'b0),
        .DIV(3'b0),
        .I(src_clk),
        .O(usrclk)
    );
    BUFG_GT bufg_inst2 (
        .CE(1'b1),
        .CEMASK(1'b0),
        .CLR(rst),
        .CLRMASK(1'b0),
        .DIV(3'b0),
        .I(src_clk),
        .O(usrclk2)
    );
    BUFG_GT bufg_inst3 (
        .CE(1'b1),
        .CEMASK(1'b0),
        .CLR(rst),
        .CLRMASK(1'b0),
        .DIV(DIV_CODE),
        .I(src_clk),
        .O(usrclk3)
    );

    always_ff @(posedge usrclk2, posedge rst) begin
        if (rst) begin
            usrclk_active_meta <= 1'b0;
            usrclk_active_sync <= 1'b0;
        end
        else begin
            usrclk_active_meta <= 1'b1;
            usrclk_active_sync <= usrclk_active_meta;
        end
    end

    assign usrclk_active = usrclk_active_sync;
endmodule

