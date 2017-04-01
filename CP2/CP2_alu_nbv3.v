module CP2_alu_nbv3(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result,
isNotEqual, isLessThan, overflow);
	
	input [31:0] data_operandA, data_operandB;
	input [4:0] ctrl_ALUopcode, ctrl_shiftamt;
	
	output [31:0] data_result;
	output isNotEqual, isLessThan, overflow;
	
	// Organization
	// Declare the output wires from the different modules
	wire [31:0] add_output, subtract_output, shift_left_output, shift_right_output, bitwiseand_output, bitwiseor_output;
	wire add_isNotEqual, subtract_isNotEqual;
	wire add_isLessThan, subtract_isLessThan;
	wire add_overflow, subtract_overflow;
	
	// Feed all necessary data into the different modules
	
	// Compute addition
	adder	addition(data_operandA, data_operandB, add_isNotEqual, add_isLessThan, 
		add_overflow, add_output, 1'b0);
	
	// Compute subtraction
	
	wire [31:0] not_data_operandB;
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)begin: loop0
			assign not_data_operandB[i] = ~data_operandB[i];
		end
	endgenerate
	
	adder subtraction(data_operandA, not_data_operandB, subtract_isNotEqual, subtract_isLessThan, subtract_overflow, subtract_output, 1'b1);
	
	// Compute shift left
	
	logicalleft shiftleft(data_operandA, ctrl_shiftamt, shift_left_output);
	
	// Compute shift right
	
	arithmeticright shiftright(data_operandA, ctrl_shiftamt, shift_right_output);
	
	// Compute bitwise and
	
	bitwiseand bitand(data_operandA, data_operandB, bitwiseand_output);
	
	// Compute bitwise or
	
	bitwiseor bitor(data_operandA, data_operandB, bitwiseor_output);
	
	
	
	// User ternary's to assign the outputs to the data_result for different opcodes
	// Build a ternary tree
	
	// least significant bit of ALUopcode
	wire [31:0] branch0, branch1;
	assign data_result = (ctrl_ALUopcode[0]) ? branch1 : branch0;
	
	// second least significant bit
	wire [31:0] branch00, branch01, branch10, branch11;
	assign branch0 = (ctrl_ALUopcode[1] == 1'b1) ? branch10 : branch00;
	assign branch1 = (ctrl_ALUopcode[1] == 1'b1) ? branch11 : branch01;
	
	// third least significant bit
	wire [31:0] branch000, branch001, branch100, branch101;
	assign branch00 = (ctrl_ALUopcode[2] == 1'b1) ? branch100 : branch000;
	assign branch01 = (ctrl_ALUopcode[2] == 1'b1) ? branch101 : branch001;
	
	// tie the ends together
	assign branch000 = add_output;
	assign branch100 = shift_left_output;
	assign branch10 = bitwiseand_output;
	assign branch11 = bitwiseor_output;
	assign branch001 = subtract_output;
	assign branch101 = shift_right_output;
	
	// tree for the other output
	assign isNotEqual = subtract_isNotEqual;
	assign isLessThan = subtract_isLessThan;
	assign overflow = (ctrl_ALUopcode[0]) ? subtract_overflow : add_overflow;
	
endmodule 

module bitwiseor(data_operandA, data_operandB, result);

	input [31:0] data_operandA, data_operandB;
	output [31:0] result;
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)begin: loop7
			or oriter(result[i], data_operandA[i], data_operandB[i]);
		end
	endgenerate


endmodule

module bitwiseand(data_operandA, data_operandB, result);

	input [31:0] data_operandA, data_operandB;
	output [31:0] result;
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)begin: loop6
			and anditer(result[i], data_operandA[i], data_operandB[i]);
		end
	endgenerate


endmodule

module arithmeticright(data_operandA, ctrl_shiftamt, result);
	
	// Maintain the sign bit
	
	input [31:0] data_operandA;
	input [4:0] ctrl_shiftamt;
	
	output [31:0] result;
	
	// Shift by 16 first
	wire [31:0] shifted_16, after_stage0;
	
	// first maintain the sign bit
	genvar i;
	generate
		for (i = 31; i >= 16; i = i - 1)begin: loop23
			assign shifted_16[i] = data_operandA[31];
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 15; i >= 0; i = i - 1)begin: loop24
			assign shifted_16[i] = data_operandA[i + 16];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage0 = (ctrl_shiftamt[4]) ? shifted_16 : data_operandA;
	
	
	
	// Shift by 8 
	wire [31:0] shifted_8, after_stage1;
	
	// first maintain the sign bit
	generate
		for (i = 31; i >= 24; i = i - 1)begin: loop6
			assign shifted_8[i] = after_stage0[31];
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 23; i >= 0; i = i - 1)begin: loop7
			assign shifted_8[i] = after_stage0[i + 8];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage1 = (ctrl_shiftamt[3]) ? shifted_8 : after_stage0;
	
	// Shift by 4
	
	wire [31:0] shifted_4, after_stage2;
	
// first maintain the sign bit
	generate
		for (i = 31; i >= 28; i = i - 1)begin: loop8
			assign shifted_4[i] = after_stage1[31];
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 27; i >= 0; i = i - 1)begin: loop9
			assign shifted_4[i] = after_stage1[i + 4];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage2 = (ctrl_shiftamt[2]) ? shifted_4 : after_stage1;

	// Shift by 2
	
	wire [31:0] shifted_2, after_stage3;
	
