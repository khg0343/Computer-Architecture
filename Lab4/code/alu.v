`include "opcodes.v"

`define NumBits 16

module alu (alu_input_1, alu_input_2, alu_func_code, branch_type, alu_result, overflow_flag, bcond);
	input [`NumBits-1:0] alu_input_1; //input data A
	input [`NumBits-1:0] alu_input_2; //input data B
	input [2:0] alu_func_code; //function code for the operation
	input [1:0] branch_type; //branch type for bne, beq, bgz, blz

	output reg signed [`NumBits-1:0] alu_result; //output data C
	output reg overflow_flag; 
	output reg bcond; //1 if branch condition met, else 0

	always @(*) begin
		case(alu_func_code)
			`FUNC_ADD : alu_result = alu_input_1 + alu_input_2;
			`FUNC_SUB : begin
				alu_result = alu_input_1 - alu_input_2;
				case (branch_type)
					`BNE : bcond = alu_result != 0 ? 1 : 0;
					`BEQ : bcond = alu_result == 0 ? 1 : 0;
					`BGZ : bcond = alu_result > 0 ? 1 : 0;
					`BLZ : bcond = alu_result < 0 ? 1 : 0;
					default : bcond = 0;
				endcase
			end
			`FUNC_AND : alu_result = alu_input_1 & alu_input_2;
			`FUNC_ORR : alu_result = alu_input_1 | alu_input_2;
			`FUNC_NOT : alu_result = ~ alu_input_1;
			`FUNC_TCP : alu_result = ~ alu_input_1 + 1;
			`FUNC_SHL : alu_result = alu_input_1 << 1;
			`FUNC_SHR : alu_result = alu_input_1 >>> 1;
		endcase
	end
endmodule
