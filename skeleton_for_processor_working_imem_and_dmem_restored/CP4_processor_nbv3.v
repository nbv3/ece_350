module CP4_processor_nbv3(clock, reset, /*ps2_key_pressed, ps2_out, lcd_write, lcd_data,*/ dmem_data_in, dmem_address, dmem_out);

	input 			clock, reset/*, ps2_key_pressed*/;
	//input 	[7:0]	ps2_out;
	
	//output 			lcd_write;
	//output 	[31:0] 	lcd_data;
	
	// GRADER OUTPUTS - YOU MUST CONNECT TO YOUR DMEM
	output 	[31:0] 	dmem_data_in, dmem_out;
	output	[11:0]   dmem_address;
	
	wire writeEnable;
	wire [31:0] data_writeReg;

	
	// Testing
   fetch_stage fetch(clock, reset, pc_wires, pc_wires, instruction_wires);
	wire [11:0] fetch_pipe_pc;
	wire [31:0] fetch_pipe_instruction;
	FDPipe fdpipe(clock, reset, pc_wires, instruction_wires, pipepc, pipeinst);
	wire [11:0] pipe_decode_pc;
	wire [31:0] pipe_decode_instruction;
	decode_stage decode(clock, reset, ctrl_writeEnable, data_writeReg, pipe_decode_pc, pipe_decode_instruction,
								decode_pipe_pc, decode_pipe_instruction, rs, rt);
	wire [11:0] decode_pipe_pc;
	wire [31:0] decode_pipe_instruction;
	wire [31:0] rs, rt;
	DXPipe dxpipe(clock, reset, )
	
	// your processor here
	
	//
	
	//////////////////////////////////////
	////// THIS IS REQUIRED FOR GRADING
	// CHANGE THIS TO ASSIGN YOUR DMEM WRITE ADDRESS ALSO TO debug_addr
//	assign dmem_address = (12'b000000000001);
	// CHANGE THIS TO ASSIGN YOUR DMEM DATA INPUT (TO BE WRITTEN) ALSO TO debug_data
