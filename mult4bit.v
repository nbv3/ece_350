module mult4bit(data_operandA, data_operandB, ctrl_MULT,
  clock, data_result, data_exception, data_resultRDY);

  input [3:0] data_operandA, data_operandB;
  input ctrl_MULT, clock;

  output [3:0] data_result;
  output data_exception, data_resultRDY;

  // Instantiate flip flops and wires
  dffe [3:0] product_bits, multiplier_bits;
  dffe edge_bit;
  wire [3:0] multiplicand_bits;


endmodule
