`timescale 1ns/1ps
module clock_counter #
(
    parameter int RATIO = 4
)
(
    input logic clk_slow,
    input logic clk_fast,
    output logic [$clog2(RATIO)-1:0] cnt = {$clog2(RATIO){1'b0}}
);
    logic slow_flag = 1'b0;
    logic fast_flag[RATIO-1:0];
    always_ff @(posedge clk_slow) begin
        slow_flag <= ~slow_flag;
    end
    always_ff @(posedge clk_fast) begin
        fast_flag[0] <= slow_flag;
        for (int i = 0; i < RATIO-1; i++)
            fast_flag[i+1] <= fast_flag[i];
    end
    always_ff @(posedge clk_fast) begin
        if (fast_flag[RATIO-1]^fast_flag[RATIO-2])
            cnt <= 'b0;
        else
            cnt <= cnt + 'b1;
    end
endmodule