//	assign dmem_data_in = (12'b000000000000);
	////////////////////////////////////////////////////////////

	
	
	// You'll need to change where the dmem and imem read and write...
	dmem mydmem(.address	(dmem_address),
					.clock		(clock),
					.data		(debug_data),
					.wren		(1'b1), //,	//need to fix this!
					.q			(dmem_out) // change where output q goes...
	);
	
	
	
endmodule

module DXPipe(clock, reset, in_pc, in_instruction, in_rs, in_rt, out_pc, out_instruction, out_rs, out_rt);
	
	input clock, reset;
	
	input [11:0] in_pc;
	input [31:0] in_instruction, in_rs, in_rt;
	
	output [11:0] out_pc;
	output [31:0] out_instruction, out_rs, out_rt;
	
	CP1_reg_nbv3 pc_latch(clock, clear, 1'b1, 1'b1, in_pc, out_pc);
	CP1_reg_nbv3 instruction_latch(clock, clear, 1'b1, 1'b1, in_instruction, out_instruction);
	CP1_reg_nbv3 rs_latch(clock, clear, 1'b1, 1'b1, in_rs, out_rs);
	CP1_reg_nbv3 rt_latch(clock, clear, 1'b1, 1'b1, in_rt, out_rt);
	
endmodule

module decode_stage(clock, reset, ctrl_writeEnable, data_writeReg, in_pc, in_instruction, out_pc, out_instruction, out_rs, out_rt);
	
	input clock, reset;
	input [11:0] in_pc;
	input [31:0] in_instruction, data_writeReg;
	input ctrl_writeEnable;
	
	output [11:0] out_pc;
	output [31:0] out_instruction, out_rs, out_rt;
	
	assign out_pc = in_pc;
	assign out_instruction = in_instruction;
	
	CP1_regfile_nbv3 regfile(
	clock, ctrl_writeEnable, reset,
	in_instruction[26:22], in_instruction[21:17], in_instruction[16:12],
	data_writeReg, out_rs, out_rt);
	
	
endmodule

module FDPipe(clock, reset, in_pc, in_instruction, out_pc, out_instruction);
	
	input clock, reset;
	
	input [11:0] in_pc;
	input [31:0] in_instruction;
	
	output [11:0] out_pc;
	output [31:0] out_instruction;
	
	CP1_reg_nbv3 pc_latch(clock, clear, 1'b1, 1'b1, in_pc, out_pc);
	CP1_reg_nbv3 instruction_latch(clock, clear, 1'b1, 1'b1, in_instruction, out_instruction);
	
endmodule

module fetch_stage(clock, reset, in_address, next_address, out_instruction);
	
	input clock, reset;
	input [11:0] in_address;
	output [31:0] out_instruction;
	output [11:0] next_address;
	
	wire [11:0] out_address;
	wire overflow;

	program_counter pc(.clock(clock), .reset(reset), .in_address(in_address), .out_address(out_address));
	
	adder next_instruction(out_address, 32'd1, overflow, next_address, 1'b0);
	
	imem myimem(.address 	(out_address),
					.clken		(1'b1),
					.clock		(~clock), //,
					.q			(out_instruction) // change where output q goes...
	); 
	
endmodule

module program_counter(clock, reset, in_address, out_address);

	// Note that the program_counter is 12 bits wide
	
	input [11:0] in_address;
	output [11:0] out_address;
	input clock, reset;
	
	CP1_reg_nbv3 register(.clock(clock), .clear(reset), .ctrl_writeEnable(1'b1), 
	.ctrl_outputEnable(1'b1), .data_writeReg(in_address), .data_readReg(out_address));
	
	
endmodule

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
	// ctrl_outputEnable should be high
	
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

module adder(data_operandA, data_operandB,
overflow, adder_output, cin);

	input [31:0] data_operandA, data_operandB;
	input cin;
	
	output [31:0] adder_output;
	output overflow;
	
	// Setup Overflow Logic
	wire matched_msb;
	wire different_sign;
	assign matched_msb = (data_operandA[31] == data_operandB[31]) ? 1'b1 : 1'b0; 
	xor diffxor(different_sign, data_operandA[31], adder_output[31]);
	and overflowand(overflow, matched_msb, different_sign);
	
	// Setting up cascaded blocks
	// First build c8, c16, c24, c32
	
	wire c8, c16, c24, c32;
	wire [3:0] P;
	wire [3:0] G;
	
	// build c8
	wire P0cin;
	and P0andcin(P0cin, cin, P[0]);
	or c8or(c8, P0cin, G[0]);
	
	// build c16
	wire P1P0cin;
	and P1P0andcin(P1P0cin, P[1], P[0], cin);
	wire P1G0;
	and P1andG0(P1G0, P[1], G[0]);
	or c16or(c16, P1G0, G[1], P1P0cin);
	
	// build c24
	wire P2P1P0cin;
	and P2P1P0andcin(P2P1P0cin, P[2], P[1], P[0], cin);
	wire P2P1G0;
	and P2P1andG0(P2P1G0, P[2], P[1], G[0]);
	wire P2G1;
	and P2andG1(P2G1, P[2], G[1]);
	or c24or(c24, P2P1G0, G[2], P2P1P0cin, P2G1);
	
	// build c32
	wire P3P2P1P0cin;
	and P3P2P1P0andcin(P3P2P1P0cin, P[3], P[2], P[1], P[0], cin);
	wire P3P2P1G0;
	and P3P2P1andG0(P3P2P1G0, P[3], P[2], P[1], G[0]);
	wire P3P2G1;
	and P3P2andG1(P3P2G1, P[3], P[2], G[1]);
	wire P3G2;
	and P3andG2(P3G2, P[3], G[2]);
	or c32or(c32, P3P2P1P0cin, P3P2P1G0, P3P2G1, P3G2, G[3]);
	
	// declare blocks
	cla_block block0(.bits_operandA(data_operandA[7:0]), .bits_operandB(data_operandB[7:0]), .cin(cin), 
	.block_output(adder_output[7:0]), .P(P[0]), .G(G[0]));
	
	cla_block block1(.bits_operandA(data_operandA[15:8]), .bits_operandB(data_operandB[15:8]), .cin(c8), 
	.block_output(adder_output[15:8]), .P(P[1]), .G(G[1]));
	
	cla_block block2(.bits_operandA(data_operandA[23:16]), .bits_operandB(data_operandB[23:16]), .cin(c16), 
	.block_output(adder_output[23:16]), .P(P[2]), .G(G[2]));
	
	cla_block block3(.bits_operandA(data_operandA[31:24]), .bits_operandB(data_operandB[31:24]), .cin(c24), 
	.block_output(adder_output[31:24]), .P(P[3]), .G(G[3]));
	
endmodule

module cla_block(bits_operandA, bits_operandB, cin, block_output, P, G);

	input [7:0] bits_operandA, bits_operandB;
	input cin;
	
	output [7:0] block_output;
	output P, G;
	
	// instantiate the 8 1 bit adders
	
	// start by defining the prop and gen signals, building the cout vals
	wire [7:0] gensignals;
	wire [7:0] propsignals;
	wire [8:1] coutsignals;
	
	wire pc0;
	and pcand0(pc0, propsignals[0], cin);
	or gpcor0(coutsignals[1], pc0, gensignals[0]);
	
	wire pc1;
	and pcand1(pc1, propsignals[0], propsignals[1], cin);
	wire pc11;
	and pcand11(pc11, propsignals[1], gensignals[0]);
	or gpcor1(coutsignals[2], gensignals[1], pc11, pc1);
	
	wire pc2;
	and pcand2(pc2, propsignals[0], propsignals[1], propsignals[2], cin);
	wire pc21;
	and pcand21(pc21, propsignals[1], propsignals[2], gensignals[0]);
	wire pc22;
	and pcand22(pc22, propsignals[2], gensignals[1]);
	or gpcor2(coutsignals[3], gensignals[2], pc2, pc21, pc22);

	wire pc3;
	and pcand3(pc3, propsignals[0], propsignals[1], propsignals[2], propsignals[3], cin);
	wire pc31;
	and pcand31(pc31, propsignals[1], propsignals[2], propsignals[3], gensignals[0]);
	wire pc32;
	and pcand32(pc32, propsignals[2], propsignals[3], gensignals[1]);
	wire pc33;
	and pcand33(pc33, propsignals[3], gensignals[2]);
	or gpcor3(coutsignals[4], gensignals[3], pc3, pc31, pc32, pc33);
	
	wire pc4;
	and pcand4(pc4, propsignals[0], propsignals[1], propsignals[2], propsignals[3], propsignals[4], cin);
	wire pc41;
	and pcand41(pc41, propsignals[1], propsignals[2], propsignals[3], propsignals[4], gensignals[0]);
	wire pc42;
	and pcand42(pc42, propsignals[2], propsignals[3], propsignals[4], gensignals[1]);
	wire pc43;
	and pcand43(pc43, propsignals[3], propsignals[4], gensignals[2]);
	wire pc44;
	and pcand44(pc44, propsignals[4], gensignals[3]);
	or gpcor4(coutsignals[5], gensignals[4], pc4, pc41, pc42, pc43, pc44);
	
	wire pc5;
	and pcand5(pc5, propsignals[0], propsignals[1], propsignals[2], propsignals[3], propsignals[4], propsignals[5], cin);
	wire pc51;
	and pcand51(pc51, propsignals[1], propsignals[2], propsignals[3], propsignals[4], propsignals[5], gensignals[0]);
	wire pc52;
	and pcand52(pc52, propsignals[2], propsignals[3], propsignals[4], propsignals[5], gensignals[1]);
	wire pc53;
	and pcand53(pc53, propsignals[3], propsignals[4], propsignals[5], gensignals[2]);
	wire pc54;
	and pcand54(pc54, propsignals[4], propsignals[5], gensignals[3]);
	wire pc55;
	and pcand55(pc55, propsignals[5], gensignals[4]);
	or gpcor5(coutsignals[6], gensignals[5], pc5, pc51, pc52, pc53, pc54, pc55);
	
	wire pc6;
	and pcand6(pc6, propsignals[0], propsignals[1], propsignals[2], propsignals[3], propsignals[4], propsignals[5], propsignals[6], cin);
	wire pc61;
	and pcand61(pc61, propsignals[1], propsignals[2], propsignals[3], propsignals[4], propsignals[5], propsignals[6], gensignals[0]);
	wire pc62;
	and pcand62(pc62, propsignals[2], propsignals[3], propsignals[4], propsignals[5], propsignals[6], gensignals[1]);
	wire pc63;
	and pcand63(pc63, propsignals[3], propsignals[4], propsignals[5], propsignals[6], gensignals[2]);
	wire pc64;
	and pcand64(pc64, propsignals[4], propsignals[5], propsignals[6], gensignals[3]);
	wire pc65;
	and pcand65(pc65, propsignals[5], propsignals[6], gensignals[4]);
	wire pc66;
	and pcand66(pc66, propsignals[6], gensignals[5]);
	or gpcor6(coutsignals[7], gensignals[6], pc6, pc61, pc62, pc63, pc64, pc65, pc66);

	// Build the big G, P values
	
	and pcand7(P, propsignals[0], propsignals[1], propsignals[2], propsignals[3], propsignals[4], propsignals[5], propsignals[6], propsignals[7]);

	wire pc71;
	and pcand71(pc71, propsignals[1], propsignals[2], propsignals[3], propsignals[4], propsignals[5], propsignals[6], propsignals[7], gensignals[0]);
	wire pc72;
	and pcand72(pc72, propsignals[2], propsignals[3], propsignals[4], propsignals[5], propsignals[6], propsignals[7], gensignals[1]);
	wire pc73;
	and pcand73(pc73, propsignals[3], propsignals[4], propsignals[5], propsignals[6], propsignals[7], gensignals[2]);
	wire pc74;
	and pcand74(pc74, propsignals[4], propsignals[5], propsignals[6], propsignals[7], gensignals[3]);
	wire pc75;
	and pcand75(pc75, propsignals[5], propsignals[6], propsignals[7], gensignals[4]);
	wire pc76;
	and pcand76(pc76, propsignals[6], propsignals[7], gensignals[5]);
	wire pc77;
	and pcand77(pc77, propsignals[7], gensignals[6]);
	or gpcor7(G, gensignals[7], pc71, pc72, pc73, pc74, pc75, pc76, pc77);
	
	
	// instantiate bit adders, first one is special case
	bit_adder ba(.bit_A(bits_operandA[0]), .bit_B(bits_operandB[0]), .sum(block_output[0]), .cin(cin),
	.g(gensignals[0]), .p(propsignals[0]));
	
	genvar i;
	generate
		for (i = 1; i <= 7; i = i+1) begin: loop3
			bit_adder baiter(.bit_A(bits_operandA[i]), .bit_B(bits_operandB[i]), .sum(block_output[i]),
			.cin(coutsignals[i]), .g(gensignals[i]), .p(propsignals[i]));
		end
	endgenerate			
	
	
	
endmodule

module bit_adder(bit_A, bit_B, sum, cin, g, p);
	
	input bit_A, bit_B, cin;
	output sum, g, p;
	
	// create generate and propagate signals
	and gensignal(g, bit_A, bit_B);
	or propsignal(p, bit_A, bit_B);
	
	// calculate the sum bit
	xor sumcalc(sum, bit_A, bit_B, cin);
	
	// dont need to calculate carry out since this is CLA
	
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
