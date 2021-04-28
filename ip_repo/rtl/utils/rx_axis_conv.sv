//MIT License
//
//Author: Qianfeng (Clark) Shen
//Copyright (c) 2021 swift-link
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
`timescale 1ns/1ps
module rx_axis_conv #(
    parameter int DWIDTH_IN = 240,
    parameter int DWIDTH_OUT = 256
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
    localparam int DWIDTH_UNIT = DWIDTH_OUT-DWIDTH_IN;
    localparam int KEEP_UNIT = DWIDTH_UNIT/8;
    localparam bit [$clog2(DWIDTH_OUT/DWIDTH_UNIT):0] N = DWIDTH_OUT/DWIDTH_UNIT;
    localparam bit [$clog2(DWIDTH_OUT/DWIDTH_UNIT):0] M = N - 1;

    logic [DWIDTH_IN*2-1:0] data_vector;
    logic [DWIDTH_IN/4-1:0] keep_vector;

    logic [DWIDTH_IN-1:0] tdata_reg;
    logic [DWIDTH_IN/8-1:0] tkeep_reg;
    logic tlast_reg;
    logic tvalid_reg;

    logic [$clog2(N)-1:0] cnt = {$clog2(N){1'b0}};
    logic buffer_loaded = 1'b0;
    logic pass_through;
    logic buffer_store, buffer_consume;

    always_ff @(posedge clk) begin
        if (rst) begin
            tdata_reg <= {DWIDTH_IN{1'b0}};
            tkeep_reg <= {DWIDTH_IN/8{1'b0}};
            tlast_reg <= 1'b0;
            tvalid_reg <= 1'b0;
        end
        else if (s_axis_tready) begin
            if (buffer_store) begin
                tdata_reg <= s_axis_tdata;
                tkeep_reg <= s_axis_tkeep;
                tlast_reg <= s_axis_tlast && (cnt == M || tlast_reg || s_axis_tkeep[DWIDTH_IN/8-1-cnt*KEEP_UNIT]);
                tvalid_reg <= 1'b1;
            end
            else if (buffer_consume) begin
                tdata_reg <= {DWIDTH_IN{1'b0}};
                tkeep_reg <= {DWIDTH_IN/8{1'b0}};
                tlast_reg <= 1'b0;
                tvalid_reg <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst)
            cnt <= 'b0;
        else if (s_axis_tready) begin
            if (buffer_store) begin
                if (buffer_loaded & tlast_reg)
                    cnt <= 'b1;
                else
                    cnt <= cnt + 1'b1;
            end
            else if (buffer_consume)
                cnt <= 'b0;
        end
    end
    always_ff @(posedge clk) begin
        if (rst)
            buffer_loaded <= 1'b0;
        else if (s_axis_tready) begin
            if (buffer_store)
                buffer_loaded <= 1'b1;
            else if (buffer_consume)
                buffer_loaded <= 1'b0;
        end
    end

    assign data_vector = {tdata_reg,s_axis_tdata};
    assign keep_vector = {tkeep_reg,{(DWIDTH_IN/8){~tlast_reg}}&s_axis_tkeep};

    always_ff @(posedge clk) begin
        if (rst) begin
            m_axis_tdata <= {DWIDTH_OUT{1'b0}};
            m_axis_tkeep <= {(DWIDTH_OUT/8){1'b0}};
            m_axis_tlast <= 1'b0;
            m_axis_tvalid <= 1'b0;
        end
        else if (m_axis_tready | ~m_axis_tvalid) begin
            if (pass_through) begin
                m_axis_tdata <= {s_axis_tdata,{DWIDTH_UNIT{1'b0}}};
                m_axis_tkeep <= {s_axis_tkeep,{KEEP_UNIT{1'b0}}};
                m_axis_tlast <= 1'b1;
                m_axis_tvalid <= 1'b1;
            end
            else if (~buffer_loaded) begin
                m_axis_tdata <= {DWIDTH_OUT{1'b0}};
                m_axis_tkeep <= {(DWIDTH_OUT/8){1'b0}};
                m_axis_tlast <= 1'b0;
                m_axis_tvalid <= 1'b0;
            end
            else begin
                m_axis_tdata <= data_vector[DWIDTH_IN*2-1-(cnt-1'b1)*DWIDTH_UNIT-:DWIDTH_OUT];
                m_axis_tkeep <= keep_vector[DWIDTH_IN/4-1-(cnt-1'b1)*KEEP_UNIT-:DWIDTH_OUT/8];
                m_axis_tlast <= tlast_reg | (s_axis_tlast&~buffer_store);
                m_axis_tvalid <= tlast_reg | s_axis_tvalid;
            end
        end
    end

    assign pass_through = ~buffer_loaded && s_axis_tvalid && s_axis_tlast;
    assign buffer_store = s_axis_tvalid && (tlast_reg || (cnt != M &&
                        (cnt == 'b0 ? ~pass_through : s_axis_tkeep[DWIDTH_IN/8-1-cnt*KEEP_UNIT])));
    assign buffer_consume = buffer_loaded & (tlast_reg | s_axis_tvalid);

    assign s_axis_tready = m_axis_tready | (~buffer_loaded & ~pass_through) | ~m_axis_tvalid;
endmodule