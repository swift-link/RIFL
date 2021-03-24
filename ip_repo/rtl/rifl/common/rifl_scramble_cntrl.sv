module rifl_scramble_cntrl #
(
    parameter int FRAME_WIDTH = 256,
    parameter int DWIDTH = 64,
    parameter int CRC_WIDTH = 12,
    parameter bit DIRECTION = 1'b0,
    parameter int N1 = 13,
    parameter int N2 = 33
)
(
    input logic clk,
    input logic sof,
    input logic [DWIDTH-1:0] data_in,
    output logic sof_out,
    output logic [DWIDTH-1:0] data_out
);
    localparam PIP_CYCLES = FRAME_WIDTH/DWIDTH;
    localparam CNT_WIDTH = PIP_CYCLES > 1 ? $clog2(PIP_CYCLES) : 1;
    logic [N2-1:0] scrambler_in = {N2{1'b0}};
    logic [N2-1:0] scrambler_out_head, scrambler_out_tail, scrambler_out_body;
    logic [DWIDTH-3-CRC_WIDTH:0] data_out_head_narrow;
    logic [DWIDTH-3:0] data_out_head;
    logic [DWIDTH-CRC_WIDTH-1:0] data_out_tail;
    logic [DWIDTH-1:0] data_out_body;
    logic [CNT_WIDTH-1:0] cnt;

/*
    if (N2 > (DWIDTH+2) || (PIP_CYCLES == 1 && N2 > (DWIDTH+2+CRC_WIDTH)))
        $error("RIFL couldn't handle this combination of {CRC,SCRAMBLER,FRAME_WIDTH,BUS_WIDTH}");
*/

    always_ff @(posedge clk) begin
        sof_out <= sof;
    end

    if (PIP_CYCLES != 1) begin
        always_ff @(posedge clk) begin
            if (sof)
                cnt <= 'b1;
            else if (cnt != 'b0)
                cnt <= cnt + 1'b1;
        end
    end
    else
        assign cnt = 1'b0;

    if (PIP_CYCLES == 1) begin
        always_ff @(posedge clk) begin
            scrambler_in <= scrambler_out_head;
        end
        always_ff @(posedge clk) begin
            data_out <= {data_in[DWIDTH-1:DWIDTH-2],data_out_head_narrow,{CRC_WIDTH{1'b0}}};
        end
    end
    else if (PIP_CYCLES == 2) begin
        always_ff @(posedge clk) begin
            if (cnt == 'b0)
                scrambler_in <= scrambler_out_head;
            else
                scrambler_in <= scrambler_out_tail;
        end
        always_ff @(posedge clk) begin
            if (cnt == 'b0)
                data_out <= {data_in[DWIDTH-1:DWIDTH-2],data_out_head};
            else
                data_out <= {data_out_tail,{CRC_WIDTH{1'b0}}};
        end
    end
    else begin
        always_ff @(posedge clk) begin
            if (cnt == 'b0)
                scrambler_in <= scrambler_out_head;
            else if (cnt == PIP_CYCLES-1)
                scrambler_in <= scrambler_out_tail;
            else
                scrambler_in <= scrambler_out_body;
        end
        always_ff @(posedge clk) begin
            if (cnt == 'b0)
                data_out <= {data_in[DWIDTH-1:DWIDTH-2],data_out_head};
            else if (cnt == PIP_CYCLES-1)
                data_out <= {data_out_tail,{CRC_WIDTH{1'b0}}};
            else
                data_out <= data_out_body;
        end
    end

    if (PIP_CYCLES == 1) begin
        scrambler #(
            .DWIDTH(DWIDTH-2-CRC_WIDTH),
            .DIRECTION(DIRECTION),
            .N1(N1),
            .N2(N2)
        ) u_scrambler_head (
            .*,
            .data_in       (data_in[DWIDTH-3-CRC_WIDTH:0]),
            .data_out      (data_out_head_narrow),
            .scrambler_out (scrambler_out_head)
        );
    end
    else begin
        scrambler #(
            .DWIDTH(DWIDTH-2),
            .DIRECTION(DIRECTION),
            .N1(N1),
            .N2(N2)
        ) u_scrambler_head (
            .*,
            .data_in       (data_in[DWIDTH-3:0]),
            .data_out      (data_out_head),
            .scrambler_out (scrambler_out_head)
        );
    end

    if (PIP_CYCLES >= 2) begin
        scrambler #(
            .DWIDTH(DWIDTH-CRC_WIDTH),
            .DIRECTION(DIRECTION),
            .N1(N1),
            .N2(N2)
        ) u_scrambler_tail (
            .*,
            .data_in       (data_in[DWIDTH-1:CRC_WIDTH]),
            .data_out      (data_out_tail),
            .scrambler_out (scrambler_out_tail)
        );
    end
    
    if (PIP_CYCLES > 2) begin
        scrambler #(
            .DWIDTH(DWIDTH),
            .DIRECTION(DIRECTION),
            .N1(N1),
            .N2(N2)
        ) u_scrambler_body (
            .*,
            .data_in       (data_in),
            .data_out      (data_out_body),
            .scrambler_out (scrambler_out_body)
        );
    end

endmodule