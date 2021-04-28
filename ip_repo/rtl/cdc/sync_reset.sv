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
`timescale 1ns/1ps
module sync_reset # (
	parameter int N_STAGE = 4
)(
	input logic clk,
	input logic rst_in,
	output logic rst_out
);
	(* ASYNC_REG = "TRUE" *) logic rst_meta[N_STAGE-1:0];

	always_ff @(posedge clk, posedge rst_in) begin
		if (rst_in) begin
			for (int i = 0; i < N_STAGE; i++) begin
				rst_meta[i] <= 1'b1;
			end
		end
		else begin
			rst_meta[0] <= 1'b0;
			for (int i = 1; i < N_STAGE; i++) begin
				rst_meta[i] <= rst_meta[i-1];
			end
		end
	end

	assign rst_out = rst_meta[N_STAGE-1];
endmodule
