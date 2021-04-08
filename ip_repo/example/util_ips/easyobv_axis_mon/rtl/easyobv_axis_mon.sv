`timescale 1ns/1ps
`ifndef WIDTH_VAL
    `define WIDTH_VAL(x) x <= 0 ? 1 : x
`endif
module easyobv_axis_mon #
(
    parameter bit EN_AXIL = 1'b1,
    parameter bit LOOPBACK = 1'b1,
//AXI4-Stream signals
    parameter int DWIDTH = 32,
    parameter bit HAS_READY = 0,
    parameter bit HAS_KEEP = 0,
    parameter bit HAS_LAST = 0,
    parameter bit HAS_STRB = 0,
    parameter int DEST_WIDTH = 0,
    parameter int USER_WIDTH = 0,
    parameter int ID_WIDTH = 0,
    parameter int CMP_FIFO_DEPTH = 16,
//Clock frequency
    parameter int CLK_FREQ = 100000000
)
(
    input logic clk,
    input logic rst,
//axi lite
    input logic			s_axil_aclk,
    input logic [6:0]   s_axil_awaddr,
    input logic			s_axil_awvalid,
    output logic		s_axil_awready,
    input logic [31:0]  s_axil_wdata,
    input logic [3:0]   s_axil_wstrb,
    input logic         s_axil_wvalid,
    output logic        s_axil_wready,
    output logic [1:0]  s_axil_bresp,
    output logic		s_axil_bvalid,
    input logic         s_axil_bready,
    input logic [6:0]   s_axil_araddr,
    input logic         s_axil_arvalid,
    output logic        s_axil_arready,
    output logic [31:0] s_axil_rdata,
    output logic [1:0]  s_axil_rresp,
    output logic		s_axil_rvalid,
    input logic         s_axil_rready,
    //user signals
    input logic clear,
    //tx
    input logic [DWIDTH-1:0] tx_mon_tdata,
    input logic tx_mon_tvalid,
    input logic tx_mon_tready,
    input logic [DWIDTH/8-1:0] tx_mon_tkeep,
    input logic tx_mon_tlast,
    input logic [DWIDTH/8-1:0] tx_mon_tstrb,
    input logic [`WIDTH_VAL(DEST_WIDTH)-1:0] tx_mon_tdest,
    input logic [`WIDTH_VAL(USER_WIDTH)-1:0] tx_mon_tuser,
    input logic [`WIDTH_VAL(ID_WIDTH)-1:0] tx_mon_tid,
    //rx
    input logic [DWIDTH-1:0] rx_mon_tdata,
    input logic rx_mon_tvalid,
    input logic rx_mon_tready,
    input logic [DWIDTH/8-1:0] rx_mon_tkeep,
    input logic rx_mon_tlast,
    input logic [DWIDTH/8-1:0] rx_mon_tstrb,
    input logic [`WIDTH_VAL(DEST_WIDTH)-1:0] rx_mon_tdest,
    input logic [`WIDTH_VAL(USER_WIDTH)-1:0] rx_mon_tuser,
    input logic [`WIDTH_VAL(ID_WIDTH)-1:0] rx_mon_tid,
    //stats
    output logic mismatch,
    output logic [63:0] time_cnt,
    output logic [63:0] tx_pkt_cnt,
    output logic [63:0] tx_time_elapsed,
    output logic [63:0] tx_transferred_size,
    output logic [63:0] rx_pkt_cnt,
    output logic [63:0] rx_time_elapsed,
    output logic [63:0] rx_transferred_size,
    output logic [63:0] latency_sum
);
    logic clear_int;

    if (EN_AXIL) begin
        logic clear_axil;
        logic loopback_axil;
        logic mismatch_axil;
        logic [31:0] freq_axil;
        logic [63:0] tx_pkt_cnt_axil;
        logic [63:0] tx_time_elapsed_axil;
        logic [63:0] tx_transferred_size_axil;
        logic [63:0] rx_pkt_cnt_axil;
        logic [63:0] rx_time_elapsed_axil;
        logic [63:0] rx_transferred_size_axil;
        logic [63:0] latency_sum_axil;

        axis_mon_axil u_axil(
            .*,
            .clk (s_axil_aclk),
            .rst (s_axil_rst)
        );
        axis_mon_cdc u_cdc(
            .*,
            .clear(clear_int)
        );
        assign loopback_axil = LOOPBACK;
        assign freq_axil = 32'(CLK_FREQ);
    end
    else begin
        assign clear_int = clear;
    end

    axis_mon #(
        .DWIDTH         (DWIDTH         ),
        .HAS_READY      (HAS_READY      ),
        .HAS_KEEP       (HAS_KEEP       ),
        .HAS_LAST       (HAS_LAST       ),
        .HAS_STRB       (HAS_STRB       ),
        .DEST_WIDTH     (DEST_WIDTH     ),
        .USER_WIDTH     (USER_WIDTH     ),
        .ID_WIDTH       (ID_WIDTH       ),
        .LOOPBACK       (LOOPBACK       ),
        .CMP_FIFO_DEPTH (CMP_FIFO_DEPTH )
    ) u_axis_mon(
        .*,
        .rst           (rst|clear_int)
    );
endmodule
