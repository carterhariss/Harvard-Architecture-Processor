module alu #(
    parameter int WIDTH = 32

)(
    input logic [WIDTH-1:0] a,
    input logic [WIDTH-1:0] b,
    input logic [2:0] op,
    output logic [WIDTH-1:0] y,
    output logic zero
);

    // op encoding 
    localparam logic ALU_ADD = 3'd0;
    localparam logic ALU_SUB = 3'd1;
    localparam logic ALU_AND = 3'd2;
    localparam logic ALU_OR = 3'd3;

    always_comb begin
        unique case (op)
            ALU_ADD: y = a + b;
            ALU_SUB: y = a - b;
            ALU_AND: y = a & b;
            ALU_OR: y = a | b;
            default: y = '0;
        endcase
    end

    assign zero = (y == '0);
     
endmodule