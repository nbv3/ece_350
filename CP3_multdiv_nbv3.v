module CP3_multdiv_nbv3(data_operandA, data_operandB, ctrl_MULT, ctrl_DIV,
	clock, data_result, data_exception, data_resultRDY);
	
	input [31:0] data_operandA, data_operandB;
	input ctrl_DIV, ctrl_MULT, clock;

	output [31:0] data_result;
	output data_exception, data_resultRDY;
	
	
	wire [31:0] multResult, divResult;
	wire multException, divException;
	wire multReady, divReady;
	
	mult multiplier(data_operandA, data_operandB, ctrl_MULT,
	clock, multResult, multException, multReady);
	
	div divider(data_operandA, data_operandB, ctrl_DIV,
	clock, divResult, divException, divReady);
	
	wire multiplying;
	wire enable;
	or enableFF(enable, ctrl_DIV, ctrl_MULT);
	dffe shouldMult(.clk(clock), .prn(1'b1), .ena(enable),
			.d(ctrl_MULT), .q(multiplying));
			
	assign data_result = (multiplying == 1'b1) ? multResult : divResult;
	assign data_resultRDY = (multiplying == 1'b1) ? multReady : divReady;
	assign data_exception = (multiplying == 1'b1) ? multException : divException;
	
endmodule

module div(data_operandA, data_operandB, ctrl_DIV,
	clock, data_result, data_exception, data_resultRDY);

	input [31:0] data_operandA, data_operandB;
	input ctrl_DIV, clock;

	output [31:0] data_result;
	output data_exception, data_resultRDY;
	
	wire [31:0] dividend_from_ctrl, quotient_from_ctrl;
	wire [31:0] in_dividend, out_dividend;
	wire [31:0] in_quotient, out_quotient;
	wire [31:0] divisor;
	wire [31:0] dividend;
	
	assign data_exception = (divisor == 32'd0) ? 1'b1 : 1'b0;
	
	genvar i;

	// Going to negate both operands
	
	wire [31:0] negated_operandA, negated_operandB;
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop25
			assign negated_operandA[i] = ~data_operandA[i];
			assign negated_operandB[i] = ~data_operandB[i];
		end
	endgenerate
	
	wire [31:0] complement_A, complement_B;
	wire ov1, ov2;
	adder complementA(negated_operandA, 32'd0, ov1, complement_A, 1'b1);
	adder complementB(negated_operandB, 32'd0, ov2, complement_B, 1'b1);
	//
	
	assign dividend = (data_operandA[31] == 1'b1) ? complement_A : data_operandA;
	assign divisor = (data_operandB[31] == 1'b1) ? complement_B : data_operandB;
	
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop15
			dffe iter_dffe(.clk(clock), .clrn(~ctrl_DIV), .prn(1'b1), .ena(1'b1),
			.d(in_quotient[i]), .q(out_quotient[i]));
		end 
	endgenerate

	generate
		for (i = 0; i < 32; i = i + 1) begin: loop16
			dffe iter_dffe(.clk(clock), .clrn(1'b1), .prn(1'b1), .ena(1'b1),
			.d(in_dividend[i]), .q(out_dividend[i]));
		end 
	endgenerate
	
	divControl divC(.divisor(divisor), .in_dividend(out_dividend), .out_dividend(dividend_from_ctrl),
	.in_quotient(out_quotient), .out_quotient(quotient_from_ctrl), .clock(clock), .ready(data_resultRDY), .reset(ctrl_DIV));
	
	assign in_dividend = (ctrl_DIV == 1'b1) ? dividend : dividend_from_ctrl;
	assign in_quotient = quotient_from_ctrl;
	
	// Make sure to check to negate
	wire [31:0] negated_quotient;
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop30
			assign negated_quotient[i] = ~out_quotient[i];
		end
	endgenerate
	
	wire [31:0] complement_quotient;
	wire ov3;
	adder complementQ(negated_quotient, 32'd0, ov3, complement_quotient, 1'b1);
	
	wire shouldNegate;
	xor checkToNegate(shouldNegate, data_operandA[31], data_operandB[31]);
	assign data_result = (shouldNegate == 1'b1) ? complement_quotient : out_quotient;
	
endmodule

module divControl(divisor, in_dividend, out_dividend, in_quotient, out_quotient, clock, ready, reset);
	
	input [31:0] divisor, in_dividend, in_quotient;
	input clock, reset;
	
	output [31:0] out_dividend, out_quotient;
	output ready;
	
	
		
	// Instantiate counter
	wire [6:0] counter_out;
	counter32DIV counter(clock, reset, counter_out);
	wire [31:0] full_counter_out;
	assign full_counter_out = {25'd0, counter_out};
	wire [31:0] not_full_counter_out;
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop20
			assign not_full_counter_out[i] = ~full_counter_out[i];
		end
	endgenerate	
	
	wire over;
	wire [31:0] shiftAmt;
	adder getShiftAmt(32'd31, not_full_counter_out, over, shiftAmt, 1'b1);
	
	
	
	
	// Now you have the shift amount
	
	assign ready = (shiftAmt[31] == 1'b1) ? 1'b1 : 1'b0;
	
	wire [31:0] shifted_dividend_wires;
	assign shifted_dividend_wires = (shiftAmt[31] == 1'b0) ? in_dividend >> shiftAmt : in_dividend >> 0;

	
	wire overflow1;
	wire [31:0] not_divisor;
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop10
			assign not_divisor[i] = ~divisor[i];
		end
	endgenerate
	
	wire [31:0] difference;
	wire shouldAdd;
	adder divisorGTdividend(shifted_dividend_wires, not_divisor, overflow1, difference, 1'b1);
	assign shouldAdd = (difference[31] == 1'b1) ? 1'b0 : 1'b1;
	
	// Now you know whether or not to add a bit in the spot
	
	wire overflow3;
	wire [31:0] incremQuotient;
	adder quotientplusone(in_quotient, 32'd1, overflow3, incremQuotient, 1'b0);
	
	wire [31:0] before_shift;
	assign before_shift = (shouldAdd == 1'b0) ? in_quotient: incremQuotient;
		
	assign out_quotient = ((shiftAmt[31] == 1'b1) || (shiftAmt == 32'd0)) ? before_shift : before_shift << 1;
	
	// You have assigned the output quotient, now calculate the new dividend
	
	wire [31:0] shifted_divisor_wires;
	wire overflow2;
	wire [31:0] new_dividend;
	assign shifted_divisor_wires = divisor << shiftAmt;
	wire [31:0] not_shifted_divisor_wires;
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop11
			assign not_shifted_divisor_wires[i] = ~shifted_divisor_wires[i];
		end
	endgenerate
	
	adder smallerDividend(in_dividend, not_shifted_divisor_wires, overflow2, new_dividend, 1'b1);
	
	assign out_dividend = (shouldAdd == 1'b0) ? in_dividend : new_dividend;
endmodule

module mult(data_operandA, data_operandB, ctrl_MULT,
	clock, data_result, data_exception, data_resultRDY);
	
	input [31:0] data_operandA, data_operandB;
	input ctrl_MULT, clock;

	output [31:0] data_result;
	output data_exception, data_resultRDY;
	
	wire [31:0] in_product_bits, in_multiplier_bits;
	wire in_edgeBit;
	
	wire [31:0] out_multiplier_bits, out_product_bits;
	wire out_edgeBit;
	
	wire [31:0] product_result, multiplier_result;
	wire edgeBit_result;
	
	assign in_multiplier_bits = (ctrl_MULT == 1'b0) ? multiplier_result : data_operandB;
	assign in_product_bits = product_result;
	assign in_edgeBit = edgeBit_result;
	assign data_result = out_multiplier_bits;
	
	// Check for overflow
//	wire [31:0] bus;
//	assign bus[31] = data_result[31];
//	wire [31:0] bus2;
//	assign bus2 = bus >>> 31;
//	
//	wire ovahflow;
//	wire [31:0] diff;
//	adder overflowdiff(bus2, out_product_bits, ovahflow, diff, 1'b1);
//	
//	assign data_exception = (diff == 32'd0) ? 1'b0 : 1'b1;

	wire [31:0] bus;
	genvar i;
	generate
		for (i = 0 ; i < 32 ; i = i + 1)begin: loop31
			assign bus[i] = data_result[31];
		end
	endgenerate
	
	wire over;
	wire [31:0] diff;
	adder overflowdiff(bus, out_product_bits, over, diff, 1'b1);
	
	assign data_exception = (diff == 32'd0) ? 1'b0 : 1'b1;

//	wire shouldNeg;
//	xor shouldNegCheck(shouldNeg, data_operandA[31], data_operandB[31]);
//	
//	wire signResult;
//	assign signResult = data_result[31];
//	
//	assign data_exception = (((signResult == 1'b1 && shouldNeg == 1'b0) || (signResult == 1'b0 && shouldNeg == 1'b1)) && (data_result != 32'd0));
//	
	
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop1
			dffe iter_dffe(.clk(clock), .clrn(~ctrl_MULT), .prn(1'b1), .ena(1'b1),
			.d(in_product_bits[i]), .q(out_product_bits[i]));
		end 
	endgenerate
	

	
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop2
			dffe iter_dffe(.clk(clock), .clrn(1'b1), .prn(1'b1), .ena(1'b1),
			.d(in_multiplier_bits[i]), .q(out_multiplier_bits[i]));
		end
	endgenerate
	
	dffe edge_dffe(.clk(clock), .clrn(~ctrl_MULT), .prn(1'b1), .ena(1'b1),
			.d(in_edgeBit), .q(out_edgeBit));
			
	multControlBlock cb(.input_product(out_product_bits), .input_multiplicand(data_operandA), .input_multiplier(out_multiplier_bits),
	.output_product(product_result), .output_multiplier(multiplier_result), .clock(clock), .input_edgeBit(out_edgeBit), 
	.output_edgeBit(edgeBit_result), .lastBit(out_multiplier_bits[0]), .ready(data_resultRDY), .reset(ctrl_MULT));
	
	
	
endmodule


module counter32DIV(clock, reset, out);
	input clock, reset;
	output [6:0] out;
	reg [6:0] next;
	
	dff dff0(.d(next[0]), .clk(clock), .q(out[0]), .clrn(~reset)); 
	dff dff1(.d(next[1]), .clk(clock), .q(out[1]), .clrn(~reset)); 
	dff dff2(.d(next[2]), .clk(clock), .q(out[2]), .clrn(~reset));
	dff dff3(.d(next[3]), .clk(clock), .q(out[3]), .clrn(~reset)); 
	dff dff4(.d(next[4]), .clk(clock), .q(out[4]), .clrn(~reset));
	dff dff5(.d(next[5]), .clk(clock), .q(out[5]), .clrn(~reset));
	dff dff6(.d(next[6]), .clk(clock), .q(out[6]), .clrn(~reset)); 


	
	always@(*) begin
		casex({reset, out})
			7'b1xxxxxx: next = 0;
			7'd0: next = 1;
			7'd1: next = 2;
			7'd2: next = 3;
			7'd3: next = 4;
			7'd4: next = 5;
			7'd5: next = 6;
			7'd6: next = 7;
			7'd7: next = 8;
			7'd8: next = 9;
			7'd9: next = 10;
			7'd10: next = 11;
			7'd11: next = 12;
			7'd12: next = 13;
			7'd13: next = 14;
			7'd14: next = 15;
			7'd15: next = 16;
			7'd16: next = 17;
			7'd17: next = 18;
			7'd18: next = 19;
			7'd19: next = 20;
			7'd20: next = 21;
			7'd21: next = 22;
			7'd22: next = 23;
			7'd23: next = 24;
			7'd24: next = 25;
			7'd25: next = 26;
			7'd26: next = 27;
			7'd27: next = 28;
			7'd28: next = 29;
			7'd29: next = 30;
			7'd30: next = 31;
			7'd31: next = 32;
			7'd32: next = 33;
			7'd33: next = 33;
		endcase
	end
endmodule




module multControlBlock(input_product, input_multiplicand, input_multiplier, output_product, output_multiplier, clock, input_edgeBit, 
output_edgeBit, lastBit, ready, reset);
	
	input [31:0] input_product, input_multiplicand, input_multiplier;
	input clock, input_edgeBit, lastBit, reset;
	
	output [31:0] output_product, output_multiplier;
	output ready, output_edgeBit;
	
	// Setup counter to alert when data is ready
	wire [5:0] counter_out;
	counter32 counter(.clock(clock), .reset(reset), .out(counter_out));
	assign ready = (counter_out[5] == 1'b1) ? 1'b1 : 1'b0;
	
	// Compute the next value
	wire [31:0] wires_input_product, wires_input_multiplicand;
	assign wires_input_product = input_product;
	assign wires_input_multiplicand = input_multiplicand;
	
	// First by declaring both multiplicand and not multiplicand
	wire [31:0] not_wires_input_multiplicand;
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1) begin: loop0
			assign not_wires_input_multiplicand[i] = ~wires_input_multiplicand[i];
		end
	endgenerate
	
	// Now decide whether or not to add
	wire [31:0] output_adder;
	wire [31:0] sum, new_addition;
	wire cin;
	
	wire [31:0] not_addition;
	assign new_addition = (lastBit == 1'b0 && input_edgeBit == 1'b1) ? wires_input_multiplicand : not_addition;
	assign not_addition = (lastBit == 1'b1 && input_edgeBit == 1'b0) ? not_wires_input_multiplicand : 32'd0;

	assign sum = wires_input_product;
	assign cin = (lastBit == 1'b1 && input_edgeBit == 1'b0) ? 1'b1 : 1'b0;
	
	wire overflow;
	adder add_module(.data_operandA(sum), .data_operandB(new_addition), .cin(cin), .overflow(overflow), .adder_output(output_adder));
	
	// Now glue the parts together and shift
	wire [64:0] full_line;
	assign full_line = {output_adder, input_multiplier, input_edgeBit};
	
	wire [64:0] new_line;
	assign new_line = full_line >> 1;
	wire [64:0] final_line;
	assign final_line = {full_line[64], new_line[63:0]};
	
	
	// break them up for the output
	assign output_product = final_line[64:33];
	assign output_multiplier = final_line[32:1];
	assign output_edgeBit = final_line[0];

endmodule


module counter32(clock, reset, out);
	input clock, reset;
	output [5:0] out;
	reg [5:0] next;
	
	dff dff0(.d(next[0]), .clk(clock), .q(out[0]), .clrn(~reset)); 
	dff dff1(.d(next[1]), .clk(clock), .q(out[1]), .clrn(~reset)); 
	dff dff2(.d(next[2]), .clk(clock), .q(out[2]), .clrn(~reset));
	dff dff3(.d(next[3]), .clk(clock), .q(out[3]), .clrn(~reset)); 
	dff dff4(.d(next[4]), .clk(clock), .q(out[4]), .clrn(~reset));
	dff dff5(.d(next[5]), .clk(clock), .q(out[5]), .clrn(~reset)); 

	
	always@(*) begin
		casex({reset, out})
			6'b1xxxxx: next = 0;
			6'd0: next = 1;
			6'd1: next = 2;
			6'd2: next = 3;
			6'd3: next = 4;
			6'd4: next = 5;
			6'd5: next = 6;
			6'd6: next = 7;
			6'd7: next = 8;
			6'd8: next = 9;
			6'd9: next = 10;
			6'd10: next = 11;
			6'd11: next = 12;
			6'd12: next = 13;
			6'd13: next = 14;
			6'd14: next = 15;
			6'd15: next = 16;
			6'd16: next = 17;
			6'd17: next = 18;
			6'd18: next = 19;
			6'd19: next = 20;
			6'd20: next = 21;
			6'd21: next = 22;
			6'd22: next = 23;
			6'd23: next = 24;
			6'd24: next = 25;
			6'd25: next = 26;
			6'd26: next = 27;
			6'd27: next = 28;
			6'd28: next = 29;
			6'd29: next = 30;
			6'd30: next = 31;
			6'd31: next = 32;
			6'd32: next = 32;
		endcase
	end
endmodule





// Adder implementation from ALU
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
