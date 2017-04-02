module CP4_processor_nbv3(clock, reset, /*ps2_key_pressed, ps2_out, lcd_write, lcd_data,*/ dmem_data_in, 
dmem_address, dmem_out, fetch_pipe_pc, fetch_pipe_instruction, pipe_decode_pc, pipe_decode_instruction,
decode_pipe_pc, decode_pipe_instruction, pipe_execute_pc, pipe_execute_instruction, execute_pipe_data, execute_pipe_instruction,
execute_pipe_address, pipe_memory_address, pipe_memory_data, pipe_memory_instruction, memory_pipe_from_memory, memory_pipe_not_from_memory,
pipe_write_from_memory, pipe_write_not_from_memory, pipe_write_instruction, memory_pipe_instruction, decode_pipe_a, decode_pipe_b, pipe_execute_a,
pipe_execute_b);

	input 			clock, reset/*, ps2_key_pressed*/;
	//input 	[7:0]	ps2_out;
	
	//output 			lcd_write;
	//output 	[31:0] 	lcd_data;
	
	// GRADER OUTPUTS - YOU MUST CONNECT TO YOUR DMEM
	output 	[31:0] 	dmem_data_in, dmem_out;
	output	[11:0]   dmem_address;
	
	wire writeEnable;
	assign writeEnable = 1'b1;
	wire [31:0] data_writeReg;
	wire [4:0] address_writeReg;

	
	// Testing
	wire [11:0] next_pc;
	assign next_pc = (reset) ? 11'd0 : fetch_pipe_pc;
	
   fetch_stage fetch(clock, reset, next_pc, fetch_pipe_pc, fetch_pipe_instruction);
	output [11:0] fetch_pipe_pc;
	output [31:0] fetch_pipe_instruction;
	FDPipe fdpipe(clock, reset, fetch_pipe_pc, fetch_pipe_instruction, pipe_decode_pc, pipe_decode_instruction);
	output [11:0] pipe_decode_pc;
	output [31:0] pipe_decode_instruction;
	decode_stage decode(clock, reset, writeEnable, address_writeReg, data_writeReg, pipe_decode_pc, pipe_decode_instruction,
								decode_pipe_pc, decode_pipe_instruction, decode_pipe_a, decode_pipe_b);
	output [11:0] decode_pipe_pc;
	output [31:0] decode_pipe_instruction;
	output [31:0] decode_pipe_a, decode_pipe_b;
	DXPipe dxpipe(clock, reset, decode_pipe_pc, decode_pipe_instruction, decode_pipe_a, decode_pipe_b, pipe_execute_pc, 
						pipe_execute_instruction, pipe_execute_a, pipe_execute_b);
	output [11:0] pipe_execute_pc;
	output [31:0] pipe_execute_instruction;
	output [31:0] pipe_execute_a, pipe_execute_b;
	execute_stage execute(clock, reset, pipe_execute_pc, pipe_execute_instruction, pipe_execute_a, pipe_execute_b, execute_pipe_instruction,
	execute_pipe_address, execute_pipe_data);
	output [31:0] execute_pipe_data, execute_pipe_instruction;
	output [31:0] execute_pipe_address;
	
	XMPipe xmpipe(clock, reset, execute_pipe_data, execute_pipe_address, execute_pipe_instruction, pipe_memory_address, pipe_memory_data,
	pipe_memory_instruction);
	
	output [31:0] pipe_memory_data, pipe_memory_address, pipe_memory_instruction;
	
	memory_stage memory(clock, reset, pipe_memory_address, pipe_memory_data, pipe_memory_instruction, 
	memory_pipe_not_from_memory, memory_pipe_from_memory, memory_pipe_instruction);
	
	output [31:0] memory_pipe_from_memory, memory_pipe_not_from_memory, memory_pipe_instruction;
	
	MWPipe mwpipe(clock, reset, memory_pipe_not_from_memory, memory_pipe_from_memory, memory_pipe_instruction,
	pipe_write_not_from_memory, pipe_write_from_memory, pipe_write_instruction);
	
	output [31:0] pipe_write_from_memory, pipe_write_not_from_memory, pipe_write_instruction;
	
	write_stage write(clock, reset, pipe_write_from_memory, pipe_write_not_from_memory, pipe_write_instruction, 
		address_writeReg, data_writeReg);
	
	// your processor here
	
	//
	
	//////////////////////////////////////
	////// THIS IS REQUIRED FOR GRADING
	// CHANGE THIS TO ASSIGN YOUR DMEM WRITE ADDRESS ALSO TO debug_addr
