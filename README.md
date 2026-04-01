alu.sv
set the paramater to support a 32 bit value
set a 2 input operands, for a and b
set a 3 bit input for the opcode
set a 32 bit output for the reuslt of the alu operation
set an output flag to derermine if the output ALU is 0 which is necesary for our BEQ and BNE branches. if an instruction is either BEQ or BNE, than the alu will do subtraciton between the 2 operands and compare it to zero, and the result is stored in the output

Then create local parameters for the different types of opcodes im supporting:
- ADD: 000
- SUB: 001
- AND: 010
- OR: 011

 then we have combinatorial logic running to enact these opcodes when they are inputed using case operations on the opcode input
 if the opcode does not match one of the 4 previously listed, we assume that the opcode is not being used and we set the output to 0 to avoid processing garbage numbers
 set the zero flag to the comparison between y and 0
____________________________________________________________

decoder.sv
this module decodes the instruction
input is a 32 bit instruction 
set three 5 bit outputs for source register 1, source register 2, and a destination register
have a flag output for using the first source register, second register, and if an immediate value is used. the source register flags are necesary for our hazard module but overall necesary for determining if forwarding needs to be used. More on this soon. immediate value flag is necesary to determine what is going to be the second operand for the alu, a register or an immediate value
set a 32 bit output for an immediate value 
set an flag for a write enable to the 
