`include "opcodes.v" 

module register_file (read_out1, read_out2, read1, read2, dest, write_data, reg_write, clk, reset_n);

	input [1:0] read1;
    input [1:0] read2;
    input [1:0] dest;
    input signed [`WORD_SIZE-1:0] write_data;
    input reg_write;
    input clk, reset_n;
    output reg signed [`WORD_SIZE-1:0] read_out1;
    output reg signed [`WORD_SIZE-1:0] read_out2;

    reg signed [`WORD_SIZE-1:0] register[`NUM_REGS-1:0];
    
    integer i;

    initial begin
        for (i = 0; i < `NUM_REGS; i = i + 1) register[i] = 0;
    end

    always @(*) begin
        read_out1 = (read1 == dest && reg_write) ? write_data : register[read1];
        read_out2 = (read2 == dest && reg_write) ? write_data : register[read2];
    end

    always @(posedge clk) begin
        if (reg_write) begin register[dest] <= write_data; end
    end

endmodule
