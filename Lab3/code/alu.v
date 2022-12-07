`include "opcodes.v"

`define	NumBits	16

//TODO: func_code input size
module alu (alu_input_1, alu_input_2, alu_op, alu_output);
	input signed [`NumBits-1:0] alu_input_1;
	input signed [`NumBits-1:0] alu_input_2;
	input [3:0] alu_op;

	output reg signed [`NumBits-1:0] alu_output;

	always @(*) begin
		case(alu_op)
			`FUNC_ADD : alu_output = alu_input_1 + alu_input_2;
			`FUNC_SUB : alu_output = alu_input_1 - alu_input_2;
			`FUNC_AND : alu_output = alu_input_1 & alu_input_2;
			`FUNC_ORR : alu_output = alu_input_1 | alu_input_2;					    
			`FUNC_NOT : alu_output = ~ alu_input_1;
			`FUNC_TCP : alu_output = ~ alu_input_1 + 1;
			`FUNC_SHL : alu_output = alu_input_1 << 1;
			`FUNC_SHR : alu_output = alu_input_1 >>> 1;
			`FUNC_ZRO : alu_output = 0;
			`FUNC_ID1 : alu_output = alu_input_1;
			`FUNC_ID2 : alu_output = alu_input_2;
		endcase
	end
endmodule