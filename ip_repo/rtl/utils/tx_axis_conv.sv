module tx_axis_conv #(
    parameter int DWIDTH_IN = 256,
    parameter int DWIDTH_OUT = 240
)
(
    input logic clk,
    input logic rst,
    input logic [DWIDTH_IN-1:0] s_axis_tdata,
    input logic [DWIDTH_IN/8-1:0] s_axis_tkeep,
    input logic s_axis_tlast,
    input logic s_axis_tvalid,
    output logic s_axis_tready,
    output logic [DWIDTH_OUT-1:0] m_axis_tdata,
    output logic [DWIDTH_OUT/8-1:0] m_axis_tkeep,
    output logic m_axis_tlast,
    output logic m_axis_tvalid,
    input logic m_axis_tready
);
    localparam int DWIDTH_UNIT = DWIDTH_IN-DWIDTH_OUT;
    localparam int KEEP_UNIT = DWIDTH_UNIT/8;
    localparam bit [$clog2(DWIDTH_IN/DWIDTH_UNIT):0] N = DWIDTH_IN/DWIDTH_UNIT;
    localparam bit [$clog2(DWIDTH_IN/DWIDTH_UNIT):0] M = N - 1;

    logic [DWIDTH_OUT*2-1:0] data_vector;
    logic [DWIDTH_OUT/4-1:0] keep_vector;
    logic [$clog2(N)-1:0] cnt;
    logic [DWIDTH_OUT-1:0] data_tail_reg;
    logic [DWIDTH_OUT/8-1:0] keep_tail_reg;

    logic tail_eop;
    logic core_pause;

/*
    Pause the input when
    1. Output is not ready
    2. The last cycle of a full FSM cycle 
    3. Packet ends in tails
*/
    assign s_axis_tready = m_axis_tready && ~core_pause;  
    always_ff @(posedge clk) begin
        if (rst)
            core_pause <= 1'b0;
        else if (m_axis_tready) begin
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
        else if (m_axis_tready) begin
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
        else if (m_axis_tready) begin
            tail_eop <= ~tail_eop && s_axis_tvalid && s_axis_tlast && s_axis_tkeep[KEEP_UNIT*(cnt+1)-1] && ~core_pause;
        end
    end
//end EOP logic 


    //store the tail bytes
    always_ff @(posedge clk) begin
        if (rst) begin
            data_tail_reg <= {DWIDTH_OUT{1'b0}};
            keep_tail_reg <= {DWIDTH_OUT/8{1'b0}};
        end
        else if (m_axis_tready && s_axis_tvalid) begin
            data_tail_reg <= s_axis_tdata[DWIDTH_OUT-1:0];
            keep_tail_reg <= s_axis_tkeep[DWIDTH_OUT/8-1:0];
        end
    end

    //compose the narrower AXIS interface
    assign data_vector = {data_tail_reg,s_axis_tdata[DWIDTH_IN-1:DWIDTH_UNIT]};
    assign keep_vector = {keep_tail_reg,({DWIDTH_OUT/8{~tail_eop}}&s_axis_tkeep[DWIDTH_IN/8-1:KEEP_UNIT])};

/*
    function [7:0] BYTE_CNT_SUM;
        input [DWIDTH_OUT/8-1:0] tkeep;
        BYTE_CNT_SUM = 8'b0;
        for (int i = 0; i < DWIDTH_OUT/8; i++)
            BYTE_CNT_SUM = BYTE_CNT_SUM + tkeep[i];
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < N_CHANNEL; i++) begin
                tx_axis_tdata[i] <= {DWIDTH_OUT/N_CHANNEL{1'b0}};
                tx_axis_tlast[i] <= 1'b0;
                tx_axis_tvalid[i] <= 1'b0;
                tx_byte_cnt[i] <= 8'b0;
            end
        end
        else if (m_axis_tready) begin
            for (int i = 0; i < N_CHANNEL; i++) begin
                tx_axis_tdata[i] <= m_axis_tdata[(i+1)*DWIDTH_OUT_CHANNEL-1-:DWIDTH_OUT_CHANNEL];
                tx_byte_cnt[i] <= BYTE_CNT_SUM(m_axis_tkeep[(i+1)*DWIDTH_OUT_CHANNEL/8-1-:DWIDTH_OUT_CHANNEL/8]);
                if (i != 0)
                    tx_axis_tlast[i] <= m_axis_tvalid & int_tlast & int_tkeep[(i+1)*DWIDTH_OUT_CHANNEL/8-1] & ~int_tkeep[i*DWIDTH_OUT_CHANNEL/8-1];
                else
                    tx_axis_tlast[i] <= m_axis_tvalid & int_tlast & int_tkeep[DWIDTH_OUT_CHANNEL/8-1];
                tx_axis_tvalid[i] = m_axis_tvalid & int_tkeep[(i+1)*DWIDTH_OUT_CHANNEL/8-1];
            end
        end
    end
*/
    assign m_axis_tdata = data_vector[DWIDTH_OUT-1+DWIDTH_UNIT*cnt-:DWIDTH_OUT];
    assign m_axis_tkeep = keep_vector[DWIDTH_OUT/8-1+KEEP_UNIT*cnt-:DWIDTH_OUT/8];
    assign m_axis_tlast = (tail_eop || (s_axis_tlast && ~s_axis_tkeep[KEEP_UNIT*(cnt+1)-1])) && (s_axis_tvalid | core_pause);
    assign m_axis_tvalid = s_axis_tvalid | core_pause;

endmodule