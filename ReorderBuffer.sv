`timescale 1us/1us

`include "defs.sv"

typedef struct packed{
    logic data_flag;
    logic end_flag;
    logic [31:0] pc;
    logic [31:0] data;
    logic [31:0] addr;
    logic [4:0] regid;
    ROB_write_t wtype;
} ROB_data_t; // ReorderBuffer data type


module ReorderBuffer(input ROB_in_t inst1, input ROB_in_t inst2, input clock, input reset);
    ROB_data_t inst_queue[32];
    logic [4:0] head;
    reg finished;
    integer inst_count;
    task print();
        if(finished) begin
            #1; $finish; // 尝试解决$finish与$display冲突问题
        end
        if(!inst_queue[head].data_flag) begin
            return;
        end
        inst_count = inst_count + 1;
        $display("inst_cnt: %d", inst_count);
        if(inst_queue[head].end_flag) begin
            finished = 1;
            $finish;
        end
        else if(inst_queue[head].wtype == ROB_REG)
            $display("@%h: $%d <= %h", inst_queue[head].pc, inst_queue[head].regid, inst_queue[head].data);
        else if(inst_queue[head].wtype == ROB_MEM)
            $display("@%h: *%h <= %h", inst_queue[head].pc, inst_queue[head].addr, inst_queue[head].data);
        else if(inst_queue[head].wtype == ROB_OUT)
            $display("%d", inst_queue[head].data);
        inst_queue[head].data_flag = 0;
        head = head + 1;
    endtask

    always_ff @(posedge clock) begin
        if(reset) begin
            inst_count <= 0;
            head <= 0;
            for(int i = 0; i < 32; i++) begin
                inst_queue[i] <= 0;
            end
            finished <= 0;
        end
        else begin
            if(!inst1.null_flag) begin
                inst_queue[inst1.rob_id].end_flag = inst1.end_flag;
                inst_queue[inst1.rob_id].pc = inst1.pc;
                inst_queue[inst1.rob_id].data = inst1.data;
                inst_queue[inst1.rob_id].addr = inst1.addr;
                inst_queue[inst1.rob_id].regid = inst1.regid;
                inst_queue[inst1.rob_id].wtype = inst1.wtype;
                inst_queue[inst1.rob_id].data_flag = 1;
            end
            if(!inst2.null_flag) begin
                inst_queue[inst2.rob_id].end_flag = inst2.end_flag;
                inst_queue[inst2.rob_id].pc = inst2.pc;
                inst_queue[inst2.rob_id].data = inst2.data;
                inst_queue[inst2.rob_id].addr = inst2.addr;
                inst_queue[inst2.rob_id].regid = inst2.regid;
                inst_queue[inst2.rob_id].wtype = inst2.wtype;
                inst_queue[inst2.rob_id].data_flag = 1;
            end
            print();
            print();
        end
    end

    always_ff @(negedge clock) begin
        if(!reset) begin
            print();
            print();
        end
    end
endmodule