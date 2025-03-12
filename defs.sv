`timescale 1us/1us

`ifndef defs_sv
`define defs_sv

`include "MultiplicationDivisionUnit.sv"

//ScoreBoard

typedef enum logic {
    EX_STAGE,
    MEM_STAGE
} stage_t;

typedef enum logic [2:0]{
    MDU_NONE,
    MDU_READ,
    MDU_WRITE,
    MDU_MUL,
    MDU_DIV
} SB_mdu_t; // ScoreBoard MDU type

typedef struct packed{
    logic line; // 旁路来源流水�??
    stage_t stage; // 旁路来源阶段
} forward_source_t;

typedef struct packed{
    logic need_forward; // 是否�??要旁�??
    forward_source_t source; // 旁路来源
    stage_t target; // 旁路目标阶段
} forward_t; 

typedef struct packed{
    logic [4:0] rs, rt, rw; // rs, rt寄存器（如果要读入）和要写入的寄存器，不�??要读/写则�??0
    stage_t rs_stage, rt_stage, rw_stage; // 使用/生成对应数据的阶�??
    SB_mdu_t mdu_use; // MDU类型
    logic special; // 是否为特殊指�??(store, syscall(1))
} SB_in_t; // ScoreBoard input type

typedef struct packed{
    logic block; // 是否阻塞
    logic fakewb; // 是否为假写回
    forward_t rs_forward, rt_forward; // rs, rt旁路信息
} SB_out_t; // ScoreBoard output type

//ALU

typedef enum logic [3:0]{
    ALU_NONE,
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR,
    ALU_XOR,
    ALU_NOR,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA,
    ALU_SLT,
    ALU_SLTU,
    ALU_X,
    ALU_Y,
    ALU_PC8
} ALU_op_t;

// DataMemory

typedef enum logic [1:0]{
    DM_BYTE,
    DM_HALF,
    DM_WORD,
    DM_NONE
} DM_size_t;

typedef struct packed{
    logic [31:0] address; // 地址
    logic [31:0] writeInput; // 写入数据
    logic writeEnabled; // 是否写入
    logic readSigned; // 读取有符号数
    DM_size_t size; // 读取/写入大小
} DM_in_t; // DataMemory input type

typedef struct packed{
    logic [31:0] result; // 读取结果
    logic [31:0] writeData; // 写入数据
    logic [31:0] writeAddr; // 写入地址
} DM_out_t; // DataMemory output type

// GeneralPurposeRegisters

typedef struct packed{
    logic [4:0] read1, read2, write;
    logic writeEnabled;
    logic [31:0] writeData;
} GPR_in_t; // GeneralPurposeRegisters input type

typedef struct packed{
    logic [31:0] read1, read2;
} GPR_out_t; // GeneralPurposeRegisters output type

// ReorderBuffer

typedef enum logic [1:0]{
    ROB_NONE,
    ROB_REG,
    ROB_MEM,
    ROB_OUT
} ROB_write_t; // ReorderBuffer write type

typedef struct packed{
    logic null_flag;
    logic end_flag; // syscall(10)指令
    logic [4:0] rob_id;
    logic [31:0] pc;
    logic [31:0] data;
    logic [31:0] addr;
    logic [4:0] regid;
    ROB_write_t wtype;
} ROB_in_t; // ReorderBuffer input type

// ProgramCounter

typedef struct packed{
    logic block;
    logic is_jmp;
    logic [31:0] jmp_addr;
} PC_in_t; // PC input type

typedef struct packed{
    logic [31:0] pc;
    logic null_flag;
    logic [4:0] rob_id;
} PC_out_t; // PC output type

// Inst
typedef struct packed{
    logic [5:0] op;
    logic [4:0] rs;
    logic [4:0] rt;
    logic [4:0] rd;
    logic [4:0] sa;
    logic [5:0] func;
} R_type_inst;

typedef struct packed{
    logic [5:0] op;
    logic [4:0] rs;
    logic [4:0] rt;
    logic [15:0] imm;
} I_type_inst;

typedef struct packed{
    logic [5:0] op;
    logic [25:0] addr;
} J_type_inst;

typedef union packed{
    R_type_inst R;
    I_type_inst I;
    J_type_inst J;
} Inst;

// ControllerUnit
typedef enum logic[1:0] {
    ALU_IN1_RS,
    ALU_IN1_SA,
    ALU_IN1_PC
} ALU_in1_con_t;

typedef enum logic {
    ALU_IN2_RT,
    ALU_IN2_IMM
} ALU_in2_con_t;

typedef enum logic [1:0]{
    EXTEND_SIGN,
    EXTEND_ZERO,
    EXTEND_LSHIFT
} extend_con_t;

