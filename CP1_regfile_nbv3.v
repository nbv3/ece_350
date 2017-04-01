module CP1_regfile_nbv3(
	clock, ctrl_writeEnable, ctrl_reset,
	ctrl_writeReg, ctrl_readRegA, ctrl_readRegB,
	data_writeReg, data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;
	
	output [31:0] data_readRegA, data_readRegB;
	
	wire [31:0] oneHotA;
	wire [31:0] oneHotB;
	
	decoder32 dec32A(.code(ctrl_readRegA), .decoding(oneHotA), .enable(1'b1));
	decoder32 dec32B(.code(ctrl_readRegB), .decoding(oneHotB), .enable(1'b1));
	
	wire[31:0] oneHotWrite;
	
	decoder32 dec32Write(.code(ctrl_writeReg), .decoding(oneHotWrite), .enable(1'b1));
	
	genvar i;
	generate
		for (i=0; i<32; i=i+1) begin: loop1
		
			wire [31:0] data_int;
			wire wE;
			and(wE, ctrl_writeEnable, oneHotWrite[i]);
			
			CP1_reg_nbv3 register(.clock(clock), .clear(ctrl_reset), .ctrl_writeEnable(wE),
			.ctrl_outputEnable(1'b1), .data_writeReg(data_writeReg), .data_readReg(data_int));
			
			tri32 regAtri(.data_readReg(data_int), .RS(oneHotA[i]), .buffered_data_readReg(data_readRegA));
			tri32 regBtri(.data_readReg(data_int), .RS(oneHotB[i]), .buffered_data_readReg(data_readRegB));
		end
	endgenerate
				
endmodule


module CP1_reg_nbv3(clock, clear, ctrl_writeEnable, ctrl_outputEnable, 
	data_writeReg, data_readReg);
	
	input clock, clear, ctrl_writeEnable, ctrl_outputEnable;
	input [31:0] data_writeReg;
	
	output [31:0] data_readReg;
	
	wire [31:0] data_int;
		
	genvar i;
	generate
		for (i=0; i<32; i=i+1) begin: loop1
			dffe iter_dff(.d(data_writeReg[i]), .clk(clock), .clrn(~clear), .prn(1'b1), .ena(ctrl_writeEnable),
			.q(data_int[i]));
			assign data_readReg[i] = ctrl_outputEnable ? data_int[i] : 1'bz;
		end
	endgenerate
	
endmodule

module tri32(data_readReg, RS, buffered_data_readReg);
	input [31:0] data_readReg;
	input RS;
	output [31:0] buffered_data_readReg;
	
	genvar i;
	generate
		for (i=0; i<32; i=i+1) begin: loop1
			assign buffered_data_readReg[i] = RS ? data_readReg[i] : 1'bz;
		end
	endgenerate
endmodule

module decoder32(code, decoding, enable);
	input [4:0] code;
	input enable;
	output [31:0] decoding;
	
	and(decoding[0], enable, ~code[4], ~code[3], ~code[2], ~code[1], ~code[0]);
	and(decoding[1], enable, ~code[4], ~code[3], ~code[2], ~code[1], code[0]);
	and(decoding[2], enable, ~code[4], ~code[3], ~code[2], code[1], ~code[0]);
	and(decoding[3], enable, ~code[4], ~code[3], ~code[2], code[1], code[0]);
	and(decoding[4], enable, ~code[4], ~code[3], code[2], ~code[1], ~code[0]);
	and(decoding[5], enable, ~code[4], ~code[3], code[2], ~code[1], code[0]);
	and(decoding[6], enable, ~code[4], ~code[3], code[2], code[1], ~code[0]);
	and(decoding[7], enable, ~code[4], ~code[3], code[2], code[1], code[0]);
	and(decoding[8], enable, ~code[4], code[3], ~code[2], ~code[1], ~code[0]);
	and(decoding[9], enable, ~code[4], code[3], ~code[2], ~code[1], code[0]);
	and(decoding[10], enable, ~code[4], code[3], ~code[2], code[1], ~code[0]);
	and(decoding[11], enable, ~code[4], code[3], ~code[2], code[1], code[0]);
	and(decoding[12], enable, ~code[4], code[3], code[2], ~code[1], ~code[0]);
	and(decoding[13], enable, ~code[4], code[3], code[2], ~code[1], code[0]);
	and(decoding[14], enable, ~code[4], code[3], code[2], code[1], ~code[0]);
	and(decoding[15], enable, ~code[4], code[3], code[2], code[1], code[0]);
	and(decoding[16], enable, code[4], ~code[3], ~code[2], ~code[1], ~code[0]);
	and(decoding[17], enable, code[4], ~code[3], ~code[2], ~code[1], code[0]);
	and(decoding[18], enable, code[4], ~code[3], ~code[2], code[1], ~code[0]);
	and(decoding[19], enable, code[4], ~code[3], ~code[2], code[1], code[0]);
	and(decoding[20], enable, code[4], ~code[3], code[2], ~code[1], ~code[0]);
	and(decoding[21], enable, code[4], ~code[3], code[2], ~code[1], code[0]);
	and(decoding[22], enable, code[4], ~code[3], code[2], code[1], ~code[0]);
	and(decoding[23], enable, code[4], ~code[3], code[2], code[1], code[0]);
	and(decoding[24], enable, code[4], code[3], ~code[2], ~code[1], ~code[0]);
	and(decoding[25], enable, code[4], code[3], ~code[2], ~code[1], code[0]);
	and(decoding[26], enable, code[4], code[3], ~code[2], code[1], ~code[0]);
	and(decoding[27], enable, code[4], code[3], ~code[2], code[1], code[0]);
	and(decoding[28], enable, code[4], code[3], code[2], ~code[1], ~code[0]);
	and(decoding[29], enable, code[4], code[3], code[2], ~code[1], code[0]);
	and(decoding[30], enable, code[4], code[3], code[2], code[1], ~code[0]);
	and(decoding[31], enable, code[4], code[3], code[2], code[1], code[0]);

endmodule

	


	