//	assign dmem_address = (12'b000000000001);
	// CHANGE THIS TO ASSIGN YOUR DMEM DATA INPUT (TO BE WRITTEN) ALSO TO debug_data
//	assign dmem_data_in = (12'b000000000000);
	////////////////////////////////////////////////////////////

	
	
	
endmodule

module write_stage(clock, reset, pipe_write_from_memory, pipe_write_not_from_memory, pipe_write_instruction, write_register,
write_value);

	input clock, reset;
	input [31:0] pipe_write_from_memory, pipe_write_not_from_memory, pipe_write_instruction;
	
	output [4:0] write_register;
	output [31:0] write_value;
	// output, shouldWrite??
	
	// check if always rd, i.e. jal
	assign write_register = pipe_write_instruction[26:22];
	// Logic here for what to write
	wire signal;
	assign signal = 1'b1;
	assign write_value = (signal) ? pipe_write_not_from_memory : pipe_write_not_from_memory;
	
	
endmodule

module MWPipe(clock, reset, memory_pipe_not_from_memory, memory_pipe_from_memory, memory_pipe_instruction,
pipe_write_not_from_memory, pipe_write_from_memory, pipe_write_instruction);

	input clock, reset;
	input [31:0] memory_pipe_from_memory, memory_pipe_not_from_memory, memory_pipe_instruction;
	
	output [31:0] pipe_write_from_memory, pipe_write_not_from_memory, pipe_write_instruction;
	
	CP1_reg_nbv3 from_memory_latch(clock, reset, 1'b1, 1'b1, memory_pipe_from_memory, pipe_write_from_memory);
	CP1_reg_nbv3 instruction_latch(clock, reset, 1'b1, 1'b1, memory_pipe_instruction, pipe_write_instruction);
	CP1_reg_nbv3 not_from_memory_latch(clock, reset, 1'b1, 1'b1, memory_pipe_not_from_memory, pipe_write_not_from_memory);
	

endmodule

module memory_stage(clock, reset, pipe_memory_address, pipe_memory_data, pipe_memory_instruction, not_from_memory, from_memory, memory_pipe_instruction);
	
	input clock, reset;
	input [31:0] pipe_memory_address, pipe_memory_data, pipe_memory_instruction;
	
	output [31:0] from_memory, not_from_memory, memory_pipe_instruction;
	
	assign memory_pipe_instruction = pipe_memory_instruction;
	
	assign not_from_memory = pipe_memory_address;
	// Check memory logic below for different instructions
//	dmem mydmem(.address	(pipe_memory_address),
//					.clock		(clock),
//					.data		(pipe_memory_data),
//					.wren		(1'b1), //,	//need to fix this!
//					.q			(from_memory) // change where output q goes...
//	);
	
	
endmodule

module XMPipe(clock, reset, execute_pipe_data, execute_pipe_address, execute_pipe_instruction, pipe_memory_address, pipe_memory_data, pipe_memory_instruction);
	
	input clock, reset;
	
	input [31:0] execute_pipe_data, execute_pipe_address, execute_pipe_instruction;
	output [31:0] pipe_memory_address, pipe_memory_data, pipe_memory_instruction;
	
	CP1_reg_nbv3 address_latch(clock, reset, 1'b1, 1'b1, execute_pipe_address, pipe_memory_address);
	CP1_reg_nbv3 instruction_latch(clock, reset, 1'b1, 1'b1, execute_pipe_instruction, pipe_memory_instruction);
	CP1_reg_nbv3 data_latch(clock, reset, 1'b1, 1'b1, execute_pipe_data, pipe_memory_data);
	
endmodule

