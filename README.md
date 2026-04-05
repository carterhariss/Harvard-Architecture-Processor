alu.sv
set the parameter to support a 32 bit value
set 2 input operands, for a and b
set a 3 bit input for the opcode
set a 32 bit output for the result of the alu operation
set an output flag to determine if the output of the ALU is 0, which is necessary for our BEQ and BNE branches. If an instruction is either BEQ or BNE, then the alu will do subtraction between the 2 operands and compare it to zero, and the result is stored in the output

Then create local parameters for the different types of opcodes I am supporting:
- ADD: 000
- SUB: 001
- AND: 010
- OR: 011

then we have combinational logic running to enact these opcodes when they are inputted using case operations on the opcode input
if the opcode does not match one of the 4 previously listed, we assume that the opcode is not being used and we set the output to 0 to avoid processing garbage numbers
set the zero flag to the comparison between y and 0
____________________________________________________________

decoder.sv
this module decodes the instruction
input is a 32 bit instruction
set three 5 bit outputs for source register 1, source register 2, and a destination register
have a flag output for using the first source register, second register, and if an immediate value is used. the source register flags are necessary for our hazard module, but overall are necessary for determining if forwarding needs to be used. More on this soon. The immediate value flag is necessary to determine what is going to be the second operand for the alu, a register or an immediate value
set a 32 bit output for an immediate value
set a flag for a write enable to the register file. This is necessary for our writeback stage
set a flag for whether we are loading or storing a word. also necessary for our writeback stage and ALU stage (used to calculate the address)
set a flag for if we are branching, which is important for maintaining an accurate PC
also have a flag for whether this branch is BEQ or BNE, which makes branch logic a lot easier.
also have a flag for an unconditional branch and a 32 bit jump target, which is also necessary for PC calculation
lastly have an output flag for halting the module. This is necessary because we do not want the program to continue to calculate garbage and run when it is not supposed to, so this halt is needed in the decode stage to get propagated to the rest of the pipeline

then we create local parameters for a 6 bit opcode and a 6 bit function. the function represents the alu opcode, if it is used, and the opcode is used to represent the 7 different types of processes: a register type operation (ADD, SUB, AND, OR), an immediate add, a load, a store, a BEQ, a BNE, and a Halt. Writing this, I realized that I have yet to include a jump instruction or a normal add, so if you see this portion I am in the process of coming back around to add it

Additionally, I use this umbrella type of grouping and a 6 bit function to represent a 3 bit opcode so we can have a full 32 bit instruction. The grouping makes the processor more organized and gives a structure for different types of operations needed. It makes a lot more sense to me visually and is less messy than having a 12 bit opcode with a bunch of different combinations to represent every operation. Also, it would probably be difficult to do that instead of doing what I did, as my method allows me to reuse those 6 bits of the function for imm16 and rs2 if necessary.

assign the opcode to the most significant 6 bits of the instruction
assign the first source register to the next 5 bits of the instruction
assign the second source register to the next 5 bits of the instruction
assign the destination register to the next 5 bits of the instruction
assign the alu opcode (function) to the last 6 bits of the instruction

sign extend the immediate value to 32 bits. We are assuming immediate values are 16 bits.

* it is also important to note that all these outputs are calculated, even if they may not be used, depending on the type of instruction *

have combinational logic always running that initializes the source register usage flags, immediate value flag, alu opcode, register file write enable flag, load and store word flags, branch flag, beq or bne flag, jump flag and jump target, and halt to 0 (jump target is initialized to a 32 bit 0 value).


use case switch with the opcode. if the opcode is 000000 (truncate 2 hex values), that means it is a register type operation, so we use another case switch with the function value. First we set the source register usage flags and the register file write enable to 1. then we see if the function is equal to a 6 truncated hex value of 20. If it is, then we set the alu op to 000 (ADD). If the function is 22, we set the alu op to 001 (SUB). If the function is equal to 24, then we set the alu op to 010 (AND). If the function is equal to 25, then we set the alu op to 011 (OR).
if the function is equal to none of these values, we assume there is no operation, so we set the register file write flag to 0. This is important because we ensure that no garbage operation messes up our pipeline.

