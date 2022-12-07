`include "opcodes.v"

module hazard_detection_unit(read1, read2, ID_dest, ID_mem_read, opcode, funccode, bcond, jp, num_clock, IF_flush, ID_flush, is_stall);

	input [1:0] read1;
	input [1:0] read2; 
	input [1:0] ID_dest;
	input ID_mem_read;

	input [3:0] opcode;
	input [5:0] funccode;
	input bcond;
	input jp;
	input [`WORD_SIZE-1:0] num_clock;

	output reg IF_flush, ID_flush, is_stall;

	reg use_read1, use_read2;

	initial begin
		is_stall = 0;
		IF_flush = 0;
		ID_flush = 0;
	end

	always @(*) begin
		if (num_clock > 1) begin 
			case (opcode)
				`ADI_OP : begin use_read1 = 1; use_read2 = 0; end
				`ORI_OP : begin use_read1 = 1; use_read2 = 0; end
				`LHI_OP : begin use_read1 = 0; use_read2 = 0; end
				`LWD_OP : begin use_read1 = 1; use_read2 = 0; end
				`SWD_OP : begin use_read1 = 1; use_read2 = 1; end

				`BNE_OP : begin use_read1 = 1; use_read2 = 1; end
				`BEQ_OP : begin use_read1 = 1; use_read2 = 1; end
				`BGZ_OP : begin use_read1 = 1; use_read2 = 0; end
				`BLZ_OP : begin use_read1 = 1; use_read2 = 0; end

				`JMP_OP : begin use_read1 = 0; use_read2 = 0; end
				`JAL_OP : begin use_read1 = 0; use_read2 = 0; end

				`ALU_OP : begin
					case (funccode)
						`INST_FUNC_JPR : begin use_read1 = 1; use_read2 = 0; end
						`INST_FUNC_JRL : begin use_read1 = 1; use_read2 = 0; end
						`INST_FUNC_WWD : begin use_read1 = 1; use_read2 = 0; end
						`INST_FUNC_HLT : begin use_read1 = 0; use_read2 = 0; end
						default        : begin use_read1 = 1; use_read2 = 1; end
					endcase
				end
			endcase
		end

		if (ID_mem_read && ((ID_dest == read1 && use_read1) || (ID_dest == read2 && use_read2))) begin 
        	IF_flush = 0; 
        	ID_flush = (num_clock > 2) ? 1 : 0;
        	is_stall = (num_clock > 2) ? !is_stall : 0;
		end
		else if (bcond | jp) begin 
			IF_flush = 1;
			ID_flush = (num_clock > 2) ? 1 : 0;
			is_stall = 0;
		end
       	else begin IF_flush = 0; ID_flush = 0; is_stall = 0; end
	end

endmodule