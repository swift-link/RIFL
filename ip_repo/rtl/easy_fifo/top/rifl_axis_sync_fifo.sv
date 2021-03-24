`timescale 1ns/1ps
module rifl_axis_sync_fifo #
(
    parameter int DWIDTH = 32,
    parameter int DEPTH = 1,
    parameter bit OUTPUT_REG = 0
)
(
    input logic rst,
    input logic clk,
    input logic [DWIDTH-1:0] s_axis_tdata,
    input logic [DWIDTH/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [DWIDTH-1:0] m_axis_tdata,
    output logic [DWIDTH/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tvalid,
    input logic m_axis_tready,
	output logic [$clog2(DEPTH):0] fifo_cnt
);
//internal data
    logic [DWIDTH*9/8:0] wr_data_int, rd_data_int;
    logic wr_en_int, rd_en_int;
    logic wr_full_int, rd_empty_int;

    sync_fifo #(
        .DWIDTH   (DWIDTH*9/8+1),
        .DEPTH    (DEPTH)
    ) u_sync_fifo (
    	.clk      (clk),
        .rst      (rst),
        .wr_data  (wr_data_int),
        .wr_en    (wr_en_int),
        .rd_en    (rd_en_int),
        .rd_data  (rd_data_int),
        .wr_full  (wr_full_int),
        .rd_empty (rd_empty_int),
		.fifo_cnt (fifo_cnt)
    );

    if (OUTPUT_REG) begin
        always_ff @(posedge clk) begin
            if (rst) begin
                m_axis_tdata <= {DWIDTH{1'b0}};
                m_axis_tkeep <= {DWIDTH/8{1'b0}};
                m_axis_tlast <= 1'b0;
                m_axis_tvalid <= 1'b0;
            end
            else if (rd_en_int) begin
                m_axis_tdata <= rd_data_int[DWIDTH-1:0];
                m_axis_tkeep <= rd_data_int[DWIDTH*9/8-1-:DWIDTH/8];
                m_axis_tlast <= rd_data_int[DWIDTH*9/8];
                m_axis_tvalid <= ~rd_empty_int;            
            end
        end
        assign rd_en_int = m_axis_tready | ~m_axis_tvalid;
    end
    else begin
        assign m_axis_tdata = rd_data_int[DWIDTH-1:0];
        assign m_axis_tkeep = rd_data_int[DWIDTH*9/8-1-:DWIDTH/8];
        assign m_axis_tlast = rd_data_int[DWIDTH*9/8];
        assign m_axis_tvalid = ~rd_empty_int;
        assign rd_en_int = m_axis_tready;        
    end

    assign wr_data_int = {s_axis_tlast,s_axis_tkeep,s_axis_tdata};
    assign wr_en_int = s_axis_tvalid;
    assign s_axis_tready = ~wr_full_int;
endmodule