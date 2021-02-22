/*
    Meta Code       Valid Frame     EOP     ABV
    00                  NO          NO      NO
    01                  YES         NO      YES
    10                  YES         YES     NO
    11                  YES         YES     YES
    meta[0]=ABV
    meta[1]=EOP
*/
`timescale 1ns/1ps
module rifl_encode #(
    parameter int FRAME_WIDTH = 256,
    parameter int PAYLOAD_WIDTH = 240
)
(
    input logic clk,
    input logic rst,
    input logic [FRAME_WIDTH-1:0] s_axis_tdata,
    input logic [FRAME_WIDTH/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [PAYLOAD_WIDTH+1:0] rifl_tx_payload,
    input logic rifl_tx_ready
);
    localparam int DWIDTH_UNIT = FRAME_WIDTH-PAYLOAD_WIDTH;
    localparam int KEEP_UNIT = DWIDTH_UNIT/8;
    localparam bit [$clog2(FRAME_WIDTH/DWIDTH_UNIT):0] N = FRAME_WIDTH/DWIDTH_UNIT;
    localparam bit [$clog2(FRAME_WIDTH/DWIDTH_UNIT):0] M = N - 1;

    logic [PAYLOAD_WIDTH*2-1:0] data_vector;
    logic [PAYLOAD_WIDTH/4-1:0] keep_vector;
    logic [PAYLOAD_WIDTH-1:0] int_tdata;
    logic [PAYLOAD_WIDTH/8-1:0] int_tkeep;
    logic int_tlast;
    logic int_tvalid;

    logic [$clog2(N)-1:0] cnt;
    logic [PAYLOAD_WIDTH-1:0] data_tail_reg;
    logic [PAYLOAD_WIDTH/8-1:0] keep_tail_reg;

    logic tail_eop;
    logic core_pause;

    logic [1:0] rifl_tx_meta;

/*
    Pause the input when
    1. Output is not ready
    2. The last cycle of a full FSM cycle 
    3. Packet ends in tails
*/
    assign s_axis_tready = rifl_tx_ready & ~core_pause;  
    always_ff @(posedge clk) begin
        if (rst)
            core_pause <= 1'b0;
        else if (rifl_tx_ready) begin
            if (core_pause)
                core_pause <= 1'b0;
            else if (s_axis_tvalid && s_axis_tkeep[KEEP_UNIT*(cnt+1)-1] && (s_axis_tlast || (cnt+1'b1) == M[$clog2(N)-1:0]))
                core_pause <= 1'b1;
        end
    end
//end of pause logic

/*
    The counter indicates the FSM stage
    1. when there is a pause, it means either
            a full payload is collected or
            packets ends in tails
       either cases, set cnt to 0 cuz next cycle we'd pick up the data from the MSB
    2. otherwise, if we see eop in the body, set cnt to 0 as well (for the same reason)
    3. any other cases when the input is valid, add 1 to cnt 
*/
    always_ff @(posedge clk) begin
        if (rst)
            cnt <= {$clog2(N){1'b0}};
        else if (rifl_tx_ready) begin
            if (core_pause)
                cnt <= {$clog2(N){1'b0}};
            else if (s_axis_tvalid && s_axis_tlast && ~s_axis_tkeep[KEEP_UNIT*(cnt+1)-1])
                cnt <= {$clog2(N){1'b0}};
            else if (s_axis_tvalid)
                cnt <= cnt + 1'b1;
        end
    end
//end of counter logic

/*
    set tail_eop when tail_eop is 0 and tail contains EOP
    unset tail_eop for other cases
*/
    always_ff @(posedge clk) begin
        if (rst)
            tail_eop <= 1'b0;
        else if (rifl_tx_ready) begin
            tail_eop <= ~tail_eop & s_axis_tvalid & s_axis_tlast & s_axis_tkeep[KEEP_UNIT*(cnt+1)-1] & ~core_pause;
        end
    end
//end EOP logic 

    //store the tail bytes
    always_ff @(posedge clk) begin
        if (rst) begin
            data_tail_reg <= {PAYLOAD_WIDTH{1'b0}};
            keep_tail_reg <= {PAYLOAD_WIDTH/8{1'b0}};
        end
        else if (rifl_tx_ready && s_axis_tvalid) begin
            data_tail_reg <= s_axis_tdata[PAYLOAD_WIDTH-1:0];
            keep_tail_reg <= s_axis_tkeep[PAYLOAD_WIDTH/8-1:0];
        end
    end

    //compose the narrower AXIS interface
    assign data_vector = {data_tail_reg,s_axis_tdata[FRAME_WIDTH-1:DWIDTH_UNIT]};
    assign keep_vector = {keep_tail_reg,({PAYLOAD_WIDTH/8{~tail_eop}}&s_axis_tkeep[FRAME_WIDTH/8-1:KEEP_UNIT])};
    always_comb begin
        int_tdata = data_vector[PAYLOAD_WIDTH-1+DWIDTH_UNIT*cnt-:PAYLOAD_WIDTH];
        int_tkeep = keep_vector[PAYLOAD_WIDTH/8-1+KEEP_UNIT*cnt-:PAYLOAD_WIDTH/8];
        int_tlast = tail_eop || (s_axis_tlast && ~s_axis_tkeep[KEEP_UNIT*(cnt+1)-1]);
        int_tvalid = s_axis_tvalid | core_pause;
    end

    function [7:0] BYTE_CNT_SUM;
        input [PAYLOAD_WIDTH/8-1:0] tkeep;
        BYTE_CNT_SUM = 8'b0;
        for (int i = 0; i < PAYLOAD_WIDTH/8; i++)
            BYTE_CNT_SUM = BYTE_CNT_SUM + tkeep[i];
    endfunction
    assign rifl_tx_meta[0] = int_tkeep[0] & int_tvalid;
    assign rifl_tx_meta[1] = int_tlast & int_tvalid;

    assign rifl_tx_payload = rifl_tx_meta[0] ? {rifl_tx_meta,int_tdata} : {rifl_tx_meta,int_tdata[PAYLOAD_WIDTH-1:8],BYTE_CNT_SUM(int_tkeep)};
endmodule