module ex_wb_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,

    input  wire        in_valid,
    input  wire        in_wen,
    input  wire [4:0]  in_rd,
    input  wire [31:0] in_wdata,
    input  wire        in_halt,

    output reg         out_valid,
    output reg         out_wen,
    output reg [4:0]   out_rd,
    output reg [31:0]  out_wdata,
    output reg         out_halt
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_wen   <= 1'b0;
            out_rd    <= 5'd0;
            out_wdata <= 32'd0;
            out_halt  <= 1'b0;
        end
        else if (flush) begin
            out_valid <= 1'b0;
            out_wen   <= 1'b0;
            out_rd    <= 5'd0;
            out_wdata <= 32'd0;
            out_halt  <= 1'b0;
        end
        else begin
            out_valid <= in_valid;
            out_wen   <= in_wen;
            out_rd    <= in_rd;
            out_wdata <= in_wdata;
            out_halt  <= in_halt;
        end
    end

endmodule