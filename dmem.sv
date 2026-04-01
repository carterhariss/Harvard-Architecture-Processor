module dmem #(
    parameter int DEPTH_WORDS = 1024
)(
    input logic clk,
    input logic we,
    input logic [31:0] addr, // byte address
    input logic [31:0] wdata,
    output logic [31:0] rdata
);
    logic [31:0] mem [DEPTH_WORDS-1:0];
    logic [$clog2(DEPTH_WORDS)-1:0] idx; // figures out how many bits we need to index 1024 words, so index is a 10 bit number
    integer i;

    initial begin
        // initialize all memory to 0
        for (i = 0; i < DEPTH_WORDS; i = i + 1)
            mem[i] = 32'd0;

        // forwarding test value
        mem[0] = 32'd6;
    end
    assign idx = addr[31:2]; // [11:2] used to access word-aligned memory
    assign rdata = mem[idx]; // comb read (v1) gets returns

    always_ff @(posedge clk) begin  // write into memory on positive edge of clock
        if (we) mem[idx] <= wdata;
    end
endmodule
