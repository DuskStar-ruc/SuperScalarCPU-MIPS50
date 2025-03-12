`timescale 1us/1us

`include "defs.sv"

module ControllerUnit(input Inst inst, output ControlSignals signal, output SB_in_t sb_in);
    // 使用函数是为了省去填充默认值的麻烦
    function ControlSignals pack_signal(ALU_op_t alu_op = ALU_NONE, ALU_in1_con_t alu_in1_con = ALU_IN1_RS,
                                        ALU_in2_con_t alu_in2_con = ALU_IN2_RT, extend_con_t extend_con = EXTEND_ZERO,
                                        mdu_operation_t mdu_op = MDU_READ_HI, logic mdu_start = 0, logic mem_writeenable = 0,
                                        logic mem_readsigned = 0, DM_size_t mem_size = DM_NONE, logic syscall = 0,
                                        logic gpr_writeenable = 0, GPR_wdata_con_t gpr_wdata_con = GPR_WDATA_ALU,
                                        GPR_wreg_con_t gpr_wreg_con = GPR_WREG_RT, branch_t branch_type = BRANCH_NONE,
                                        jmp_t jmp_type = JMP_NONE, logic overflow_exception = 0);
        ControlSignals signals = '{
            alu_op : alu_op,
            alu_in1_con : alu_in1_con,
            alu_in2_con : alu_in2_con,
            extend_con : extend_con,
            mdu_op : mdu_op,
            mdu_start : mdu_start,
            mem_writeenable : mem_writeenable,
            mem_readsigned : mem_readsigned,
            mem_size : mem_size,
            syscall : syscall,
            gpr_writeenable : gpr_writeenable,
            gpr_wdata_con : gpr_wdata_con,
            gpr_wreg_con : gpr_wreg_con,
            branch_type : branch_type,
            jmp_type : jmp_type,
            overflow_exception : overflow_exception
        };
        return signals;
    endfunction
    function SB_in_t pack_sb_in(logic [4:0] rs = 0, logic [4:0] rt = 0, logic [4:0] rw = 0,
                                stage_t rs_stage = EX_STAGE, stage_t rt_stage = EX_STAGE, stage_t rw_stage = EX_STAGE,
                                SB_mdu_t mdu_use = MDU_NONE, logic special = 0);
        SB_in_t sb_in = '{
            rs : rs,
            rt : rt,
            rw : rw,
            rs_stage : rs_stage,
            rt_stage : rt_stage,
            rw_stage : rw_stage,
            mdu_use : mdu_use,
            special : special
        };
        return sb_in;
    endfunction
    always_comb begin
        // 为了便于管理，signal只要使用到的元件，其信号都必须赋值，即使是默认�??
        // sb_in的stage如果为默认�?�，可以不赋值，因为这个值在大多数情况下都是EX_STAGE，赋值的话代码太�??
        case(inst.R.op)
            6'b000000: begin
                case(inst.R.func)
                    6'b100000: begin // add
                        signal = pack_signal(
                            .alu_op(ALU_ADD),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD),
                            .overflow_exception(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b100001: begin // addu
                        signal = pack_signal(
                            .alu_op(ALU_ADD),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b100010: begin // sub
                        signal = pack_signal(
                            .alu_op(ALU_SUB),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD),
                            .overflow_exception(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b100011: begin // subu
                        signal = pack_signal(
                            .alu_op(ALU_SUB),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b000000: begin // sll
                        signal = pack_signal(
                            .alu_op(ALU_SLL),
                            .alu_in1_con(ALU_IN1_SA),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b000010: begin // srl
                        signal = pack_signal(
                            .alu_op(ALU_SRL),
                            .alu_in1_con(ALU_IN1_SA),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b000011: begin // sra
                        signal = pack_signal(
                            .alu_op(ALU_SRA),
                            .alu_in1_con(ALU_IN1_SA),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b000100: begin // sllv
                        signal = pack_signal(
                            .alu_op(ALU_SLL),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b000110: begin // srlv
                        signal = pack_signal(
                            .alu_op(ALU_SRL),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b000111: begin // srav
                        signal = pack_signal(
                            .alu_op(ALU_SRA),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b100100: begin // and
                        signal = pack_signal(
                            .alu_op(ALU_AND),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b100101: begin // or
                        signal = pack_signal(
                            .alu_op(ALU_OR),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b100110: begin // xor
                        signal = pack_signal(
                            .alu_op(ALU_XOR),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b100111: begin // nor
                        signal = pack_signal(
                            .alu_op(ALU_NOR),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b101010: begin // slt
                        signal = pack_signal(
                            .alu_op(ALU_SLT),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b101011: begin // sltu
                        signal = pack_signal(
                            .alu_op(ALU_SLTU),
                            .alu_in1_con(ALU_IN1_RS),
                            .alu_in2_con(ALU_IN2_RT),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b011000: begin // mult
                        signal = pack_signal(
                            .mdu_op(MDU_START_SIGNED_MUL),
                            .mdu_start(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .mdu_use(MDU_MUL)
                        );
                    end
                    6'b011001: begin // multu
                        signal = pack_signal(
                            .mdu_op(MDU_START_UNSIGNED_MUL),
                            .mdu_start(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .mdu_use(MDU_MUL)
                        );
                    end
                    6'b011010: begin // div
                        signal = pack_signal(
                            .mdu_op(MDU_START_SIGNED_DIV),
                            .mdu_start(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .mdu_use(MDU_DIV)
                        );
                    end
                    6'b011011: begin // divu
                        signal = pack_signal(
                            .mdu_op(MDU_START_UNSIGNED_DIV),
                            .mdu_start(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rt(inst.R.rt),
                            .mdu_use(MDU_DIV)
                        );
                    end
                    6'b010000: begin // mfhi
                        signal = pack_signal(
                            .mdu_op(MDU_READ_HI),
                            .mdu_start(1),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_MDU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rw(inst.R.rd),
                            .mdu_use(MDU_READ)
                        );
                    end
                    6'b010001: begin // mthi
                        signal = pack_signal(
                            .mdu_op(MDU_WRITE_HI),
                            .mdu_start(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .mdu_use(MDU_WRITE)
                        );
                    end
                    6'b010010: begin // mflo
                        signal = pack_signal(
                            .mdu_op(MDU_READ_LO),
                            .mdu_start(1),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_MDU),
                            .gpr_wreg_con(GPR_WREG_RD)
                        );
                        sb_in = pack_sb_in(
                            .rw(inst.R.rd),
                            .mdu_use(MDU_READ)
                        );
                    end
                    6'b010011: begin // mtlo
                        signal = pack_signal(
                            .mdu_op(MDU_WRITE_LO),
                            .mdu_start(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .mdu_use(MDU_WRITE)
                        );
                    end
                    6'b001000: begin // jr
                        signal = pack_signal(
                            .jmp_type(JMP_REG)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs)
                        );
                    end
                    6'b001001: begin // jalr
                        signal = pack_signal(
                            .alu_op(ALU_PC8),
                            .alu_in1_con(ALU_IN1_PC),
                            .gpr_writeenable(1),
                            .gpr_wdata_con(GPR_WDATA_ALU),
                            .gpr_wreg_con(GPR_WREG_RD),
                            .jmp_type(JMP_REG)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs),
                            .rw(inst.R.rd)
                        );
                    end
                    6'b001100: begin // syscall
                        signal = pack_signal(
                            .syscall(1)
                        );
                        sb_in = pack_sb_in(
                            .rs(2),
                            .rt(4),
                            .rs_stage(MEM_STAGE),
                            .rt_stage(MEM_STAGE)
                        );
                    end
                    default: begin
                        signal = pack_signal();
                        sb_in = pack_sb_in();
                    end
                endcase
            end
            6'b001111: begin // lui
                signal = pack_signal(
                    .alu_op(ALU_Y),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_LSHIFT),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rw(inst.R.rt)
                );
            end
            6'b001000: begin // addi
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt)
                );
            end
            6'b001001: begin // addiu
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt)
                );
            end
            6'b001100: begin // andi
                signal = pack_signal(
                    .alu_op(ALU_AND),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_ZERO),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt)
                );
            end
            6'b001101: begin // ori
                signal = pack_signal(
                    .alu_op(ALU_OR),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_ZERO),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt)
                );
            end
            6'b001110: begin // xori
                signal = pack_signal(
                    .alu_op(ALU_XOR),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_ZERO),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt)
                );
            end
            6'b001010: begin // slti
                signal = pack_signal(
                    .alu_op(ALU_SLT),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt)
                );
            end
            6'b001011: begin // sltiu
                signal = pack_signal(
                    .alu_op(ALU_SLTU),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt)
                );
            end
            6'b000100: begin // beq
                signal = pack_signal(
                    .branch_type(BRANCH_EQ),
                    .jmp_type(JMP_BRANCH)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rt(inst.R.rt)
                );
            end
            6'b000101: begin // bne
                signal = pack_signal(
                    .branch_type(BRANCH_NE),
                    .jmp_type(JMP_BRANCH)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rt(inst.R.rt)
                );
            end
            6'b000110: begin // blez
                signal = pack_signal(
                    .branch_type(BRANCH_LE),
                    .jmp_type(JMP_BRANCH)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs)
                );
            end
            6'b000111: begin // bgtz
                signal = pack_signal(
                    .branch_type(BRANCH_GT),
                    .jmp_type(JMP_BRANCH)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs)
                );
            end
            6'b000001: begin
                case(inst.I.rt)
                    5'b00001: begin // bgez
                        signal = pack_signal(
                            .branch_type(BRANCH_GE),
                            .jmp_type(JMP_BRANCH)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs)
                        );
                    end
                    5'b00000: begin // bltz
                        signal = pack_signal(
                            .branch_type(BRANCH_LT),
                            .jmp_type(JMP_BRANCH)
                        );
                        sb_in = pack_sb_in(
                            .rs(inst.R.rs)
                        );
                    end
                    default: begin
                        signal = pack_signal();
                        sb_in = pack_sb_in();
                    end
                endcase
            end
            6'b000010: begin // j
                signal = pack_signal(
                    .jmp_type(JMP_ADDR)
                );
                sb_in = pack_sb_in();
            end
            6'b000011: begin // jal
                signal = pack_signal(
                    .alu_op(ALU_PC8),
                    .alu_in1_con(ALU_IN1_PC),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_ALU),
                    .gpr_wreg_con(GPR_WREG_31),
                    .jmp_type(JMP_ADDR)
                );
                sb_in = pack_sb_in(
                    .rw(31)
                );
            end
            6'b100000: begin // lb
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .mem_readsigned(1),
                    .mem_size(DM_BYTE),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_MEM),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt),
                    .rw_stage(MEM_STAGE)
                );
            end
            6'b100100: begin // lbu
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .mem_readsigned(0),
                    .mem_size(DM_BYTE),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_MEM),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt),
                    .rw_stage(MEM_STAGE)
                );
            end
            6'b100001: begin // lh
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .mem_readsigned(1),
                    .mem_size(DM_HALF),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_MEM),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt),
                    .rw_stage(MEM_STAGE)
                );
            end
            6'b100101: begin // lhu
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .mem_readsigned(0),
                    .mem_size(DM_HALF),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_MEM),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt),
                    .rw_stage(MEM_STAGE)
                );
            end
            6'b100011: begin // lw
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .mem_readsigned(0),
                    .mem_size(DM_WORD),
                    .gpr_writeenable(1),
                    .gpr_wdata_con(GPR_WDATA_MEM),
                    .gpr_wreg_con(GPR_WREG_RT)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rw(inst.R.rt),
                    .rw_stage(MEM_STAGE)
                );
            end
            6'b101000: begin // sb
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .mem_writeenable(1),
                    .mem_size(DM_BYTE)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rt(inst.R.rt),
                    .rt_stage(MEM_STAGE),
                    .special(1)
                );
            end
            6'b101001: begin // sh
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .mem_writeenable(1),
                    .mem_size(DM_HALF)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rt(inst.R.rt),
                    .rt_stage(MEM_STAGE),
                    .special(1)
                );
            end
            6'b101011: begin // sw
                signal = pack_signal(
                    .alu_op(ALU_ADD),
                    .alu_in1_con(ALU_IN1_RS),
                    .alu_in2_con(ALU_IN2_IMM),
                    .extend_con(EXTEND_SIGN),
                    .mem_writeenable(1),
                    .mem_size(DM_WORD)
                );
                sb_in = pack_sb_in(
                    .rs(inst.R.rs),
                    .rt(inst.R.rt),
                    .rt_stage(MEM_STAGE),
                    .special(1)
                );
            end
            default: begin
                signal = pack_signal();
                sb_in = pack_sb_in();
            end
        endcase
    end
endmodule