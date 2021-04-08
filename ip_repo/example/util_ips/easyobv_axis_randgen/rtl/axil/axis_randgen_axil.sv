`timescale 1ns/1ps
module axis_randgen_axil
(
//user
    output logic start_axil,
    output logic [31:0] pkt_cnt_limit_axil,
    output logic [63:0] idle_ratio_code_axil,
    output logic [15:0] pkt_len_min_axil,
    output logic [15:0] pkt_len_max_axil,
    input logic done_axil,
//axi lite
    input logic         clk,
    input logic         rst,
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
    input logic         s_axil_rready
);
//------------------------Address Info-------------------
// 0x0 : Data signal of start_axil
//    bit 0->0 - start_axil (READ/WRITE)
// 0x4 : Data signal of pkt_cnt_limit_axil
//    bit 31->0 - pkt_cnt_limit_axil[31:0] (READ/WRITE)
// 0x8 : Data signal of idle_ratio_code_axil
//    bit 31->0 - idle_ratio_code_axil[31:0] (READ/WRITE)
// 0xc : Data signal of idle_ratio_code_axil
//    bit 31->0 - idle_ratio_code_axil[63:32] (READ/WRITE)
// 0x10 : Data signal of pkt_len_min_axil
//    bit 15->0 - pkt_len_min_axil[15:0] (READ/WRITE)
// 0x14 : Data signal of pkt_len_max_axil
//    bit 15->0 - pkt_len_max_axil[15:0] (READ/WRITE)
// 0x18 : Data signal of done_axil
//    bit 0->0 - done_axil (READ)
//------------------------Parameter----------------------
    localparam bit [4:0] START_AXIL_ADDR_0 = 5'd0;
    localparam bit [4:0] PKT_CNT_LIMIT_AXIL_ADDR_0 = 5'd4;
    localparam bit [4:0] IDLE_RATIO_CODE_AXIL_ADDR_0 = 5'd8;
    localparam bit [4:0] IDLE_RATIO_CODE_AXIL_ADDR_1 = 5'd12;
    localparam bit [4:0] PKT_LEN_MIN_AXIL_ADDR_0 = 5'd16;
    localparam bit [4:0] PKT_LEN_MAX_AXIL_ADDR_0 = 5'd20;
    localparam bit [4:0] DONE_AXIL_ADDR_0 = 5'd24;
    localparam int ADDR_BITS = 5;
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
    logic [31:0] int_start_axil_0;
    logic [31:0] int_pkt_cnt_limit_axil_0;
    logic [31:0] int_idle_ratio_code_axil_0;
    logic [31:0] int_idle_ratio_code_axil_1;
    logic [31:0] int_pkt_len_min_axil_0;
    logic [31:0] int_pkt_len_max_axil_0;
    logic [31:0] int_done_axil_0;
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
                START_AXIL_ADDR_0: begin
                    rdata <= int_start_axil_0;
                end
                PKT_CNT_LIMIT_AXIL_ADDR_0: begin
                    rdata <= int_pkt_cnt_limit_axil_0;
                end
                IDLE_RATIO_CODE_AXIL_ADDR_0: begin
                    rdata <= int_idle_ratio_code_axil_0;
                end
                IDLE_RATIO_CODE_AXIL_ADDR_1: begin
                    rdata <= int_idle_ratio_code_axil_1;
                end
                PKT_LEN_MIN_AXIL_ADDR_0: begin
                    rdata <= int_pkt_len_min_axil_0;
                end
                PKT_LEN_MAX_AXIL_ADDR_0: begin
                    rdata <= int_pkt_len_max_axil_0;
                end
                DONE_AXIL_ADDR_0: begin
                    rdata <= int_done_axil_0;
                end
            endcase
        end
    end

    //------------------------user read logic-----------------
    // int_done_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_done_axil_0 <= 32'b0;
        else
            int_done_axil_0[0:0] <= done_axil;
    end
    //------------------------user write logic-----------------
    // int_start_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_start_axil_0 <= 32'b0;
        else if (int_start_axil_0 != 32'b0)
            int_start_axil_0 <= 32'b0;
        else if (w_hs && waddr == START_AXIL_ADDR_0)
            int_start_axil_0 <= (s_axil_wdata[31:0] & wmask) | (int_start_axil_0 & ~wmask);
    end
    // int_pkt_cnt_limit_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_pkt_cnt_limit_axil_0 <= 32'b0;
        else if (w_hs && waddr == PKT_CNT_LIMIT_AXIL_ADDR_0)
            int_pkt_cnt_limit_axil_0 <= (s_axil_wdata[31:0] & wmask) | (int_pkt_cnt_limit_axil_0 & ~wmask);
    end
    // int_idle_ratio_code_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_idle_ratio_code_axil_0 <= 32'b0;
        else if (w_hs && waddr == IDLE_RATIO_CODE_AXIL_ADDR_0)
            int_idle_ratio_code_axil_0 <= (s_axil_wdata[31:0] & wmask) | (int_idle_ratio_code_axil_0 & ~wmask);
    end
    // int_idle_ratio_code_axil_1
    always_ff @(posedge clk) begin
        if (rst)
            int_idle_ratio_code_axil_1 <= 32'b0;
        else if (w_hs && waddr == IDLE_RATIO_CODE_AXIL_ADDR_1)
            int_idle_ratio_code_axil_1 <= (s_axil_wdata[31:0] & wmask) | (int_idle_ratio_code_axil_1 & ~wmask);
    end
    // int_pkt_len_min_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_pkt_len_min_axil_0 <= 32'b0;
        else if (w_hs && waddr == PKT_LEN_MIN_AXIL_ADDR_0)
            int_pkt_len_min_axil_0 <= (s_axil_wdata[31:0] & wmask) | (int_pkt_len_min_axil_0 & ~wmask);
    end
    // int_pkt_len_max_axil_0
    always_ff @(posedge clk) begin
        if (rst)
            int_pkt_len_max_axil_0 <= 32'b0;
        else if (w_hs && waddr == PKT_LEN_MAX_AXIL_ADDR_0)
            int_pkt_len_max_axil_0 <= (s_axil_wdata[31:0] & wmask) | (int_pkt_len_max_axil_0 & ~wmask);
    end
    assign start_axil = int_start_axil_0[0:0];
    assign pkt_cnt_limit_axil[31:0] = int_pkt_cnt_limit_axil_0[31:0];
    assign idle_ratio_code_axil[31:0] = int_idle_ratio_code_axil_0[31:0];
    assign idle_ratio_code_axil[63:32] = int_idle_ratio_code_axil_1[31:0];
    assign pkt_len_min_axil[15:0] = int_pkt_len_min_axil_0[15:0];
    assign pkt_len_max_axil[15:0] = int_pkt_len_max_axil_0[15:0];
endmodule
