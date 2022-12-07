   `timescale 1ns/1ns
   `define WORD_SIZE 16    // data and address word size
   `include "opcodes.v" 

   module CacheCPU(clk, reset_n, block1_read, address1_out, block1_in, block2_read, block2_write, address2_out, block2_inout, num_inst, output_port, is_halted);
   input clk;
   input reset_n;

   output block1_read;
   output [`WORD_SIZE-1:0] address1_out;
   input [`BLOCK_SIZE-1:0] block1_in;

   output block2_read;
   output block2_write;
   output [`WORD_SIZE-1:0] address2_out;
   inout [`BLOCK_SIZE-1:0] block2_inout;

   output reg [`WORD_SIZE-1:0] num_inst;
   output reg [`WORD_SIZE-1:0] output_port;
   output reg is_halted;

   // cache
   wire read_m1, read_m2, write_m2;
   wire waitCache1, waitCache2, dataReady1, dataReady2, isReady;
   wire [`WORD_SIZE-1:0] address1_in, data1_out, address2_in, data2_in, data2_out;
   wire [`BLOCK_SIZE-1:0] block2_in, block2_out;

    // control values
   wire alu_src_A; 
   wire [1:0] alu_src_B, branch_type, reg_dst, pc_src;
   wire [2:0] alu_op;
   wire mem_read, mem_write, mem_to_reg;
   wire reg_write;
   wire hlt, wwd, branch, jp;

   // for RF
	reg [1:0] read1, read2, dest;
	reg signed [`WORD_SIZE-1:0] write_data;
	wire signed [`WORD_SIZE-1:0] read_out1;
   wire signed [`WORD_SIZE-1:0] read_out2;
   reg bcond;

   // for ALU
   wire overflow_flag;
	wire signed [`WORD_SIZE-1:0] alu_result;

	// for ID
   reg [3:0] opcode;
   reg [1:0] rs, rt, rd;
   reg [5:0] funccode;
   reg [11:0] target;
   wire signed [`WORD_SIZE-1:0] immediate;

   // for PC
   reg [`WORD_SIZE-1:0] PC, PC_NXT;

   // for Forwarding Unit
   wire [1:0] forward_A, forward_B, forward_read_out1, forward_read_out2;

   // for Hazard Detection Unit
   wire is_stall, IF_flush, ID_flush;
   reg [`WORD_SIZE-1:0] num_clock;

   /* Pipeline Register */
   // IF ID
   // IF/ID Control
   reg IF_is_bubble;
   // IF/ID Register
   reg [`WORD_SIZE-1:0] IF_PC;
   reg [`WORD_SIZE-1:0] IF_inst;

   // ID EX
   // ID/EX Control
   reg [2:0] ID_alu_op;
   reg ID_alu_src_A;
   reg [1:0] ID_alu_src_B;
   reg ID_mem_read;
   reg ID_mem_write;
   reg ID_mem_to_reg;
   reg ID_reg_write;
   reg ID_wwd;
   reg ID_hlt;
   reg ID_is_bubble;
   // ID/EX Register
   reg [`WORD_SIZE-1:0] ID_PC;
   reg [`WORD_SIZE-1:0] ID_readData1;
   reg [`WORD_SIZE-1:0] ID_readData2;
   reg [1:0] ID_read1, ID_read2, ID_dest;
   reg [`WORD_SIZE-1:0] ID_immediate;

   // EX/MEM
   // EX/MEM Control
   reg EX_mem_read;
   reg EX_mem_write;
   reg EX_mem_to_reg;
   reg EX_reg_write;
   reg EX_wwd;
   reg EX_hlt;
   reg EX_is_bubble;
   // EX/MEM Register
   reg signed [`WORD_SIZE-1:0] EX_alu_out, EX_B;
   reg [1:0] EX_dest;

   // MEM/WB
   // MEM/WB Control
   reg MEM_reg_write;
   reg MEM_mem_to_reg;
   reg MEM_wwd;
   reg MEM_hlt;
   reg MEM_is_bubble;
   // MEM/WB Register
   reg [`WORD_SIZE-1:0] MEM_data;
   reg [`WORD_SIZE-1:0] MEM_alu_out;
   reg [1:0] MEM_dest;

   // mux
   wire signed [`WORD_SIZE-1:0] ForwardAMuxOut, ForwardBMuxOut, ForwardReadOut1MuxOut, ForwardReadOut2MuxOut;
   wire signed [`WORD_SIZE-1:0] ALUSrcAMuxOut, ALUSrcBMuxOut;
   wire signed [1:0] WriteDestMuxOut;
   wire signed [`WORD_SIZE-1:0] WriteDataMuxOut;
   wire signed [`WORD_SIZE-1:0] PCMuxOut;

   mux4_1 #(`WORD_SIZE) ForwardAMux(forward_A, `WORD_SIZE'd0, ID_readData1, EX_alu_out, WriteDataMuxOut, ForwardAMuxOut);
   mux4_1 #(`WORD_SIZE) ForwardBMux(forward_B, `WORD_SIZE'd0, ID_readData2, EX_alu_out, WriteDataMuxOut, ForwardBMuxOut);
   mux4_1 #(`WORD_SIZE) ForwardReadOut1Mux(forward_read_out1, read_out1, alu_result, read_m2? data2_out : EX_alu_out, WriteDataMuxOut, ForwardReadOut1MuxOut);
   mux4_1 #(`WORD_SIZE) ForwardReadOut2Mux(forward_read_out2, read_out2, alu_result, read_m2? data2_out : EX_alu_out, WriteDataMuxOut, ForwardReadOut2MuxOut);

   mux2_1 #(`WORD_SIZE) ALUSrcAMux(ID_alu_src_A, ForwardAMuxOut, `WORD_SIZE'd0, ALUSrcAMuxOut);
   mux4_1 #(`WORD_SIZE) ALUSrcBMux(ID_alu_src_B, ForwardBMuxOut, ID_immediate, ID_PC, `WORD_SIZE'd0, ALUSrcBMuxOut);

   mux4_1 #(2) WriteDestMux(reg_dst, rd, rt, 2'd2, 2'd0, WriteDestMuxOut);
   mux2_1 #(`WORD_SIZE) WriteDataMux(MEM_mem_to_reg, MEM_alu_out, MEM_data, WriteDataMuxOut);
   mux4_1 #(`WORD_SIZE) PCMux(pc_src, PC + `WORD_SIZE'd1, IF_PC + immediate, {IF_PC[15:12], target}, ForwardReadOut1MuxOut, PCMuxOut);

   imm_gen ImmGen(IF_inst, immediate);
   alu ALU(ALUSrcAMuxOut, ALUSrcBMuxOut, ID_alu_op, alu_result, overflow_flag);
   control_unit ControlUnit(opcode, funccode, clk, reset_n, bcond, alu_op, alu_src_A, alu_src_B, mem_read, mem_write, mem_to_reg, reg_dst, reg_write, pc_src, hlt, wwd, branch_type, branch, jp);
   register_file RegisterFile(read_out1, read_out2, read1, read2, MEM_dest, WriteDataMuxOut, !MEM_is_bubble & MEM_reg_write, clk, reset_n);
   hazard_detection_unit HazardDetectionUnit(read1, read2, ID_dest, ID_mem_read, opcode, funccode, bcond, jp, num_clock, IF_flush, ID_flush, is_stall);
   forwarding_unit ForwardingUnit(!waitCache2, rs, rt, ID_read1, ID_read2, ID_dest, EX_dest, MEM_dest, ID_reg_write, EX_reg_write, MEM_reg_write, ID_is_bubble, EX_is_bubble, MEM_is_bubble, forward_A, forward_B, forward_read_out1, forward_read_out2);

   ICache i_cache(!clk, read_m1, address1_in, address1_out, data1_out, block1_in, block1_read, dataReady1, waitCache1);
   DCache d_cache(!clk, read_m2, write_m2, address2_in, address2_out, data2_in, data2_out, block2_in, block2_out, block2_read, block2_write, dataReady2, waitCache2);

   assign read_m1  = waitCache1 ? 0 : 1;
   assign read_m2  = waitCache2 ? 0 : (EX_is_bubble ? 0 : EX_mem_read);
   assign write_m2 = waitCache2 ? 0 : (EX_is_bubble ? 0 : EX_mem_write);
   assign address1_in = PC;
   assign address2_in = EX_alu_out;
   assign data2_in = EX_B;
   assign isReady = waitCache2 ? dataReady2 : 1;

   assign block2_inout = block2_write ? block2_out : `BLOCK_SIZE'bz;
   assign block2_in = block2_read? block2_inout : block2_in;

   always @(posedge clk) begin
      if (!reset_n) begin
         PC <= 0;
         PC_NXT <= 0;
         IF_PC <= 0;
         bcond <= 0;

         IF_is_bubble <= 1;
         ID_is_bubble <= 1;
         EX_is_bubble <= 1;
         MEM_is_bubble <= 1;

         num_inst <= 0;
         num_clock <= 1;

         ID_mem_read <= 0;
         ID_mem_write <= 0;
         EX_mem_read <= 0;
         EX_mem_write <= 0;

      end else begin

         num_clock <= num_clock + 1;
         num_inst <= (!MEM_is_bubble) ? num_inst + 1 : num_inst;

         if (isReady) begin
            //MEM
            MEM_data <= data2_out;
            MEM_alu_out <= EX_alu_out;
            MEM_dest <= EX_dest;

            MEM_mem_to_reg <= EX_mem_to_reg;
            MEM_reg_write <= EX_reg_write;
            MEM_wwd <= EX_wwd;
            MEM_hlt <= EX_hlt;
            MEM_is_bubble <= EX_is_bubble;

            // EX
            EX_B <= ForwardBMuxOut;
            EX_alu_out <= alu_result;
            EX_dest <= ID_dest;
            EX_mem_read <= ID_mem_read;
            EX_mem_write <= ID_mem_write;
            EX_mem_to_reg <= ID_mem_to_reg;
            EX_reg_write <= ID_reg_write;
            EX_wwd <= ID_wwd;
            EX_hlt <= ID_hlt;
            EX_is_bubble <= ID_is_bubble;
      
            // ID
            ID_PC <= IF_PC;
            ID_readData1 <= read_out1;
            ID_readData2 <= read_out2;
            ID_dest <= WriteDestMuxOut;
            ID_read1 <= rs;
            ID_read2 <= rt;
            ID_immediate <= immediate;

            // ID/EX Control
            ID_alu_op <= alu_op;
            ID_alu_src_A <= alu_src_A;
            ID_alu_src_B <= alu_src_B;
            ID_reg_write <= reg_write;
            ID_wwd <= wwd;
            ID_hlt <= hlt;
            
            if(!ID_flush) begin
               ID_mem_read <= mem_read;
               ID_mem_write <= mem_write;
               ID_mem_to_reg <= mem_to_reg;
            end else begin
               ID_mem_read <= 0;
               ID_mem_write <= 0;
               ID_mem_to_reg <= 0;
            end
            ID_is_bubble <= IF_is_bubble;
            
            if (!is_stall && dataReady1) begin 
               PC <= PC_NXT;
               IF_PC <= PC + 1;
               if (!IF_flush) begin
                  IF_inst <= data1_out;
                  IF_is_bubble <= 0;
               end
               else begin
                  IF_inst <= 0;
                  IF_is_bubble <= 1;
               end
            end else begin
               IF_is_bubble <= 1;
            end
         end else begin MEM_is_bubble <= 1; end
      end
   end

   always @(*) begin
      // ID
      opcode = IF_inst[15:12];
      rs = IF_inst[11:10];
      rt = IF_inst[9:8];
      rd = IF_inst[7:6];
      funccode = IF_inst[5:0];
      target = IF_inst[11:0];

      read1 = rs; read2 = rt;

      if (branch) begin 
         case (branch_type)
            `BRANCH_NE : bcond = ForwardReadOut1MuxOut != ForwardReadOut2MuxOut ? 1 : 0;
            `BRANCH_EQ : bcond = ForwardReadOut1MuxOut == ForwardReadOut2MuxOut ? 1 : 0;
            `BRANCH_GZ : bcond = ForwardReadOut1MuxOut > 0 ? 1 : 0;
            `BRANCH_LZ : bcond = ForwardReadOut1MuxOut < 0 ? 1 : 0;
         endcase
      end

      if (MEM_wwd) begin output_port = MEM_alu_out; end
      if (MEM_hlt) is_halted = 1;

      PC_NXT = PCMuxOut;
   end
endmodule



