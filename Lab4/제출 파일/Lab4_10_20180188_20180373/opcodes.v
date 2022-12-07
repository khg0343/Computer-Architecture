// Stages
`define IF 3'b000
`define ID 3'b001
`define EXE 3'b010
`define MEM 3'b011
`define WB 3'b100
`define PCUpdate 3'b101

// ALUSrcA
`define ALUSrcA_A 2'b00
`define ALUSrcA_PC 2'b01

// ALUSrcB
`define ALUSrcB_B 2'b00
`define ALUSrcB_IMM 2'b01
`define ALUSrcB_1 2'b10
`define ALUSrcB_0 2'b11

// PCSrc
`define PCSrc_ALURes 2'b00
`define PCSrc_ALUOut 2'b01
`define PCSrc_A 2'b10
`define PCSrc_Target 2'b11

// RegDst
`define RegDst_RD 2'b00
`define RegDst_RT 2'b01
`define RegDst_2 2'b10

// MemToReg
`define MemToReg_ALUOut 2'b00
`define MemToReg_IMM 2'b01
`define MemToReg_MDR 2'b10
`define MemToReg_PC 2'b11


// Branch Type for bne, beq, bgz, blz
`define BNE 2'b00
`define BEQ 2'b01
`define BGZ 2'b10
`define BLZ 2'b11
 		  
// Opcode
`define   ALU_OP   4'd15
`define   ADI_OP   4'd4
`define   ORI_OP   4'd5
`define   LHI_OP   4'd6
`define   LWD_OP   4'd7
`define   SWD_OP   4'd8
`define   BNE_OP   4'd0
`define   BEQ_OP   4'd1
`define   BGZ_OP   4'd2
`define   BLZ_OP   4'd3
`define   JMP_OP   4'd9
`define   JAL_OP   4'd10
`define   JPR_OP   4'd15
`define   JRL_OP   4'd15
`define   HLT_OP   4'd15
`define   WWD_OP   4'd15

// ALU Function Codes
`define   FUNC_ADD   3'b000
`define   FUNC_SUB   3'b001             
`define   FUNC_AND   3'b010
`define   FUNC_ORR   3'b011                            
`define   FUNC_NOT   3'b100
`define   FUNC_TCP   3'b101
`define   FUNC_SHL   3'b110
`define   FUNC_SHR   3'b111   

// ALU instruction function codes
`define INST_FUNC_ADD 6'd0
`define INST_FUNC_SUB 6'd1
`define INST_FUNC_AND 6'd2
`define INST_FUNC_ORR 6'd3
`define INST_FUNC_NOT 6'd4
`define INST_FUNC_TCP 6'd5
`define INST_FUNC_SHL 6'd6
`define INST_FUNC_SHR 6'd7
`define INST_FUNC_JPR 6'd25
`define INST_FUNC_JRL 6'd26
`define INST_FUNC_WWD 6'd28
`define INST_FUNC_HLT 6'd29

`define   WORD_SIZE   16         
`define   NUM_REGS   4