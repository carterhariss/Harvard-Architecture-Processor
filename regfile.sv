module regfile #(
    parameter int WIDTH = 32,
    parameter int NREGS = 32
    
)(
    input logic clk,
    // write port
    input logic wen,
    input logic [$clog2(NREGS)-1:0] waddr,
    input logic [WIDTH-1:0] wdata,
    // read ports
    input logic [$clog2(NREGS)-1:0] raddr1,
    input logic [$clog2(NREGS)-1:0] raddr2,
    output logic [WIDTH-1:0] rdata1,
    output logic [WIDTH-1:0] rdata2
);

logic [WIDTH-1:0] regs [NREGS-1:0];
integer i;
initial begin
    for (i = 0; i < 32; i = i + 1)
        regs[i] = 32'd0;
end

// combinationals reads, with x0 = 0
always_comb begin 
    rdata1 = (raddr1 == '0) ? '0 : regs[raddr1];
    rdata2 = (raddr2 == '0) ? '0 : regs[raddr2];
end

// synchronous write, ignore writes to x0
always_ff @(posedge clk) begin
    if (wen && (waddr != '0)) begin
        regs[waddr] <= wdata;
    end
end
endmodule