// first maintain the sign bit
	generate
		for (i = 31; i >= 30; i = i - 1)begin: loop10
			assign shifted_2[i] = after_stage2[31];
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 29; i >= 0; i = i - 1)begin: loop11
			assign shifted_2[i] = after_stage2[i + 2];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage3 = (ctrl_shiftamt[1]) ? shifted_2 : after_stage2;

	// Shift by 1
	
	wire [31:0] shifted_1, after_stage4;
	
// first maintain the sign bit
	generate
		for (i = 31; i >= 31; i = i - 1)begin: loop12
			assign shifted_1[i] = after_stage3[31];
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 30; i >= 0; i = i - 1)begin: loop13
			assign shifted_1[i] = after_stage3[i + 1];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage4 = (ctrl_shiftamt[0]) ? shifted_1 : after_stage3;
	assign result = after_stage4;
	

endmodule

module logicalleft(data_operandA, ctrl_shiftamt, result);

	// Does not maintain sign bit

	input [31:0] data_operandA;
	input [4:0] ctrl_shiftamt;
	
	output [31:0] result;
	
	// Shift by 8 first
	wire [31:0] shifted_16, after_stage0;
	
	// fill with 0's on the right
	genvar i;
	generate
		for (i = 0; i < 16; i = i + 1)begin: loop30
			assign shifted_16[i] = 1'b0;
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 16; i < 32; i = i + 1)begin: loop22
			assign shifted_16[i] = data_operandA[i - 16];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage0 = (ctrl_shiftamt[4]) ? shifted_16 : data_operandA;
	

	// Shift by 8 
	wire [31:0] shifted_8, after_stage1;
	
	// fill with 0's on the right
	generate
		for (i = 0; i < 8; i = i + 1)begin: loop14
			assign shifted_8[i] = 1'b0;
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 8; i < 32; i = i + 1)begin: loop15
			assign shifted_8[i] = after_stage0[i - 8];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage1 = (ctrl_shiftamt[3]) ? shifted_8 : after_stage0;
	
	// Shift by 4
	wire [31:0] shifted_4, after_stage2;
	
	// fill with 0's on the right
	generate
		for (i = 0; i < 4; i = i + 1)begin: loop16
			assign shifted_4[i] = 1'b0;
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 4; i < 32; i = i + 1)begin: loop17
			assign shifted_4[i] = after_stage1[i - 4];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage2 = (ctrl_shiftamt[2]) ? shifted_4 : after_stage1;
	
	// Shift by 2
	wire [31:0] shifted_2, after_stage3;
	
	// fill with 0's on the right
	generate
		for (i = 0; i < 2; i = i + 1)begin: loop18
			assign shifted_2[i] = 1'b0;
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 2; i < 32; i = i + 1)begin: loop19
			assign shifted_2[i] = after_stage2[i - 2];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage3 = (ctrl_shiftamt[1]) ? shifted_2 : after_stage2;
	
	// Shift by 2
	wire [31:0] shifted_1, after_stage4;
	
	// fill with 0's on the right
	generate
		for (i = 0; i < 1; i = i + 1)begin: loop20
			assign shifted_1[i] = 1'b0;
		end
	endgenerate
	
	// then shift the rest
	generate
		for (i = 1; i < 32; i = i + 1)begin: loop21
			assign shifted_1[i] = after_stage3[i - 1];
		end
	endgenerate
	
	// should the shifted part move on to the next stage?
	
	assign after_stage4 = (ctrl_shiftamt[0]) ? shifted_1 : after_stage3;
	assign result = after_stage4;
	
endmodule


module adder(data_operandA, data_operandB, isNotEqual, isLessThan, 
overflow, adder_output, cin);

	input [31:0] data_operandA, data_operandB;
	input cin;
	
	output [31:0] adder_output;
	output isNotEqual, isLessThan, overflow;
	
	// Setup Overflow Logic
	wire matched_msb;
	wire different_sign;
	assign matched_msb = (data_operandA[31] == data_operandB[31]) ? 1'b1 : 1'b0; 
	xor diffxor(different_sign, data_operandA[31], adder_output[31]);
	and overflowand(overflow, matched_msb, different_sign);
	
	// Setup isNotEqual Logic
	assign isNotEqual = (adder_output == 32'b0) ? 1'b0 : 1'b1;
	
	// Setup isLessThan Logic
	// IF A - B is negative, then yeah, it's less than
	wire posDiff;
	assign posDiff = (adder_output[31] == 1'b0) ? 1'b0 : 1'b1;
	xor isLessThanXOR(isLessThan, posDiff, overflow);
	
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
	
	