typedef enum logic [1:0]{
    GPR_WDATA_ALU,
    GPR_WDATA_MEM,
    GPR_WDATA_MDU
} GPR_wdata_con_t;

typedef enum logic [1:0]{
    GPR_WREG_RT,
    GPR_WREG_RD,
    GPR_WREG_31
} GPR_wreg_con_t;

typedef enum logic [2:0]{
    BRANCH_NONE,
    BRANCH_EQ,
    BRANCH_NE,
    BRANCH_LT,
    BRANCH_LE,
    BRANCH_GT,
    BRANCH_GE
} branch_t;

typedef enum logic [1:0]{
    JMP_NONE,
    JMP_BRANCH,
    JMP_ADDR,
    JMP_REG
} jmp_t;

typedef struct packed{
    ALU_op_t alu_op;
    ALU_in1_con_t alu_in1_con;
    ALU_in2_con_t alu_in2_con;
    extend_con_t extend_con;
    mdu_operation_t mdu_op;
    logic mdu_start; // 这里的mdu_start除传给mdu外，也作为此指令会使用mdu的信�??
    logic mem_writeenable;
    logic mem_readsigned;
    DM_size_t mem_size;
    logic syscall;
    logic gpr_writeenable;
    GPR_wdata_con_t gpr_wdata_con;
    GPR_wreg_con_t gpr_wreg_con;
    branch_t branch_type;
    jmp_t jmp_type;
    logic overflow_exception;
} ControlSignals;

// PipelineReg
typedef struct packed{
    logic effective;
    logic [31:0] pc;
    logic [4:0] rob_id;
    Inst inst;
    ControlSignals signal;
    logic fakewb;
    forward_t rs_forward, rt_forward;
    logic [31:0] rsvalue, rtvalue, extend_imm, ex_result, mem_result;
    logic [31:0] mem_writeData, mem_writeAddr;
    logic exception;
} PipelineReg_inst_t;

typedef struct packed{
    PipelineReg_inst_t inst1, inst2;
    logic first;
} PipelineReg_t;

`endif

// module definitions
// 说明1，输入信号无序，inst1为流水线1的指令，inst2为流水线2的指�??
// 说明2：由于编码位数，流水�??1的id�??0，流水线2的id�??1
// 说明3：为了配合MDU，下降沿时流水线更新，上升沿时流水线内部实现

// module ScoreBoard
// (input SB_in_t inst1,input SB_in_t inst2, input clock, input reset,
// output SB_out_t out1, output SB_out_t out2, output first);
// inst1,inst2来自同级的controller unit, out1,out2,first输出至流水线寄存器forward,first

// module ALU (input [31:0] x, input [31:0] y, input [3:0] op, output [31:0] res);
// 输入来自流水线寄存器的rsvalue,rtvalue,extend_imm,pc,以及控制信号，输出至流水线寄存器ex_result

// module MultiplicationDivisionUnit(input logic reset, input logic clock, input _mdu_int_t operand1,
//     input _mdu_int_t operand2, input mdu_operation_t operation, input logic start, 
//     output logic busy, output _mdu_int_t dataRead);
// 输入来自流水线寄存器的rsvalue,rtvalue,控制信号，输出至流水线寄存器ex_result

// module DataMemory
// (input DM_in_t inst_1, input DM_in_t inst_2, input clock, input reset, input first,
// output DM_out_t out_1, output DM_out_t out_2);
// 输入来自流水线寄存器的ex_result,rtvalue,控制信号，输出至流水线寄存器mem_result

// module GeneralPurposeRegisters
// (input GPR_in_t inst1, input GPR_in_t inst2, input clock, input reset, input first,
// output GPR_out_t out1, output GPR_out_t out2);
// 输入来自流水线寄存器的inst,控制信号,ex_result,mem_result,输出至流水线寄存器rsvalue,rtvalue

// module InstructionMemory
// (input [31:0] addr1, input [31:0] addr2,
// output [31:0] inst1, output [31:0] inst2);
// 输入来自同级的pc,输出至流水线寄存器inst

// module PC(input PC_in_t inst1,input PC_in_t inst2, input first, input clock, input reset,
//           output PC_out_t out1, output PC_out_t out2);
// 输入来自下一级的controller unit,scoreboard,输出至同级的instruction memory和流水线寄存器pc

// module ReorderBuffer(input ROB_in_t inst1, input ROB_in_t inst2, input clock, input reset);
// 输入来自流水线寄存器的控制信号，ex_result,mem_result

// module ControllerUnit(input Inst inst, output ControlSignals signal, output SB_in_t sb_in);
// 输入来自流水线寄存器的inst,输出至同级的ScoreBoard和流水线寄存器的控制信号

// module PipelineReg (input PipelineReg_t in, input clock, input reset, output PipelineReg_t out);