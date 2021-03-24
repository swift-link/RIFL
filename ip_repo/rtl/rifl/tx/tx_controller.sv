`timescale 1ns/1ps
module tx_controller # (
    parameter int FRAME_WIDTH = 256,
    parameter int PAYLOAD_WIDTH = 240,
    parameter int FRAME_ID_WIDTH = 8
)
(
    input logic clk,
    input logic rst,
    input logic rx_up,
    input logic rx_error,
    input logic pause_req,
    input logic retrans_req,
    input logic compensate,
    input logic [PAYLOAD_WIDTH+1:0] rifl_tx_payload,
    output logic rifl_tx_ready,
    output logic [FRAME_WIDTH-1:0] rifl_tx_data,
    output logic [2:0] state
);
//control codes
    localparam bit [15:0] IDLE_KEY = 16'h0001;
    localparam bit [15:0] PAUSE_KEY = 16'h0010;
    localparam bit [15:0] RETRANS_KEY = 16'h1000;
    localparam bit [PAYLOAD_WIDTH+3:0] IDLE_CODE = {2'b10,IDLE_KEY,{(PAYLOAD_WIDTH-14){1'b0}}};
    localparam bit [PAYLOAD_WIDTH+3:0] PAUSE_CODE = {2'b10,PAUSE_KEY,{(PAYLOAD_WIDTH-14){1'b0}}};
    localparam bit [PAYLOAD_WIDTH+3:0] RETRANS_CODE = {2'b10,RETRANS_KEY,{(PAYLOAD_WIDTH-14){1'b0}}};
//states
    localparam bit [2:0] INIT = 3'd0;
    localparam bit [2:0] SEND_PAUSE = 3'd1;
    localparam bit [2:0] PAUSE = 3'd2;
    localparam bit [2:0] RETRANS = 3'd3;
    localparam bit [2:0] SEND_RESTRANS = 3'd4;
    localparam bit [2:0] NORMAL = 3'd5;

    logic shiftreg_ready;

    logic retrans_data_in_vld;
    logic [PAYLOAD_WIDTH+1:0] retrans_data_in;
    logic [PAYLOAD_WIDTH+1:0] retrans_data_out;

    logic [FRAME_ID_WIDTH+1:0] retrans_counter;
    logic [FRAME_ID_WIDTH:0] rollback_counter;

    logic [PAYLOAD_WIDTH+3:0] rifl_tx_data_reg = PAUSE_CODE;

    rifl_shiftreg #(
        .PAYLOAD_WIDTH  (PAYLOAD_WIDTH),
        .FRAME_ID_WIDTH (FRAME_ID_WIDTH)
    ) u_rifl_shiftreg(
        .*,
        .enable         (retrans_data_in_vld),
        .data_in        (retrans_data_in),
        .data_out       (retrans_data_out),
        .shiftreg_ready (shiftreg_ready)
    );
    
//state control
    always_comb begin
        if (~shiftreg_ready)
            state = INIT;
        else if (~rx_up)
            state = SEND_PAUSE;
        else if (pause_req)
            state = PAUSE;
        else if (retrans_req | (|retrans_counter))
            state = RETRANS;
        else if (rx_error)
            state = SEND_RESTRANS;
        else
            state = NORMAL;
    end
//allow user input only in normal state and rollback counter is filled
    always_ff @(posedge clk) begin
        if (rst)
            rollback_counter <= {(FRAME_ID_WIDTH+1){1'b0}};
        else if (state == NORMAL && ~rollback_counter[FRAME_ID_WIDTH])
            rollback_counter <= rollback_counter + 1'b1;
    end
//retransmit counter
//0~2^(FRAME_ID_WIDTH+1)-1 : EVEN: data from retrans buffer, ODD: idle or RETRANS depends on rx_error
//2^(FRAME_ID_WIDTH+1)~2^(FRAME_ID_WIDTH+1)+2^FRAME_ID_WIDTH-1 : IDLE, wait for remote_retrans_req to become low
    always @(posedge clk) begin
        if (rst)
            retrans_counter <= {(FRAME_ID_WIDTH+2){1'b0}};
        else if (state == RETRANS) begin
            if (retrans_counter[FRAME_ID_WIDTH+1-:2] != 2'b11)
                retrans_counter <= retrans_counter + 1'd1;
            else
                retrans_counter <= {(FRAME_ID_WIDTH+2){1'b0}};
        end
    end

//control the retrans buffer input
    always_comb begin
        if (state == RETRANS && ~retrans_counter[FRAME_ID_WIDTH+1] && ~retrans_counter[0])
            retrans_data_in = retrans_data_out;
        else if (state == NORMAL && ~compensate)
            retrans_data_in = rifl_tx_payload;
        else
            retrans_data_in = {(PAYLOAD_WIDTH+2){1'b0}};
    end
    assign retrans_data_in_vld = (state == RETRANS && ~retrans_counter[FRAME_ID_WIDTH+1] && ~retrans_counter[0]) || (state == NORMAL && ~compensate);

//output for different situations
    always_ff @(posedge clk) begin
        if (rst)
            rifl_tx_data_reg <= PAUSE_CODE;
        else begin
            if (state == INIT)
                rifl_tx_data_reg <= PAUSE_CODE;
            else if (state == SEND_PAUSE)
                rifl_tx_data_reg <= PAUSE_CODE;
            else if (state == PAUSE)
                rifl_tx_data_reg <= IDLE_CODE;
            else if (state == RETRANS) begin
                if (retrans_counter[FRAME_ID_WIDTH+1])
                    rifl_tx_data_reg <= rx_error ? RETRANS_CODE : IDLE_CODE;
                else if (~retrans_counter[0])
                    rifl_tx_data_reg <= {2'b01,retrans_data_out};
                else
                    rifl_tx_data_reg <= rx_error ? RETRANS_CODE : IDLE_CODE;
            end
            else if (state == SEND_RESTRANS)
                rifl_tx_data_reg <= RETRANS_CODE;
            else if (state == NORMAL) begin
                if (compensate)
                    rifl_tx_data_reg <= IDLE_CODE;
                else if (rifl_tx_payload[PAYLOAD_WIDTH+1-:2] == 2'b00 || ~rollback_counter[FRAME_ID_WIDTH])
                    rifl_tx_data_reg <= {2'b01,{(PAYLOAD_WIDTH+2){1'b0}}};
                else
                    rifl_tx_data_reg <= {2'b01,rifl_tx_payload};
            end
            else
                rifl_tx_data_reg <= IDLE_CODE;
        end
    end
    assign rifl_tx_data = {rifl_tx_data_reg,{(FRAME_WIDTH-PAYLOAD_WIDTH-4){1'b0}}};
    assign rifl_tx_ready = state == NORMAL && rollback_counter[FRAME_ID_WIDTH] && ~compensate;
endmodule

module rifl_shiftreg #(
    parameter int PAYLOAD_WIDTH = 240,
    parameter int FRAME_ID_WIDTH = 8
)
(
    input logic clk,
    input logic rst,
    input logic enable,
    input logic [PAYLOAD_WIDTH+1:0] data_in,
    output logic [PAYLOAD_WIDTH+1:0] data_out,
    output logic shiftreg_ready
);
    localparam int DEPTH = 1 << FRAME_ID_WIDTH;
    logic [FRAME_ID_WIDTH:0] rdy_cnt = {(FRAME_ID_WIDTH+1){1'b0}};
    logic [PAYLOAD_WIDTH+1:0] shiftreg[DEPTH-1:0];

    always_ff @(posedge clk) begin
        if (rst)
            rdy_cnt <= {(FRAME_ID_WIDTH+1){1'b0}};
        else if (~shiftreg_ready)
            rdy_cnt <= rdy_cnt + 1'b1;
    end

    always_ff @(posedge clk) begin
        if (~shiftreg_ready)
            shiftreg[0] <= {2'b01,{(PAYLOAD_WIDTH+2){1'b0}}};
        else if (enable)
            shiftreg[0] <= data_in;
        if (~shiftreg_ready | enable)
            for (int i = 0; i < DEPTH-1; i++)
                shiftreg[i+1] <= shiftreg[i];
    end
    assign data_out = shiftreg[DEPTH-1];
    assign shiftreg_ready = rdy_cnt[FRAME_ID_WIDTH];
endmodule