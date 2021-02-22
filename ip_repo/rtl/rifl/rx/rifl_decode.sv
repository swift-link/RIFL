`timescale 1ns/1ps
module rifl_decode #(
    parameter int FRAME_WIDTH = 256,
    parameter int PAYLOAD_WIDTH = 240
)
(
    input logic clk,
    input logic rst,
    input logic [PAYLOAD_WIDTH-1:0] int_tdata,
    input logic [PAYLOAD_WIDTH/8-1:0] int_tkeep,
    input logic int_tlast,
    input logic int_tvalid,
    output logic [FRAME_WIDTH+FRAME_WIDTH/8:0] rx_axis_product,
    output logic rx_axis_valid = 1'b0
);
    localparam int DWIDTH_UNIT = FRAME_WIDTH-PAYLOAD_WIDTH;
    localparam int KEEP_UNIT = DWIDTH_UNIT/8;
    localparam bit [$clog2(FRAME_WIDTH/DWIDTH_UNIT):0] N = FRAME_WIDTH/DWIDTH_UNIT;
    localparam bit [$clog2(FRAME_WIDTH/DWIDTH_UNIT):0] M = N - 2;

//axis products
    logic [FRAME_WIDTH-1:0] m_axis_tdata;
    logic [FRAME_WIDTH/8-1:0] m_axis_tkeep;
    logic m_axis_tlast;
    logic m_axis_tvalid;

    logic [PAYLOAD_WIDTH*2-1:0] data_vector;
    logic [PAYLOAD_WIDTH/4-1:0] keep_vector;

    logic [PAYLOAD_WIDTH-1:0] tdata_reg;
    logic [PAYLOAD_WIDTH/8-1:0] tkeep_reg;
    logic tlast_reg;
    logic tvalid_reg;

    logic [$clog2(N)-1:0] cnt;

    always_ff @(posedge clk) begin
        if (rst) begin
            tdata_reg <= {PAYLOAD_WIDTH{1'b0}};
            tkeep_reg <= {PAYLOAD_WIDTH/8{1'b0}};
        end
        else if (int_tvalid) begin
            tdata_reg <= int_tdata;
            tkeep_reg <= int_tkeep;
        end
    end

    always_ff @(posedge clk) begin
        if (rst)
            tvalid_reg <= 1'b0;
        else if ((cnt == M) && ~tlast_reg && int_tvalid)
            tvalid_reg <= 1'b0;
        else if (tlast_reg & tvalid_reg)
            tvalid_reg <= int_tvalid;
        else if (int_tlast & ~int_tkeep[0] & tvalid_reg)
            tvalid_reg <= int_tkeep[PAYLOAD_WIDTH/8-1-(cnt+1)*KEEP_UNIT];
        else if (int_tvalid)
            tvalid_reg <= 1'b1;
    end


    always_ff @(posedge clk) begin
        if (rst)
            tlast_reg <= 1'b0;
        else
            tlast_reg <= int_tlast && 
            (~tvalid_reg ||
                (int_tkeep[PAYLOAD_WIDTH/8-1-(cnt+1)*KEEP_UNIT] && cnt != M) ||
                tlast_reg
            );
    end

    always_ff @(posedge clk) begin
        if (rst)
            cnt <= 'b0;
        else if ((cnt == M) && int_tvalid)
            cnt <= 'b0;
        else if (tvalid_reg && tlast_reg)
            cnt <= 'b0;
        else if (int_tlast && ~int_tkeep[PAYLOAD_WIDTH/8-1-(cnt+1)*KEEP_UNIT])
            cnt <= 'b0;
        else if (int_tvalid & tvalid_reg)
            cnt <= cnt + 1'b1;
    end

    assign data_vector = {tdata_reg,int_tdata};
    assign keep_vector = {tkeep_reg,{(PAYLOAD_WIDTH/8){~tlast_reg}}&int_tkeep};

    always_ff @(posedge clk) begin
        if (rst) begin
            m_axis_tdata <= {FRAME_WIDTH{1'b0}};
            m_axis_tkeep <= {(FRAME_WIDTH/8){1'b0}};
            m_axis_tlast <= 1'b0;
            rx_axis_valid <= 1'b0;
        end
        else begin
            m_axis_tdata <= data_vector[PAYLOAD_WIDTH*2-1-cnt*DWIDTH_UNIT-:FRAME_WIDTH];
            m_axis_tkeep <= keep_vector[PAYLOAD_WIDTH/4-1-cnt*KEEP_UNIT-:FRAME_WIDTH/8];
            m_axis_tlast <= tlast_reg || (int_tlast && (~int_tkeep[PAYLOAD_WIDTH/8-1-(cnt+1)*KEEP_UNIT] || cnt == M));
            rx_axis_valid <= tvalid_reg & (tlast_reg | int_tvalid);
        end
    end
    assign rx_axis_product = {m_axis_tlast,m_axis_tkeep,m_axis_tdata};

endmodule