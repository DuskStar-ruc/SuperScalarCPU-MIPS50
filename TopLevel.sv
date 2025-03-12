`timescale 1us/1us

`include "defs.sv"

module TopLevel(input clock, input reset);

    // 采用消极的方式声明，定义�??有的输入输出信号，且不为其赋值或连接，以便于后续代码可读�??
    PipelineReg_t IF_ID_in, IF_ID_in_, IF_ID_out, ID_EX_in, ID_EX_in_, ID_EX_out,
                  EX_MEM_in, EX_MEM_out, MEM_WB_in, MEM_WB_out;
    PipelineReg IF_ID_reg(.in(IF_ID_in_), .out(IF_ID_out), .clock(clock), .reset(reset));
    PipelineReg ID_EX_reg(.in(ID_EX_in_), .out(ID_EX_out), .clock(clock), .reset(reset));
    PipelineReg EX_MEM_reg(.in(EX_MEM_in), .out(EX_MEM_out), .clock(clock), .reset(reset));
    PipelineReg MEM_WB_reg(.in(MEM_WB_in), .out(MEM_WB_out), .clock(clock), .reset(reset));

    PC_in_t pc_in_inst1, pc_in_inst2;
    PC_out_t pc_out_inst1, pc_out_inst2;
    wire pc_first;
    wire branch_res1, branch_res2;
    PC pc(.inst1(pc_in_inst1), .inst2(pc_in_inst2), .first(pc_first), .clock(clock), .reset(reset), .out1(pc_out_inst1), .out2(pc_out_inst2));

    wire [31:0] im_addr_inst1, im_addr_inst2, im_inst1, im_inst2;
    InstructionMemory im(.addr1(im_addr_inst1), .addr2(im_addr_inst2), .inst1(im_inst1), .inst2(im_inst2));

    wire [31:0] cu_inst1, cu_inst2;
    ControlSignals signal_inst1, signal_inst2;
    SB_in_t cu_to_sb_inst1, cu_to_sb_inst2;
    ControllerUnit cu1(.inst(cu_inst1), .signal(signal_inst1), .sb_in(cu_to_sb_inst1));
    ControllerUnit cu2(.inst(cu_inst2), .signal(signal_inst2), .sb_in(cu_to_sb_inst2));

    SB_in_t sb_in_inst1, sb_in_inst2;
    SB_out_t sb_out_inst1, sb_out_inst2;
    wire sb_out_first;
    ScoreBoard sb(.inst1(sb_in_inst1), .inst2(sb_in_inst2), .clock(clock), .reset(reset), .out1(sb_out_inst1), .out2(sb_out_inst2), .first(sb_out_first));

    GPR_in_t gpr_in_inst1, gpr_in_inst2;
    GPR_out_t gpr_out_inst1, gpr_out_inst2;
    wire gpr_first;
    GeneralPurposeRegisters gpr(.inst1(gpr_in_inst1), .inst2(gpr_in_inst2), .clock(clock), .reset(reset), .first(gpr_first), .out1(gpr_out_inst1), .out2(gpr_out_inst2));

    wire [31:0] alu_in1_inst1, alu_in2_inst1, alu_in1_inst2, alu_in2_inst2, alu_res_inst1, alu_res_inst2;
    ALU_op_t alu_op_inst1, alu_op_inst2;
    wire alu_overflow_inst1, alu_overflow_inst2;
    ALU alu1(.x(alu_in1_inst1), .y(alu_in2_inst1), .op(alu_op_inst1), .res(alu_res_inst1), .overflow(alu_overflow_inst1));
    ALU alu2(.x(alu_in1_inst2), .y(alu_in2_inst2), .op(alu_op_inst2), .res(alu_res_inst2), .overflow(alu_overflow_inst2));
    
    wire [31:0] mdu_in1, mdu_in2, mdu_dataRead;
    mdu_operation_t mdu_op;
    wire mdu_busy, mdu_start;
    MultiplicationDivisionUnit mdu(.reset(reset), .clock(clock), .operand1(mdu_in1), .operand2(mdu_in2), .operation(mdu_op), .start(mdu_start), .busy(mdu_busy), .dataRead(mdu_dataRead));

    DM_in_t dm_in_inst1, dm_in_inst2;
    DM_out_t dm_out_inst1, dm_out_inst2;
    wire dm_first;
    DataMemory dm(.inst_1(dm_in_inst1), .inst_2(dm_in_inst2), .clock(clock), .reset(reset), .first(dm_first), .out_1(dm_out_inst1), .out_2(dm_out_inst2));

    ROB_in_t rob_in_inst1, rob_in_inst2;
    ReorderBuffer rob(.inst1(rob_in_inst1), .inst2(rob_in_inst2), .clock(clock), .reset(reset));

    // IF stage
    assign pc_in_inst1.block = sb_out_inst1.block;
    assign pc_in_inst1.is_jmp = signal_inst1.jmp_type != JMP_NONE;
    assign pc_in_inst1.jmp_addr = (signal_inst1.jmp_type == JMP_ADDR) ?                 {IF_ID_out.inst1.pc[31:28], IF_ID_out.inst1.inst.J.addr, 2'b00} :
                                  (signal_inst1.jmp_type == JMP_REG) ?                   ID_EX_in.inst1.rsvalue : // 使用ID_EX_in的rsvalue, 以利用旁�??
                                  (signal_inst1.jmp_type == JMP_BRANCH && branch_res1) ? IF_ID_out.inst1.pc + 4 + {{16{IF_ID_out.inst1.inst.I.imm[15]}}, IF_ID_out.inst1.inst.I.imm} * 4 :
                                                                                         IF_ID_out.inst1.pc + 8; // pc�??要明确给出是否跳转，�??以将不跳转视为跳转至下一条指�??
    assign pc_in_inst2.block = sb_out_inst2.block;
    assign pc_in_inst2.is_jmp = signal_inst2.jmp_type != JMP_NONE;
    assign pc_in_inst2.jmp_addr = (signal_inst2.jmp_type == JMP_ADDR) ?                 {IF_ID_out.inst2.pc[31:28], IF_ID_out.inst2.inst.J.addr, 2'b00} :
                                  (signal_inst2.jmp_type == JMP_REG) ?                   ID_EX_in.inst2.rsvalue : // 使用ID_EX_in的rsvalue, 以利用旁�??
                                  (signal_inst2.jmp_type == JMP_BRANCH && branch_res2) ? IF_ID_out.inst2.pc + 4 + {{16{IF_ID_out.inst2.inst.I.imm[15]}}, IF_ID_out.inst2.inst.I.imm} * 4 :
                                                                                         IF_ID_out.inst2.pc + 8; // pc�??要明确给出是否跳转，�??以将不跳转视为跳转至下一条指�??
    assign pc_first = sb_out_first;

    assign im_addr_inst1 = pc_out_inst1.pc;
    assign im_addr_inst2 = pc_out_inst2.pc;

    assign IF_ID_in.inst1.effective = ~pc_out_inst1.null_flag;
    assign IF_ID_in.inst1.pc = pc_out_inst1.pc;
    assign IF_ID_in.inst1.rob_id = pc_out_inst1.rob_id;
    assign IF_ID_in.inst1.inst = im_inst1;
    assign {IF_ID_in.inst1.signal, IF_ID_in.inst1.fakewb, IF_ID_in.inst1.rs_forward, IF_ID_in.inst1.rt_forward,
            IF_ID_in.inst1.rsvalue, IF_ID_in.inst1.rtvalue, IF_ID_in.inst1.extend_imm, IF_ID_in.inst1.ex_result, 
            IF_ID_in.inst1.mem_result, IF_ID_in.inst1.mem_writeData, IF_ID_in.inst1.mem_writeAddr, IF_ID_in.inst1.exception} = 0;

    assign IF_ID_in.inst2.effective = ~pc_out_inst2.null_flag;
    assign IF_ID_in.inst2.pc = pc_out_inst2.pc;
    assign IF_ID_in.inst2.rob_id = pc_out_inst2.rob_id;
    assign IF_ID_in.inst2.inst = im_inst2;
    assign {IF_ID_in.inst2.signal, IF_ID_in.inst2.fakewb, IF_ID_in.inst2.rs_forward, IF_ID_in.inst2.rt_forward,
            IF_ID_in.inst2.rsvalue, IF_ID_in.inst2.rtvalue, IF_ID_in.inst2.extend_imm, IF_ID_in.inst2.ex_result,
            IF_ID_in.inst2.mem_result, IF_ID_in.inst2.mem_writeData, IF_ID_in.inst2.mem_writeAddr, IF_ID_in.inst2.exception} = 0;

    assign IF_ID_in.first = 0;

    assign IF_ID_in_.inst1 = sb_out_inst1.block ?  IF_ID_out.inst1 : IF_ID_in.inst1;
    assign IF_ID_in_.inst2 = sb_out_inst2.block ?  IF_ID_out.inst2 : IF_ID_in.inst2;
    assign IF_ID_in_.first = IF_ID_in.first;

    // ID stage
    assign cu_inst1 = IF_ID_out.inst1.inst;
    assign cu_inst2 = IF_ID_out.inst2.inst;

    assign sb_in_inst1 = cu_to_sb_inst1;
    assign sb_in_inst2 = cu_to_sb_inst2;

    assign gpr_in_inst1.read1 = signal_inst1.syscall ? 2 : IF_ID_out.inst1.inst.R.rs; //syscall v0寄存�??
    assign gpr_in_inst1.read2 = signal_inst1.syscall ? 4 : IF_ID_out.inst1.inst.R.rt; //syscall a0寄存�??
    assign gpr_in_inst2.read1 = signal_inst2.syscall ? 2 : IF_ID_out.inst2.inst.R.rs; //syscall v0寄存�??
    assign gpr_in_inst2.read2 = signal_inst2.syscall ? 4 : IF_ID_out.inst2.inst.R.rt; //syscall a0寄存�??

    assign branch_res1 = (signal_inst1.branch_type == BRANCH_EQ && ID_EX_in.inst1.rsvalue == ID_EX_in.inst1.rtvalue) ||
                         (signal_inst1.branch_type == BRANCH_NE && ID_EX_in.inst1.rsvalue != ID_EX_in.inst1.rtvalue) ||
                         (signal_inst1.branch_type == BRANCH_LT && $signed(ID_EX_in.inst1.rsvalue) < 0) ||
                         (signal_inst1.branch_type == BRANCH_LE && $signed(ID_EX_in.inst1.rsvalue) <= 0) ||
                         (signal_inst1.branch_type == BRANCH_GT && $signed(ID_EX_in.inst1.rsvalue) > 0) ||
                         (signal_inst1.branch_type == BRANCH_GE && $signed(ID_EX_in.inst1.rsvalue) >= 0);
    assign branch_res2 = (signal_inst2.branch_type == BRANCH_EQ && ID_EX_in.inst2.rsvalue == ID_EX_in.inst2.rtvalue) ||
                         (signal_inst2.branch_type == BRANCH_NE && ID_EX_in.inst2.rsvalue != ID_EX_in.inst2.rtvalue) ||
                         (signal_inst2.branch_type == BRANCH_LT && $signed(ID_EX_in.inst2.rsvalue) < 0) ||
                         (signal_inst2.branch_type == BRANCH_LE && $signed(ID_EX_in.inst2.rsvalue) <= 0) ||
                         (signal_inst2.branch_type == BRANCH_GT && $signed(ID_EX_in.inst2.rsvalue) > 0) ||
                         (signal_inst2.branch_type == BRANCH_GE && $signed(ID_EX_in.inst2.rsvalue) >= 0);

    assign ID_EX_in.inst1.effective = IF_ID_out.inst1.effective && ~sb_out_inst1.block;
    assign {ID_EX_in.inst1.pc, ID_EX_in.inst1.rob_id, ID_EX_in.inst1.inst} = {IF_ID_out.inst1.pc, IF_ID_out.inst1.rob_id, IF_ID_out.inst1.inst};
    assign ID_EX_in.inst1.signal = signal_inst1;
    assign ID_EX_in.inst1.fakewb = sb_out_inst1.fakewb;
    assign ID_EX_in.inst1.rs_forward = sb_out_inst1.rs_forward;
    assign ID_EX_in.inst1.rt_forward = sb_out_inst1.rt_forward;
    assign ID_EX_in.inst1.rsvalue = (!sb_out_inst1.rs_forward.need_forward || !sb_out_inst1.rs_forward.target == EX_STAGE) ? gpr_out_inst1.read1 :
                                    (sb_out_inst1.rs_forward.source.line==0 && sb_out_inst1.rs_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst1.ex_result :
                                    (sb_out_inst1.rs_forward.source.line==0 && sb_out_inst1.rs_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst1.mem_result :
                                    (sb_out_inst1.rs_forward.source.line==1 && sb_out_inst1.rs_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst2.ex_result :
                                    (sb_out_inst1.rs_forward.source.line==1 && sb_out_inst1.rs_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst2.mem_result : 0;
    assign ID_EX_in.inst1.rtvalue = (!sb_out_inst1.rt_forward.need_forward || !sb_out_inst1.rt_forward.target == EX_STAGE) ? gpr_out_inst1.read2 :
                                    (sb_out_inst1.rt_forward.source.line==0 && sb_out_inst1.rt_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst1.ex_result :
                                    (sb_out_inst1.rt_forward.source.line==0 && sb_out_inst1.rt_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst1.mem_result :
                                    (sb_out_inst1.rt_forward.source.line==1 && sb_out_inst1.rt_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst2.ex_result :
                                    (sb_out_inst1.rt_forward.source.line==1 && sb_out_inst1.rt_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst2.mem_result : 0;
    assign ID_EX_in.inst1.extend_imm = (signal_inst1.extend_con == EXTEND_SIGN) ? {{16{IF_ID_out.inst1.inst.I.imm[15]}}, IF_ID_out.inst1.inst.I.imm} :
                                       (signal_inst1.extend_con == EXTEND_ZERO) ? {16'b0, IF_ID_out.inst1.inst.I.imm} :
                                       (signal_inst1.extend_con == EXTEND_LSHIFT) ? {IF_ID_out.inst1.inst.I.imm, 16'b0} : 0;
    assign {ID_EX_in.inst1.ex_result, ID_EX_in.inst1.mem_result, ID_EX_in.inst1.mem_writeData, ID_EX_in.inst1.mem_writeAddr, ID_EX_in.inst1.exception} = 0;

    assign ID_EX_in.inst2.effective = IF_ID_out.inst2.effective && ~sb_out_inst2.block;
    assign {ID_EX_in.inst2.pc, ID_EX_in.inst2.rob_id, ID_EX_in.inst2.inst} = {IF_ID_out.inst2.pc, IF_ID_out.inst2.rob_id, IF_ID_out.inst2.inst};
    assign ID_EX_in.inst2.signal = signal_inst2;
    assign ID_EX_in.inst2.fakewb = sb_out_inst2.fakewb;
    assign ID_EX_in.inst2.rs_forward = sb_out_inst2.rs_forward;
    assign ID_EX_in.inst2.rt_forward = sb_out_inst2.rt_forward;
    assign ID_EX_in.inst2.rsvalue = (!sb_out_inst2.rs_forward.need_forward || !sb_out_inst2.rs_forward.target == EX_STAGE) ? gpr_out_inst2.read1 :
                                    (sb_out_inst2.rs_forward.source.line==0 && sb_out_inst2.rs_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst1.ex_result :
                                    (sb_out_inst2.rs_forward.source.line==0 && sb_out_inst2.rs_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst1.mem_result :
                                    (sb_out_inst2.rs_forward.source.line==1 && sb_out_inst2.rs_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst2.ex_result :
                                    (sb_out_inst2.rs_forward.source.line==1 && sb_out_inst2.rs_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst2.mem_result : 0;
    assign ID_EX_in.inst2.rtvalue = (!sb_out_inst2.rt_forward.need_forward || !sb_out_inst2.rt_forward.target == EX_STAGE) ? gpr_out_inst2.read2 :
                                    (sb_out_inst2.rt_forward.source.line==0 && sb_out_inst2.rt_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst1.ex_result :
                                    (sb_out_inst2.rt_forward.source.line==0 && sb_out_inst2.rt_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst1.mem_result :
                                    (sb_out_inst2.rt_forward.source.line==1 && sb_out_inst2.rt_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst2.ex_result :
                                    (sb_out_inst2.rt_forward.source.line==1 && sb_out_inst2.rt_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst2.mem_result : 0;
    assign ID_EX_in.inst2.extend_imm = (signal_inst2.extend_con == EXTEND_SIGN) ? {{16{IF_ID_out.inst2.inst.I.imm[15]}}, IF_ID_out.inst2.inst.I.imm} :
                                       (signal_inst2.extend_con == EXTEND_ZERO) ? {16'b0, IF_ID_out.inst2.inst.I.imm} :
                                       (signal_inst2.extend_con == EXTEND_LSHIFT) ? {IF_ID_out.inst2.inst.I.imm, 16'b0} : 0;
    assign {ID_EX_in.inst2.ex_result, ID_EX_in.inst2.mem_result, ID_EX_in.inst2.mem_writeData, ID_EX_in.inst2.mem_writeAddr, ID_EX_in.inst2.exception} = 0;

    assign ID_EX_in.first = sb_out_first;

    assign ID_EX_in_.inst1 = ID_EX_in.inst1.effective ? ID_EX_in.inst1 : 0;
    assign ID_EX_in_.inst2 = ID_EX_in.inst2.effective ? ID_EX_in.inst2 : 0;
    assign ID_EX_in_.first = ID_EX_in.first;

    // EX stage
    assign alu_in1_inst1 = (ID_EX_out.inst1.signal.alu_in1_con == ALU_IN1_RS) ? ID_EX_out.inst1.rsvalue :
                           (ID_EX_out.inst1.signal.alu_in1_con == ALU_IN1_SA) ? ID_EX_out.inst1.inst.R.sa :
                           (ID_EX_out.inst1.signal.alu_in1_con == ALU_IN1_PC) ? ID_EX_out.inst1.pc : 0;
    assign alu_in2_inst1 = (ID_EX_out.inst1.signal.alu_in2_con == ALU_IN2_RT) ? ID_EX_out.inst1.rtvalue :
                           (ID_EX_out.inst1.signal.alu_in2_con == ALU_IN2_IMM) ? ID_EX_out.inst1.extend_imm : 0;
    assign alu_op_inst1 = ID_EX_out.inst1.signal.alu_op;
    assign alu_in1_inst2 = (ID_EX_out.inst2.signal.alu_in1_con == ALU_IN1_RS) ? ID_EX_out.inst2.rsvalue :
                           (ID_EX_out.inst2.signal.alu_in1_con == ALU_IN1_SA) ? ID_EX_out.inst2.inst.R.sa :
                           (ID_EX_out.inst2.signal.alu_in1_con == ALU_IN1_PC) ? ID_EX_out.inst2.pc : 0;
    assign alu_in2_inst2 = (ID_EX_out.inst2.signal.alu_in2_con == ALU_IN2_RT) ? ID_EX_out.inst2.rtvalue :
                           (ID_EX_out.inst2.signal.alu_in2_con == ALU_IN2_IMM) ? ID_EX_out.inst2.extend_imm : 0;
    assign alu_op_inst2 = ID_EX_out.inst2.signal.alu_op;

    assign mdu_in1 = ID_EX_out.inst1.signal.mdu_start ? ID_EX_out.inst1.rsvalue :
                     ID_EX_out.inst2.signal.mdu_start ? ID_EX_out.inst2.rsvalue : 0;
    assign mdu_in2 = ID_EX_out.inst1.signal.mdu_start ? ID_EX_out.inst1.rtvalue :
                     ID_EX_out.inst2.signal.mdu_start ? ID_EX_out.inst2.rtvalue : 0;
    assign mdu_op = ID_EX_out.inst1.signal.mdu_start ? ID_EX_out.inst1.signal.mdu_op :
                    ID_EX_out.inst2.signal.mdu_start ? ID_EX_out.inst2.signal.mdu_op : MDU_READ_HI;
    assign mdu_start = ID_EX_out.inst1.signal.mdu_start || ID_EX_out.inst2.signal.mdu_start;

    assign {EX_MEM_in.inst1.effective, EX_MEM_in.inst1.pc, EX_MEM_in.inst1.rob_id, EX_MEM_in.inst1.inst,
            EX_MEM_in.inst1.signal, EX_MEM_in.inst1.fakewb, EX_MEM_in.inst1.rs_forward, EX_MEM_in.inst1.rt_forward,
            EX_MEM_in.inst1.extend_imm} = {ID_EX_out.inst1.effective, ID_EX_out.inst1.pc, ID_EX_out.inst1.rob_id, ID_EX_out.inst1.inst,
                                     ID_EX_out.inst1.signal, ID_EX_out.inst1.fakewb, ID_EX_out.inst1.rs_forward, ID_EX_out.inst1.rt_forward,
                                     ID_EX_out.inst1.extend_imm};
    assign EX_MEM_in.inst1.rsvalue = (!ID_EX_out.inst1.rs_forward.need_forward || !ID_EX_out.inst1.rs_forward.target == MEM_STAGE) ? ID_EX_out.inst1.rsvalue :
                                    //  (ID_EX_out.inst1.rs_forward.source.line==0 && ID_EX_out.inst1.rs_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst1.ex_result : // 不可能发�??
                                     (ID_EX_out.inst1.rs_forward.source.line==0 && ID_EX_out.inst1.rs_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst1.mem_result :
                                     (ID_EX_out.inst1.rs_forward.source.line==1 && ID_EX_out.inst1.rs_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst2.ex_result :
                                     (ID_EX_out.inst1.rs_forward.source.line==1 && ID_EX_out.inst1.rs_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst2.mem_result : 0;
    assign EX_MEM_in.inst1.rtvalue = (!ID_EX_out.inst1.rt_forward.need_forward || !ID_EX_out.inst1.rt_forward.target == MEM_STAGE) ? ID_EX_out.inst1.rtvalue :
                                    //  (ID_EX_out.inst1.rt_forward.source.line==0 && ID_EX_out.inst1.rt_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst1.ex_result : // 不可能发�??
                                     (ID_EX_out.inst1.rt_forward.source.line==0 && ID_EX_out.inst1.rt_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst1.mem_result :
                                     (ID_EX_out.inst1.rt_forward.source.line==1 && ID_EX_out.inst1.rt_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst2.ex_result :
                                     (ID_EX_out.inst1.rt_forward.source.line==1 && ID_EX_out.inst1.rt_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst2.mem_result : 0;
    assign EX_MEM_in.inst1.ex_result = (ID_EX_out.inst1.signal.gpr_wdata_con == GPR_WDATA_MDU) ? mdu_dataRead : alu_res_inst1;
    assign {EX_MEM_in.inst1.mem_result, EX_MEM_in.inst1.mem_writeData, EX_MEM_in.inst1.mem_writeAddr} = 0;
    assign EX_MEM_in.inst1.exception = ID_EX_out.inst1.signal.overflow_exception && alu_overflow_inst1;

    assign {EX_MEM_in.inst2.effective, EX_MEM_in.inst2.pc, EX_MEM_in.inst2.rob_id, EX_MEM_in.inst2.inst,
            EX_MEM_in.inst2.signal, EX_MEM_in.inst2.fakewb, EX_MEM_in.inst2.rs_forward, EX_MEM_in.inst2.rt_forward,
            EX_MEM_in.inst2.extend_imm} = {ID_EX_out.inst2.effective, ID_EX_out.inst2.pc, ID_EX_out.inst2.rob_id, ID_EX_out.inst2.inst,
                                     ID_EX_out.inst2.signal, ID_EX_out.inst2.fakewb, ID_EX_out.inst2.rs_forward, ID_EX_out.inst2.rt_forward,
                                     ID_EX_out.inst2.extend_imm};
    assign EX_MEM_in.inst2.rsvalue = (!ID_EX_out.inst2.rs_forward.need_forward || !ID_EX_out.inst2.rs_forward.target == MEM_STAGE) ? ID_EX_out.inst2.rsvalue :
                                     (ID_EX_out.inst2.rs_forward.source.line==0 && ID_EX_out.inst2.rs_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst1.ex_result :
                                     (ID_EX_out.inst2.rs_forward.source.line==0 && ID_EX_out.inst2.rs_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst1.mem_result :
                                    //  (ID_EX_out.inst2.rs_forward.source.line==1 && ID_EX_out.inst2.rs_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst2.ex_result : // 不可能发�??
                                     (ID_EX_out.inst2.rs_forward.source.line==1 && ID_EX_out.inst2.rs_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst2.mem_result : 0;
    assign EX_MEM_in.inst2.rtvalue = (!ID_EX_out.inst2.rt_forward.need_forward || !ID_EX_out.inst2.rt_forward.target == MEM_STAGE) ? ID_EX_out.inst2.rtvalue :
                                     (ID_EX_out.inst2.rt_forward.source.line==0 && ID_EX_out.inst2.rt_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst1.ex_result :
                                     (ID_EX_out.inst2.rt_forward.source.line==0 && ID_EX_out.inst2.rt_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst1.mem_result :
                                    //  (ID_EX_out.inst2.rt_forward.source.line==1 && ID_EX_out.inst2.rt_forward.source.stage == EX_STAGE) ? EX_MEM_in.inst2.ex_result : // 不可能发�??
                                     (ID_EX_out.inst2.rt_forward.source.line==1 && ID_EX_out.inst2.rt_forward.source.stage == MEM_STAGE) ? MEM_WB_in.inst2.mem_result : 0;
    assign EX_MEM_in.inst2.ex_result = (ID_EX_out.inst2.signal.gpr_wdata_con == GPR_WDATA_MDU) ? mdu_dataRead : alu_res_inst2;
    assign {EX_MEM_in.inst2.mem_result, EX_MEM_in.inst2.mem_writeData, EX_MEM_in.inst2.mem_writeAddr} = 0;
    assign EX_MEM_in.inst2.exception = ID_EX_out.inst2.signal.overflow_exception && alu_overflow_inst2;

    assign EX_MEM_in.first = ID_EX_out.first;

    // MEM stage
    assign dm_in_inst1.address = EX_MEM_out.inst1.ex_result;
    assign dm_in_inst1.writeInput = EX_MEM_out.inst1.rtvalue;
    assign dm_in_inst1.writeEnabled = EX_MEM_out.inst1.signal.mem_writeenable;
    assign dm_in_inst1.readSigned = EX_MEM_out.inst1.signal.mem_readsigned;
    assign dm_in_inst1.size = EX_MEM_out.inst1.signal.mem_size;
    assign dm_in_inst2.address = EX_MEM_out.inst2.ex_result;
    assign dm_in_inst2.writeInput = EX_MEM_out.inst2.rtvalue;
    assign dm_in_inst2.writeEnabled = EX_MEM_out.inst2.signal.mem_writeenable;
    assign dm_in_inst2.readSigned = EX_MEM_out.inst2.signal.mem_readsigned;
    assign dm_in_inst2.size = EX_MEM_out.inst2.signal.mem_size;
    assign dm_first = EX_MEM_out.first;

    assign {MEM_WB_in.inst1.effective, MEM_WB_in.inst1.pc, MEM_WB_in.inst1.rob_id, MEM_WB_in.inst1.inst,
            MEM_WB_in.inst1.signal, MEM_WB_in.inst1.fakewb, MEM_WB_in.inst1.rs_forward, MEM_WB_in.inst1.rt_forward,
            MEM_WB_in.inst1.rsvalue, MEM_WB_in.inst1.rtvalue, MEM_WB_in.inst1.extend_imm, MEM_WB_in.inst1.ex_result} =
            {EX_MEM_out.inst1.effective, EX_MEM_out.inst1.pc, EX_MEM_out.inst1.rob_id, EX_MEM_out.inst1.inst,
             EX_MEM_out.inst1.signal, EX_MEM_out.inst1.fakewb, EX_MEM_out.inst1.rs_forward, EX_MEM_out.inst1.rt_forward,
             EX_MEM_out.inst1.rsvalue, EX_MEM_out.inst1.rtvalue, EX_MEM_out.inst1.extend_imm, EX_MEM_out.inst1.ex_result};
    assign MEM_WB_in.inst1.mem_result = (EX_MEM_out.inst1.signal.gpr_wdata_con == GPR_WDATA_MEM) ? dm_out_inst1.result : EX_MEM_out.inst1.ex_result; // 使ALU/MDU结果可以通过MEM旁路转发
    assign MEM_WB_in.inst1.mem_writeData = dm_out_inst1.writeData;
    assign MEM_WB_in.inst1.mem_writeAddr = dm_out_inst1.writeAddr;
    assign MEM_WB_in.inst1.exception = EX_MEM_out.inst1.exception;

    assign {MEM_WB_in.inst2.effective, MEM_WB_in.inst2.pc, MEM_WB_in.inst2.rob_id, MEM_WB_in.inst2.inst,
            MEM_WB_in.inst2.signal, MEM_WB_in.inst2.fakewb, MEM_WB_in.inst2.rs_forward, MEM_WB_in.inst2.rt_forward,
            MEM_WB_in.inst2.rsvalue, MEM_WB_in.inst2.rtvalue, MEM_WB_in.inst2.extend_imm, MEM_WB_in.inst2.ex_result} =
            {EX_MEM_out.inst2.effective, EX_MEM_out.inst2.pc, EX_MEM_out.inst2.rob_id, EX_MEM_out.inst2.inst,
             EX_MEM_out.inst2.signal, EX_MEM_out.inst2.fakewb, EX_MEM_out.inst2.rs_forward, EX_MEM_out.inst2.rt_forward,
             EX_MEM_out.inst2.rsvalue, EX_MEM_out.inst2.rtvalue, EX_MEM_out.inst2.extend_imm, EX_MEM_out.inst2.ex_result};
    assign MEM_WB_in.inst2.mem_result = (EX_MEM_out.inst2.signal.gpr_wdata_con == GPR_WDATA_MEM) ? dm_out_inst2.result : EX_MEM_out.inst2.ex_result; // 使ALU/MDU结果可以通过MEM旁路转发
    assign MEM_WB_in.inst2.mem_writeData = dm_out_inst2.writeData;
    assign MEM_WB_in.inst2.mem_writeAddr = dm_out_inst2.writeAddr;
    assign MEM_WB_in.inst2.exception = EX_MEM_out.inst2.exception;

    assign MEM_WB_in.first = EX_MEM_out.first;

    // WB stage
    assign gpr_in_inst1.write = (MEM_WB_out.inst1.signal.gpr_wreg_con == GPR_WREG_RT) ? MEM_WB_out.inst1.inst.R.rt :
                                (MEM_WB_out.inst1.signal.gpr_wreg_con == GPR_WREG_RD) ? MEM_WB_out.inst1.inst.R.rd :
                                (MEM_WB_out.inst1.signal.gpr_wreg_con == GPR_WREG_31) ? 5'b11111 : 0;
    assign gpr_in_inst1.writeData = MEM_WB_out.inst1.mem_result;
    assign gpr_in_inst1.writeEnabled = MEM_WB_out.inst1.signal.gpr_writeenable && !MEM_WB_out.inst1.fakewb && gpr_in_inst1.write != 0;
    assign gpr_in_inst2.write = (MEM_WB_out.inst2.signal.gpr_wreg_con == GPR_WREG_RT) ? MEM_WB_out.inst2.inst.R.rt :
                                (MEM_WB_out.inst2.signal.gpr_wreg_con == GPR_WREG_RD) ? MEM_WB_out.inst2.inst.R.rd :
                                (MEM_WB_out.inst2.signal.gpr_wreg_con == GPR_WREG_31) ? 5'b11111 : 0;
    assign gpr_in_inst2.writeData = MEM_WB_out.inst2.mem_result;
    assign gpr_in_inst2.writeEnabled = MEM_WB_out.inst2.signal.gpr_writeenable && !MEM_WB_out.inst2.fakewb && gpr_in_inst2.write != 0;
    assign gpr_first = MEM_WB_out.first;

    assign rob_in_inst1.null_flag = MEM_WB_out.inst1.effective ? 0 : 1;
    assign rob_in_inst1.end_flag = (MEM_WB_out.inst1.signal.syscall && (MEM_WB_out.inst1.rsvalue == 10)) || MEM_WB_out.inst1.exception;
    assign rob_in_inst1.rob_id = MEM_WB_out.inst1.rob_id;
    assign rob_in_inst1.pc = MEM_WB_out.inst1.pc;
    assign rob_in_inst1.data = MEM_WB_out.inst1.signal.mem_writeenable ? MEM_WB_out.inst1.mem_writeData :
                               MEM_WB_out.inst1.signal.gpr_writeenable ? MEM_WB_out.inst1.mem_result :
                               (MEM_WB_out.inst1.signal.syscall && (MEM_WB_out.inst1.rsvalue == 1)) ? MEM_WB_out.inst1.rtvalue : 0;
    assign rob_in_inst1.addr = MEM_WB_out.inst1.mem_writeAddr;
    assign rob_in_inst1.regid = gpr_in_inst1.write;
    assign rob_in_inst1.wtype = MEM_WB_out.inst1.signal.mem_writeenable ? ROB_MEM :
                                MEM_WB_out.inst1.signal.gpr_writeenable ? ROB_REG :
                               (MEM_WB_out.inst1.signal.syscall && (MEM_WB_out.inst1.rsvalue == 1)) ? ROB_OUT : ROB_NONE;
    assign rob_in_inst2.null_flag = MEM_WB_out.inst2.effective ? 0 : 1;
    assign rob_in_inst2.end_flag = MEM_WB_out.inst2.signal.syscall && (MEM_WB_out.inst2.rsvalue == 10) || MEM_WB_out.inst2.exception;
    assign rob_in_inst2.rob_id = MEM_WB_out.inst2.rob_id;
    assign rob_in_inst2.pc = MEM_WB_out.inst2.pc;
    assign rob_in_inst2.data = MEM_WB_out.inst2.signal.mem_writeenable ? MEM_WB_out.inst2.mem_writeData :
                               MEM_WB_out.inst2.signal.gpr_writeenable ? MEM_WB_out.inst2.mem_result :
                               (MEM_WB_out.inst2.signal.syscall && (MEM_WB_out.inst2.rsvalue == 1)) ? MEM_WB_out.inst2.rtvalue : 0;
    assign rob_in_inst2.addr = MEM_WB_out.inst2.mem_writeAddr;
    assign rob_in_inst2.regid = gpr_in_inst2.write;
    assign rob_in_inst2.wtype = MEM_WB_out.inst2.signal.mem_writeenable ? ROB_MEM :
                                MEM_WB_out.inst2.signal.gpr_writeenable ? ROB_REG :
                               (MEM_WB_out.inst2.signal.syscall && (MEM_WB_out.inst2.rsvalue == 1)) ? ROB_OUT : ROB_NONE;
endmodule