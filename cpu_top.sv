module cpu_top #(
    parameter int IMEM_DEPTH = 1024,
    parameter int DMEM_DEPTH = 1024,
    parameter IMEM_FILE = ""
)(
    input logic clk, 
    input logic rst_n,
    output logic halted
);

// IF stage: PC + instruction fetch 
    logic [31:0] pc_q, pc_d; // q is current pc, d is next pc, which needs to be caluclated based on branch/jump logic, so we know where to go next.
    logic [31:0] if_inst;
    logic stall_if, flush_if;
    logic branch_taken;
    logic [31:0] branch_target;

    // simple PC register with stall/redirect 
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) pc_q <= 32'd0;
        else if (!stall_if) pc_q <= pc_d;
    end

    always_comb begin
        if (branch_taken) pc_d = branch_target;
        else pc_d = pc_q + 32'd4;
    end

    imem #(.DEPTH_WORDS(IMEM_DEPTH), .MEMFILE(IMEM_FILE)) u_imem(
        .addr(pc_q),
        .inst(if_inst) // how we get the instruction 
    );

    // IF/ID pipeline reg inputs 
    logic [31:0] if_id_pc, if_id_inst;
    logic if_id_valid;
    if_id_reg u_if_id(
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall_if),
        .flush(flush_if),
        .in_pc(pc_q),
        .in_inst(if_inst),
        .in_valid(1'b1), // fetched instruciton is "real" unless flushed/reset
        .out_pc(if_id_pc),
        .out_inst(if_id_inst),
        .out_valid(if_id_valid)
    );

    // EX stage: decode + regfile + forwarding + ALU + mem +branch 
    //Decode outputs
    logic [4:0] rs1, rs2, rd_rtype;
    logic uses_rs1, uses_rs2;
    logic is_imm;
    logic [31:0] imm32;
    logic [2:0] alu_op;
    logic reg_wen_dec;
    logic is_lw, is_sw;
    logic is_branch, branch_ne;
    logic is_jump;
    logic [31:0] jump_target;
    logic is_halt; 


    decoder u_dec (
        .inst(if_id_inst),
        .rs1(rs1), .rs2(rs2), .rd(rd_rtype),
        .uses_rs1(uses_rs1), .uses_rs2(uses_rs2),
        .is_imm(is_imm), .imm32(imm32),
        .alu_op(alu_op),
        .reg_wen(reg_wen_dec),
        .is_lw(is_lw),
        .is_sw(is_sw),
        .is_branch(is_branch), .branch_ne(branch_ne),
        .is_jump(is_jump), .jump_target(jump_target),
        .is_halt(is_halt)
    );

    // Regfile
    logic rf_wen;
    logic [4:0] rf_waddr;
    logic [31:0] rf_wdata;
    logic [31:0] rf_rdata1, rf_rdata2;

    regfile u_rf(
        .clk(clk),
        .wen(rf_wen),
        .waddr(rf_waddr),
        .wdata(rf_wdata),
        .raddr1(rs1),
        .raddr2(rs2),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2)
    );

    // WB bundle (from EX/WB reg) for forwarding
    logic wb_valid, wb_wen;
    logic [4:0] wb_rd;
    logic [31:0] wb_wdata;
    logic wb_halt;

    // hazard + forwarding 
    logic bubble_ex, fwdA, fwdB;
    hazard_unit u_haz (
        .if_id_valid(if_id_valid),
        .if_rs1(rs1),
        .if_rs2(rs2),
        .if_uses_rs1(uses_rs1),
        .if_uses_rs2(uses_rs2),
        .ex_is_lw(is_lw && if_id_valid), // Ex sees current decoded instr
        .ex_rd( (if_id_inst[31:26]==6'b000000) ? rd_rtype : if_id_inst[20:16]), // rough destination
        .wb_valid(wb_valid),
        .wb_wen(wb_wen),
        .wb_rd(wb_rd),
        .stall_if(stall_if),
        .bubble_ex(bubble_ex), // if we do stall, there will be a garbage value in the write back stage potentially, so we diregard it with a flag that is
        //generated in the hazard module
        .fwdA(fwdA),
        .fwdB(fwdB)
    );

    // Operand selection with forwarding 
    logic [31:0] opA_raw, opB_raw, opA, opB;
    assign opA_raw = rf_rdata1;
    assign opB_raw = rf_rdata2; 
    // these rawd are what the register file already denotes these registers as. We have OpA anad opB
    // becuase there is a chance of a necesarry wb, we need to check the fwd flags

    assign opA = fwdA ? wb_wdata : opA_raw; // if true, make it equal to the wb data

    // B operand : either forwarded reg value or imm 
    logic [31:0] regB;
    assign regB = fwdB ? wb_wdata : opB_raw;
    assign opB = is_imm ? imm32 : regB; // if true, make it equal to the imm value, else use the register value (which may have been forwarded)


    // ALU
    logic [31:0] alu_y;
    logic alu_zero;

    alu u_alu ( 
        .a(opA),
        .b(opB),
        .op(alu_op),
        .y(alu_y),
        .zero(alu_zero)
    );


    // data memory 
    logic [31:0] dmem_rdata; 
    dmem #(.DEPTH_WORDS(DMEM_DEPTH)) u_dmem (
        .clk(clk),
        .we(if_id_valid && is_sw && !bubble_ex),
        .addr(alu_y),
        .wdata(regB), // store data comes from rs2 (after forwarding)
        .rdata(dmem_rdata) 
    );

    // Branch decision
    logic take_branch;
    always_comb begin
        take_branch  = 1'b0;
        if  (if_id_valid && is_branch && !bubble_ex) begin
            if (!branch_ne) take_branch = (regB == opA); // BEQ :: rs1 == rs2
            else take_branch = (regB != opA); // BNE
        end
    end

    assign branch_taken = take_branch; // (jump not included yet)
    assign branch_target = if_id_pc + 32'd4 + (imm32 <<2);

    // Flush when branch is taken (kill wrong-path intructions in IF/ID next cycle)
    assign flush_if = branch_taken; 
    
    // select WB data: for LW use dmem_rdata, else alu_y 
    logic [31:0] ex_result;
    assign ex_result = is_lw ? dmem_rdata: alu_y;

    // Destination reg seleciton: R-type uses rd, I-type use rt 
    logic [4:0] ex_rd;
    assign ex_rd = (if_id_inst[31:26] == 6'b000000) ? rd_rtype: if_id_inst[20:16]; // destinatin reg lies in different place for R vs I type, so we need to check the opcode to know where to look.

    // EX/WB pipeline reg inputs (bubble_ex kills this slot)
    logic ex_valid;
    assign ex_valid = if_id_valid && !bubble_ex;

    ex_wb_reg u_ex_wb(
        .clk(clk),
        .rst_n(rst_n),
        .flush(1'b0),
        .in_valid(ex_valid),
        .in_wen(ex_valid && reg_wen_dec),
        .in_rd(ex_rd),
        .in_wdata(ex_result),
        .in_halt(ex_valid && is_halt),
        .out_valid(wb_valid),
        .out_wen(wb_wen),
        .out_rd(wb_rd),
        .out_wdata(wb_wdata),
        .out_halt(wb_halt)

    );

    // WB stage: drive regfile wrtie prot + halted

    assign rf_wen = wb_valid && wb_wen && (wb_rd != 5'd0);
    assign rf_waddr = wb_rd;
    assign rf_wdata = wb_wdata;
    assign halted = wb_valid && wb_halt;
endmodule





