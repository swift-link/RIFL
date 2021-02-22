`timescale 1ns/1ps
module datapath_reset #
(
    parameter int COUNTER_WIDTH = 16
)
(
    input logic clk,
    input logic rst,
    input logic channel_good,
    output logic rst_out
);
    logic [COUNTER_WIDTH-1:0] reset_counter = {COUNTER_WIDTH{1'b0}};

    always_ff @(posedge clk) begin
        if (rst) begin
            rst_out <= 1'b0;
            reset_counter <= {COUNTER_WIDTH{1'b0}};
        end
        else if (channel_good) begin
            rst_out <= 1'b0;
            reset_counter <= {COUNTER_WIDTH{1'b0}};
        end
        else begin
            rst_out <= reset_counter[COUNTER_WIDTH-1];
            if (reset_counter[COUNTER_WIDTH-1])
                reset_counter <= {COUNTER_WIDTH{1'b0}};
            else
                reset_counter <= reset_counter + 1'd1;
        end
    end
endmodule
