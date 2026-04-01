module imem #(
    //instruction memory 
    parameter int DEPTH_WORDS = 1024,
    parameter MEMFILE = ""

)(
    input logic [31:0] addr, // byte address
    output logic [31:0] inst

);

    logic [31:0] mem [0:DEPTH_WORDS-1];
    logic [$clog2(DEPTH_WORDS)-1:0] idx;
    integer i;

    assign idx = addr[31:2]; // word index
    assign inst = mem[idx]; // now we have the current instruction.

    initial begin
    for (i = 0; i < DEPTH_WORDS; i = i + 1)
        mem[i] = 32'h00000000;
    if (MEMFILE != "") $readmemh(MEMFILE, mem); //Read a file in hex format and load it into memory array mem[]
        
    end
endmodule