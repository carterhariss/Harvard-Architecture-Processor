module hazard_unit(
    input  wire        if_id_valid,
    input  wire [4:0]  if_rs1,
    input  wire [4:0]  if_rs2,
    input  wire        if_uses_rs1,
    input  wire        if_uses_rs2,

    input  wire        ex_is_lw,
    input  wire [4:0]  ex_rd,

    input  wire        wb_valid,
    input  wire        wb_wen,
    input  wire [4:0]  wb_rd,

    output reg         stall_if,
    output reg         bubble_ex,
    output reg         fwdA,
    output reg         fwdB
);

    always @(*) begin
        stall_if  = 1'b0;
        bubble_ex = 1'b0;

        if (if_id_valid && ex_is_lw && (ex_rd != 5'd0)) begin
            if ((if_uses_rs1 && (if_rs1 == ex_rd)) ||
                (if_uses_rs2 && (if_rs2 == ex_rd))) begin
                stall_if  = 1'b1;
                bubble_ex = 1'b1;
            end
        end
    end

    always @(*) begin
        fwdA = 1'b0;
        fwdB = 1'b0;

        if (wb_valid && wb_wen && (wb_rd != 5'd0) && (wb_rd == if_rs1))
            fwdA = 1'b1;

        if (wb_valid && wb_wen && (wb_rd != 5'd0) && (wb_rd == if_rs2))
            fwdB = 1'b1;
    end

endmodule