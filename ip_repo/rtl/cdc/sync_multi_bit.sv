`timescale 1ns/1ps
module sync_multi_bit #
(
    parameter int SIZE = 1,
    parameter int N_STAGE = 2,
    parameter bit OUTPUT_REG = 0
)
(
    input logic clk_in,
    input logic clk_out,
    input logic rst,
    input logic [SIZE-1:0] din,
    input logic din_vld,
    output logic din_rdy,
    output logic [SIZE-1:0] dout,
    output logic dout_vld,
    input logic dout_rdy
);
    logic rd_flag,wr_flag;
    logic rd_flag_wr_synced;
    logic wr_flag_rd_synced;
    logic dout_vld_int;
    (* ASYNC_REG = "TRUE" *) logic [SIZE-1:0] mbc_int_reg;

    always_ff @(posedge clk_in or posedge rst) begin
        if (rst)
            wr_flag <= 1'b0;
        else if (din_rdy & din_vld)
            wr_flag <= ~wr_flag;
    end
    always_ff @(posedge clk_out or posedge rst) begin
        if (rst)
            rd_flag <= 1'b0;
        else if (dout_rdy & dout_vld_int)
            rd_flag <= ~rd_flag;
    end
    always_ff @(posedge clk_in) begin
        if (din_rdy & din_vld)
            mbc_int_reg <= din;
    end

    sync_signle_bit #(
        .N_STAGE   (N_STAGE)
    ) sync_wr (
        .clk_in  (1'b0),
    	.clk_out (clk_out),
        .rst     (rst),
        .din     (wr_flag),
        .dout    (wr_flag_rd_synced)
    );    
    sync_signle_bit #(
        .N_STAGE   (N_STAGE)
    ) sync_rd (
        .clk_in  (1'b0),
    	.clk_out (clk_in),
        .rst     (rst),
        .din     (rd_flag),
        .dout    (rd_flag_wr_synced)
    );

    assign din_rdy = wr_flag ~^ rd_flag_wr_synced;
    assign dout_vld_int = rd_flag ^ wr_flag_rd_synced;
    if (OUTPUT_REG) begin
        always_ff @(posedge clk_out or posedge rst) begin
            if (rst) begin
                dout <= {SIZE{1'b0}};
                dout_vld <= 1'b0;
            end
            else if (dout_rdy) begin
                if (dout_vld_int)
                    dout <= mbc_int_reg;
                dout_vld <= dout_vld_int;
            end
        end
    end
    else begin
        assign dout = mbc_int_reg;
        assign dout_vld = dout_vld_int;
    end
endmodule