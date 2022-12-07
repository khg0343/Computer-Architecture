`include "opcodes.v"

module register_file(read_out1, read_out2, read1, read2, write_reg, write_data, reg_write, clk); 
    input [1:0] read1;
    input [1:0] read2;
    input [1:0] write_reg;
    input signed [`WORD_SIZE-1:0] write_data;
    input reg_write;
    input clk;
    output reg signed [`WORD_SIZE-1:0] read_out1;
    output reg signed [`WORD_SIZE-1:0] read_out2;

    reg signed [`WORD_SIZE-1:0] register[`NUM_REGS-1:0];
    
    integer i;

    initial begin
        for (i = 0; i < `NUM_REGS; i = i + 1) register[i] = 0;
    end

    always @(*) begin
        read_out1 = register[read1];
        read_out2 = register[read2];
    end

    always @(posedge clk) begin
        if (reg_write) register[write_reg] <= write_data;
    end

endmodule