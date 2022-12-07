`include "opcodes.v" 	   

module control_unit (instr, instrDataFetch, memoryDataFetch, alu_op, alu_src, reg_dst, reg_write, mem_read, mem_to_reg, mem_write, jp, branch, pc_src);
    input [`WORD_SIZE-1:0] instr;
    input instrDataFetch;
    input memoryDataFetch;

    output reg [3:0] alu_op;
    output reg alu_src;
    output reg reg_dst;
    output reg reg_write;
    output reg mem_read;
    output reg mem_to_reg;
    output reg mem_write;
    output reg jp;
    output reg [1:0] branch;
    output reg [1:0] pc_src;

    wire[3:0] opcode;
    wire[5:0] func;
    
    assign opcode = instr[15:12];
    assign func = instr[5:0];

    always @(*) begin
        if (instrDataFetch) begin
            case (opcode)      
                `ADI_OP : begin alu_op = `FUNC_ADD; alu_src = 1; reg_dst = 0; reg_write = 1; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 0; branch = 0; pc_src = `PC_DEF; end
                `ORI_OP : begin alu_op = `FUNC_ORR; alu_src = 1; reg_dst = 0; reg_write = 1; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 0; branch = 0; pc_src = `PC_DEF; end
                `LHI_OP : begin alu_op = `FUNC_ID2; alu_src = 1; reg_dst = 0; reg_write = 1; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 0; branch = 0; pc_src = `PC_DEF; end

                `LWD_OP : begin alu_op = `FUNC_ADD; alu_src = 1; reg_dst = 0; reg_write = 1; mem_read = 1; mem_to_reg = 1; mem_write = 0; jp = 0; branch = 0; pc_src = `PC_DEF; end
                `SWD_OP : begin alu_op = `FUNC_ADD; alu_src = 1; reg_dst = 0; reg_write = 0; mem_read = 0; mem_to_reg = 0; mem_write = 1; jp = 0; branch = 0; pc_src = `PC_DEF; end

                `BNE_OP : begin alu_op = `FUNC_SUB; alu_src = 0; reg_dst = 0; reg_write = 0; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 0; branch = `BRANCH_NE; pc_src = `PC_IMM; end
                `BEQ_OP : begin alu_op = `FUNC_SUB; alu_src = 0; reg_dst = 0; reg_write = 0; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 0; branch = `BRANCH_EQ; pc_src = `PC_IMM; end
                `BGZ_OP : begin alu_op = `FUNC_ID1; alu_src = 0; reg_dst = 0; reg_write = 0; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 0; branch = `BRANCH_GZ; pc_src = `PC_IMM; end
                `BLZ_OP : begin alu_op = `FUNC_ID1; alu_src = 0; reg_dst = 0; reg_write = 0; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 0; branch = `BRANCH_LZ; pc_src = `PC_IMM; end

                `JMP_OP : begin alu_op = `FUNC_ZRO; alu_src = 0; reg_dst = 0; reg_write = 0; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 1; branch = 0; pc_src = `PC_TAR; end
                `JAL_OP : begin alu_op = `FUNC_ID2; alu_src = 0; reg_dst = 1; reg_write = 1; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 1; branch = 0; pc_src = `PC_TAR; end
                `ALU_OP : begin
                    case (func)
                        `INST_FUNC_JPR : begin alu_op = `FUNC_ZRO; alu_src = 0; reg_dst = 0; reg_write = 0; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 1; branch = 0; pc_src = `PC_REG; end
                        `INST_FUNC_JRL : begin alu_op = `FUNC_ID2; alu_src = 0; reg_dst = 1; reg_write = 1; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 1; branch = 0; pc_src = `PC_REG; end
                        
                        default        : begin alu_op = func[3:0]; alu_src = 0; reg_dst = 1; reg_write = 1; mem_read = 0; mem_to_reg = 0; mem_write = 0; jp = 0; branch = 0; pc_src = `PC_DEF; end
                    endcase
                end 
            endcase
        end
        else begin
            mem_read = 1; mem_write = 0;
        end
    end

endmodule