`include "opcodes.v"
module DMAController (clk, reset_n, interrupt_in, length, BG, BR, write, base_address, address, interrupt_out, offset_count);
    input clk;
    input reset_n;
    input interrupt_in;                     // from cpu
    input BG;
    input [3:0] length;
    input [`WORD_SIZE-1:0] base_address;

    output reg write;
    output reg BR;
    output reg [`WORD_SIZE-1:0] address;
    output reg interrupt_out;               // to cpu
    output reg [1:0] offset_count;

    wire [1:0] offset_max;
    reg [2:0] clock_count;

    assign offset_max = length / 4;

    // set BR
    always @(*) begin
        if (interrupt_in) BR = 1;
        if (interrupt_out) BR = 0;
    end

    always @(posedge clk) begin
        if(!reset_n) begin
            write <= 0;
            address <= base_address;
            interrupt_out <= 0;
            offset_count <= 0;
            clock_count <= 0;
        end
        if (BG) begin
            if (offset_count < offset_max) begin
                if(clock_count == 0) begin
                    address <= base_address + offset_count*4;
                    offset_count <= offset_count + 1;
                    clock_count <= 5;
                    write <= 1;
                end else begin
                    clock_count <= clock_count - 1;
                    write <= 0;
                end
            end
            else begin // last request
                if(clock_count == 0) begin
                    offset_count <= 0;
                    address <= base_address + offset_count*4;
                    clock_count <= 5;
                    interrupt_out <= 1;
                    write <= 1;
                end else begin 
                    clock_count <= clock_count - 1;
                    write <= 0;
                end
            end
        end else write <= 0;
    end

endmodule