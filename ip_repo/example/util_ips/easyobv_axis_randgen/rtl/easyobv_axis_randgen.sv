`timescale 1ns/1ps
module easyobv_axis #
(
    parameter bit EN_AXIL = 1,
//AXI4-Stream signals
    parameter int DWIDTH = 64,
    parameter bit HAS_READY = 0,
    parameter bit HAS_KEEP = 0,
    parameter bit HAS_LAST = 0,
    parameter bit [63:0] SEED = 64'd1
)
(
    input logic clk,
    input logic rst,
//axi lite
    input logic         s_axil_aclk,
    input logic [4:0]   s_axil_awaddr,
    input logic         s_axil_awvalid,
    output logic        s_axil_awready,
    input logic [31:0]  s_axil_wdata,
    input logic [3:0]   s_axil_wstrb,
    input logic         s_axil_wvalid,
    output logic        s_axil_wready,
    output logic [1:0]  s_axil_bresp,
    output logic        s_axil_bvalid,
    input logic         s_axil_bready,
    input logic [4:0]   s_axil_araddr,
    input logic         s_axil_arvalid,
    output logic        s_axil_arready,
    output logic [31:0] s_axil_rdata,
    output logic [1:0]  s_axil_rresp,
    output logic        s_axil_rvalid,
    input logic         s_axil_rready,
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
    logic s_axil_rst;

    logic start_int;
    logic [31:0] pkt_cnt_limit_int;
    logic [63:0] idle_ratio_code_int;
    logic [15:0] pkt_len_min_int;
    logic [15:0] pkt_len_max_int;
    logic done_int;

    if (EN_AXIL) begin
        logic start_axil;
        logic [31:0] pkt_cnt_limit_axil;
        logic [63:0] idle_ratio_code_axil;
        logic [15:0] pkt_len_min_axil;
        logic [15:0] pkt_len_max_axil;
        logic done_axil;
        axis_randgen_cdc u_cdc(.*);
        axis_randgen_axil u_axil(
            .*,
            .clk (s_axil_aclk),
            .rst (s_axil_rst)
        );
    end
    else begin
        assign start_int = start;
        assign pkt_cnt_limit_int = pkt_cnt_limit;
        assign idle_ratio_code_int = idle_ratio_code;
        assign pkt_len_min_int = pkt_len_min;
        assign pkt_len_max_int = pkt_len_max;
        assign done = done_int;
    end
    axis_gen #(
        .DWIDTH    (DWIDTH),
        .HAS_READY (HAS_READY),
        .HAS_KEEP  (HAS_KEEP),
        .HAS_LAST  (HAS_LAST),
        .SEED      (SEED)
    ) u_axis_gen(
        .*,
        .start           (start_int),
        .pkt_cnt_limit   (pkt_cnt_limit_int),
        .idle_ratio_code (idle_ratio_code_int),
        .pkt_len_min     (pkt_len_min_int),
        .pkt_len_max     (pkt_len_max_int),
        .done            (done_int)
    );

endmodule
