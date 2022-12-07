`include "opcodes.v"

module alu_control_unit(clk, funccode, opcode, alu_op, alu_funccode, branch_type);
    input clk;
    input [5:0] funccode;
    input [3:0] opcode;
    input [2:0] alu_op;
    output reg [2:0] alu_funccode;
    output reg [1:0] branch_type;

    always @(*) begin
      case(opcode)
        `BNE_OP : branch_type = `BNE;
        `BEQ_OP : branch_type = `BEQ;
        `BGZ_OP : branch_type = `BGZ;
        `BLZ_OP : branch_type = `BLZ;
      endcase
      alu_funccode = alu_op;
    end
  
endmodule