`include "opcodes.v"

module ExternalDevice(clk, reset_n, dma_offset, interrupt, block);
	input clk;
	input reset_n;
	input [1:0] dma_offset;
	output reg interrupt;
	output reg [`BLOCK_SIZE-1:0] block;
	
	reg [`WORD_SIZE-1:0] num_clk; 				// num_clk to count cycles and trigger interrupt at appropriate cycle
	reg [`WORD_SIZE-1:0] data [0:`WORD_SIZE-1]; // data to transfer

	always @(*) begin
		block = { data[(dma_offset-1)*4+3], data[(dma_offset-1)*4+2], data[(dma_offset-1)*4+1], data[(dma_offset-1)*4] };
	end

	always @(posedge clk) begin
		if(!reset_n) begin
			data[16'd0] <= 16'h0001;
			data[16'd1] <= 16'h0002;
			data[16'd2] <= 16'h0003;
			data[16'd3] <= 16'h0004;
			data[16'd4] <= 16'h0005;
			data[16'd5] <= 16'h0006;
			data[16'd6] <= 16'h0007;
			data[16'd7] <= 16'h0008;
			data[16'd8] <= 16'h0009;
			data[16'd9] <= 16'h000a;
			data[16'd10] <= 16'h000b;
			data[16'd11] <= 16'h000c;
			num_clk <= 0;
		end else begin
			num_clk <= num_clk + 1;
			if (num_clk == 1200) interrupt <= 1;
			else 				 interrupt <= 0;
		end
	end
endmodule
