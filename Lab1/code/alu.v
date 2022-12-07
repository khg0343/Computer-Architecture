`include "alu_func.v"
module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C,
    output reg OverflowFlag
);
	wire wireOverflowFlag;
	wire [data_width - 1: 0] wireAddnSubC;
	wire [data_width - 1: 0] wireBitwiseC;
	wire [data_width - 1: 0] wireShiftC;
	wire [data_width - 1: 0] wireOtherC;

	ALU_AddnSub #(16) AddnSub(A, B, FuncCode, wireAddnSubC, wireOverflowFlag);
	ALU_Bitwise #(16) Bitwise(A, B, FuncCode, wireBitwiseC);
	ALU_Shift 	#(16) Shift(A, FuncCode, wireShiftC);
	ALU_Other	#(16) Other(A, FuncCode, wireOtherC);

	initial begin
		C = 0;
		OverflowFlag = 0;
	end   	

	always @(*) begin
		OverflowFlag <= 0;
		if (FuncCode >= 0 && FuncCode < 2) begin
			C <= wireAddnSubC;
			OverflowFlag <= wireOverflowFlag;
		end
		else if (FuncCode >= 3 && FuncCode < 10) begin
			C <= wireBitwiseC;
		end
		else if (FuncCode >= 10 && FuncCode < 14) begin
			C <= wireShiftC;
		end
		else begin
			C <= wireOtherC;
		end
	end
endmodule

module ALU_AddnSub #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C,
    output reg OverflowFlag
);
	always @(*) begin
		case(FuncCode)
			`FUNC_ADD : begin
				C <= A + B;
				if((A[data_width - 1] == B[data_width - 1]) && (A[data_width - 1] != C[data_width - 1])) OverflowFlag <= 1;
				else OverflowFlag <= 0;
			end
			`FUNC_SUB : begin
				C <= A - B;
				if ((A[data_width-1] == 0 && B[data_width-1] == 1 && C[data_width-1] == 1) || (A[data_width-1] == 1 && B[data_width-1] == 0 && C[data_width-1] == 0)) OverflowFlag <= 1;
				else OverflowFlag <= 0;
			end
			default   : C <= 0;  				//do nothing
		endcase

		
	end

endmodule

module ALU_Bitwise #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [data_width - 1 : 0] B, 
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C
);

	always @(*) begin
		case(FuncCode)
			`FUNC_NOT  : C <= ~ A;
			`FUNC_AND  : C <= A & B;
			`FUNC_OR   : C <= A | B;
			`FUNC_NAND : C <= ~(A & B);
			`FUNC_NOR  : C <= ~(A | B);
			`FUNC_XOR  : C <= A ^ B;
			`FUNC_XNOR : C <= ~(A ^ B);
			default    : C <= 0; 				//do nothing
		endcase
	end

endmodule

module ALU_Shift #(parameter data_width = 16) (
	input [data_width - 1 : 0] A, 
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C
);

	always @(*) begin
		case(FuncCode)
			`FUNC_LLS  : C <= A << 1;
			`FUNC_LRS  : C <= A >> 1;
			`FUNC_ALS  : C <= A <<< 1;
			`FUNC_ARS  : begin 
				C <= A >>> 1;
				if (A[data_width - 1] == 1) C[data_width - 1] <= 1;
			end
			default : C <= 0; 				//do nothing
		endcase
	end

endmodule

module ALU_Other #(parameter data_width = 16) (
	input [data_width - 1 : 0] A,
	input [3 : 0] FuncCode,
    output reg [data_width - 1: 0] C
);

	always @(*) begin
		case(FuncCode)
			`FUNC_ID   : C <= A;
			`FUNC_TCP  : C <= ~A + 1;
			`FUNC_ZERO : C <= 0;
			default : C <= 0; 				//do nothing
		endcase
	end

endmodule