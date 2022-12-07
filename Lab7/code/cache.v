`include "opcodes.v"
module ICache(BG, clk, read_m1, address1_in, address1_out, data1_out, block1_in, block_read, dataReady, waitCache);
	input BG;
	input clk;
	input read_m1;
	input [`WORD_SIZE-1:0] address1_in; // CPU -> Cache
	input [`BLOCK_SIZE-1:0] block1_in;  // Cache <- Memory

	output reg [`WORD_SIZE-1:0] address1_out; // Cache -> Memory
	output reg [`WORD_SIZE-1:0] data1_out;     // CPU <- Cache

	output reg block_read;
	output reg dataReady; // signal to CPU
	output reg waitCache;

	wire [12:0] tag;
	wire idx;
	wire [1:0] bo;
	assign tag = address1_in[15:3];
	assign idx = address1_in[2];
	assign bo = address1_in[1:0];

	reg [`LINE_SIZE-1:0] i_cache[0:1][0:1];

	reg hit[1:0];
	reg way;

	reg [2:0] counter_read;

	integer i,j;
	initial begin
		waitCache = 0;
		for(i=0; i<=1; i=i+1) begin
			for(j=0; j<=1; j=j+1) begin
				i_cache[i][j][`VALID] = 0;
			end
		end
	end

	always @(*) begin
		if (read_m1) begin
			hit[0] = i_cache[0][idx][`VALID] && (tag == i_cache[0][idx][`TAG]);
			hit[1] = i_cache[1][idx][`VALID] && (tag == i_cache[1][idx][`TAG]);
			if 		(hit[0]) way = 0;		//cache way0 hit
			else if (hit[1]) way = 1;		//cache way1 hit
			else begin						//cache miss
				if (!i_cache[0][idx][`VALID]) way = 0;
				else if (!i_cache[1][idx][`VALID]) way = 1;
				else if (i_cache[0][idx][`LRU]) way = 0; 
				else 					   way = 1;
			end
		end
	end
	
	always @(posedge clk) begin
		if (hit[0]) begin			//cache way0 hit
			waitCache <= 0;
			i_cache[0][idx][`LRU] <= 0;
			i_cache[1][idx][`LRU] <= 1;
			
			if (read_m1) begin
				dataReady <= 1;
				case (bo)
					0: data1_out <= i_cache[0][idx][`BLOCK0];
					1: data1_out <= i_cache[0][idx][`BLOCK1];
					2: data1_out <= i_cache[0][idx][`BLOCK2];
					3: data1_out <= i_cache[0][idx][`BLOCK3];
				endcase
			end
		end else if (hit[1]) begin //cache way1 hit
			waitCache <= 0;
			i_cache[1][idx][`LRU] <= 0;
			i_cache[0][idx][`LRU] <= 1;

			if (read_m1) begin
				dataReady <= 1;
				case (bo)
					0: data1_out <= i_cache[1][idx][`BLOCK0];
					1: data1_out <= i_cache[1][idx][`BLOCK1];
					2: data1_out <= i_cache[1][idx][`BLOCK2];
					3: data1_out <= i_cache[1][idx][`BLOCK3];
				endcase
			end
		end else begin					//cache miss
			if (read_m1) begin
				dataReady <= 0;
				// signal to cpu
				waitCache <= 1;
				counter_read <= 5;
				address1_out <= { i_cache[way][idx][`TAG], idx, 2'b00 };
			end else begin
				if (counter_read == 4) begin block_read <= 1; address1_out <= { tag, idx, 2'b00 }; end
				else 				   begin block_read <= 0; end
				if (counter_read == 1) begin
					dataReady <= 1;
					if(way == 0) begin 
						i_cache[0][idx] <= {tag, 1'b1, 1'b0, 1'b0, block1_in };
						i_cache[1][idx][`LRU] <= 1'b1;
					end else begin
					  	i_cache[1][idx] <= {tag, 1'b1, 1'b0, 1'b0, block1_in };
						i_cache[0][idx][`LRU] <= 1'b1;
					end
					case (bo)
						0: data1_out <= block1_in[`BLOCK0];
						1: data1_out <= block1_in[`BLOCK1];
						2: data1_out <= block1_in[`BLOCK2];
						3: data1_out <= block1_in[`BLOCK3];
					endcase
				end	else begin dataReady <= 0; end

				if (counter_read == 0) waitCache <= 0;
				
				if (counter_read > 0 && !BG) begin
					counter_read <= counter_read - 1;
				end
			end

		end
	end
endmodule

module DCache(BG, clk, read_m2, write_m2, address2_in, address2_out, data2_in, data2_out, block2_in, block2_out, block_read, block_write, dataReady, waitCache);
	input BG;
	input clk;
	input read_m2;
	input write_m2;
	input [`WORD_SIZE-1:0] address2_in; // CPU -> Cache
	input [`WORD_SIZE-1:0] data2_in; // CPU -> Cache
	input [`BLOCK_SIZE-1:0] block2_in;  // out: Cache -> Memory / in: <-

	output reg [`WORD_SIZE-1:0] address2_out; // Cache -> Memory
	output reg [`WORD_SIZE-1:0] data2_out;    // CPU <- Cache
	output reg [`BLOCK_SIZE-1:0] block2_out;  // out: Cache -> Memory / in: <-

	output reg block_read; // signal to MEM   
	output reg block_write;

	output reg dataReady; // signal to CPU that MEM stage is done
	output reg waitCache;
	
	wire [12:0] tag;
	wire idx;
	wire [1:0] bo;
	assign tag = address2_in[15:3];
	assign idx = address2_in[2];
	assign bo = address2_in[1:0];

	reg [`LINE_SIZE-1:0] d_cache[0:1][0:1];

	reg hit[1:0];
	reg way;

	reg [2:0] counter_read;
	reg [2:0] counter_write;

	reg block_read_r; 
	reg block_write_r;
	reg block_read_w; 
	reg block_write_w;
	reg dataReady_r;
	reg dataReady_w;
	reg waitCache_r;
	reg waitCache_w;

	assign block_read = block_read_r | block_read_w;
	assign block_write = block_write_r | block_write_w;
	assign dataReady = dataReady_r | dataReady_w;
	assign waitCache = waitCache_r | waitCache_w;

	assign block2_out = d_cache[way][idx][`BLOCK_SIZE-1:0];
	
	integer i,j;
	initial begin
		waitCache = 0; waitCache_r = 0; waitCache_w = 0;
		dataReady = 0; dataReady_r = 0; dataReady_w = 0;
		
		for(i=0; i<=1; i=i+1) begin
			for(j=0; j<=1; j=j+1) begin
				d_cache[i][j][`VALID] = 0;
			end
		end
	end

	always @(*) begin

		if (read_m2 || write_m2) begin
			hit[0] = (d_cache[0][idx][`VALID]==1'b1) && (tag == d_cache[0][idx][`TAG]);
			hit[1] = (d_cache[1][idx][`VALID]==1'b1) && (tag == d_cache[1][idx][`TAG]);
			
			if 		(hit[0]) way = 0;
			else if (hit[1]) way = 1;
			else begin
				if (!d_cache[0][idx][`VALID]) way = 0;
				else if (!d_cache[1][idx][`VALID]) way = 1;
				else if (d_cache[0][idx][`LRU]) way = 0; 
				else 					   way = 1;
			end
		end
	end
	
	always @(posedge clk) begin
		if (hit[0]) begin				//cache hit
			//waitCache <= 0;
			d_cache[0][idx][`LRU] <= 1'b0;
			d_cache[1][idx][`LRU] <= 1'b1;

			if (read_m2) begin
				dataReady_r <= 1;
				waitCache_r <= 0;
				case (bo)
					0: data2_out <= d_cache[0][idx][`BLOCK0];
					1: data2_out <= d_cache[0][idx][`BLOCK1];
					2: data2_out <= d_cache[0][idx][`BLOCK2];
					3: data2_out <= d_cache[0][idx][`BLOCK3];
				endcase
			end
			if (write_m2) begin
				dataReady_w <= 1;
				waitCache_w <= 0;
				case (bo)
					0: d_cache[0][idx][`BLOCK0] <= data2_in;
					1: d_cache[0][idx][`BLOCK1] <= data2_in;
					2: d_cache[0][idx][`BLOCK2] <= data2_in;
					3: d_cache[0][idx][`BLOCK3] <= data2_in;
				endcase
				d_cache[0][idx][`DIRTY] <= 1;
			end
		end else if (hit[1]) begin
			//waitCache <= 0;
			d_cache[1][idx][`LRU] <= 1'b0;
			d_cache[0][idx][`LRU] <= 1'b1;

			if (read_m2) begin
				dataReady_r <= 1;
				waitCache_r <= 0;
				case (bo)
					0: data2_out <= d_cache[1][idx][`BLOCK0];
					1: data2_out <= d_cache[1][idx][`BLOCK1];
					2: data2_out <= d_cache[1][idx][`BLOCK2];
					3: data2_out <= d_cache[1][idx][`BLOCK3];
				endcase
			end
			if (write_m2) begin
				dataReady_w <= 1;
				waitCache_w <= 0;
				case (bo)
					0: d_cache[1][idx][`BLOCK0] <= data2_in;
					1: d_cache[1][idx][`BLOCK1] <= data2_in;
					2: d_cache[1][idx][`BLOCK2] <= data2_in;
					3: d_cache[1][idx][`BLOCK3] <= data2_in;
				endcase
				d_cache[1][idx][`DIRTY] <= 1'b1;				
			end
		end else begin							//cache miss
			
			if (read_m2) begin
				dataReady_r <= 0;
				counter_read <= 5;
				waitCache_r <= 1;
				if(d_cache[way][idx][`DIRTY] == 1) block_write_r <= 1;
				address2_out <= { d_cache[way][idx][`TAG], idx, 2'b00 };
			end else begin
				block_write_r <= 0;
				if (counter_read == 4) begin block_read_r <= 1; address2_out <= { tag, idx, 2'b00 }; end
				else 				   begin block_read_r <= 0; end

				if (counter_read == 1) begin
					dataReady_r <= 1; 
					if(way == 0) begin 
						d_cache[0][idx] <= {tag, 1'b1, 1'b0, 1'b0, block2_in };
						d_cache[1][idx][`LRU] <= 1'b1;
					end
					else if(way == 1) begin
					  	d_cache[1][idx] <= {tag, 1'b1, 1'b0, 1'b0, block2_in };
						d_cache[0][idx][`LRU] <= 1'b1;
					end

					case (bo)
						0: data2_out <= block2_in[`BLOCK0];
						1: data2_out <= block2_in[`BLOCK1];
						2: data2_out <= block2_in[`BLOCK2];
						3: data2_out <= block2_in[`BLOCK3];
					endcase	
				end else begin dataReady_r <= 0; end
				
				if (counter_read == 0) begin waitCache_r <= 0; end

				if (counter_read > 0 && !BG) begin
					counter_read <= counter_read - 1;
				end
			end

			if (write_m2) begin
				dataReady_w <= 0;
				counter_write <= 5;
				waitCache_w <= 1;
				if(d_cache[way][idx][`DIRTY] == 1) block_write_w <= 1;
				address2_out <= { d_cache[way][idx][`TAG], idx, 2'b00 };
			end else begin
				block_write_w <= 0;
				if (counter_write == 4) begin block_read_w <= 1; address2_out <= { tag, idx, 2'b00 }; end
				else 					begin block_read_w <= 0; end
				if (counter_write == 1) begin
					dataReady_w <= 1;
					if (way == 0) begin						
						if(bo == 3) d_cache[0][idx] <= { tag, 1'b1, 1'b1, 1'b0, data2_in, block2_in[`BLOCK2], block2_in[`BLOCK1], block2_in[`BLOCK0]};
						if(bo == 2) d_cache[0][idx] <= { tag, 1'b1, 1'b1, 1'b0, block2_in[`BLOCK3], data2_in, block2_in[`BLOCK1], block2_in[`BLOCK0]};
						if(bo == 1) d_cache[0][idx] <= { tag, 1'b1, 1'b1, 1'b0, block2_in[`BLOCK3], block2_in[`BLOCK2], data2_in, block2_in[`BLOCK0]};
						if(bo == 0) d_cache[0][idx] <= { tag, 1'b1, 1'b1, 1'b0, block2_in[`BLOCK3], block2_in[`BLOCK2], block2_in[`BLOCK1], data2_in};

						d_cache[1][idx][`LRU] <= 1'b1;
					end
					else if (way == 1) begin
						if(bo == 3) d_cache[1][idx] <= { tag, 1'b1, 1'b1, 1'b0, data2_in, block2_in[`BLOCK2], block2_in[`BLOCK1], block2_in[`BLOCK0]};
						if(bo == 2) d_cache[1][idx] <= { tag, 1'b1, 1'b1, 1'b0, block2_in[`BLOCK3], data2_in, block2_in[`BLOCK1], block2_in[`BLOCK0]};
						if(bo == 1) d_cache[1][idx] <= { tag, 1'b1, 1'b1, 1'b0, block2_in[`BLOCK3], block2_in[`BLOCK2], data2_in, block2_in[`BLOCK0]};
						if(bo == 0) d_cache[1][idx] <= { tag, 1'b1, 1'b1, 1'b0, block2_in[`BLOCK3], block2_in[`BLOCK2], block2_in[`BLOCK1], data2_in};

						d_cache[0][idx][`LRU] <= 1'b1;		
					end
				end else begin dataReady_w <= 0; end

				if (counter_write == 0) begin waitCache_w <= 0; end

				if (counter_write > 0 && !BG) begin
					counter_write <= counter_write - 1;
				end
			end
		end
	end
endmodule