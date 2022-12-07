`include "opcodes.v"

module control_unit(opcode, funccode, bcond, clk, reset_n, is_halted, pc_write_not_cond, pc_write, i_or_d, mem_read, mem_write, mem_to_reg, ir_write, mdr_write, pc_src, alu_op, alu_src_A, alu_src_B, reg_dst, reg_write, A_write, B_write, alu_write);
  input [3:0] opcode;
  input [5:0] funccode;
  input bcond;
  input clk;
  input reset_n;

  output reg is_halted, pc_write_not_cond, pc_write, i_or_d, mem_read, mem_write, ir_write, mdr_write, alu_src_A, reg_write;
  output reg [1:0] alu_src_B, reg_dst, mem_to_reg, pc_src;
  output reg [2:0] alu_op;
  output reg A_write, B_write, alu_write;

  // store current state
  reg [2:0] state, next_state;

  always @(posedge clk) begin
		if (!reset_n) state <= 0;
		else state <= next_state;
	end

  always @(*) begin
    case (state)
      `IF : begin
        if(opcode == `HLT_OP && funccode == `INST_FUNC_HLT) is_halted = 1;
        else                                                is_halted = 0;

        pc_write = 0; pc_write_not_cond = 0;
        ir_write = 1; mdr_write = 0; A_write = 0; B_write = 0; alu_write = 0;
        mem_read = 1; mem_write = 0;
        reg_write = 0;
        i_or_d = 0;

        next_state = `ID;
      end
      `ID : begin
        is_halted = 0;
        pc_write = 0; pc_write_not_cond = 0;
        ir_write = 0; mdr_write = 0; A_write = 1; B_write = 1; alu_write = 0;
        mem_read = 0; mem_write = 0;
        reg_write = 0;
        i_or_d = 0;

        case (opcode)
          `BNE_OP, `BEQ_OP, `BGZ_OP, `BLZ_OP: begin   //ALUOut = PC + Imm + 1
            alu_src_A = `ALUSrcA_PC;
            alu_src_B = `ALUSrcB_IMM;
            alu_op = `FUNC_ADD;
            alu_write = 1;
          end
        endcase

        // set next state
        case (opcode)
          `LHI_OP : next_state = `WB;
          `JMP_OP : next_state = `PCUpdate;  
          `JAL_OP : next_state = `WB;
          `JRL_OP, `JPR_OP, `WWD_OP: begin
            case (funccode)
              `INST_FUNC_JPR : next_state = `PCUpdate;
              `INST_FUNC_JRL : next_state = `WB;
              `INST_FUNC_WWD : next_state = `PCUpdate;
              default : next_state = `EXE;
            endcase
          end
          default : next_state = `EXE;
        endcase
      end

      `EXE : begin
        is_halted = 0;
        pc_write = 0; pc_write_not_cond = 0;
        ir_write = 0; mdr_write = 0; A_write = 0; B_write = 0; alu_write = 0;
        mem_read = 0; mem_write = 0;
        reg_write = 0;
        i_or_d = 0;

        alu_src_A = `ALUSrcA_A;

        case (opcode)
          `BNE_OP, `BEQ_OP, `BGZ_OP, `BLZ_OP: begin
            alu_src_B = (opcode == `BNE_OP || opcode == `BEQ_OP) ? `ALUSrcB_B : `ALUSrcB_0;
            alu_op = `FUNC_SUB;
            alu_write = 0;
          end
          `ALU_OP: begin              //ALUOut = A o B
            alu_src_B = `ALUSrcB_B;
            alu_op = funccode[2:0];
            alu_write = 1;
          end
          default: begin              //ALUOut = A o Imm
            alu_src_B = `ALUSrcB_IMM;
            alu_op = (opcode == `ORI_OP) ? `FUNC_ORR : `FUNC_ADD;
            alu_write = 1;
          end
        endcase

        // set next state
        case (opcode)
          `BNE_OP, `BEQ_OP, `BGZ_OP, `BLZ_OP: next_state = `PCUpdate;
          `LWD_OP, `SWD_OP: next_state = `MEM;
          default: begin
            if(funccode == `INST_FUNC_WWD) next_state = `PCUpdate;
            else next_state = `WB;
          end
        endcase
      end

      `MEM : begin
        is_halted = 0;
        pc_write = 0; pc_write_not_cond = 0;
        ir_write = 0; mdr_write = 0; A_write = 0; B_write = 0; alu_write = 0;
        mem_read = 0; mem_write = 0;
        reg_write = 0;
        i_or_d = 1;

        case (opcode)
          `LWD_OP : begin
            mem_read = 1;
            mdr_write = 1;
          end
          `SWD_OP : begin
            mem_write = 1;
          end
        endcase

        // set next state
        case (opcode)
          `LWD_OP : next_state = `WB;
          `SWD_OP : next_state = `PCUpdate;
        endcase
      end

      `WB : begin
        is_halted = 0;
        pc_write = 0; pc_write_not_cond = 0;
        ir_write = 0; mdr_write = 0; A_write = 0; B_write = 0; alu_write = 0;
        mem_read = 0; mem_write = 0;
        reg_write = 1;
        i_or_d = 0;

        case (opcode)
          `ADI_OP, `ORI_OP: begin reg_dst = `RegDst_RT; mem_to_reg = `MemToReg_ALUOut; end
          `LHI_OP :         begin reg_dst = `RegDst_RT; mem_to_reg = `MemToReg_IMM; end
          `JAL_OP :         begin reg_dst = `RegDst_2;  mem_to_reg = `MemToReg_PC; end
          `LWD_OP :         begin reg_dst = `RegDst_RT; mem_to_reg = `MemToReg_MDR; end
          default: begin
            case(funccode)
              `INST_FUNC_JRL : begin reg_dst = `RegDst_2;  mem_to_reg = `MemToReg_PC; end
              default :        begin reg_dst = `RegDst_RD; mem_to_reg = `MemToReg_ALUOut; end
            endcase
          end
        endcase

        // set next state
        next_state = `PCUpdate;
      end

      `PCUpdate: begin
        is_halted = 0;
        pc_write = 1; pc_write_not_cond = 0;
        ir_write = 0; mdr_write = 0; A_write = 0; B_write = 0; alu_write = 0;
        mem_read = 0; mem_write = 0;
        reg_write = 0;
        i_or_d = 0;

        case (opcode)
          `JMP_OP, `JAL_OP : pc_src = `PCSrc_Target;
          `BNE_OP, `BEQ_OP, `BGZ_OP, `BLZ_OP: begin
            
            alu_write = 0;
            alu_src_A = `ALUSrcA_PC;
            alu_src_B = `ALUSrcB_1;
            alu_op = `FUNC_ADD;
            if(bcond) begin
              pc_write_not_cond = 0;
              pc_src = `PCSrc_ALUOut;
            end else begin
              pc_write_not_cond = 1;
              pc_src = `PCSrc_ALURes;
            end
            
          end
          `ADI_OP, `ORI_OP, `LHI_OP, `LWD_OP, `SWD_OP : begin
            alu_write = 0;
            alu_src_A = `ALUSrcA_PC;
            alu_src_B = `ALUSrcB_1;
            alu_op = `FUNC_ADD;
            pc_src = `PCSrc_ALURes; 
          end
          `ALU_OP : begin
            case (funccode)
              `INST_FUNC_JPR, `INST_FUNC_JRL: pc_src = `PCSrc_A;
              `INST_FUNC_WWD : begin
                alu_write = 0;
                alu_src_A = `ALUSrcA_PC;
                alu_src_B = `ALUSrcB_1;
                alu_op = `FUNC_ADD;
                pc_src = `PCSrc_ALURes;
              end
              default: begin
                alu_write = 0;
                alu_src_A = `ALUSrcA_PC;
                alu_src_B = `ALUSrcB_1;
                alu_op = `FUNC_ADD;
                pc_src = `PCSrc_ALURes; 
              end
            endcase
          end
        endcase

        // set next state
        next_state = `IF;

      end
    endcase
  end

endmodule
