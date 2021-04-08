`timescale 1ns/1ps
`define GET_STATE_sub1(val) (val+64'h9e3779b97f4a7c15)
`define GET_STATE_sub2(val) ((`GET_STATE_sub1(val) ^ (`GET_STATE_sub1(val) >> 30)) * 64'hbf58476d1ce4e5b9)
`define GET_STATE_sub3(val) ((`GET_STATE_sub2(val) ^ (`GET_STATE_sub2(val) >> 27)) * 64'h94d049bb133111eb)
`define GET_STATE(val) (`GET_STATE_sub3(val) ^ (`GET_STATE_sub3(val) >> 31))
`define A 64'd19911102
`define B 64'h9e3779b97f4a7c15

module axis_gen #
(
//AXI4-Stream signals
    parameter int DWIDTH = 64,
    parameter bit HAS_READY = 1'b0,
    parameter bit HAS_KEEP = 1'b0,
    parameter bit HAS_LAST = 1'b0,
    parameter bit [63:0] SEED = 64'd1
)
(
    input logic clk,
    input logic rst,
//user signals
    input logic start,
    input logic [31:0] pkt_cnt_limit,
    input logic [63:0] idle_ratio_code,
    input logic [15:0] pkt_len_min,
    input logic [15:0] pkt_len_max,
    output logic done,
//traffic out
    output logic [DWIDTH-1:0] traffic_tdata,
    output logic traffic_tvalid,
    output logic [DWIDTH/8-1:0] traffic_tkeep,
    output logic traffic_tlast,
    input logic traffic_tready
);
    logic [DWIDTH-1:0] tdata;
    logic cycle_valid;
    logic [DWIDTH/8-1:0] tkeep;
    logic tlast;
    logic tready;

    logic start_delay;
    logic core_enabled;
    logic vld;
    logic [63:0] rand64_idle;
    logic [31:0] pkt_cnt = {32{1'b1}};

    tdata_gen #(
        .DWIDTH   (DWIDTH),
        .SEED     (SEED)
    ) u_tdata_gen(
    	.clk    (clk),
        .rst    (rst),
        .enable (tready),
        .tdata  (tdata)
    );

    if (HAS_KEEP | HAS_LAST) begin
        tkeep_gen #(
            .DWIDTH (DWIDTH/8),
            .S0     (`GET_STATE(SEED+`A+`B*100)),
            .S1     (`GET_STATE(SEED+`A+`B*101))
        ) u_tkeep_gen(
    	    .clk         (clk),
            .rst         (rst|(start&~start_delay)),
            .enable      (tready),
            .pkt_len_min (pkt_len_min),
            .pkt_len_max (pkt_len_max),
            .tkeep       (tkeep),
            .tlast       (tlast),
            .vld         (vld)
        );
    end

    axis_gen_xoshiro128ss #(
        .S0 (`GET_STATE(SEED+`A+`B*102)),
        .S1 (`GET_STATE(SEED+`A+`B*103))
    ) u_rand_idle (
    	.clk    (clk),
        .enable (traffic_tready),
        .rand64 (rand64_idle)
    );

    always_ff @(posedge clk) begin
        start_delay <= start;
    end

    always_ff @(posedge clk) begin
        if (rst)
            cycle_valid <= 1'b0;
        else if (core_enabled)
            cycle_valid <= rand64_idle >= idle_ratio_code;
        else
            cycle_valid <= 1'b0;
    end

    always_ff @(posedge clk) begin
        if (rst)
            pkt_cnt <= 32'b0;
        else if (start & ~start_delay)
            pkt_cnt <= 32'b0;
        else if (traffic_tvalid && traffic_tready && traffic_tlast)
            pkt_cnt <= pkt_cnt + 1'b1;
    end
    always_ff @(posedge clk) begin
        if (rst) begin
            core_enabled <= 1'b0;
            done <= 1'b0;
        end
        else if (start & ~start_delay) begin
            core_enabled <= 1'b1;
            done <= 1'b0;
        end
        else if (pkt_cnt_limit != 32'b0 && ((pkt_cnt + 1'b1) == pkt_cnt_limit) && traffic_tvalid && traffic_tready && traffic_tlast) begin
            core_enabled <= 1'b0;
            done <= 1'b1;
        end
    end

    assign traffic_tdata = tdata;
    if (HAS_READY)
        assign tready = traffic_tready & cycle_valid;
    else
        assign tready = cycle_valid;

    if (HAS_KEEP)
        assign traffic_tkeep = tkeep;
    else
        assign traffic_tkeep = {(DWIDTH/8){1'b1}};

    if (HAS_LAST)
        assign traffic_tlast = tlast;
    else
        assign traffic_tlast = 1'b1;

    assign traffic_tvalid = cycle_valid & vld & core_enabled;

endmodule