if the opcode is 001000, we know the operation is an add with an immediate value. Here we set the source register one usage flag to one but the second one to 0, because we are using that bit space for the 16 bit immediate value. We set the immediate value flag to 1, make the alu operation 000 (ADD), and the register file write enable flag to 1.

if the opcode is 100011, then we are loading a word into a register. We do this with an immediate value, so we set the first source register usage flag to 1, the second one to 0, the immediate flag to 1, the alu op to 000 to calculate the address, the register file write enable flag to one, and the load word flag to one.

if the opcode is 101011, then we are storing a word into the register. We do this by taking a value in a register and storing it in memory with an offset determined by the sum of a second register and an immediate value. So we set both source register usage flags to one, the immediate flag to one, the alu op to 000, the store word flag to 1, and the register file write enable to 0.

if the opcode is 000100, then we are doing a BEQ (branch if equal) operation.
set both register flags to 1, the branch flag to 1, and the type of branch to 0 (signaling eq)

if the opcode is 000101, then we are doing a BNE (branch if not equal) operation.
set both register flags to 1, the branch flag to 1, and the type of branch to 1 (signaling ne)

if the opcode is 111111, the pipeline should halt, so we turn the halt flag on.
for anything else we assume that there is no operation.

______________________________________________________________________________________________

dmem.sv

have a parameter for the amount of words we are storing in memory, which I have as 1024, obviously overkill.

we have an input clock, write enable, a 32 bit input of the addr, which is byte addressable, a 32 bit input for the write data, and a 32 bit output for the read data.

create a memory array, which contains 1024 words. we initialize the memory to hold zeros to avoid getting garbage values. We also set the first word to 6 to test loads.



we will also create an index using the clog2 method, which takes the log of a value. We take the log of the depth of words so this index can map to every possible address. In this case, our index is a 10 bit number, meaning there are 2^10 possible combinations, which is the amount of words we have.

Right now, addr is a 32 bit value. we need to map this value to the index so we can access the word aligned memory. Since the address is byte addressable, dividing it by 4 (4 bytes in a word) will give a word aligned address. so we assign the index to this address that has been shifted right by 2 and truncated to 10 bits. We then use this index to access memory and store the value in the read data output.

We also have a write data input at this index in memory at the posedge of the clock if write is enabled. I have it at the posedge because it is convention, so there is no apparent reason.

______________________________________________________________________________________________

ex_wb_reg.sv

set input for clock
set input for rst_n, meaning reset on a negative edge
input for a flush flag, meaning get rid of any output, necessary if there was a stall in the fetch stage due to forwarding
set input for a valid flag, necessary to ensure that if we were to halt the program, an invalid flag is carried throughout the pipeline
set an input for write enable, which would be propagated to the reg file
set a 5 bit input for the destination register, set an input for write data, and set an input for a halt flag.
although these flags and inputs might not be needed in this stage, they are needed here so they can travel through the pipeline for where they are needed.

set an output for a valid flag
set an output for the write enable flag
set an output for the 5 bit destination register
set an output for the 32 bit write data
set an output for the halt flag

have logic that runs on the positive edge of the clock or negative edge of the rst_n (meaning it is active low)
if rst_n is active low, set out valid to 0 so future stages know to disregard upcoming data, set the write enable flag to 0, set the out register to a 5 bit number 0, set the output write data to a 32 bit number 0, and set the out halt to 0.

if flush is active, set out valid to 0, set write enable to 0, set destination register to a 5 bit number 0, set output write data to a 32 bit 0 value, and set the out halt to 0, so the same as reset.

else, this is a good stage execution, so transition all input values to their respective outputs
_____________________________________________________________________________________________

hazard_unit.sv

set an input for if the fetch stage was valid
set an input for if the first and second source register were used
set inputs for the 5 bit first and second source registers
set an input for if the execution stage is loading a word
set a 5 bit input for the execution stage's destination register file
set an input for if the writeback is valid
set an input for the writeback write enable
set an input for the 5 bit writeback destination register

set an output for a fetch stall flag,
set an output for an execute bubble flag,
set an output for a forward A flag and a forward B flag

