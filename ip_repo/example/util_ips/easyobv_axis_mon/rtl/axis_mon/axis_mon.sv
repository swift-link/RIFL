`timescale 1ns/1ps
`ifndef WIDTH_VAL
    `define WIDTH_VAL(x) x <= 0 ? 1 : x
`endif
module axis_mon #
(
    parameter int DWIDTH = 32,
    parameter bit HAS_READY = 0,
    parameter bit HAS_KEEP = 0,
    parameter bit HAS_LAST = 0,
    parameter bit HAS_STRB = 0,
    parameter int DEST_WIDTH = 0,
    parameter int USER_WIDTH = 0,
    parameter int ID_WIDTH = 0,
    parameter bit LOOPBACK = 0,
    parameter int CMP_FIFO_DEPTH = 16
)
(
    input logic clk,
    input logic rst,
//AXI4-Stream TX
    input logic [DWIDTH-1:0] tx_mon_tdata,
    input logic tx_mon_tvalid,
    input logic tx_mon_tready,
    input logic [DWIDTH/8-1:0] tx_mon_tkeep,
    input logic tx_mon_tlast,
    input logic [DWIDTH/8-1:0] tx_mon_tstrb,
    input logic [`WIDTH_VAL(DEST_WIDTH)-1:0] tx_mon_tdest,
    input logic [`WIDTH_VAL(USER_WIDTH)-1:0] tx_mon_tuser,
    input logic [`WIDTH_VAL(ID_WIDTH)-1:0] tx_mon_tid,
//AXI4-Stream RX
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
    logic [63:0] tx_start_time;
    logic tx_started;
    logic [$clog2(DWIDTH/8):0] tx_byte_cnt;

    always_ff @(posedge clk) begin
        if (rst)
            time_cnt <= 64'b0;
        else
            time_cnt <= time_cnt + 1'b1;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_started <= 1'b0;
            tx_start_time <= 64'b0;
        end
        else if (~tx_started && (tx_mon_tready & tx_mon_tvalid)) begin
            tx_started <= 1'b1;
            tx_start_time <= time_cnt - 1'b1;
        end
    end
    always_ff @(posedge clk) begin
        if (rst)
            tx_time_elapsed <= 64'b0;
        else if (tx_mon_tready & tx_mon_tvalid) begin
            if (tx_started)
                tx_time_elapsed <= time_cnt - tx_start_time;
            else
                tx_time_elapsed <= 64'b1;
        end
    end

    always_ff @(posedge clk) begin
        if (rst)
            tx_pkt_cnt <= 64'b0;
        else if (tx_mon_tready & tx_mon_tvalid & tx_mon_tlast)
            tx_pkt_cnt <= tx_pkt_cnt + 1'b1;
    end

    if (HAS_KEEP) begin
        always_comb begin
            tx_byte_cnt = {($clog2(DWIDTH/8)+1){1'b0}};
            for (int i = 0; i < DWIDTH/8; i++)
                tx_byte_cnt = tx_byte_cnt + tx_mon_tkeep[i];
        end
    end
    else begin
        assign tx_byte_cnt = {1'b1,{$clog2(DWIDTH/8){1'b0}}};
    end

    always_ff @(posedge clk) begin
        if (rst)
            tx_transferred_size <= 64'b0;
        else if (tx_mon_tready & tx_mon_tvalid)
            tx_transferred_size <= tx_transferred_size + tx_byte_cnt;
    end

    if (LOOPBACK) begin
        localparam int VEC_WIDTH = DWIDTH + HAS_KEEP*DWIDTH/8 + HAS_LAST + HAS_STRB*DWIDTH/8 + DEST_WIDTH + USER_WIDTH + ID_WIDTH;
        localparam int TDATA_IDX = DWIDTH-1;
        localparam int TKEEP_IDX = TDATA_IDX+DWIDTH/8*HAS_KEEP;
        localparam int TSTRB_IDX = TKEEP_IDX+DWIDTH/8*HAS_STRB;
        localparam int TLAST_IDX = TSTRB_IDX+HAS_LAST;
        localparam int TDEST_IDX = TLAST_IDX+DEST_WIDTH;
        localparam int TUSER_IDX = TDEST_IDX+USER_WIDTH;
        localparam int TID_IDX = TUSER_IDX+ID_WIDTH;
        logic [DWIDTH-1:0] tx_mon_tdata_int, rx_mon_tdata_int;
        logic [VEC_WIDTH-1:0] tx_vec_tdata, rx_vec_tdata, cmp_tdata;
        logic tx_vec_tvalid, cmp_tvalid, cmp_tready;

        logic rx_started;
        logic [63:0] rx_start_time;

        logic [$clog2(DWIDTH/8):0] rx_byte_cnt;

        logic [63:0] latency_fifo_in;
        logic latency_fifo_in_vld;
        logic [63:0] latency_fifo_out;
        logic latency_fifo_out_rdy;

        if (HAS_KEEP) begin
            logic [DWIDTH-1:0] tx_mon_tdata_mask, rx_mon_tdata_mask;
            genvar i;
            for (i = 0; i < DWIDTH/8; i++) begin
                assign tx_mon_tdata_mask[(i+1)*8-1-:8] = {8{tx_mon_tkeep[i]}};
                assign rx_mon_tdata_mask[(i+1)*8-1-:8] = {8{rx_mon_tkeep[i]}};
            end
            assign tx_mon_tdata_int = tx_mon_tdata & tx_mon_tdata_mask;
            assign rx_mon_tdata_int = rx_mon_tdata & rx_mon_tdata_mask;
        end
        else begin
            assign tx_mon_tdata_int = tx_mon_tdata;
            assign rx_mon_tdata_int = rx_mon_tdata;
        end

        assign tx_vec_tdata[TDATA_IDX:0] = tx_mon_tdata_int; 
        if (HAS_KEEP)
            assign tx_vec_tdata[TKEEP_IDX-:DWIDTH/8] = tx_mon_tkeep;
        if (HAS_STRB)
            assign tx_vec_tdata[TSTRB_IDX-:DWIDTH/8] = tx_mon_tstrb;
        if (HAS_LAST)
            assign tx_vec_tdata[TLAST_IDX] = tx_mon_tlast;
        if (DEST_WIDTH != 0)
            assign tx_vec_tdata[TDEST_IDX-:DEST_WIDTH] = tx_mon_tdest;
        if (USER_WIDTH != 0)
            assign tx_vec_tdata[TUSER_IDX-:USER_WIDTH] = tx_mon_tuser;
        if (ID_WIDTH != 0)
            assign tx_vec_tdata[TID_IDX-:ID_WIDTH] = tx_mon_tid;

        assign rx_vec_tdata[TDATA_IDX:0] = rx_mon_tdata_int; 
        if (HAS_KEEP)
            assign rx_vec_tdata[TKEEP_IDX-:DWIDTH/8] = rx_mon_tkeep;
        if (HAS_STRB)
            assign rx_vec_tdata[TSTRB_IDX-:DWIDTH/8] = rx_mon_tstrb;
        if (HAS_LAST)
            assign rx_vec_tdata[TLAST_IDX] = rx_mon_tlast;
        if (DEST_WIDTH != 0)
            assign rx_vec_tdata[TDEST_IDX-:DEST_WIDTH] = rx_mon_tdest;
        if (USER_WIDTH != 0)
            assign rx_vec_tdata[TUSER_IDX-:USER_WIDTH] = rx_mon_tuser;
        if (ID_WIDTH != 0) 
            assign rx_vec_tdata[TID_IDX-:ID_WIDTH] = rx_mon_tid;

        assign tx_vec_tvalid = tx_mon_tvalid&tx_mon_tready;

        easy_fifo_axis_sync #(
            .DWIDTH     (VEC_WIDTH),
            .DEPTH      (CMP_FIFO_DEPTH),
            .INPUT_REG  (1),
            .OUTPUT_REG (0)
        ) cmp_fifo (
            .*,
            .s_axis_tdata  (tx_vec_tdata),
            .s_axis_tvalid (tx_vec_tvalid),
            .s_axis_tready (),
            .m_axis_tdata  (cmp_tdata),
            .m_axis_tvalid (cmp_tvalid),
            .m_axis_tready (cmp_tready)
        );
        assign cmp_tready = rx_mon_tvalid & rx_mon_tready & ~mismatch;

        easy_fifo_axis_sync #(
            .DWIDTH     (64),
            .DEPTH      (CMP_FIFO_DEPTH),
            .INPUT_REG  (1),
            .OUTPUT_REG (0)
        ) latency_fifo (
            .*,
            .s_axis_tdata  (latency_fifo_in),
            .s_axis_tvalid (latency_fifo_in_vld),
            .s_axis_tready (),
            .m_axis_tdata  (latency_fifo_out),
            .m_axis_tvalid (),
            .m_axis_tready (latency_fifo_out_rdy)
        );

        assign latency_fifo_in = time_cnt;
        assign latency_fifo_in_vld = tx_mon_tready&tx_mon_tvalid&tx_mon_tlast&~mismatch;
        assign latency_fifo_out_rdy = rx_mon_tready&rx_mon_tvalid&rx_mon_tlast&~mismatch;

        always_ff @(posedge clk) begin
            if (rst) begin
                rx_started <= 1'b0;
                rx_start_time <= 64'b0;
            end
            else if (~rx_started & rx_mon_tready & rx_mon_tvalid) begin
                rx_started <= 1'b1;
                rx_start_time <= time_cnt - 1'b1;
            end
        end
        always_ff @(posedge clk) begin
            if (rst)
                rx_time_elapsed <= 64'b0;
            else if (rx_mon_tready & rx_mon_tvalid) begin
                if (rx_started)
                    rx_time_elapsed <= time_cnt - rx_start_time;
                else
                    rx_time_elapsed <= 64'b1;
            end
        end

        always_ff @(posedge clk or posedge rst) begin
            if (rst)
                mismatch <= 1'b0;
            else if ((rx_mon_tready &rx_mon_tvalid) && (rx_vec_tdata != cmp_tdata || ~cmp_tvalid))
                mismatch <= 1'b1;
        end

        always_ff @(posedge clk) begin
            if (rst)
                rx_pkt_cnt <= 64'b0;
            else if (rx_mon_tready & rx_mon_tvalid & rx_mon_tlast)
                rx_pkt_cnt <= rx_pkt_cnt + 1'b1;
        end

        if (HAS_KEEP) begin
            always_comb begin
                rx_byte_cnt = {($clog2(DWIDTH/8)+1){1'b0}};
                for (int i = 0; i < DWIDTH/8; i++)
                    rx_byte_cnt = rx_byte_cnt + rx_mon_tkeep[i];
            end
        end
        else begin
            assign rx_byte_cnt = {1'b1,{$clog2(DWIDTH/8){1'b0}}};
        end

        always_ff @(posedge clk) begin
            if (rst)
                rx_transferred_size <= 64'b0;
            else if (rx_mon_tready & rx_mon_tvalid)
                rx_transferred_size <= rx_transferred_size + rx_byte_cnt;
        end

        always_ff @(posedge clk) begin
            if (rst)
                latency_sum <= 64'b0;
            else if (latency_fifo_out_rdy)
                latency_sum <= latency_sum + (time_cnt-latency_fifo_out);
        end
    end
    else begin
        assign mismatch = 1'b0;
        assign rx_pkt_cnt = 64'b0;
        assign rx_time_elapsed = 64'b0;
        assign rx_transferred_size = 64'b0;
        assign latency_sum = 64'b0;
    end
endmodule
