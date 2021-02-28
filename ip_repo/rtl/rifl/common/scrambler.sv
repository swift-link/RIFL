//out[n]=in[n]^in[n-N1]^in[n-N2]
module scrambler # (
    parameter int DWIDTH = 64,
    parameter int N1 = 13,
    parameter int N2 = 33,
    parameter bit DIRECTION = 1'b0
)
(
    input logic [N2-1:0] scrambler_in,
    input logic [DWIDTH-1:0] data_in,
    output logic [DWIDTH-1:0] data_out,
    output logic [N2-1:0] scrambler_out
);
    logic [DWIDTH+N2-1:0] scrambler_wire;
    logic [DWIDTH-1:0] data_out_wire;

    assign scrambler_out = scrambler_wire[N2-1:0];
    assign data_out = data_in ^ scrambler_wire[DWIDTH-1+N2:N2] ^ scrambler_wire[DWIDTH-1+N1:N1];

    if (DIRECTION == 0)
        assign scrambler_wire = {scrambler_in,data_out};
    else
        assign scrambler_wire = {scrambler_in,data_in};
endmodule