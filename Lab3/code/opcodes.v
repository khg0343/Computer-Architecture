		  
// Opcode
`define	ALU_OP	4'd15
`define	ADI_OP	4'd4
`define	ORI_OP	4'd5
`define	LHI_OP	4'd6
`define	LWD_OP	4'd7   		  
`define	SWD_OP	4'd8  
`define	BNE_OP	4'd0
`define	BEQ_OP	4'd1
`define BGZ_OP	4'd2
`define BLZ_OP	4'd3
`define	JMP_OP	4'd9
`define JAL_OP	4'd10
`define	JPR_OP	4'd15
`define	JRL_OP	4'd15

// PC Control
`define PC_DEF 2'b00
`define PC_IMM 2'b01
`define PC_TAR 2'b10
`define PC_REG 2'b11

// Branch Control
`define BRANCH_NE 2'b00
`define BRANCH_EQ 2'b01
`define BRANCH_GZ 2'b10
`define BRANCH_LZ 2'b11

// ALU Function Codes
`define	FUNC_ADD	4'b0000
`define	FUNC_SUB	4'b0001				 
`define	FUNC_AND	4'b0010
`define	FUNC_ORR	4'b0011								    
`define	FUNC_NOT	4'b0100
`define	FUNC_TCP	4'b0101
`define	FUNC_SHL	4'b0110
`define	FUNC_SHR	4'b0111
`define FUNC_ID1    4'b1000
`define FUNC_ID2    4'b1001
`define FUNC_ZRO    4'b1010

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

`define	WORD_SIZE	16			
`define	NUM_REGS	4