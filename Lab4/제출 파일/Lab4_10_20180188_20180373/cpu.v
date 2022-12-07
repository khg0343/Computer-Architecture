`timescale 1ns/1ns
`include "opcodes.v"
`include "control_unit.v"
`include "alu.v"
`include "register_file.v"
`include "util.v"

module cpu(clk, reset_n, read_m, write_m, address, data, num_inst, output_port, is_halted);
	input clk;
	input reset_n;
	
	output reg read_m;
	output reg write_m;
	output reg [`WORD_SIZE-1:0] address;

	inout [`WORD_SIZE-1:0] data;

	output reg [`WORD_SIZE-1:0] num_inst;	// number of instruction executed (for testing purpose)
	output reg [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
	output is_halted;

	reg [3:0] opcode;
	reg [1:0] rs, rt, rd;
	reg [5:0] funccode;
	reg [11:0] target;
	wire signed [`WORD_SIZE - 1:0] immediate;

	reg signed [`WORD_SIZE-1:0] InstReg, MemReg;
	reg signed [`WORD_SIZE-1:0] A, B;
	reg signed [`WORD_SIZE-1:0] ALUOut;
	reg signed [`WORD_SIZE-1:0] MemData;

	// control values
	wire alu_src_A;
	wire [1:0] alu_src_B;
	wire [2:0] alu_op;
	wire [1:0] pc_src;
	wire [1:0] mem_to_reg;
	wire [1:0] reg_dst;

	wire pc_write_not_cond, pc_write, i_or_d;
	wire mem_read, mem_write, ir_write, mdr_write, reg_write;

	wire A_write, B_write, alu_write;

	// for RF
	reg [1:0] read1, read2, write_reg;
	wire signed [`WORD_SIZE-1:0] read_out1, read_out2;

	// for ALU
	wire [2:0] alu_funccode;
	wire [1:0] branch_type;
	wire overflow_flag, bcond;
	wire signed [`WORD_SIZE-1:0] alu_result;

	// PC value
	reg [`WORD_SIZE-1:0] PC, PC_NXT;

	// Mux outputs
	wire signed [1:0] WriteRegMuxOut;
	wire signed [`WORD_SIZE-1:0] WriteDataMuxOut;
	wire signed [`WORD_SIZE-1:0] MemoryMuxOut;
	wire signed [`WORD_SIZE-1:0] ALUMux1Out, ALUMux2Out;
	wire signed [`WORD_SIZE-1:0] PCMuxOut;

	mux4_1 #(2) WriteRegMux(reg_dst, rd, rt, 2'd2, 2'd0, WriteRegMuxOut);
	mux4_1 #(`WORD_SIZE) WriteDataMux(mem_to_reg, ALUOut, immediate, MemReg, PC + `WORD_SIZE'd1, WriteDataMuxOut);
	mux2_1 #(`WORD_SIZE) MemoryMux(i_or_d, PC, ALUOut, MemoryMuxOut);
	mux2_1 #(`WORD_SIZE) ALUMux1(alu_src_A, A, PC, ALUMux1Out);
	mux4_1 #(`WORD_SIZE) ALUMux2(alu_src_B, B, immediate, `WORD_SIZE'd1, `WORD_SIZE'd0, ALUMux2Out);
	mux4_1 #(`WORD_SIZE) PCMux(pc_src, alu_result, ALUOut, A, { PC[15:12], target }, PCMuxOut);
	
	imm_gen ImmGen(InstReg, immediate);
	alu ALU(ALUMux1Out, ALUMux2Out, alu_funccode, branch_type, alu_result, overflow_flag, bcond);
	alu_control_unit ALUControlUnit(clk, funccode, opcode, alu_op, alu_funccode, branch_type);
	control_unit ControlUnit (opcode, funccode, bcond, clk, reset_n, is_halted, pc_write_not_cond, pc_write, i_or_d, mem_read, mem_write, mem_to_reg, ir_write, mdr_write, pc_src, alu_op, alu_src_A, alu_src_B, reg_dst, reg_write, A_write, B_write, alu_write);
	register_file RegisterFile(read_out1, read_out2, read1, read2, WriteRegMuxOut, WriteDataMuxOut, reg_write, clk);

	assign data = write_m ? B : `WORD_SIZE'bz;
	assign read_m = mem_read;
	assign write_m = mem_write;

	always @(*) begin

		opcode = InstReg[15:12];
		rs = InstReg[11:10];
		rt = InstReg[9:8];
		rd = InstReg[7:6];
		funccode = InstReg[5:0];
		target = InstReg[11:0];

		read1 = rs; read2 = rt;

		if(pc_write) begin
			if (opcode == `WWD_OP && funccode == `INST_FUNC_WWD) output_port = A;
		end

		address = MemoryMuxOut;
		MemData = data;

		if (pc_write || pc_write_not_cond && !bcond) PC_NXT = PCMuxOut;
		
	end

	always @(posedge clk) begin
		if(!reset_n) begin
			PC <= 0;
			num_inst <= 0;	
			InstReg <= 0;
			MemReg <= 0;
			A <= 0;
			B <= 0;
			ALUOut <= 0;
		end	
		else begin
			if (A_write) begin A <= read_out1; end
			if (B_write) begin B <= read_out2; end
			if (alu_write) begin ALUOut <= alu_result; end
			if (ir_write) InstReg <= MemData;
			if (mdr_write) MemReg <= MemData;

			if (pc_write || pc_write_not_cond && !bcond) begin	//pc_write 
				num_inst <= num_inst + 1;	//new instruction
				PC <= PC_NXT;
			end
		end
	end								
endmodule
