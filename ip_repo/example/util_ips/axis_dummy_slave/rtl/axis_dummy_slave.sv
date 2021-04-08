`timescale 1ns/1ps
`ifndef WIDTH_VAL
    `define WIDTH_VAL(x) x <= 0 ? 1 : x
`endif
`define GET_STATE_sub1(val) (val+64'h9e3779b97f4a7c15)
`define GET_STATE_sub2(val) ((`GET_STATE_sub1(val) ^ (`GET_STATE_sub1(val) >> 30)) * 64'hbf58476d1ce4e5b9)
`define GET_STATE_sub3(val) ((`GET_STATE_sub2(val) ^ (`GET_STATE_sub2(val) >> 27)) * 64'h94d049bb133111eb)
`define GET_STATE(val) (`GET_STATE_sub3(val) ^ (`GET_STATE_sub3(val) >> 31))
`define A 64'd19911102
`define B 64'h9e3779b97f4a7c15

module axis_dummy_slave #
(
//AXI4-Stream signals
    parameter int DWIDTH = 32,
    parameter bit HAS_READY = 0,
    parameter bit HAS_KEEP = 0,
    parameter bit HAS_LAST = 0,
    parameter bit HAS_STRB = 0,
    parameter int DEST_WIDTH = 0,
    parameter int USER_WIDTH = 0,
    parameter int ID_WIDTH = 0,
    parameter bit [63:0] SEED = 64'b0
)
(
    input logic clk,
//axis
    input logic [DWIDTH-1:0] s_axis_tdata,
    input logic s_axis_tvalid,
    input logic [DWIDTH/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic [DWIDTH/8-1:0] s_axis_tstrb,
    input logic [`WIDTH_VAL(DEST_WIDTH)-1:0] s_axis_tdest,
    input logic [`WIDTH_VAL(USER_WIDTH)-1:0] s_axis_tuser,
    input logic [`WIDTH_VAL(ID_WIDTH)-1:0] s_axis_tid,
    output logic s_axis_tready,
//back pressure ratio code
    input [63:0] bp_ratio_code
);
    logic s_axis_tready_int = 1'b1;
    logic [63:0] bp_ratio_code_reg;
    logic [63:0] rand64;

    xoshiro128ss_simple #(
        .S0 (`GET_STATE(SEED+`A)),
        .S1 (`GET_STATE(SEED+`A+`B))
    ) u_xoshiro128ss (
    	.clk    (clk),
        .rand64 (rand64)
    );
    always_ff @(posedge clk) begin
        bp_ratio_code_reg <= bp_ratio_code;
    end

    always_ff @(posedge clk) begin
        s_axis_tready <= rand64 >= bp_ratio_code_reg;
    end
endmodule
