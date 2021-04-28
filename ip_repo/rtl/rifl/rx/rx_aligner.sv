//MIT License
//
//Author: Qianfeng (Clark) Shen;Contact: qianfeng.shen@gmail.com
//
//Copyright (c) 2021 swift-link
//
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
`timescale 1ns / 1ps
module rx_aligner # (
	parameter int DWIDTH = 64,
	parameter int FRAME_WIDTH = 256,
	parameter bit LITTLE_ENDIAN = 1
)
(
    input logic rst,
	input logic clk,
	input logic [DWIDTH-1:0] rxdata_unaligned_in,
	output logic [DWIDTH-1:0] rxdata_aligned_out,
	output logic sof,
	output logic rx_aligned,
	output logic rx_up
);

	localparam N_FRAME_CYCLE = FRAME_WIDTH / DWIDTH;
	localparam N_INPUT1 = 1 << ($clog2(DWIDTH)/2);
	localparam DWIDTH_IN1 = 2*DWIDTH-1; 
	localparam DWIDTH_OUT1 = 2*DWIDTH-N_INPUT1;
	localparam N_INPUT2 = 1 << ($clog2(DWIDTH) - $clog2(DWIDTH)/2);

	logic [DWIDTH-2:0] rxdata_unaligned_reg;
	logic [DWIDTH_IN1-1:0] rxdata_combined;
	logic [DWIDTH_OUT1-1:0] p1_out;
	logic p1_slide;
	logic p2_slide;

	logic [$clog2(N_INPUT1)-1:0] p1_selector;
	logic [$clog2(N_INPUT2)-1:0] p2_selector;

	rx_aligner_mux #(
		.N_INPUT    (N_INPUT1),
		.DWIDTH_IN  (DWIDTH_IN1),
		.DWIDTH_OUT (DWIDTH_OUT1)
	) phase1_selector (
		.rst      (rst),
		.clk      (clk),
		.data_in  (rxdata_combined),
		.slide_in (p1_slide),
		.data_out (p1_out),
		.selector_out (p1_selector)
	);
	rx_aligner_mux #(
		.N_INPUT    (N_INPUT2),
		.DWIDTH_IN  (DWIDTH_OUT1),
		.DWIDTH_OUT (DWIDTH)
	) phase2_selector (
		.rst      (rst),
		.clk      (clk),
		.data_in  (p1_out),
		.slide_in (p2_slide),
		.data_out (rxdata_aligned_out),
		.selector_out (p2_selector)
	);

	rx_align_detector #(
		.N_FRAME_CYCLE (N_FRAME_CYCLE),
		.DWIDTH     (DWIDTH),
		.P1_SEL_WIDTH  ($clog2(N_INPUT1)),
		.P2_SEL_WIDTH  ($clog2(N_INPUT2))
	) rx_align_detector_inst (
		.rst(rst),
		.clk(clk),
		.rxdata_aligned(rxdata_aligned_out),
		.p1_selector(p1_selector),
		.p2_selector(p2_selector),
		.p1_slide(p1_slide),
		.p2_slide(p2_slide),
		.sof(sof),
		.rx_aligned(rx_aligned)
	);
	
	rx_up_detector rx_up_detector_inst (
		.rst        (rst        ),
		.clk        (clk        ),
		.rx_aligned (rx_aligned ),
		.rx_up      (rx_up      )
	);

//construct header search space
	genvar i;
	if (LITTLE_ENDIAN) begin
		always_ff @(posedge clk) begin
			rxdata_unaligned_reg <= rxdata_unaligned_in[DWIDTH-1:1];
			rxdata_combined <= {rxdata_unaligned_in,rxdata_unaligned_reg};
		end
	end
	else begin
		always_ff @(posedge clk) begin
			rxdata_unaligned_reg <= rxdata_unaligned_in[DWIDTH-2:0];
			rxdata_combined <= {rxdata_unaligned_reg,rxdata_unaligned_in};
		end
	end
	//assign rxdata_combined = {rxdata_unaligned_reg,rxdata_unaligned_in};

endmodule

module rx_aligner_mux #
(
    parameter int N_INPUT = 8,
    parameter int DWIDTH_IN = 127,
    parameter int DWIDTH_OUT= 120
)
(
	input logic rst,
	input logic clk,
	input logic [DWIDTH_IN-1:0] data_in,
	input logic slide_in,
	output logic [DWIDTH_OUT-1:0] data_out,
	output logic [$clog2(N_INPUT)-1:0] selector_out
);
	localparam N_STRIDE = (DWIDTH_IN - DWIDTH_OUT)/(N_INPUT-1);
	logic [$clog2(N_INPUT)-1:0] selector;
	logic [DWIDTH_IN-1:0] data_tmp_w;

	always_ff @(posedge clk) begin
		if (rst)
			selector <= {$clog2(N_INPUT){1'b0}};
		else if (slide_in)
			selector <= selector + 1'b1;
	end

	always_ff @(posedge clk) begin
		data_out <= data_tmp_w[DWIDTH_IN-1:DWIDTH_IN-DWIDTH_OUT];
	end

	assign data_tmp_w = data_in << N_STRIDE*selector;
	assign selector_out = selector;
endmodule

module rx_up_detector (
	input logic rst,
	input logic clk,
	input logic rx_aligned,
	output logic rx_up
);
	logic [20:0] rx_up_counter;

	`ifdef SIM_SPEED_UP
		always_ff @(posedge clk) begin
			if (rst) begin
				rx_up_counter <= 21'd0;
				rx_up <= 1'b0;
			end
			else begin
				rx_up <= rx_up_counter[12];
				if (~rx_aligned) begin
					if (rx_up_counter != 0)
						rx_up_counter <= rx_up_counter - 21'd1;
					else
						rx_up_counter <= 21'd0;
				end
				else if (~rx_up_counter[12])
					rx_up_counter <= rx_up_counter + 21'd1;
			end
		end
	`else
		always_ff @(posedge clk) begin
			if (rst) begin
				rx_up_counter <= 21'd0;
				rx_up <= 1'b0;
			end
			else begin
				rx_up <= rx_up_counter[20];
				if (~rx_aligned) begin
					if (rx_up_counter != 0)
						rx_up_counter <= rx_up_counter - 21'd1;
				end
				else if (~rx_up_counter[20])
					rx_up_counter <= rx_up_counter + 21'd1;
			end
		end
	`endif
