`timescale 1ns/1ps
`define GET_STATE_sub1(val) (val+64'h9e3779b97f4a7c15)
`define GET_STATE_sub2(val) ((`GET_STATE_sub1(val) ^ (`GET_STATE_sub1(val) >> 30)) * 64'hbf58476d1ce4e5b9)
`define GET_STATE_sub3(val) ((`GET_STATE_sub2(val) ^ (`GET_STATE_sub2(val) >> 27)) * 64'h94d049bb133111eb)
`define GET_STATE(val) (`GET_STATE_sub3(val) ^ (`GET_STATE_sub3(val) >> 31))
`define A 64'd19911102
`define B 64'h9e3779b97f4a7c15

module tdata_gen #(
    parameter int DWIDTH = 64,
    parameter bit [63:0] SEED = 64'd1
)
(
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [DWIDTH-1:0] tdata,
    output logic vld = 1'b0
);
    localparam int N_rand64 = (DWIDTH-1)/64+1;
    logic [63:0] rand64[N_rand64-1:0];

    genvar i;
    for (i = 0; i < N_rand64; i++) begin   
        axis_gen_xoshiro128ss #(
            .S0 (`GET_STATE(SEED+(`A+`B*(i*2)))),
            .S1 (`GET_STATE(SEED+(`A+`B*(i*2))))
        ) u_xoshiro128ss(
    	    .clk    (clk),
            .enable (enable),
            .rand64 (rand64[i])
        );
    end
    always_ff @(posedge clk) begin
        if (rst)
            vld <= 1'b0;
        else if (enable)
            vld <= 1'b1;
    end
    for (i = 0; i < N_rand64-1; i++) begin
        assign tdata[(i+1)*64-1-:64] = rand64[i];
    end
    assign tdata[DWIDTH-1:64*(N_rand64-1)] = rand64[N_rand64-1][DWIDTH-1-64*(N_rand64-1):0];
endmodule
