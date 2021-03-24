`timescale 1ns / 1ps
module rifl #
(
//gt
    parameter int N_CHANNEL = 1,
    parameter real LANE_LINE_RATE = 28,
    parameter real GT_REF_FREQ = 100.0,
    parameter MASTER_CHAN = "UNDEFINED",
    parameter int GT_WIDTH = 64,
//rifl
    //error injection
    parameter bit ERROR_INJ = 1'b0,
    parameter bit [63:0] ERROR_SEED = 64'b0,
    parameter int CABLE_LENGTH = 10,
    parameter int USER_WIDTH = 256,
    parameter int FRAME_WIDTH = 256,
    parameter int CRC_WIDTH = 12,
    parameter int CRC_POLY = 12'h02f,
    parameter int SCRAMBLER_N1 = 13,
    parameter int SCRAMBLER_N2 = 33
)
(
//clk and rst
    input logic gt_ref_clk_p,
    input logic gt_ref_clk_n,
    input logic init_clk,
    input logic rst,
    input logic gt_rst,
//clk out
    output logic usr_clk,
//gt
    input logic [3*N_CHANNEL-1:0] gt_loopback_in,
    input logic [N_CHANNEL-1:0] gt_rxp_in,
    input logic [N_CHANNEL-1:0] gt_rxn_in,
    output logic [N_CHANNEL-1:0] gt_txp_out,
    output logic [N_CHANNEL-1:0] gt_txn_out,
//user AXI4_Stream interface
    input logic [USER_WIDTH-1:0] s_axis_tdata,
    input logic [USER_WIDTH/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [USER_WIDTH-1:0] m_axis_tdata,
    output logic [USER_WIDTH/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tvalid,
    input logic m_axis_tready,
//error injection
    input logic [63:0] err_threshold,
//stats
    //tx
    output logic [N_CHANNEL-1:0] tx_state_init,
    output logic [N_CHANNEL-1:0] tx_state_send_pause,
    output logic [N_CHANNEL-1:0] tx_state_pause,
    output logic [N_CHANNEL-1:0] tx_state_send_retrans,
    output logic [N_CHANNEL-1:0] tx_state_retrans,
    output logic [N_CHANNEL-1:0] tx_state_normal,
    //rx
    output logic [N_CHANNEL-1:0] rx_up,
    output logic [N_CHANNEL-1:0] rx_aligned,
    output logic [N_CHANNEL-1:0] rx_error,
    output logic [N_CHANNEL-1:0] rx_pause_request,
    output logic [N_CHANNEL-1:0] rx_retrans_request,
    output logic compensate
);
    localparam int N_BOUNDING_GRP = FRAME_WIDTH*N_CHANNEL/USER_WIDTH;
    localparam int PAYLOAD_WIDTH = FRAME_WIDTH-4-CRC_WIDTH;
    localparam int CHANNEL_PER_GRP = N_CHANNEL/N_BOUNDING_GRP;
    localparam int SPATIAL_CB_WIDTH = PAYLOAD_WIDTH*CHANNEL_PER_GRP;

    localparam int FRAME_RATIO = FRAME_WIDTH/GT_WIDTH;
    localparam int FRAME_CNT_WIDTH = FRAME_RATIO == 1 ? 1 : $clog2(FRAME_RATIO);
    localparam int USR_RATIO = N_BOUNDING_GRP;
    localparam int USR_CNT_WIDTH = USR_RATIO == 1 ? 1 : $clog2(USR_RATIO);
    localparam bit [2:0] USR_DIV_CODE = USR_RATIO-1;
    localparam int FRAME_FREQ = int'(LANE_LINE_RATE*10**3/FRAME_WIDTH);
    //set GT latency to 80 ns (normally lower than this)
    localparam real GT_LATENCY = 80.0;
    //time for electrons to travel through the cable
    localparam real CABLE_LATENCY = real'(CABLE_LENGTH)*3.34;
    localparam real RTT = 2*(GT_LATENCY+CABLE_LATENCY);
    //it takes up to 8*2 frame cycles for RX to confirm a retransmission request (when both sides have errors)
    localparam int RX_DELAY = 16;
    //the retrans buffer need to preserve all frames started from N-16 instead of N
    localparam int ROLLBACK_DELAY = 16;
    localparam int FRAME_ID_WIDTH = $clog2(RX_DELAY+ROLLBACK_DELAY+int'(RTT*LANE_LINE_RATE/real'(FRAME_WIDTH)));

//clks
    logic tx_frame_clk;
    logic rx_frame_clk;
    logic tx_gt_clk;
    logic rx_gt_clk;
//resets
    logic tx_frame_rst;
    logic rx_frame_rst;
    logic gt_init_rst;

//gt
    logic [N_CHANNEL-1:0] tx_gt_src_clk;
    logic [N_CHANNEL-1:0] rx_gt_src_clk;
    logic tx_usr_clk;
    logic rx_usr_clk;
    logic tx_usr_clk_active, rx_usr_clk_active;
    logic tx_gt_clk_rst, rx_gt_clk_rst;
    logic [GT_WIDTH-1:0] gt_tx_data[N_CHANNEL-1:0];
    logic [GT_WIDTH-1:0] gt_rx_data[N_CHANNEL-1:0];

//rifl
    //error injection
    logic [63:0] threshold_reg;
    logic [GT_WIDTH*N_CHANNEL-1:0] gt_bit_error;
    //tx
    //rst
    logic tx_poweron_rst = 1'b1;
    //status
    logic [2:0] tx_state[N_CHANNEL-1:0];
    logic [2:0] tx_state_core[N_BOUNDING_GRP-1:0][CHANNEL_PER_GRP-1:0];
    //clock counters
    logic [FRAME_CNT_WIDTH-1:0] frame_clk_cnt;
    logic [USR_CNT_WIDTH-1:0] usr_clk_cnt;
    //gt
    logic [GT_WIDTH-1:0] gt_tx_data_core[N_BOUNDING_GRP-1:0][CHANNEL_PER_GRP-1:0];
    //tx narrow axis
    logic [SPATIAL_CB_WIDTH-1:0] tx_narrow_tdata;
    logic [SPATIAL_CB_WIDTH/8-1:0] tx_narrow_tkeep;
    logic tx_narrow_tlast;
    logic tx_narrow_tvalid;
    logic tx_narrow_tready;
    //tx core axis
    logic [SPATIAL_CB_WIDTH-1:0] rifl_core_tx_tdata[N_BOUNDING_GRP-1:0];
    logic [SPATIAL_CB_WIDTH/8-1:0] rifl_core_tx_tkeep[N_BOUNDING_GRP-1:0];
    logic rifl_core_tx_tlast[N_BOUNDING_GRP-1:0];
    logic rifl_core_tx_tvalid[N_BOUNDING_GRP-1:0];
    logic rifl_core_tx_tready[N_BOUNDING_GRP-1:0];
    //rx
    //status
    logic [N_CHANNEL-1:0] rx_aligned_tx;
    logic [N_CHANNEL-1:0] rx_aligned_rx;
    logic [CHANNEL_PER_GRP-1:0] rx_aligned_tx_core[N_BOUNDING_GRP-1:0];
    logic [CHANNEL_PER_GRP-1:0] rx_aligned_rx_core[N_BOUNDING_GRP-1:0];
    logic [CHANNEL_PER_GRP-1:0] rx_up_core[N_BOUNDING_GRP-1:0];
    logic [CHANNEL_PER_GRP-1:0] rx_aligned_core[N_BOUNDING_GRP-1:0];
    logic [CHANNEL_PER_GRP-1:0] rx_error_core[N_BOUNDING_GRP-1:0];
    logic [CHANNEL_PER_GRP-1:0] rx_pause_request_core[N_BOUNDING_GRP-1:0];
    logic [CHANNEL_PER_GRP-1:0] rx_retrans_request_core[N_BOUNDING_GRP-1:0];
    //gt
    logic [GT_WIDTH-1:0] gt_rx_data_core[N_BOUNDING_GRP-1:0][CHANNEL_PER_GRP-1:0];
    //rx narrow axis
    logic [SPATIAL_CB_WIDTH-1:0] rx_narrow_tdata;
    logic [SPATIAL_CB_WIDTH/8-1:0] rx_narrow_tkeep;
    logic rx_narrow_tlast;
    logic rx_narrow_tvalid;
    logic rx_narrow_tready;
    //rx core axis
    logic [SPATIAL_CB_WIDTH-1:0] rifl_core_rx_tdata[N_BOUNDING_GRP-1:0];
    logic [SPATIAL_CB_WIDTH/8-1:0] rifl_core_rx_tkeep[N_BOUNDING_GRP-1:0];
    logic rifl_core_rx_tlast[N_BOUNDING_GRP-1:0];
    logic rifl_core_rx_tvalid[N_BOUNDING_GRP-1:0];
    logic rifl_core_rx_tready[N_BOUNDING_GRP-1:0];

//compensate
    logic clock_active;

    genvar i,j;
    rifl_rst_gen u_rifl_rst_gen(.*);
    clock_compensate u_clock_compensate(.*);

//external clock buffer
    IBUFDS_GTE4 #(
        .REFCLK_EN_TX_PATH  (1'b0),
        .REFCLK_HROW_CK_SEL (2'b00),
        .REFCLK_ICNTL_RX    (2'b00)
    ) gt_ref_inst(
        .I (gt_ref_clk_p),
        .IB (gt_ref_clk_n),
        .CEB (1'b0),
        .O (gt_ref_clk),
        .ODIV2 ()
    );

//error injection
    if (ERROR_INJ) begin
        always_ff @(posedge usr_clk) begin
            threshold_reg <= err_threshold;
        end
        rifl_err_inj #(
            .DWIDTH (GT_WIDTH*N_CHANNEL),
            .SEED (ERROR_SEED)
        ) u_rifl_err_inj(
          	.clk       (tx_gt_clk),
            .threshold (threshold_reg),
            .err_vec   (gt_bit_error)
        );
    end
    else begin
        for (i = 0; i < N_CHANNEL; i++)
            assign gt_bit_error = {GT_WIDTH*N_CHANNEL{1'b0}};
    end


//gt
    rifl_gt_wrapper #(
        .N_CHANNEL   (N_CHANNEL),
        .FRAME_WIDTH (FRAME_WIDTH),
        .GT_WIDTH    (GT_WIDTH)
    ) u_rifl_gt_wrapper(
    	.gt_ref_clk        (gt_ref_clk),
        .init_clk          (init_clk),
        .rst               (rst),
        .gt_init_rst       (gt_init_rst),
        .rx_aligned        (rx_aligned_rx),
        .gt_rxp_in         (gt_rxp_in),
        .gt_rxn_in         (gt_rxn_in),
        .gt_loopback_in    (gt_loopback_in),
        .gt_tx_data        (gt_tx_data),
        .gt_rx_data        (gt_rx_data),
        .gt_txp_out        (gt_txp_out),
        .gt_txn_out        (gt_txn_out),
        .tx_gt_src_clk     (tx_gt_src_clk),
        .rx_gt_src_clk     (rx_gt_src_clk),
        .tx_usr_clk        ({N_CHANNEL{tx_usr_clk}}),
        .rx_usr_clk        ({N_CHANNEL{rx_usr_clk}}),
        .tx_gt_clk         ({N_CHANNEL{tx_gt_clk}}),
        .rx_gt_clk         ({N_CHANNEL{rx_gt_clk}}),
        .tx_usr_clk_active (tx_usr_clk_active),
        .rx_usr_clk_active (rx_usr_clk_active),
        .tx_gt_clk_rst     (tx_gt_clk_rst),
        .rx_gt_clk_rst     (rx_gt_clk_rst)
    );
    
    clock_buffer #(
        .RATIO     (FRAME_RATIO)
    ) u_tx_clock_buffer(
    	.src_clk       (tx_gt_src_clk[0]),
        .rst           (tx_gt_clk_rst),
        .usrclk        (tx_usr_clk),
        .usrclk2       (tx_gt_clk),
        .usrclk3       (tx_frame_clk),
        .usrclk_active (tx_usr_clk_active)
    );
    clock_buffer #(
        .RATIO     (FRAME_RATIO)
    ) u_rx_clock_buffer(
    	.src_clk       (rx_gt_src_clk[0]),
        .rst           (rx_gt_clk_rst),
        .usrclk        (rx_usr_clk),
        .usrclk2       (rx_gt_clk),
        .usrclk3       (rx_frame_clk),
        .usrclk_active (rx_usr_clk_active)
    );

    if (N_BOUNDING_GRP != 1) begin
        BUFG_GT usr_clk_bufg (
            .CE(1'b1),
            .CEMASK(1'b0),
            .CLR(tx_gt_clk_rst),
            .CLRMASK(1'b0),
            .DIV(USR_DIV_CODE),
            .I(tx_gt_src_clk[0]),
            .O(usr_clk)
        );
        clock_counter #(
            .RATIO (USR_RATIO)
        ) usr_clock_counter(
            .clk_slow (tx_frame_clk),
            .clk_fast (usr_clk),
            .cnt      (usr_clk_cnt)
        );        
    end
    else begin
        assign usr_clk = tx_frame_clk;
        assign usr_clk_cnt = 1'b0;
    end

    if (FRAME_RATIO != 1) begin
        clock_counter #(
            .RATIO (FRAME_RATIO)
        ) frame_clock_counter(
            .clk_slow (tx_frame_clk),
            .clk_fast (tx_gt_clk),
            .cnt      (frame_clk_cnt)
        );
    end
    else begin
        assign frame_clk_cnt = 1'b0;
    end

    tx_axis_conv #(
        .DWIDTH_IN   (USER_WIDTH),
        .DWIDTH_OUT  (SPATIAL_CB_WIDTH)
    ) u_tx_axis_conv(
    	.clk           (usr_clk),
        .rst           (tx_frame_rst|tx_poweron_rst),
        .s_axis_tdata  (s_axis_tdata),
        .s_axis_tkeep  (s_axis_tkeep),
        .s_axis_tlast  (s_axis_tlast),
        .s_axis_tvalid (s_axis_tvalid),
        .s_axis_tready (s_axis_tready),
        .m_axis_tdata  (tx_narrow_tdata),
        .m_axis_tkeep  (tx_narrow_tkeep),
        .m_axis_tlast  (tx_narrow_tlast),
        .m_axis_tvalid (tx_narrow_tvalid),
        .m_axis_tready (tx_narrow_tready)
    );

    if (N_BOUNDING_GRP != 1) begin
        tx_temporal_cb #(
            .DWIDTH (SPATIAL_CB_WIDTH),
            .RATIO  (N_BOUNDING_GRP)
        ) u_tx_temporal_cb(
    	    .clk           (usr_clk),
            .rst           (tx_frame_rst|tx_poweron_rst),
            .clk_cnt       (usr_clk_cnt),
            .s_axis_tdata  (tx_narrow_tdata),
            .s_axis_tkeep  (tx_narrow_tkeep),
            .s_axis_tlast  (tx_narrow_tlast),
            .s_axis_tvalid (tx_narrow_tvalid),
            .s_axis_tready (tx_narrow_tready),
            .m_axis_tdata  (rifl_core_tx_tdata),
            .m_axis_tkeep  (rifl_core_tx_tkeep),
            .m_axis_tlast  (rifl_core_tx_tlast),
            .m_axis_tvalid (rifl_core_tx_tvalid),
            .m_axis_tready (rifl_core_tx_tready)
        );
    end
    else begin
        assign rifl_core_tx_tdata[0] = tx_narrow_tdata;
        assign rifl_core_tx_tkeep[0] = tx_narrow_tkeep;
        assign rifl_core_tx_tlast[0] = tx_narrow_tlast;
        assign rifl_core_tx_tvalid[0] = tx_narrow_tvalid;
        assign tx_narrow_tready = rifl_core_tx_tready[0];
    end
    
    for (i = 0; i < N_BOUNDING_GRP; i++) begin
        rifl_core #(
            .N_CHANNEL      (CHANNEL_PER_GRP),
            .GT_WIDTH       (GT_WIDTH       ),
            .FRAME_WIDTH    (FRAME_WIDTH    ),
            .PAYLOAD_WIDTH  (PAYLOAD_WIDTH  ),
            .CRC_WIDTH      (CRC_WIDTH      ),
            .CRC_POLY       (CRC_POLY       ),
            .FRAME_ID_WIDTH (FRAME_ID_WIDTH ),
            .SCRAMBLER_N1   (SCRAMBLER_N1   ),
            .SCRAMBLER_N2   (SCRAMBLER_N2   ),
            .CNT_WIDTH      (FRAME_CNT_WIDTH),
            .FRAME_FREQ     (FRAME_FREQ)
        ) u_rifl_core(
        	.tx_frame_clk          (tx_frame_clk          ),
            .rst                   (rst                   ),
            .tx_frame_rst          (tx_frame_rst|tx_poweron_rst),
            .rx_frame_rst          (rx_frame_rst          ),
            .rifl_core_tx_tdata    (rifl_core_tx_tdata[i] ),
            .rifl_core_tx_tkeep    (rifl_core_tx_tkeep[i] ),
            .rifl_core_tx_tlast    (rifl_core_tx_tlast[i] ),
            .rifl_core_tx_tvalid   (rifl_core_tx_tvalid[i]),
            .rifl_core_tx_tready   (rifl_core_tx_tready[i]),
            .rifl_core_rx_tdata    (rifl_core_rx_tdata[i] ),
            .rifl_core_rx_tkeep    (rifl_core_rx_tkeep[i] ),
            .rifl_core_rx_tlast    (rifl_core_rx_tlast[i] ),
            .rifl_core_rx_tvalid   (rifl_core_rx_tvalid[i]),
            .rifl_core_rx_tready   (rifl_core_rx_tready[i]),
            .tx_gt_clk             (tx_gt_clk             ),
            .rx_gt_clk             (rx_gt_clk             ),
            .gt_rx_data            (gt_rx_data_core[i]    ),
            .gt_tx_data            (gt_tx_data_core[i]    ),
            .clk_cnt               (frame_clk_cnt         ),
            .compensate            (compensate            ),
            .tx_state              (tx_state_core[i]      ),
            .rx_up                 (rx_up_core[i]         ),
            .rx_aligned_tx         (rx_aligned_tx_core[i] ),
            .rx_aligned_rx         (rx_aligned_rx_core[i] ),
            .rx_error              (rx_error_core[i]      ),
            .rx_pause_request      (rx_pause_request_core[i]),
            .rx_retrans_request    (rx_retrans_request_core[i])
        );
    end

    if (N_BOUNDING_GRP != 1) begin
        rx_temporal_cb #(
            .DWIDTH (SPATIAL_CB_WIDTH),
            .RATIO  (N_BOUNDING_GRP)
        ) u_rx_temporal_cb(
        	.clk           (usr_clk),
            .rst           (tx_frame_rst|tx_poweron_rst),
            .clk_cnt       (usr_clk_cnt),
            .s_axis_tdata  (rifl_core_rx_tdata),
            .s_axis_tkeep  (rifl_core_rx_tkeep),
            .s_axis_tlast  (rifl_core_rx_tlast),
            .s_axis_tvalid (rifl_core_rx_tvalid),
            .s_axis_tready (rifl_core_rx_tready),
            .m_axis_tdata  (rx_narrow_tdata),
            .m_axis_tkeep  (rx_narrow_tkeep),
            .m_axis_tlast  (rx_narrow_tlast),
            .m_axis_tvalid (rx_narrow_tvalid),
            .m_axis_tready (rx_narrow_tready)
        );
    end
    else begin
        assign rx_narrow_tdata = rifl_core_rx_tdata[0];
        assign rx_narrow_tkeep = rifl_core_rx_tkeep[0];
        assign rx_narrow_tlast = rifl_core_rx_tlast[0];
        assign rx_narrow_tvalid = rifl_core_rx_tvalid[0];
        assign rifl_core_rx_tready[0] = rx_narrow_tready;
    end

    rx_axis_conv #(
        .DWIDTH_IN   (SPATIAL_CB_WIDTH),
        .DWIDTH_OUT  (USER_WIDTH)
    ) u_rx_axis_conv(
    	.clk           (usr_clk),
        .rst           (tx_frame_rst|tx_poweron_rst),
        .s_axis_tdata  (rx_narrow_tdata),
        .s_axis_tkeep  (rx_narrow_tkeep),
        .s_axis_tlast  (rx_narrow_tlast),
        .s_axis_tvalid (rx_narrow_tvalid),
        .s_axis_tready (rx_narrow_tready),
        .m_axis_tdata  (m_axis_tdata),
        .m_axis_tkeep  (m_axis_tkeep),
        .m_axis_tlast  (m_axis_tlast),
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready)
    );

    always_ff @(posedge tx_frame_clk) begin
        if (&rx_aligned_tx)
            tx_poweron_rst <= 1'b0;
    end

    assign clock_active = tx_usr_clk_active & rx_usr_clk_active;

//gt
    for (i = 0; i < N_BOUNDING_GRP; i++) begin
        for (j = 0; j < CHANNEL_PER_GRP; j++) begin
            assign gt_tx_data[i*CHANNEL_PER_GRP+j] = gt_tx_data_core[i][j] ^ gt_bit_error[(i*CHANNEL_PER_GRP+j+1)*GT_WIDTH-1-:GT_WIDTH];
            assign gt_rx_data_core[i][j] = gt_rx_data[i*CHANNEL_PER_GRP+j];
        end
    end

//stats
    for (i = 0; i < N_BOUNDING_GRP; i++) begin
        for (j = 0; j < CHANNEL_PER_GRP; j++) begin
            assign tx_state[i*CHANNEL_PER_GRP+j] = tx_state_core[i][j];
            assign rx_aligned_tx[i*CHANNEL_PER_GRP+j] = rx_aligned_tx_core[i][j];
            assign rx_aligned_rx[i*CHANNEL_PER_GRP+j] = rx_aligned_rx_core[i][j];
            assign rx_up[i*CHANNEL_PER_GRP+j] = rx_up_core[i][j];
            assign rx_error[i*CHANNEL_PER_GRP+j] = rx_error_core[i][j];
            assign rx_pause_request[i*CHANNEL_PER_GRP+j] = rx_pause_request_core[i][j];
            assign rx_retrans_request[i*CHANNEL_PER_GRP+j] = rx_retrans_request_core[i][j];
        end
    end

    assign rx_aligned = rx_aligned_tx;
    for (i = 0; i < N_CHANNEL; i++) begin
        assign tx_state_init[i] = tx_state[i] == 3'd0;
        assign tx_state_send_pause[i] = tx_state[i] == 3'd1;
        assign tx_state_pause[i] = tx_state[i] == 3'd2;
        assign tx_state_retrans[i] = tx_state[i] == 3'd3;
        assign tx_state_send_retrans[i] = tx_state[i] == 3'd4;
        assign tx_state_normal[i] = tx_state[i] == 3'd5;
    end
endmodule