endmodule

module rx_align_detector #
(
	parameter int N_FRAME_CYCLE = 1,
	parameter int DWIDTH = 64,
	parameter int P1_SEL_WIDTH = 1,
	parameter int P2_SEL_WIDTH = 1
)
(
	input logic rst,
	input logic clk,
	input logic [DWIDTH-1:0] rxdata_aligned,
	input logic [P1_SEL_WIDTH-1:0] p1_selector,
	input logic [P2_SEL_WIDTH-1:0] p2_selector,
	output logic p1_slide,
	output logic p2_slide,
	output logic sof,
	output logic rx_aligned
);
	localparam WIDTH_ALIGN_CHECK = $clog2(N_FRAME_CYCLE) == 0 ? 1 : $clog2(N_FRAME_CYCLE);
	logic [4:0] slide_cnt;
	logic [1:0] header_invalid_cnt;
	logic [4:0] header_valid_cnt;
	logic p1_slide_int;
	logic cycle_slide;
	logic [WIDTH_ALIGN_CHECK-1:0] do_align_check_cnt;
	logic do_align_check;
	logic [1:0] pause_align_check_cnt;

	//the muxes have 2 cycle latency, pause align check for 2 cycle after every slide
	always_ff @(posedge clk) begin
		if (rst)
			pause_align_check_cnt <= 2'b0;
		else if (p1_slide_int)
			pause_align_check_cnt <= 2'd2;
		else if (|pause_align_check_cnt)
			pause_align_check_cnt <= pause_align_check_cnt - 1'b1;
	end
	//if frame width == bus width, then should do align check every cycle, otherwise only do it for the header cycle
	if (N_FRAME_CYCLE > 1) begin
		always_ff @(posedge clk) begin
			if (rst)
				do_align_check_cnt <= {WIDTH_ALIGN_CHECK{1'b0}};
			else if (~cycle_slide) begin
				do_align_check_cnt <= do_align_check_cnt + 1'b1;
			end
		end
		assign do_align_check = (do_align_check_cnt == {WIDTH_ALIGN_CHECK{1'b0}} && ~|pause_align_check_cnt) ? 1'b1 : 1'b0;
	end
	else begin
		assign do_align_check_cnt = {WIDTH_ALIGN_CHECK{1'b0}};
		assign do_align_check = ~|pause_align_check_cnt;
	end

	always_ff @(posedge clk) begin
		if (rst) begin
			slide_cnt <= 5'b0;
			header_invalid_cnt <= 2'b0;
			header_valid_cnt <= 5'b0;
			p1_slide_int <= 1'b0;
			rx_aligned <= 1'b0;
		end
		else if(do_align_check) begin
			if (slide_cnt[4]) begin
				slide_cnt <= 5'b0;
			end
			else begin
				slide_cnt <= slide_cnt + 1'b1;
			end
			if (slide_cnt[4] | header_invalid_cnt[1]) begin
				header_invalid_cnt <= 2'd0;
				header_valid_cnt <= 5'd0;
			end
			else if (rxdata_aligned[DWIDTH-1] ^ rxdata_aligned[DWIDTH-2]) begin
				header_valid_cnt <= header_valid_cnt + 1'b1;
			end
			else begin
				header_invalid_cnt <= header_invalid_cnt + 1'b1;
			end
			p1_slide_int <= header_invalid_cnt[1];
			if (header_invalid_cnt[1])
				rx_aligned <= 1'b0;
			else if (header_valid_cnt[4])
				rx_aligned <= 1'b1;
		end
		else begin
			p1_slide_int <= 1'b0;
		end
	end
	assign p1_slide = p1_slide_int;
	assign p2_slide = p1_slide_int && p1_selector == {P1_SEL_WIDTH{1'b0}};
	assign sof = do_align_check_cnt == {WIDTH_ALIGN_CHECK{1'b0}} ? 1'b1 : 1'b0;
	if (N_FRAME_CYCLE > 1)
		assign cycle_slide = p1_slide_int && p1_selector == {P1_SEL_WIDTH{1'b0}} && p2_selector == {P2_SEL_WIDTH{1'b0}};
	else
		assign cycle_slide = 1'b0;
endmodule