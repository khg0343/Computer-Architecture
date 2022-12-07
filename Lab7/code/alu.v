`include "opcodes.v"
module alu (alu_input1, alu_input2, alu_op, alu_result, overflow_flag);

	input [`WORD_SIZE-1:0] alu_input1;
	input [`WORD_SIZE-1:0] alu_input2;
	input [2:0] alu_op;

	output reg [`WORD_SIZE-1:0] alu_result;
	output reg overflow_flag; 

	always @(*) begin
		case(alu_op)
			`FUNC_ADD : alu_result = alu_input1 + alu_input2;
			`FUNC_SUB : alu_result = alu_input1 - alu_input2;
			`FUNC_AND : alu_result = alu_input1 & alu_input2;
			`FUNC_ORR : alu_result = alu_input1 | alu_input2;
			`FUNC_NOT : alu_result = ~ alu_input1;
			`FUNC_TCP : alu_result = ~ alu_input1 + 1;
			`FUNC_SHL : alu_result = alu_input1 << 1;
			`FUNC_SHR : alu_result = alu_input1 >>> 1;
		endcase
	end
endmodule