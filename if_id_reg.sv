module if_id_reg(
    input logic clk,
    input logic rst_n,
    input logic stall, // this is necesary to prevent the Ex Wb reg from begin verwritten by garbage because a newer instruciton needs a value that is still being caluclate by the Wb. 
    // for example if there is a lw followed by an add, the add will need the value in the execution stage, but the lw will have wrote back the vlaue at the same time as the end of the execution, and IF EX and WB are synchronized
    input logic flush,

    input logic [31:0] in_pc, //pc
    input logic [31:0] in_inst, //current instruction 
    input logic in_valid,

    output logic [31:0] out_pc,
    output logic [31:0] out_inst, 
    output logic out_valid
);

    localparam logic [31:0] NOP = 32'h0000_0000;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_pc <= '0;
            out_inst <= NOP;
            out_valid <= 1'b0;
        end else if (flush) begin
            out_pc <= '0;
            out_inst <= NOP;
            out_valid <= 1'b0;
        end else if (!stall) begin
            out_pc <= in_pc;
            out_inst <= in_inst;
            out_valid <= in_valid;
        end
    end

endmodule