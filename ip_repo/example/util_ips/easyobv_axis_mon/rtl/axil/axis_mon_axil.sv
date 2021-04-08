`timescale 1ns/1ps
module axis_mon_axil
(
//user
    output logic clear_axil,
    input logic loopback_axil,
    input logic mismatch_axil,
    input logic [31:0] freq_axil,
    input logic [63:0] tx_pkt_cnt_axil,
    input logic [63:0] tx_time_elapsed_axil,
    input logic [63:0] tx_transferred_size_axil,
    input logic [63:0] rx_pkt_cnt_axil,
    input logic [63:0] rx_time_elapsed_axil,
    input logic [63:0] rx_transferred_size_axil,
    input logic [63:0] latency_sum_axil,
//axi lite
    input logic         clk,
    input logic         rst,
    input logic [6:0]   s_axil_awaddr,
    input logic         s_axil_awvalid,
    output logic        s_axil_awready,
    input logic [31:0]  s_axil_wdata,
    input logic [3:0]   s_axil_wstrb,
    input logic         s_axil_wvalid,
    output logic        s_axil_wready,
    output logic [1:0]  s_axil_bresp,
    output logic        s_axil_bvalid,
    input logic         s_axil_bready,
    input logic [6:0]   s_axil_araddr,
    input logic         s_axil_arvalid,
    output logic        s_axil_arready,
    output logic [31:0] s_axil_rdata,
    output logic [1:0]  s_axil_rresp,
    output logic        s_axil_rvalid,
    input logic         s_axil_rready
);
//------------------------Address Info-------------------
// 0x0 : Data signal of clear_axil
//    bit 0->0 - clear_axil (READ/WRITE)
// 0x4 : Data signal of loopback_axil
//    bit 0->0 - loopback_axil (READ)
// 0x8 : Data signal of mismatch_axil
//    bit 0->0 - mismatch_axil (READ)
// 0xc : Data signal of freq_axil
//    bit 31->0 - freq_axil[31:0] (READ)
// 0x10 : Data signal of tx_pkt_cnt_axil
//    bit 31->0 - tx_pkt_cnt_axil[31:0] (READ)
// 0x14 : Data signal of tx_pkt_cnt_axil
//    bit 31->0 - tx_pkt_cnt_axil[63:32] (READ)
// 0x18 : Data signal of tx_time_elapsed_axil
//    bit 31->0 - tx_time_elapsed_axil[31:0] (READ)
// 0x1c : Data signal of tx_time_elapsed_axil
//    bit 31->0 - tx_time_elapsed_axil[63:32] (READ)
// 0x20 : Data signal of tx_transferred_size_axil
//    bit 31->0 - tx_transferred_size_axil[31:0] (READ)
// 0x24 : Data signal of tx_transferred_size_axil
//    bit 31->0 - tx_transferred_size_axil[63:32] (READ)
// 0x28 : Data signal of rx_pkt_cnt_axil
//    bit 31->0 - rx_pkt_cnt_axil[31:0] (READ)
// 0x2c : Data signal of rx_pkt_cnt_axil
//    bit 31->0 - rx_pkt_cnt_axil[63:32] (READ)
// 0x30 : Data signal of rx_time_elapsed_axil
//    bit 31->0 - rx_time_elapsed_axil[31:0] (READ)
// 0x34 : Data signal of rx_time_elapsed_axil
//    bit 31->0 - rx_time_elapsed_axil[63:32] (READ)
// 0x38 : Data signal of rx_transferred_size_axil
//    bit 31->0 - rx_transferred_size_axil[31:0] (READ)
// 0x3c : Data signal of rx_transferred_size_axil
//    bit 31->0 - rx_transferred_size_axil[63:32] (READ)
// 0x40 : Data signal of latency_sum_axil
//    bit 31->0 - latency_sum_axil[31:0] (READ)
// 0x44 : Data signal of latency_sum_axil
//    bit 31->0 - latency_sum_axil[63:32] (READ)
//------------------------Parameter----------------------
    localparam bit [6:0] CLEAR_AXIL_ADDR_0 = 7'd0;
    localparam bit [6:0] LOOPBACK_AXIL_ADDR_0 = 7'd4;
    localparam bit [6:0] MISMATCH_AXIL_ADDR_0 = 7'd8;
    localparam bit [6:0] FREQ_AXIL_ADDR_0 = 7'd12;
    localparam bit [6:0] TX_PKT_CNT_AXIL_ADDR_0 = 7'd16;
    localparam bit [6:0] TX_PKT_CNT_AXIL_ADDR_1 = 7'd20;
    localparam bit [6:0] TX_TIME_ELAPSED_AXIL_ADDR_0 = 7'd24;
    localparam bit [6:0] TX_TIME_ELAPSED_AXIL_ADDR_1 = 7'd28;
    localparam bit [6:0] TX_TRANSFERRED_SIZE_AXIL_ADDR_0 = 7'd32;
    localparam bit [6:0] TX_TRANSFERRED_SIZE_AXIL_ADDR_1 = 7'd36;
    localparam bit [6:0] RX_PKT_CNT_AXIL_ADDR_0 = 7'd40;
    localparam bit [6:0] RX_PKT_CNT_AXIL_ADDR_1 = 7'd44;
    localparam bit [6:0] RX_TIME_ELAPSED_AXIL_ADDR_0 = 7'd48;
    localparam bit [6:0] RX_TIME_ELAPSED_AXIL_ADDR_1 = 7'd52;
    localparam bit [6:0] RX_TRANSFERRED_SIZE_AXIL_ADDR_0 = 7'd56;
    localparam bit [6:0] RX_TRANSFERRED_SIZE_AXIL_ADDR_1 = 7'd60;
    localparam bit [6:0] LATENCY_SUM_AXIL_ADDR_0 = 7'd64;
    localparam bit [6:0] LATENCY_SUM_AXIL_ADDR_1 = 7'd68;
    localparam int ADDR_BITS = 7;
    localparam bit [1:0] WRIDLE = 2'd0;
    localparam bit [1:0] WRDATA = 2'd1;
    localparam bit [1:0] WRRESP = 2'd2;
    localparam bit [1:0] WRRESET = 2'd3;
    localparam bit [1:0] RDIDLE = 2'd0;
    localparam bit [1:0] RDDATA = 2'd1;
    localparam bit [1:0] RDRESET = 2'd2;

    logic [1:0] wstate = WRRESET;
    logic [1:0] wnext;
    logic [ADDR_BITS-1:0] waddr;
    logic [31:0] wmask;
    logic aw_hs;
    logic w_hs;
    logic [1:0] rstate = RDRESET;
    logic [1:0] rnext;
    logic [31:0] rdata;
    logic ar_hs;
    logic [ADDR_BITS-1:0] raddr;

//user logic
    logic [31:0] int_clear_axil_0;
    logic [31:0] int_loopback_axil_0;
    logic [31:0] int_mismatch_axil_0;
    logic [31:0] int_freq_axil_0;
    logic [31:0] int_tx_pkt_cnt_axil_0;
    logic [31:0] int_tx_pkt_cnt_axil_1;
    logic [31:0] int_tx_time_elapsed_axil_0;
    logic [31:0] int_tx_time_elapsed_axil_1;
    logic [31:0] int_tx_transferred_size_axil_0;
    logic [31:0] int_tx_transferred_size_axil_1;
    logic [31:0] int_rx_pkt_cnt_axil_0;
    logic [31:0] int_rx_pkt_cnt_axil_1;
    logic [31:0] int_rx_time_elapsed_axil_0;
    logic [31:0] int_rx_time_elapsed_axil_1;
    logic [31:0] int_rx_transferred_size_axil_0;
    logic [31:0] int_rx_transferred_size_axil_1;
    logic [31:0] int_latency_sum_axil_0;
    logic [31:0] int_latency_sum_axil_1;
    assign s_axil_awready = (wstate == WRIDLE);
    assign s_axil_wready = (wstate == WRDATA);
    assign s_axil_bresp = 2'b00;
    assign s_axil_bvalid = (wstate == WRRESP);
    assign wmask = { {8{s_axil_wstrb[3]}}, {8{s_axil_wstrb[2]}}, {8{s_axil_wstrb[1]}}, {8{s_axil_wstrb[0]}} };
    assign aw_hs = s_axil_awvalid & s_axil_awready;
    assign w_hs = s_axil_wvalid & s_axil_wready;

// wstate
    always_ff @(posedge clk) begin
        if (rst)
            wstate <= WRRESET;
        else
            wstate <= wnext;
    end
    
    // wnext
    always_comb begin
        case (wstate)
            WRIDLE:
                if (s_axil_awvalid)
                    wnext = WRDATA;
                else
                    wnext = WRIDLE;
            WRDATA:
                if (s_axil_wvalid)
                    wnext = WRRESP;
                else
                    wnext = WRDATA;
            WRRESP:
                if (s_axil_bready)
                    wnext = WRIDLE;
                else
                    wnext = WRRESP;
            default:
                wnext = WRIDLE;
        endcase
    end
    
    // waddr
    always_ff @(posedge clk) begin
        if (aw_hs)
            waddr <= s_axil_awaddr[ADDR_BITS-1:0];
    end
    
    //------------------------AXI read fsm-------------------
    assign s_axil_arready = (rstate == RDIDLE);
    assign s_axil_rdata = rdata;
    assign s_axil_rresp = 2'b00;
    assign s_axil_rvalid = (rstate == RDDATA);
    assign ar_hs = s_axil_arvalid & s_axil_arready;
    assign raddr = s_axil_araddr[ADDR_BITS-1:0];
    
    // rstate
    always_ff @(posedge clk) begin
        if (rst)
            rstate <= RDRESET;
        else
            rstate <= rnext;
    end
    
    // rnext
    always_comb begin
        case (rstate)
            RDIDLE:
                if (s_axil_arvalid)
                    rnext = RDDATA;
                else
                    rnext = RDIDLE;
            RDDATA:
                if (s_axil_rready & s_axil_rvalid)
                    rnext = RDIDLE;
                else
                    rnext = RDDATA;
            default:
                rnext = RDIDLE;
        endcase
    end
    
    // rdata
    always_ff @(posedge clk) begin
        if (ar_hs) begin
            rdata <= 1'b0;
            case (raddr)
                CLEAR_AXIL_ADDR_0: begin
                    rdata <= int_clear_axil_0;
                end
                LOOPBACK_AXIL_ADDR_0: begin
                    rdata <= int_loopback_axil_0;
                end
                MISMATCH_AXIL_ADDR_0: begin
                    rdata <= int_mismatch_axil_0;
                end
                FREQ_AXIL_ADDR_0: begin
                    rdata <= int_freq_axil_0;
                end
                TX_PKT_CNT_AXIL_ADDR_0: begin
                    rdata <= int_tx_pkt_cnt_axil_0;
                end
                TX_PKT_CNT_AXIL_ADDR_1: begin
                    rdata <= int_tx_pkt_cnt_axil_1;
                end
                TX_TIME_ELAPSED_AXIL_ADDR_0: begin
                    rdata <= int_tx_time_elapsed_axil_0;
                end
                TX_TIME_ELAPSED_AXIL_ADDR_1: begin
                    rdata <= int_tx_time_elapsed_axil_1;
                end
                TX_TRANSFERRED_SIZE_AXIL_ADDR_0: begin
                    rdata <= int_tx_transferred_size_axil_0;
                end
                TX_TRANSFERRED_SIZE_AXIL_ADDR_1: begin
                    rdata <= int_tx_transferred_size_axil_1;
                end
                RX_PKT_CNT_AXIL_ADDR_0: begin
                    rdata <= int_rx_pkt_cnt_axil_0;
                end
                RX_PKT_CNT_AXIL_ADDR_1: begin
                    rdata <= int_rx_pkt_cnt_axil_1;
                end
                RX_TIME_ELAPSED_AXIL_ADDR_0: begin
                    rdata <= int_rx_time_elapsed_axil_0;
                end
                RX_TIME_ELAPSED_AXIL_ADDR_1: begin
                    rdata <= int_rx_time_elapsed_axil_1;
                end
                RX_TRANSFERRED_SIZE_AXIL_ADDR_0: begin
                    rdata <= int_rx_transferred_size_axil_0;
                end
                RX_TRANSFERRED_SIZE_AXIL_ADDR_1: begin
                    rdata <= int_rx_transferred_size_axil_1;
                end
                LATENCY_SUM_AXIL_ADDR_0: begin
                    rdata <= int_latency_sum_axil_0;
                end
                LATENCY_SUM_AXIL_ADDR_1: begin
                    rdata <= int_latency_sum_axil_1;
                end
            endcase
        end
    end

    //------------------------user read logic-----------------
    // int_loopback_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_loopback_axil_0 <= 32'b0;
        else
            int_loopback_axil_0[0:0] <= loopback_axil;
    end
    // int_mismatch_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_mismatch_axil_0 <= 32'b0;
        else
            int_mismatch_axil_0[0:0] <= mismatch_axil;
    end
    // int_freq_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_freq_axil_0 <= 32'b0;
        else
            int_freq_axil_0[31:0] <= freq_axil[31:0];
    end
    // int_tx_pkt_cnt_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_tx_pkt_cnt_axil_0 <= 32'b0;
        else
            int_tx_pkt_cnt_axil_0[31:0] <= tx_pkt_cnt_axil[31:0];
    end
    // int_tx_pkt_cnt_axil_1
    always_ff @(posedge clk) begin
        if (rst)
            int_tx_pkt_cnt_axil_1 <= 32'b0;
        else
            int_tx_pkt_cnt_axil_1[31:0] <= tx_pkt_cnt_axil[63:32];
    end
    // int_tx_time_elapsed_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_tx_time_elapsed_axil_0 <= 32'b0;
        else
            int_tx_time_elapsed_axil_0[31:0] <= tx_time_elapsed_axil[31:0];
    end
    // int_tx_time_elapsed_axil_1
    always_ff @(posedge clk) begin
        if (rst)
            int_tx_time_elapsed_axil_1 <= 32'b0;
        else
            int_tx_time_elapsed_axil_1[31:0] <= tx_time_elapsed_axil[63:32];
    end
    // int_tx_transferred_size_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_tx_transferred_size_axil_0 <= 32'b0;
        else
            int_tx_transferred_size_axil_0[31:0] <= tx_transferred_size_axil[31:0];
    end
    // int_tx_transferred_size_axil_1
    always_ff @(posedge clk) begin
        if (rst)
            int_tx_transferred_size_axil_1 <= 32'b0;
        else
            int_tx_transferred_size_axil_1[31:0] <= tx_transferred_size_axil[63:32];
    end
    // int_rx_pkt_cnt_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_rx_pkt_cnt_axil_0 <= 32'b0;
        else
            int_rx_pkt_cnt_axil_0[31:0] <= rx_pkt_cnt_axil[31:0];
    end
    // int_rx_pkt_cnt_axil_1
    always_ff @(posedge clk) begin
        if (rst)
            int_rx_pkt_cnt_axil_1 <= 32'b0;
        else
            int_rx_pkt_cnt_axil_1[31:0] <= rx_pkt_cnt_axil[63:32];
    end
    // int_rx_time_elapsed_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_rx_time_elapsed_axil_0 <= 32'b0;
        else
            int_rx_time_elapsed_axil_0[31:0] <= rx_time_elapsed_axil[31:0];
    end
    // int_rx_time_elapsed_axil_1
    always_ff @(posedge clk) begin
        if (rst)
            int_rx_time_elapsed_axil_1 <= 32'b0;
        else
            int_rx_time_elapsed_axil_1[31:0] <= rx_time_elapsed_axil[63:32];
    end
    // int_rx_transferred_size_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_rx_transferred_size_axil_0 <= 32'b0;
        else
            int_rx_transferred_size_axil_0[31:0] <= rx_transferred_size_axil[31:0];
    end
    // int_rx_transferred_size_axil_1
    always_ff @(posedge clk) begin
        if (rst)
            int_rx_transferred_size_axil_1 <= 32'b0;
        else
            int_rx_transferred_size_axil_1[31:0] <= rx_transferred_size_axil[63:32];
    end
    // int_latency_sum_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_latency_sum_axil_0 <= 32'b0;
        else
            int_latency_sum_axil_0[31:0] <= latency_sum_axil[31:0];
    end
    // int_latency_sum_axil_1
    always_ff @(posedge clk) begin
        if (rst)
            int_latency_sum_axil_1 <= 32'b0;
        else
            int_latency_sum_axil_1[31:0] <= latency_sum_axil[63:32];
    end
    //------------------------user write logic-----------------
    // int_clear_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_clear_axil_0 <= 32'b0;
        else if (int_clear_axil_0 != 32'b0)
            int_clear_axil_0 <= 32'b0;
        else if (w_hs && waddr == CLEAR_AXIL_ADDR_0)
            int_clear_axil_0 <= (s_axil_wdata[31:0] & wmask) | (int_clear_axil_0 & ~wmask);
    end
    assign clear_axil = int_clear_axil_0[0:0];
endmodule
