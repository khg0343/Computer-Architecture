`include "opcodes.v"

module imm_gen(instr, immediate);
	input [`WORD_SIZE-1:0] instr;
	output reg signed [`WORD_SIZE-1:0] immediate;

	wire [3:0] opcode;
	assign opcode = instr[15:12];

	always @(*) begin
		case (opcode)
			`ORI_OP: immediate = { 8'b0, instr[7:0] };
			`LHI_OP: immediate = instr[7:0] << 8;
			`BNE_OP, `BEQ_OP, `BGZ_OP, `BLZ_OP: immediate = { {8{instr[7]}}, instr[7:0] } + 1;
			default: immediate = { {8{instr[7]}}, instr[7:0] };
		endcase	
	end
endmodule
