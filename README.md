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
set a flag for a write enable to the register file. This is necessary for our writeback stage
set flag for wether we are loading or storing a word. also necessary for our writeback stage and ALU stage (used to calculate the address)
set a flag for if we are branching, which is important for maintaing an accurate PC
also have a flag for whether this branch is BEQ or BNE, which makes branch logic a lot easier.
also have a flag for a unconditional branch and a 32 bit jump target, which is also necessary for pc calculation 
lastly have an output flag for halting the module. This is necesarry because we dont want the program to continue to calculate garbage and run when it is not supposed to, the this halt is needed in the decode stage to get propagate to the rest of the pipeline

then we create local parametr for a 6 bit opcode and a 6 bit function. the function represents the alu opcode, if it is used, and the opcode is used to represent the 7 different types of proceses, a register type operation (ADD, SUB, AND, OR), an immediate add, a load, a store, a BEQ, a BNE, and a Halt. Writing this I realized that I have yet to include a jump instruction or a normal add, so if you see this portion I am in the process of coming back around to add it

Additionally, I use this umbrella type of grouping and a 6 bit function to represent a 3 bit opcode so we can have a full 32 bit instruction. The grouping makes the processor more organized and it give a structure for different types of operations needed. It makes a lot more sense to me visually and less messy than to have a 12 bit opcode with a bunch of different combinations to represent every operation. Also, it would porbably be difficult to do that instead of do what I did, as my method allows me to reuse those 6 bits of the funciton for imm16 and rs2 if necesary.

assign the opcode to the most significant 6 bits of the instruction
assign the first source regsiter to the next 5 bits of the instruction
assign the second source register to the next 5 bits of the instruction
assign the destination register to the next 5 bits of the instruction
assign the alu opcode (function) to the lat 6 bits of the instruction

sign extend the immediate value to 32 bits. We are assuming immediate values are 16 bits.

* it is also important to note that all these outputs are calcualted, even if they may not be used, depednign on the type of instruction *

have combinatorial logic always running that intiliazes the source register usage flags, immediate value flag, alu op code, register file write enable flag, load and store word flags, branch flag, beq or bne flag, jump flag and jump target, and halt to 0 (jump target is initilaize to a 32 bit 0 value). 


use case switch with the opcode. if the opcode is 000000 (truncate 2 hex values), that means it is a register type operation, so we use another case switch with the function value. First we set the source register usage flags and the register file write enable to 1. then we see if the funcition is equal to 6 truncated hex value of 20. If it is , then we set the alu op to 000 (ADD). If the function is 22, we set the alu op to 001 (SUB). If the function is equal to 24, then we set the alu op to 010 (AND). If the function is equal to 25, then we set the alu op to 011 (OR).
if function is equal to none of these values, we assume there is no operation, to we set the register file write flag to 0. This is important becasue we ensure that no garbage operation messes up our pipleine.

if the opcode is 001000, we know the operation is an add with an immediate value. Here we set the source register one usage flag to one but the second one to 0, because we are using that bit space for the 16 bit immediate value. We set the immediate value flag to 1, make the alu operation 000 (ADD), and the regiser file wrie enable flag 1. 

if the opcode if 100011, then we are loading a word into a register. We do this with an immediate value, so we set the first source register usage flag to 1, the second one to 0, the immediate flag to 1, the alu op to 000 to calculate the address, the register file write enable flag to one, and the load word flag to one.

if the opcode is 101011, then we are storing a word into the register. We do this by takign a value in a register and stroing in in memory with an offset determined by the sum of a second register and an immediate value. So we set both source register usage flags to one, the immeditae flag to one, teh alu op to 000, the store word flag to 1, and the registerfile write enable to 0

if the opcode is 000100, the we are doing a BEQ (branch if equal) operation.
set both register flags to 1, the branch flag to 1, and the type of branch to 0 ( signaling eq)

if the opcode is 000101, the we are doing a BNE (branch if not equal) operation.
set both register flags to 1, the branch flag to 1, and the type of branch to 1 ( signaling ne)

if the opcode is 111111, the pipeline should halt, so we turn the halt flag on.
for anythign else we assume that there is no operation.

______________________________________________________________________________________________

dmem.sv

have a parameter of the amount of words we are storing in memory, which I have 1024, obviously overkill. 

we have an input clock, write enable, at 32 bit input of the addr, which is byte addressable, a 32 bit input fo rthe right data and a 32 bit output for the read data.

create a memory array, which contains 1024 words. we intiliaze the memory to hold zeros to avoid getting garbage values. We also set the first word to 6 to test loads.

we will also create an index using the clog2 method, which takes the log of a value. We take the log of the depth of words so this index can map to every possible address. In this case, our index is a 10 bit number, meaning there are 2^10 possible combinations, which is the amount of words we have.

Right now, addr is a 32 bit value. we need to map this value to the index so we can access the word alligned memory. Since the address is byte addressable, dividing it by 4 ( 4 bytes in a word) will give of a word alligned address. so we assign the index to this address that has been shifted right by 2 and truncated to 10 bits. We then use this index to access memory and store the value in the read data ouput. 

We also have a write data inputed at this index in memory at the posedge of the clock if write is enable. I have it at the posedge because it is convention, so no apparent reason.

______________________________________________________________________________________________








