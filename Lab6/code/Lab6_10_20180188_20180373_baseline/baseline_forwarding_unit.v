`include "opcodes.v" 

module forwarding_unit(IF_read1, IF_read2, ID_read1, ID_read2, ID_dest, EX_dest, MEM_dest, ID_reg_write, EX_reg_write, MEM_reg_write, ID_is_bubble, EX_is_bubble, MEM_is_bubble, forward_A, forward_B, forward_read_out1, forward_read_out2);

	input [1:0] IF_read1, IF_read2;
    input [1:0] ID_read1, ID_read2;
    input [1:0] ID_dest, EX_dest, MEM_dest;
    input ID_reg_write, EX_reg_write, MEM_reg_write;
   	input ID_is_bubble, EX_is_bubble, MEM_is_bubble;

	output reg [1:0] forward_A, forward_B;
	output reg [1:0] forward_read_out1, forward_read_out2;

  	always @(*) begin
        // Forwarding A
		if      (ID_read1 == EX_dest && EX_reg_write && !EX_is_bubble)    forward_A = `FORWARD_EX;
   	   	else if (ID_read1 == MEM_dest && MEM_reg_write && !MEM_is_bubble) forward_A = `FORWARD_MEM;
  	    else                                                          	  forward_A = `FORWARD_ID;
      
 	    // Forwarding B
  		if      (ID_read2 == EX_dest && EX_reg_write && !EX_is_bubble)    forward_B = `FORWARD_EX;
  	    else if (ID_read2 == MEM_dest && MEM_reg_write && !MEM_is_bubble) forward_B = `FORWARD_MEM;
  	    else                                                          	  forward_B = `FORWARD_ID;

		//Forwarding read_out1
		if 		(IF_read1 == ID_dest && ID_reg_write && !ID_is_bubble)    forward_read_out1 = `FORWARD_ID;
        else if (IF_read1 == EX_dest && EX_reg_write && !EX_is_bubble) 	  forward_read_out1 = `FORWARD_EX;
        else if (IF_read1 == MEM_dest && MEM_reg_write && !MEM_is_bubble) forward_read_out1 = `FORWARD_MEM;
		else 														   	  forward_read_out1 = `FORWARD_IF;

		if 		(IF_read2 == ID_dest && ID_reg_write && !ID_is_bubble)    forward_read_out2 = `FORWARD_ID;
        else if (IF_read2 == EX_dest && EX_reg_write && !EX_is_bubble) 	  forward_read_out2 = `FORWARD_EX;
        else if (IF_read2 == MEM_dest && MEM_reg_write && !MEM_is_bubble) forward_read_out2 = `FORWARD_MEM;
		else 														   	  forward_read_out2 = `FORWARD_IF;
	end

endmodule