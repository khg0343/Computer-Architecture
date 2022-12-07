`include "opcodes.v" 

module control_unit (opcode, funccode, clk, reset_n, bcond, alu_op, alu_src_A, alu_src_B, mem_read, mem_write, mem_to_reg, reg_dst, reg_write, pc_src, hlt, wwd, branch_type, branch, jp);

	input [3:0] opcode;
	input [5:0] funccode;
	input clk;
	input reset_n;
    input bcond;

    output reg [2:0] alu_op;
    output reg alu_src_A;
    output reg [1:0] alu_src_B;
    output reg mem_read, mem_write, mem_to_reg;
    output reg [1:0] reg_dst;
    output reg reg_write;
    output reg [1:0] pc_src;
    output reg hlt, wwd;
    output reg [1:0] branch_type;
    output reg branch;
    output reg jp;

    initial begin
        alu_op = 0;
        alu_src_A = 0;
        alu_src_B = 0;
        mem_read = 0;
        mem_write = 0;
        reg_dst = 0;
        reg_write = 0;
        hlt = 0;
        wwd = 0;
        branch_type = `BRANCH_NOT;
        branch = 0;
        jp = 0;
        pc_src = `PC_DEF;
    end

	always @(*) begin
        case (opcode)
            `ADI_OP : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_IMM; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_dst = `RegDst_RT; reg_write = 1; pc_src = `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 0; end
            `ORI_OP : begin alu_op = `FUNC_ORR; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_IMM; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_dst = `RegDst_RT; reg_write = 1; pc_src = `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 0; end
            `LHI_OP : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_0; alu_src_B = `ALUSrcB_IMM; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_dst = `RegDst_RT; reg_write = 1; pc_src = `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 0; end

            `LWD_OP : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_IMM; mem_read = 1; mem_write = 0; mem_to_reg = 1; reg_dst = `RegDst_RT; reg_write = 1; pc_src = `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 0; end
            `SWD_OP : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_IMM; mem_read = 0; mem_write = 1; mem_to_reg = 0; reg_dst = `RegDst_RT; reg_write = 0; pc_src = `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 0; end

            `BNE_OP : begin alu_op = `FUNC_SUB; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_B; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_write = 0; pc_src = (bcond) ? `PC_IMM : `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_NE; branch = 1; jp = 0; end
            `BEQ_OP : begin alu_op = `FUNC_SUB; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_B; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_write = 0; pc_src = (bcond) ? `PC_IMM : `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_EQ; branch = 1; jp = 0; end
            `BGZ_OP : begin alu_op = `FUNC_SUB; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_0; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_write = 0; pc_src = (bcond) ? `PC_IMM : `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_GZ; branch = 1; jp = 0; end
            `BLZ_OP : begin alu_op = `FUNC_SUB; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_0; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_write = 0; pc_src = (bcond) ? `PC_IMM : `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_LZ; branch = 1; jp = 0; end

            `JMP_OP : begin 																	 mem_read = 0; mem_write = 0; mem_to_reg = 0; 					   reg_write = 0; pc_src = `PC_TAR; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 1; end
            `JAL_OP : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_0; alu_src_B = `ALUSrcB_PC; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_dst = `RegDst_2; reg_write = 1; pc_src = `PC_TAR; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 1; end

            `ALU_OP : begin
                case (funccode)
                    `INST_FUNC_JPR : begin 	    																mem_read = 0; mem_write = 0; mem_to_reg = 0;				 	  reg_write = 0; pc_src = `PC_REG; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 1; end
                    `INST_FUNC_JRL : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_0; alu_src_B = `ALUSrcB_PC; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_dst = `RegDst_2; reg_write = 1; pc_src = `PC_REG; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 1; end
                    `INST_FUNC_WWD : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_0;  mem_read = 0; mem_write = 0; mem_to_reg = 0;                      reg_write = 0; pc_src = `PC_DEF; hlt = 0; wwd = 1; branch_type = `BRANCH_NOT; branch = 0; jp = 0; end
                    `INST_FUNC_HLT : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_B;  mem_read = 0; mem_write = 0; mem_to_reg = 0;                      reg_write = 0; pc_src = `PC_DEF; hlt = 1; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 0; end

                    default        : begin alu_op = funccode[2:0]; alu_src_A = `ALUSrcA_A; alu_src_B = `ALUSrcB_B; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_dst = `RegDst_RD; reg_write = 1; pc_src = `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; jp = 0; end
                endcase
            end
            default : begin alu_op = `FUNC_ADD; alu_src_A = `ALUSrcA_0; alu_src_B = `ALUSrcB_0; mem_read = 0; mem_write = 0; mem_to_reg = 0; reg_dst = 0; reg_write = 0; pc_src = `PC_DEF; hlt = 0; wwd = 0; branch_type = `BRANCH_NOT; branch = 0; jp = 0; end
        endcase
    end

endmodule
