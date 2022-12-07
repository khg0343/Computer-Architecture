`include "vending_machine_def.v"

module check_time_and_coin(i_input_coin, i_trigger_return, clk, reset_n, current_total, coin_value, o_output_item, o_return_coin, wait_time);
	input clk;
	input reset_n;

	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] o_output_item;

	input i_trigger_return;
	input [31:0] coin_value [`kNumCoins-1:0];
	input [`kTotalBits-1:0] current_total;

	output reg [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;

	integer i;

	// initiate values
	initial begin
		// TODO: initiate values
		o_return_coin = `kNumCoins'b000;
		wait_time = 0;
	end

	always @(*) begin
		// TODO: o_return_coin
		o_return_coin = `kNumCoins'b000;
		if (i_trigger_return || (wait_time > `kWaitTime)) begin
			if (current_total >= coin_value[2]) 	 o_return_coin[2] = 1'b1;
			else if (current_total >= coin_value[1]) o_return_coin[1] = 1'b1;
			else 									 o_return_coin[0] = 1'b1;
		end
	end

	always @(posedge clk) begin
		if (reset_n) begin
			if (i_input_coin || o_output_item) wait_time <= 0;
			else 							   wait_time <= wait_time + 1;
		end
	end
endmodule 