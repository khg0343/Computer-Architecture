`include "opcodes.v"
`include "control_unit.v"
`include "alu.v"
`include "register_file.v"

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output reg readM;									
	output reg writeM;								
	output reg [`WORD_SIZE-1:0] address;	
	inout [`WORD_SIZE-1:0] data;
		
	input ackOutput;								
	input inputReady;								
	input reset_n;									
	input clk;

	reg [3:0] opcode;
	reg [1:0] rs, rt, rd;
	reg [5:0] funccode;
	reg [11:0] target;
	reg signed [`WORD_SIZE - 1:0] immediate;

   	wire [3:0] alu_op;
	wire alu_src, reg_dst, reg_write, mem_read, mem_to_reg, mem_write, jp;
	wire [1:0] branch, pc_src;
	
	reg [1:0] read1, read2, write_reg;
	reg signed [`WORD_SIZE-1:0] write_data;
	wire signed [`WORD_SIZE-1:0] read_out1, read_out2;

	reg signed [`WORD_SIZE-1:0] alu_input_1, alu_input_2;
	wire signed [`WORD_SIZE-1:0] alu_output;

	reg [`WORD_SIZE-1:0] PC, PC_NXT;

	reg [`WORD_SIZE-1:0] instr;
	reg [`WORD_SIZE-1:0] memory;
	reg instrDataFetch;
	reg memoryDataFetch;

	control_unit ControlUnit(instr, instrDataFetch, memoryDataFetch, alu_op, alu_src, reg_dst, reg_write, mem_read, mem_to_reg, mem_write, jp, branch, pc_src);
	register_file RegisterFile(read_out1, read_out2, read1, read2, write_reg, write_data, reg_write, clk);
	alu ALU(alu_input_1, alu_input_2, alu_op, alu_output);

	assign readM = mem_read;
	assign writeM = inputReady? 0 : mem_write;

	assign data = writeM ? read_out2 : `WORD_SIZE'bz;

	initial begin							
		PC = `WORD_SIZE'd0;
		PC_NXT = `WORD_SIZE'd0;
		address = `WORD_SIZE'd0;
		instrDataFetch = 0;
		memoryDataFetch = 0;
	end
	
	always @(posedge inputReady) begin
		if(!instrDataFetch) begin
			instr <= data;
			instrDataFetch <= 1;
		end
		if(!memoryDataFetch) begin
			memory <= data;
			memoryDataFetch <= 1;
		end
	end

	always @(*) begin
		if(instrDataFetch) begin

			//ID
			opcode = instr[15:12];
			rs = instr[11:10];
			rt = instr[9:8];
			rd = instr[7:6];
			funccode = instr[5:0];

			// immediate extension
			case (opcode)
				`ORI_OP : immediate = { 8'b0, instr[7:0] };
				`LHI_OP : immediate = instr[7:0] << 8;
				default : immediate = { {8{instr[7]}}, instr[7:0] };
			endcase
			target = instr[11:0];

			read1 = rs;
			read2 = rt;
			if (reg_dst) begin
				if (jp)  write_reg = 2;		// JAL, JRL
				else 	write_reg = rd;		// ALU
			end else 	write_reg = rt;


			//EXE
			alu_input_1 = read_out1;
			if(alu_src) alu_input_2 = immediate;					//ADI, ORI, LHI, LWD, SWD
			else begin
				if (alu_op == `FUNC_ID2) alu_input_2 = PC;			//JAL, JRL
				else 					 alu_input_2 = read_out2;
			end

			//MEM
			if(mem_read || mem_write) address = alu_output;			//LWD, SWD

			//WB
			if(mem_to_reg) begin 									//LWD
				if(memoryDataFetch) write_data = memory;
			end else 		   		write_data = alu_output;

			case(pc_src)
				`PC_DEF : PC_NXT = PC + 1;				
				`PC_IMM : begin
					if ((branch == `BRANCH_NE && alu_output != 0) ||
						(branch == `BRANCH_EQ && alu_output == 0) ||
						(branch == `BRANCH_GZ && alu_output > 0)  ||
						(branch == `BRANCH_LZ && alu_output < 0))	PC_NXT = PC + immediate + 1;	//Branch
					else 											PC_NXT = PC + 1;
				end
				`PC_TAR : PC_NXT = {PC[15:12] , target};	//JMP, JAL
				`PC_REG : PC_NXT = read_out1;				//JPR, JRL
			endcase
		end
	end

	always @(negedge clk) begin
		memoryDataFetch <= 0;
	end

	always @(posedge clk) begin
		instrDataFetch <= 0;

		if(!reset_n) begin
			PC <= `WORD_SIZE'd0;
			PC_NXT <= `WORD_SIZE'd0;
			address <= `WORD_SIZE'd0;
			instrDataFetch <= 0;
		end
		else begin
			PC <= PC_NXT;
			address <= PC_NXT;
		end
	end																													  
endmodule							  																		  