module execute_stage(clock, reset, pipe_execute_pc, pipe_execute_instruction, pipe_execute_a, pipe_execute_b,
execute_pipe_instruction, execute_pipe_address, execute_pipe_data);

	input clock, reset;
	input [11:0] pipe_execute_pc;
	input [31:0] pipe_execute_instruction, pipe_execute_a, pipe_execute_b;
	
	output [31:0] execute_pipe_instruction, execute_pipe_data, execute_pipe_address;
	
	wire [4:0] opcode, shamt, aluop;
	wire [16:0] N;
	
	assign opcode = pipe_execute_instruction[31:27];
	assign shamt = pipe_execute_instruction[11:7];
	// Will eventually need to handle bne and blt for subtraction
	assign aluop = (opcode == 5'b00000) ? pipe_execute_instruction[6:2] : 5'b00000;
	
	assign N = pipe_execute_instruction[16:0];
	wire [31:0] N_extended;
	assign N_extended[16:0] = N;
	genvar i;
	
	generate
		for (i=17; i<32; i=i+1) begin: loop100
			assign N_extended[i] = (N_extended[16] == 1'b0) ? 1'b0 : 1'b1 ;
		end
	endgenerate
	
	wire overflow, isNotEqual, isLessThan;
	wire [31:0] data_result;
	
	wire [31:0] argument_B;
	assign argument_B = (opcode == 5'b00101) ? N_extended : pipe_execute_b;
	// Hardcoded in rs rt for testing - will need to change for controls
	CP2_alu_nbv3 alu(pipe_execute_a, argument_B, aluop, shamt, data_result,
					isNotEqual, isLessThan, overflow);
	
	
	assign execute_pipe_instruction = pipe_execute_instruction;
	// Note that the address memory value is the output from the alu
	assign execute_pipe_address = data_result;
	assign execute_pipe_data = pipe_execute_b;
	

endmodule

module DXPipe(clock, reset, in_pc, in_instruction, in_a, in_b, out_pc, out_instruction, out_a, out_b);
	
	input clock, reset;
	
	input [11:0] in_pc;
	input [31:0] in_instruction, in_a, in_b;
	
	output [11:0] out_pc;
	output [31:0] out_instruction, out_a, out_b;
	
	CP1_reg_nbv3 pc_latch(clock, reset, 1'b1, 1'b1, in_pc, out_pc);
	CP1_reg_nbv3 instruction_latch(clock, reset, 1'b1, 1'b1, in_instruction, out_instruction);
	CP1_reg_nbv3 a_latch(clock, reset, 1'b1, 1'b1, in_a, out_a);
	CP1_reg_nbv3 b_latch(clock, reset, 1'b1, 1'b1, in_b, out_b);
	
endmodule

module decode_stage(clock, reset, ctrl_writeEnable, address_writeReg, data_writeReg, in_pc, in_instruction, out_pc, out_instruction, out_a, out_b);
	
	input clock, reset;
	input [11:0] in_pc;
	input [31:0] in_instruction, data_writeReg;
	input [4:0] address_writeReg;
	input ctrl_writeEnable;
	
	output [11:0] out_pc;
	output [31:0] out_instruction, out_a, out_b;
	
	assign out_pc = in_pc;
	assign out_instruction = in_instruction;
	
	wire [4:0] readRegA, readRegB;
	assign readRegA = in_instruction[21:17];
	assign readRegB = ((in_instruction[31:27] == 5'b00000)) ? in_instruction[16:12] : in_instruction[26:22];
	
	
	CP1_regfile_nbv3 regfile(
	clock, ctrl_writeEnable, reset,
	address_writeReg, readRegA, readRegB,
	data_writeReg, out_a, out_b);
	
	
endmodule

module FDPipe(clock, reset, in_pc, in_instruction, out_pc, out_instruction);
	
	input clock, reset;
	
	input [11:0] in_pc;
	input [31:0] in_instruction;
	
	output [11:0] out_pc;
	output [31:0] out_instruction;
	
	CP1_reg_nbv3 pc_latch(clock, reset, 1'b1, 1'b1, in_pc, out_pc);
	CP1_reg_nbv3 instruction_latch(clock, reset, 1'b1, 1'b1, in_instruction, out_instruction);
	
endmodule

module fetch_stage(clock, reset, in_address, next_address, out_instruction);
	
	input clock, reset;
	input [11:0] in_address;
	output [31:0] out_instruction;
	output [11:0] next_address;
	
	wire [11:0] out_address;
	wire overflow;

	program_counter pc(.clock(clock), .reset(reset), .in_address(in_address), .out_address(out_address));
	
	adder_mod next_instruction(out_address, 32'd1, overflow, next_address, 1'b0);
	
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

module adder_mod(data_operandA, data_operandB,
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
