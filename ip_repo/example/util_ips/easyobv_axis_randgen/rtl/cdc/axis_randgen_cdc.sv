module axis_randgen_cdc (
    input logic clk,
    input logic s_axil_aclk,
    input logic rst,
    output logic s_axil_rst,
//single-bit
    input logic start_axil,
    input logic done_int,
    output logic start_int,
    output logic done_axil,
//multi-bit
    input logic [31:0] pkt_cnt_limit_axil,
    input logic [63:0] idle_ratio_code_axil,
    input logic [15:0] pkt_len_min_axil,
    input logic [15:0] pkt_len_max_axil,
    output logic [31:0] pkt_cnt_limit_int,
    output logic [63:0] idle_ratio_code_int,
    output logic [15:0] pkt_len_min_int,
    output logic [15:0] pkt_len_max_int
);
//resets
    sync_reset #(
        .N_STAGE (5)
    ) u_sync_s_axil_rst(
    	.clk     (s_axil_aclk),
        .rst_in  (rst),
        .rst_out (s_axil_rst)
    );

//single-bit signals
    sync_signle_bit #(
        .N_STAGE   (3),
        .INPUT_REG (1)
    ) sync_start(
        .clk_in  (s_axil_aclk),
    	.clk_out (clk),
        .rst     (rst),
        .din     (start_axil),
        .dout    (start_int)
    );
    sync_signle_bit #(
        .N_STAGE   (3),
        .INPUT_REG (1)
    ) sync_done(
        .clk_in  (clk),
    	.clk_out (s_axil_aclk),
        .rst     (rst),
        .din     (done_int),
        .dout    (done_axil)
    );

//multi-bit signals
    sync_multi_bit #(
        .SIZE       (32),
        .N_STAGE    (3),
        .OUTPUT_REG (1)
    ) sync_pkt_cnt_limit(
    	.clk_in   (s_axil_aclk),
        .clk_out  (clk),
        .rst      (rst),
        .din      (pkt_cnt_limit_axil),
        .din_vld  (1'b1),
        .din_rdy  (),
        .dout     (pkt_cnt_limit_int),
        .dout_vld (),
        .dout_rdy (1'b1)
    );    
    sync_multi_bit #(
        .SIZE       (64),
        .N_STAGE    (3),
        .OUTPUT_REG (1)
    ) sync_idle_ratio_code(
    	.clk_in   (s_axil_aclk),
        .clk_out  (clk),
        .rst      (rst),
        .din      (idle_ratio_code_axil),
        .din_vld  (1'b1),
        .din_rdy  (),
        .dout     (idle_ratio_code_int),
        .dout_vld (),
        .dout_rdy (1'b1)
    );
    sync_multi_bit #(
        .SIZE       (16),
        .N_STAGE    (3),
        .OUTPUT_REG (1)
    ) sync_pkt_len_min(
    	.clk_in   (s_axil_aclk),
        .clk_out  (clk),
        .rst      (rst),
        .din      (pkt_len_min_axil),
        .din_vld  (1'b1),
        .din_rdy  (),
        .dout     (pkt_len_min_int),
        .dout_vld (),
        .dout_rdy (1'b1)
    );
    sync_multi_bit #(
        .SIZE       (16),
        .N_STAGE    (3),
        .OUTPUT_REG (1)
    ) sync_pkt_len_max(
    	.clk_in   (s_axil_aclk),
        .clk_out  (clk),
        .rst      (rst),
        .din      (pkt_len_max_axil),
        .din_vld  (1'b1),
        .din_rdy  (),
        .dout     (pkt_len_max_int),
        .dout_vld (),
        .dout_rdy (1'b1)
    ); 
endmodule