if any of these inputs change, initialize the bubble and stall flags to 0.
if the fetch instruction is valid, and the load word flag is valid, and the destination register is not 0, we have that as always 0, then we would want to ensure that the first or second source register of the fetch is equal to the destination register in the writeback, as that would mean forwarding should occur. If one of them is equal, turn on the stall flag and the bubble flag, so that the instruction stage waits for the value to be written to the register file before it is used, and the bubble flag nullifies whatever is in the execute stage.

also, at any input change initialize the forward flags to 0. Then check that the writeback stage is valid, the write enable flag is valid, and the writeback destination register is not 0, and that the writeback destination register is equal to either the first or second source register. If either is true, that respective forward flag is turned on, which will allow the value in the wb stage to be written to that register, so we only have to stall a stage as opposed to having broken logic.

__________________________________________________________________________________________

if_id_reg.sv

set an input for clock
set an input for reset (active low)
set an input for stall flag, which we use if the hazard module notes one instruction is dependent on another
set an input flag for flush
set a 32 bit input for the current pc
set a 32 bit input for the current instruction
set an input for a valid flag
set a 32 bit output for the pc
set a 32 bit output for the instruction
set an output for the valid flag.

create a local parameter, a 32 bit number of 0s to represent no operation
during the positive edge of the clock or negative edge of the reset:

if reset is low, set the pc output to 0, set the instruction output to the no operation parameter, and set the valid output flag to 0,

if flush is high, then do the same thing

if the stall flag is low, then we know that this stage should act as a typical fetch instruction stage, so set the output pc to the input pc, set the output instruction to the input instruction, and set the valid output flag to its input.

__________________________________________________________________________________________________________________


imem.sv

create parameters for the word capacity in memory, which is 1024
create a parameter for the memory file, which is defaulted to nothing

set an input of a 32 bit address
set an output of a 32 bit instruction.

create a memory array, which would be 1024 32 bit elements


similar to dmem, create an index variable that would be a 10 bit number representing every element in memory.
assign to the output instruction the value in memory corresponding to the input address that was word aligned and truncated into the index
initialize all instructions to hold 0
if the memory file exists, read the file into memory

__________________________________________________________________________________________________________________

program.hex

holds the 32 bit instruction I used to test functionality

__________________________________________________________________________________________________________________

regfile.sv

set parameters for the bit size of each register, and the number of registers, both are defaulted to 32.

set an input for clock
set an input for a write flag
set an input for the write address, which would be the ceiling of the log of base 2 of the amount of registers, so that every register can be represented by a 5 bit number, similar to dmem and imem.
set an input for the write data, which would be 32 bits
set inputs for the two read addresses, which are derived with the same process as the write address
set two outputs for the 32 bit read data.

create an array for register values. they are 32 bits and go up to 32 registers by default

initialize all the registers to 0.

have combinational logic running, setting read data one equal to either 0, if the read address is 0 (register 0 always holds 0), otherwise whatever is indexed in memory at that read address
do the same thing for the second read data. We have a register designated for 0, so we do not have to create a use instruction

at the positive edge of the clock if write enable is high and the write address is not equal to 0, since we cannot write to the 0th register, then we write to that register in memory (indexed by the write address), the write data.

__________________________________________________________________________________________________________________

cpu_top.sv

set parameters for the amount of words in memory for instruction and data, both defaulted to 1024
set a parameter for the instruction memory file where we will put the instruction defaulted to ""
set an input for clock, reset, and an output for a halted flag. We need this for our testbench, so we know when to stop.

The first part of this top file is to wire the instruction fetch and calculate PC
set 32 bit values for current and next pc
set a 32 bit number for the instruction fetched
set flags for stall, flush, if a branch is taken, and a 32 bit branch target.

at the posedge of the clock or negedge of reset, if reset is low, set the pc to a 32 bit 0
else if there is no stall, set the current instruction to the next instruction

also have combinational logic running, so if a branch is taken, set the next instruction to the branch target value. otherwise set it equal to the current instruction + 4

call an instance of the instruction memory with the aforementioned parameter values, with the current instruction as the input address and the fetched instruction as the output.

