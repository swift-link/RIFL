`timescale 1ns/1ps
module rifl_axis_async_fifo #
(
    parameter int DWIDTH = 32,
    parameter int DEPTH = 16
)
(
    input logic rst,
    input logic s_axis_aclk,
    input logic m_axis_aclk,
    input logic [DWIDTH-1:0] s_axis_tdata = {DWIDTH{1'b0}},
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [DWIDTH-1:0] m_axis_tdata,
    output logic m_axis_tvalid,
    input logic m_axis_tready
);
//internal rsts
    logic wr_rst, rd_rst;

//internal clocks
    logic wr_clk, rd_clk;

//internal data
    logic [DWIDTH-1:0] wr_data_int, rd_data_int;
    logic wr_en_int, rd_en_int;
    logic wr_full_int, rd_empty_int;

//internal signals for ASYNC and DEPTH > 16
    logic [DWIDTH-1:0] rd_data_async;
    logic wr_full_async, rd_empty_async;

    assign wr_clk = s_axis_aclk;
    assign rd_clk = m_axis_aclk;

    assign wr_data_int = s_axis_tdata;
    assign wr_en_int = s_axis_tvalid;
    assign s_axis_tready = ~wr_full_int & ~wr_rst;
    assign m_axis_tdata = rd_data_int;
    assign m_axis_tvalid = ~rd_empty_int & ~rd_rst;
    assign rd_en_int = m_axis_tready;

    async_fifo #(
        .DWIDTH (DWIDTH),
        .DEPTH  (DEPTH)
    ) u_async_fifo (
        .*,
        .wr_en    (wr_en_int),
        .rd_en    (rd_en_int),
        .wr_data  (wr_data_int),
        .wr_full  (wr_full_int),
        .rd_data  (rd_data_int),
        .rd_empty (rd_empty_int),
        .fifo_cnt_wr_synced(),
        .fifo_cnt_rd_synced()
    );

    rst_cntrl u_rst_cntrl(.*);

endmodule
