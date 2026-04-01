module decoder( 
    input logic [31:0] inst,

    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,

    output logic uses_rs1,
    output logic uses_rs2,

    output logic is_imm,
    output logic [31:0] imm32, 

    output logic [2:0] alu_op,
    output logic reg_wen,

    output logic is_lw,
    output logic is_sw,

    output logic is_branch, 
    output logic branch_ne, // 0=BEQ, 1=BNE

    output logic is_jump,
    output logic [31:0] jump_target, // siimple absolute/pc-rel optional 

    output logic is_halt
);

    logic [5:0] opcode;
    logic [5:0] funct;

    assign opcode = inst[31:26];
    assign rs1 = inst[25:21];
    assign rs2 = inst[20:16];
    assign rd = inst[15:11];
    assign funct = inst[5:0];

    // sign-extend imm16
    assign imm32 = {{16{inst[15]}}, inst[15:0]};

    // defaults 
    always_comb begin 
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;
        is_imm = 1'b0;
        alu_op = 3'd0;
        reg_wen = 1'b0;
        is_lw = 1'b0;
        is_sw = 1'b0;
        is_branch = 1'b0;
        branch_ne = 1'b0;
        is_jump = 1'b0;
        jump_target = 32'd0;
        is_halt = 1'b0;
        
        unique case (opcode)
            6'b000000: begin // Register type: use funct. 
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                reg_wen = 1'b1;
                unique case (funct)
                    6'h20: alu_op = 3'd0; // ADD
                    6'h22: alu_op = 3'd1; // SUB
                    6'h24: alu_op = 3'd2; // AND
                    6'h25: alu_op = 3'd3; // OR
                    default: begin
                        reg_wen = 1'b0;   // treat unknown as NOP
                    end
                endcase 
            end 

            6'h08: begin // ADDI
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;
                is_imm = 1'b1;
                alu_op = 3'd0; // ADD 
                reg_wen = 1'b1;
            end

            6'h23: begin // LW
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b0;
                is_imm = 1'b1;
                alu_op = 3'd0; // ADD for address calc
                reg_wen = 1'b1;
                is_lw = 1'b1;
            end

            6'h2B: begin // SW
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1; 
                is_imm = 1'b1;
                alu_op = 3'd0;
                is_sw = 1'b1;
                reg_wen = 1'b0; // no writeback
            end 

            6'h04: begin // BEQ
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                is_branch = 1'b1;
                branch_ne = 1'b0; 
            end
            6'h05: begin // BNE
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                is_branch = 1'b1;
                branch_ne = 1'b1; 
            end
            6'h3F: begin // HALT (custom)
                is_halt = 1'b1;
            end
            default: begin 
                // NOP
            end
        endcase 
    end
endmodule