set a 32 bit value for the pc in the fetch stage and the instruction
set a flag for if the fetch stage is valid.
then call an instance for the fetch stage, with inputs of clock, reset, stall, flush, pc, instruction, and 1 to represent a valid fetch. have outputs for pc, instruction, and valid.

additionally, we create 5 bit values for source register 1 and 2, and a destination register
create flags for if these source registers are used
create a flag for if an immediate value is used
create a 32 bit value for a 32 bit immediate value
create a 3 bit value for the alu opcode
create a flag for write enable
create flags for loading and storing words
create flags for branch and its type (BEQ and BNE)
create a jump flag
create a 32 bit jump target (still have not implemented this)
create a halt flag

we use all these values as outputs into a decoder instance, with the instruction as an input, propagated from the fetch instruction.

now we need to take what we have gained from decoder and find what registers we need
set a flag for write enable, a 5 bit write address, 32 bit write data, and 2 32 bit read data

use these along with clock and the source registers in the instance creation of the regfile module, with the two reads as the output. the write capabilities here are going to be utilized during the writeback stage.

now we can create connections for a flag signaling a valid wb stage, write enable, a 5 bit destination register, a 32 bit write data, and a halt flag. now the reason we created a new destination register, data, and write enable is because we only want write enable to be on if the writeback stage is valid. for the destination register value and the write data, we differentiate these from the register file's to represent different stages and avoid confusion.

we also create flags for a bubble in the execution stage, as well as if a forward of the 1st or second operand is necessary

now we call a hazard_unit with inputs of valid fetch flag, both source registers, their flags, a load word flag (guarded with a valid fetch flag), as well as the wb valid flag, write enable flag, and destination register (of the writeback stage).

There are also going to be outputs for the stall of the fetch stage, bubble of the execution stage, and flags for forwarding A and B. This is because this instance checks if the register in the fetch stage relies on a previously loaded word, currently in the writeback stage

now we make 32 bit operands for A and B. We create two that do not take into account forwarding so we can use a ternary operation down the line to find what the actual operands are

we assign the raw operands to the reads from the register file

and we assign the actual operands to a ternary expression between the respective forward flag, what the writeback data would be if there is a forward, and the raw operand

and since the B operand bits can also be used as an immediate value, determined by the decoder, we also do a ternary operation with the is_imm flag, the B operand, and the 32 bit immediate value

Now we are onto the ALU part

we already have operands and know what operation we are doing, given the alu_op. We also need a 32 bit value for the output as well as a zero. The zero is not actually used, but I put it there for future optimization, because I could have my BEQ and BNE utilize the ALU to see if a branch is necessary or not.

After this we run an instance of our dynamic memory module, with the inputs of clock, write enable (which is guarded by the valid fetch flag, a store word flag, and a low bubble flag), write data, which would be regB, housing the immediate 32 bit value, and the read output.

then we execute our branch logic. Basically, we ensure that there is a branch with the guard of a valid fetch and no bubble. then we calculate if the branch should be taken or not, depending on the type of branch we have. This branch flag is routed back to the fetch instruction, and the branch target is updated with the offset of the immediate value.
Because the fetch could be initially incorrect, as it precomputed a simple pc increment, we send a flush signal to reset the stages if a branch is taken.

set a 32 bit value for the result of the execute stage, and a ternary operator on the load flag that is connected to the dynamic memory read data or the output of the ALU

set a 5 bit value to the destination register of the instruction in the execute stage, and assign it to either the destination register of the r-type operation, which we found in the decoding stage, or the five bits of the instruction for rs2, which is the "destination register" used for loads

create a flag for if the execution stage is valid and assign it to the valid flag of the fetch stage anded with the negated bubble flag

then call the execute/wb instance with clk, reset, flush, ex valid, write enable (anded ex valid and write enable from decoder), ex destination register, write data from the result of either the alu or a load, and a halt signal (ex_valid and halt anded together), as inputs
for outputs we get an output valid flag, a write enable, a writeback destination register, writeback data, and an output halt signal.

Assign the register file write enable with the writeback write enable flag, and we and it with the valid flag and the comparison between the destination and 0 (we do not want to write a value to the 0th register)

