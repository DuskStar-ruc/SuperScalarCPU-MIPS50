`timescale 1us/1us

`include "defs.sv"

module PC(input PC_in_t inst1,input PC_in_t inst2, input first, input clock, input reset,
          output PC_out_t out1, output PC_out_t out2);
    reg left;
    reg [31:0] pc;
    reg [4:0] rob_id;
    
    PC_in_t inst_fir, inst_sec;
    PC_out_t out_fir, out_sec, out_none;
    wire [4:0] next_rob_id;
    wire [31:0] addr, next_pc;
    wire next_left;

    assign inst_fir = (first==0) ? inst1 : inst2;
    assign inst_sec = (first==0) ? inst2 : inst1;

    assign addr = (inst_fir.is_jmp) ? inst_fir.jmp_addr :
                  (inst_sec.is_jmp) ? inst_sec.jmp_addr :
                                      0; // 反正不会用到
    assign out_fir.rob_id = rob_id; //这里确实可能误分配rob_id，但只要null_flag为1,重复分配的rob_id就不会被使用
    assign out_sec.rob_id = rob_id + 1;
    assign out_none.pc = 32'b0;
    assign out_none.null_flag = 1'b1;
    assign out_none.rob_id = 5'b0;
    
    //以下四个assign为卡诺图分析得到，不具有常规逻辑意义
    assign {out_fir.pc, out_fir.null_flag} = (!inst_fir.is_jmp && left)                       ? {pc, 1'b0} :
                                               ((!inst_fir.block && inst_fir.is_jmp) ||
                                               (!inst_sec.block && inst_sec.is_jmp && !left))   ? {addr, 1'b0} :
                                                                                                  {32'b0, 1'b1};
    assign {out_sec.pc, out_sec.null_flag} = (!inst_fir.is_jmp && !inst_sec.is_jmp)           ? {pc+4, 1'b0} :
                                               (!inst_fir.is_jmp && inst_sec.is_jmp && left)    ? {addr, 1'b0} :
                                                                                                  {addr+4, 1'b0};
    assign next_pc = (inst_fir.block && inst_sec.block)                         ? pc :
                     ((!inst_fir.block && !inst_fir.is_jmp && inst_sec.block)||
                     (!inst_sec.block && !inst_sec.is_jmp && inst_fir.block))   ? pc+4 :
                     (!inst_fir.block && !inst_fir.is_jmp &&
                     !inst_sec.block && !inst_sec.is_jmp)                       ? pc+8 :
                     (!inst_sec.block && inst_sec.is_jmp &&
                     inst_fir.block && left)                                   ? addr :
                     (!inst_fir.block && !inst_sec.block &&
                     (!left || inst_fir.is_jmp))                                ? addr+8 :
                                                                                  addr+4;
    assign next_left = (inst_fir.block && inst_fir.is_jmp) ||
                       (inst_sec.block && inst_sec.is_jmp && (!left || !inst_fir.block)) ? 1'b0 : 1'b1;

    assign out1 = inst1.block ? out_none : out_fir;
    assign out2 = inst2.block ? out_none :
                  inst1.block ? out_fir : out_sec;
    assign next_rob_id = (out1.null_flag && out2.null_flag)   ? rob_id :
                         (!out1.null_flag && !out2.null_flag) ? rob_id+2 :
                                                                rob_id+1;

    always_ff @(negedge clock) begin
        if (reset) begin
            pc <= 32'h00003000;
            rob_id <= 5'b0;
            left <= 1'b1;
        end
        else begin
            pc <= next_pc;
            rob_id <= next_rob_id;
            left <= next_left;
            if (inst1.is_jmp && inst2.is_jmp) begin
                $display("Fatal: found jump instructions in delay slot");
                $stop;
            end
        end
    end 

endmodule