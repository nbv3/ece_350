
instructions = []

with open('imem.mif', 'rw') as f:
	for row in f:
		instructions.append(str(row))
	f.close()

# TODO: change your mappings for custom instructions
# Dictionary: {oldinstruction: newinstruction}
mappings = {'00000011010111010000000000000000': '00000011010111010000000000100000',
			'00011000000000000000000000000000': '11111000000000000000000000000010',
			'00000011010111001111000000000000': '00000011010111001111000000100000',
			'00000011010111010100000000000000': '00000011010111010100000000100000',
			'00000011010111010001000000000000': '00000011010111010001000000100000',
			'00000011010111010010000000000000': '00000011010111010010000000100000'}

for i, instruction in enumerate(instructions):
	for j, key in enumerate(mappings.keys()):
		if key in instruction:
			print(j)
			print(instruction)
			split_instruction = instruction.split(' ')
			split_instruction[2] = mappings[key]
			instruction = ' '.join(split_instruction)
			instruction = instruction + ';\n'
			instructions[i] = instruction

with open('imem.mif', 'wb') as f:
	for instruction in instructions:
		f.write(instruction)
	f.close()