assign to the register file's write address the destination register from the writeback

assign the register file data to the writeback data

assign the halted flag to the writeback valid and halt flags anded together

__________________________________________________________________________________________________________________

tb_cpu.sv

for the testbench, set a time unit of 1ns and a time precision of 1 ps

set inputs for clock, a reset, and a halted flag

call cpu_top with these values, and parameters of a memory depth of 256 and the instruction file under the name program.hex


toggle the clock every five units (period of 10 ns)

toggle the reset at 20 units, so this test will reset every 20 ns.

monitor the time, pc, and if the instruction halted, and print it whenever an argument changes

when the halt flag is high, print what is in the first 4 registers and the first element in memory because that is what we tested with, and dump variables into a dump file so we can use Surfer to view our waveforms

__________________________________________________________________________________________________________________

program.hex

Full inclusive test program

This program does the following:

r1 = 5
r2 = 7
r3 = r1 + r2 = 12
mem[0] = r3
r4 = mem[0] = 12
BEQ r3, r4, 1 so the next instruction is skipped
skipped instruction would have overwritten r1 with 99
BNE r1, r2, 1 so the next instruction is skipped
skipped instruction would have overwritten r2 with 88
HALT

Assembly version:

ADDI r1, r0, 5
ADDI r2, r0, 7
ADD  r3, r1, r2
SW   r3, [0]
LW   r4, [0]
BEQ  r3, r4, 1
ADDI r1, r0, 99
BNE  r1, r2, 1
ADDI r2, r0, 88
HALT

Forwarding is accounted for with the second ADD immediate and direct ADD
Test shows correct values:

vvp sim.out
WARNING: imem.sv:22: $readmemh(program.hex): Not enough words in the file for the requested range [0:255].
Starting simulation...
VCD info: dumpfile dump.vcd opened for output.
t=0 | pc=00000000 | halted=0
t=25000 | pc=00000004 | halted=0
t=35000 | pc=00000008 | halted=0
t=45000 | pc=0000000c | halted=0
t=55000 | pc=00000010 | halted=0
t=65000 | pc=00000014 | halted=0
t=75000 | pc=00000018 | halted=0
t=85000 | pc=0000001c | halted=0
t=95000 | pc=00000020 | halted=0
t=105000 | pc=00000024 | halted=0
t=115000 | pc=00000028 | halted=0
t=125000 | pc=0000002c | halted=1

CPU halted.
Register x1 = 5 (0x00000005)
Register x2 = 7 (0x00000007)
Register x3 = 12 (0x0000000c)
Register x4 = 12 (0x0000000c)
DMEM[0] = 12 (0x0000000c)
tb_cpu.sv:56: $finish called at 135000 (1ps)

How my instructions are formatted:

R-type format

Used for register-register ALU operations like ADD, SUB, AND, OR.

Bits	Field	Meaning
31:26	opcode	Instruction type. For all R-type instructions this is 000000
25:21	rs1	Source register 1
20:16	rs2	Source register 2
15:11	rd	Destination register
10:6	unused
5:0	funct	Specific ALU operation

Example:
ADD x3, x1, x2

opcode = 000000
rs = 1
rt = 2
rd = 3
funct = 100000 (0x20)

I-type format

Used for ADDI, LW, SW, BEQ, BNE.

Bits	Field	Meaning
31:26	opcode	Instruction type
25:21	rs	Source/base register
20:16	rt	Destination register for ADDI and LW, source register for SW, compare register for branches
15:0	imm16	16-bit immediate, sign-extended to 32 bits

Examples:

ADDI x1, x0, 5
LW x4, 0(x0)
SW x3, 0(x0)
BEQ x3, x4, 1

HALT format

Used as a custom instruction in this CPU.

Bits	Field	Meaning
31:26	opcode	111111
25:0	unused

Hex:
FC000000

Opcode table

Instruction	Opcode	Funct:

ADDI	0x08	—
BEQ	0x04	—
BNE	0x05	—
LW	0x23	—
SW	0x2B	—
HALT	0x3F	—
ADD	0x00	0x20
SUB	0x00	0x22
AND	0x00	0x24
OR	0x00	0x25
 
